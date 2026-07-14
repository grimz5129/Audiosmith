import XCTest
@testable import MicMerge

final class SettingsStoreTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "MicMergeTests")!
        defaults.removePersistentDomain(forName: "MicMergeTests")
    }

    func testDefaultsAreEmptyAndOff() {
        let store = SettingsStore(defaults: defaults)
        XCTAssertTrue(store.selectedDeviceUIDs.isEmpty)
        XCTAssertFalse(store.mergeEnabled)
        XCTAssertFalse(store.stereoOutput)
    }

    func testSelectionsPersistAcrossInstances() {
        let store = SettingsStore(defaults: defaults)
        store.selectedDeviceUIDs = ["jabra-uid", "yealink-uid"]
        store.mergeEnabled = true
        store.stereoOutput = true

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.selectedDeviceUIDs, ["jabra-uid", "yealink-uid"])
        XCTAssertTrue(reloaded.mergeEnabled)
        XCTAssertTrue(reloaded.stereoOutput)
    }
}
