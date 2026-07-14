import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var selectedDeviceUIDs: Set<String> {
        didSet { defaults.set(Array(selectedDeviceUIDs), forKey: Keys.selectedUIDs) }
    }
    @Published var mergeEnabled: Bool {
        didSet { defaults.set(mergeEnabled, forKey: Keys.mergeEnabled) }
    }
    @Published var stereoOutput: Bool {
        didSet { defaults.set(stereoOutput, forKey: Keys.stereoOutput) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let selectedUIDs = "selectedDeviceUIDs"
        static let mergeEnabled = "mergeEnabled"
        static let stereoOutput = "stereoOutput"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedDeviceUIDs = Set(defaults.stringArray(forKey: Keys.selectedUIDs) ?? [])
        mergeEnabled = defaults.bool(forKey: Keys.mergeEnabled)
        stereoOutput = defaults.bool(forKey: Keys.stereoOutput)
    }
}
