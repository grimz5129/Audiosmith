import XCTest
@testable import Audify

final class MixerTests: XCTestCase {
    func testMixSumsChannels() {
        let mono = Mixer.mixDownToMono([[0.1, 0.2], [0.3, 0.1]])
        XCTAssertEqual(mono[0], Mixer.softClip(0.4), accuracy: 0.0001)
        XCTAssertEqual(mono[1], Mixer.softClip(0.3), accuracy: 0.0001)
    }

    func testMixEmptyInputReturnsEmpty() {
        XCTAssertEqual(Mixer.mixDownToMono([]), [])
    }

    func testMixUsesShortestChannelLength() {
        XCTAssertEqual(Mixer.mixDownToMono([[0.1, 0.2, 0.3], [0.1]]).count, 1)
    }

    func testSoftClipStaysBelowUnity() {
        XCTAssertLessThan(Mixer.softClip(5.0), 1.0)
        XCTAssertGreaterThan(Mixer.softClip(-5.0), -1.0)
    }

    func testSoftClipIsTransparentForQuietSignals() {
        XCTAssertEqual(Mixer.softClip(0.1), 0.1, accuracy: 0.001)
    }
}
