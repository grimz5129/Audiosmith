import AVFoundation
import CoreAudio
import Foundation

final class AudioEngine: ObservableObject {
    @Published private(set) var outputLevel: Float = 0
    @Published private(set) var isRunning = false
    @Published private(set) var lastError: String?

    private let aggregateController = AggregateDeviceController()
    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private let ringBuffer = RingBuffer(capacity: 48_000)

    func start(inputs: [AudioDevice], stereoOutput: Bool) {
        stop()
        guard !inputs.isEmpty else { return }
        guard let blackHoleUID = AggregateDeviceController.findDeviceUID(named: "BlackHole") else {
            lastError = "BlackHole driver not found. Install it with: brew install blackhole-2ch"
            return
        }

        do {
            let aggregateID = try aggregateController.create(inputs: inputs, outputUID: blackHoleUID)
            try startEngine(on: aggregateID, stereoOutput: stereoOutput)
            lastError = nil
            isRunning = true
        } catch {
            lastError = "Audio start failed: \(error)"
            stop()
        }
    }

    func stop() {
        engine?.stop()
        engine = nil
        sourceNode = nil
        aggregateController.destroy()
        isRunning = false
        outputLevel = 0
    }

    func restart(inputs: [AudioDevice], stereoOutput: Bool) {
        start(inputs: inputs, stereoOutput: stereoOutput)
    }

    private func startEngine(on aggregateID: AudioDeviceID, stereoOutput: Bool) throws {
        let engine = AVAudioEngine()
        var deviceID = aggregateID
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioUnitSetProperty(engine.inputNode.audioUnit!, kAudioOutputUnitProperty_CurrentDevice,
                             kAudioUnitScope_Global, 0, &deviceID, size)
        AudioUnitSetProperty(engine.outputNode.audioUnit!, kAudioOutputUnitProperty_CurrentDevice,
                             kAudioUnitScope_Global, 0, &deviceID, size)

        let inputFormat = engine.inputNode.inputFormat(forBus: 0)
        let ring = ringBuffer

        engine.inputNode.installTap(onBus: 0, bufferSize: 512, format: inputFormat) { [weak self] buffer, _ in
            let channelCount = Int(buffer.format.channelCount)
            let frameCount = Int(buffer.frameLength)
            guard let channelData = buffer.floatChannelData, frameCount > 0 else { return }
            let channels = (0..<channelCount).map { channel in
                Array(UnsafeBufferPointer(start: channelData[channel], count: frameCount))
            }
            let mono = Mixer.mixDownToMono(channels)
            _ = ring.write(mono)
            let level = LevelMeter.normalizedLevel(mono)
            DispatchQueue.main.async { self?.outputLevel = level }
        }

        let outputChannels: AVAudioChannelCount = 2
        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: inputFormat.sampleRate,
                                         channels: outputChannels)!
        let source = AVAudioSourceNode(format: outputFormat) { _, _, frameCount, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            var mono = [Float](repeating: 0, count: Int(frameCount))
            _ = ring.read(into: &mono, count: Int(frameCount))
            for buffer in buffers {
                guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                for frame in 0..<Int(frameCount) {
                    data[frame] = mono[frame]
                }
            }
            return noErr
        }

        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: outputFormat)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: outputFormat)

        try engine.start()
        self.engine = engine
        self.sourceNode = source
    }
}
