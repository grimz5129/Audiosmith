import Foundation

enum Mixer {
    static func softClip(_ sample: Float) -> Float {
        tanh(sample)
    }

    static func perChannelGains(inputs: [AudioDevice], gains: [String: Float]) -> [Float] {
        inputs.flatMap { device in
            [Float](repeating: max(0, gains[device.uid] ?? 1), count: device.inputChannelCount)
        }
    }
}
