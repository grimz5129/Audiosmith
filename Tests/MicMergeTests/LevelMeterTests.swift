import XCTest
@testable import MicMerge

final class LevelMeterTests: XCTestCase {
    func testRmsOfSilenceIsZero() {
        XCTAssertEqual(LevelMeter.rms([0, 0, 0]), 0)
    }

    func testRmsOfEmptyIsZero() {
        XCTAssertEqual(LevelMeter.rms([]), 0)
    }

    func testRmsOfConstantSignal() {
        XCTAssertEqual(LevelMeter.rms([0.5, -0.5, 0.5, -0.5]), 0.5, accuracy: 0.0001)
    }

    func testNormalizedLevelClampsToOne() {
        XCTAssertEqual(LevelMeter.normalizedLevel([1, -1, 1, -1]), 1.0)
    }
}
