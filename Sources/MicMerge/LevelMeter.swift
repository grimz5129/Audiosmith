import Foundation

enum LevelMeter {
    static func rms(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        let sumOfSquares = samples.reduce(Float(0)) { $0 + $1 * $1 }
        return sqrt(sumOfSquares / Float(samples.count))
    }

    static func normalizedLevel(_ samples: [Float]) -> Float {
        min(1, rms(samples) / 0.25)
    }
}
