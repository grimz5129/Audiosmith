import CoreAudio
import Foundation

final class AudioEngine: ObservableObject {
    @Published private(set) var outputLevel: Float = 0
    @Published private(set) var isRunning = false
    @Published private(set) var lastError: String?

    private let aggregateController = AggregateDeviceController()
    private var aggregateID: AudioDeviceID?
    private var ioProcID: AudioDeviceIOProcID?
    private let mixState = MixState()
    private var levelTimer: Timer?

    func start(inputs: [AudioDevice], gains: [String: Float]) {
        stop()
        guard !inputs.isEmpty else { return }
        guard let blackHoleUID = AggregateDeviceController.findDeviceUID(named: "BlackHole") else {
            lastError = "BlackHole driver not found. Install it with: brew install blackhole-2ch"
            return
        }

        do {
            let aggID = try aggregateController.create(inputs: inputs, outputUID: blackHoleUID)
            mixState.setChannelGains(Mixer.perChannelGains(inputs: inputs, gains: gains))
            try startIOProc(on: aggID)
            aggregateID = aggID
            lastError = nil
            isRunning = true
            startLevelTimer()
        } catch {
            lastError = "Audio start failed: \(error)"
            stop()
        }
    }

    func updateGains(inputs: [AudioDevice], gains: [String: Float]) {
        mixState.setChannelGains(Mixer.perChannelGains(inputs: inputs, gains: gains))
    }

    func stop() {
        levelTimer?.invalidate()
        levelTimer = nil
        if let aggID = aggregateID, let proc = ioProcID {
            AudioDeviceStop(aggID, proc)
            AudioDeviceDestroyIOProcID(aggID, proc)
        }
        ioProcID = nil
        aggregateID = nil
        aggregateController.destroy()
        isRunning = false
        outputLevel = 0
    }

    func restart(inputs: [AudioDevice], gains: [String: Float]) {
        start(inputs: inputs, gains: gains)
    }

    private enum EngineError: Error {
        case ioProcCreationFailed(OSStatus)
        case deviceStartFailed(OSStatus)
    }

    private func startIOProc(on aggID: AudioDeviceID) throws {
        var procID: AudioDeviceIOProcID?
        let state = mixState
        let status = AudioDeviceCreateIOProcIDWithBlock(&procID, aggID, nil) { _, inputData, _, outputData, _ in
            state.process(input: inputData, output: outputData)
        }
        guard status == noErr, let proc = procID else { throw EngineError.ioProcCreationFailed(status) }
        ioProcID = proc

        let startStatus = AudioDeviceStart(aggID, proc)
        guard startStatus == noErr else { throw EngineError.deviceStartFailed(startStatus) }
    }

    private func startLevelTimer() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 15.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.outputLevel = self.mixState.currentLevel
        }
    }
}

// Runs on the HAL realtime thread: no allocation, and only try-locking so the
// audio callback can never block on the main thread. If the lock is contended
// (a gain update in flight) the callback emits one silent buffer instead.
private final class MixState {
    private static let maxFrames = 4096

    private let lock = NSLock()
    private var channelGains: [Float] = []
    private var mono = [Float](repeating: 0, count: MixState.maxFrames)
    private var level: Float = 0

    func setChannelGains(_ gains: [Float]) {
        lock.lock()
        channelGains = gains
        lock.unlock()
    }

    var currentLevel: Float {
        lock.lock()
        defer { lock.unlock() }
        return level
    }

    func process(input: UnsafePointer<AudioBufferList>, output: UnsafeMutablePointer<AudioBufferList>) {
        let outBuffers = UnsafeMutableAudioBufferListPointer(output)
        guard lock.try() else {
            silence(outBuffers)
            return
        }
        defer { lock.unlock() }

        var frames = 0
        for buffer in outBuffers where buffer.mNumberChannels > 0 {
            frames = max(frames, Int(buffer.mDataByteSize) / (MemoryLayout<Float>.size * Int(buffer.mNumberChannels)))
        }
        frames = min(frames, MixState.maxFrames)
        guard frames > 0 else { return }

        for frame in 0..<frames { mono[frame] = 0 }

        // Aggregate input streams arrive in sub-device list order: the selected
        // mics first, BlackHole's loopback channels last. Channels beyond the
        // gain map (BlackHole's) get gain 0, keeping the mix out of its own input.
        let inBuffers = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
        var channelIndex = 0
        for buffer in inBuffers {
            let channels = Int(buffer.mNumberChannels)
            guard channels > 0, let raw = buffer.mData else {
                channelIndex += channels
                continue
            }
            let data = raw.assumingMemoryBound(to: Float.self)
            let bufferFrames = min(frames, Int(buffer.mDataByteSize) / (MemoryLayout<Float>.size * channels))
            for channel in 0..<channels {
                let gain = channelIndex < channelGains.count ? channelGains[channelIndex] : 0
                channelIndex += 1
                guard gain != 0 else { continue }
                for frame in 0..<bufferFrames {
                    mono[frame] += data[frame * channels + channel] * gain
                }
            }
        }

        var sumOfSquares: Float = 0
        for frame in 0..<frames {
            let clipped = Mixer.softClip(mono[frame])
            mono[frame] = clipped
            sumOfSquares += clipped * clipped
        }
        level = min(1, sqrt(sumOfSquares / Float(frames)) / 0.25)

        for buffer in outBuffers {
            let channels = Int(buffer.mNumberChannels)
            guard channels > 0, let raw = buffer.mData else { continue }
            let data = raw.assumingMemoryBound(to: Float.self)
            let bufferFrames = min(frames, Int(buffer.mDataByteSize) / (MemoryLayout<Float>.size * channels))
            for frame in 0..<bufferFrames {
                for channel in 0..<channels {
                    data[frame * channels + channel] = mono[frame]
                }
            }
        }
    }

    private func silence(_ buffers: UnsafeMutableAudioBufferListPointer) {
        for buffer in buffers {
            if let data = buffer.mData {
                memset(data, 0, Int(buffer.mDataByteSize))
            }
        }
    }
}
