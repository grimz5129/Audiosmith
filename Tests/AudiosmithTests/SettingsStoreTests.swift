import XCTest
@testable import Audiosmith

final class SettingsStoreTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "AudiosmithTests")!
        defaults.removePersistentDomain(forName: "AudiosmithTests")
    }

    func testDefaultsAreEmptyAndOff() {
        let store = SettingsStore(defaults: defaults)
        XCTAssertTrue(store.selectedDeviceUIDs.isEmpty)
        XCTAssertFalse(store.mergeEnabled)
        XCTAssertTrue(store.deviceGains.isEmpty)
    }

    func testSelectionsPersistAcrossInstances() {
        let store = SettingsStore(defaults: defaults)
        store.selectedDeviceUIDs = ["jabra-uid", "yealink-uid"]
        store.mergeEnabled = true
        store.deviceGains = ["jabra-uid": 1.5]

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.selectedDeviceUIDs, ["jabra-uid", "yealink-uid"])
        XCTAssertTrue(reloaded.mergeEnabled)
        XCTAssertEqual(reloaded.deviceGains["jabra-uid"] ?? 0, 1.5, accuracy: 0.0001)
    }
}
