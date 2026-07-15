import XCTest
@testable import Audify

final class MixerTests: XCTestCase {
    private func device(uid: String, inputs: Int) -> AudioDevice {
        AudioDevice(id: 0, uid: uid, name: uid, inputChannelCount: inputs)
    }

    func testSoftClipBoundsSamples() {
        XCTAssertLessThan(Mixer.softClip(10), 1)
        XCTAssertGreaterThan(Mixer.softClip(-10), -1)
        XCTAssertEqual(Mixer.softClip(0), 0)
    }

    func testPerChannelGainsExpandsDeviceChannels() {
        let gains = Mixer.perChannelGains(
            inputs: [device(uid: "mono", inputs: 1), device(uid: "stereo", inputs: 2)],
            gains: ["mono": 0.5, "stereo": 1.5]
        )
        XCTAssertEqual(gains, [0.5, 1.5, 1.5])
    }

    func testPerChannelGainsDefaultsToUnity() {
        let gains = Mixer.perChannelGains(inputs: [device(uid: "mic", inputs: 2)], gains: [:])
        XCTAssertEqual(gains, [1, 1])
    }

    func testPerChannelGainsClampsNegativeToZero() {
        let gains = Mixer.perChannelGains(inputs: [device(uid: "mic", inputs: 1)], gains: ["mic": -1])
        XCTAssertEqual(gains, [0])
    }
}
