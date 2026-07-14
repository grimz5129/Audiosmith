import Foundation

enum Mixer {
    static func softClip(_ sample: Float) -> Float {
        tanh(sample)
    }

    static func mixDownToMono(_ channels: [[Float]]) -> [Float] {
        guard let frameCount = channels.map(\.count).min(), frameCount > 0 else { return [] }
        return (0..<frameCount).map { frame in
            softClip(channels.reduce(0) { $0 + $1[frame] })
        }
    }
}
