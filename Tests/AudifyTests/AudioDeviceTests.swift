import XCTest
@testable import Audify

final class AudioDeviceTests: XCTestCase {
    private func device(uid: String, name: String, inputs: Int) -> AudioDevice {
        AudioDevice(id: 0, uid: uid, name: name, inputChannelCount: inputs)
    }

    func testKeepsOnlyDevicesWithInputChannels() {
        let devices = [
            device(uid: "jabra", name: "Jabra PanaCast 50", inputs: 2),
            device(uid: "display", name: "Studio Display Speakers", inputs: 0)
        ]
        XCTAssertEqual(AudioDevice.selectableInputs(from: devices).map(\.uid), ["jabra"])
    }

    func testExcludesBlackHoleAndOwnAggregate() {
        let devices = [
            device(uid: "BlackHole2ch_UID", name: "BlackHole 2ch", inputs: 2),
            device(uid: "com.yefri.audify.aggregate", name: "Audify Aggregate", inputs: 4),
            device(uid: "yealink", name: "Yealink CP900", inputs: 1)
        ]
        XCTAssertEqual(AudioDevice.selectableInputs(from: devices).map(\.uid), ["yealink"])
    }
}
