import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var selectedDeviceUIDs: Set<String> {
        didSet { defaults.set(Array(selectedDeviceUIDs), forKey: Keys.selectedUIDs) }
    }
    @Published var mergeEnabled: Bool {
        didSet { defaults.set(mergeEnabled, forKey: Keys.mergeEnabled) }
    }
    @Published var deviceGains: [String: Float] {
        didSet { defaults.set(deviceGains.mapValues(Double.init), forKey: Keys.deviceGains) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let selectedUIDs = "selectedDeviceUIDs"
        static let mergeEnabled = "mergeEnabled"
        static let deviceGains = "deviceGains"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedDeviceUIDs = Set(defaults.stringArray(forKey: Keys.selectedUIDs) ?? [])
        mergeEnabled = defaults.bool(forKey: Keys.mergeEnabled)
        deviceGains = ((defaults.dictionary(forKey: Keys.deviceGains) as? [String: Double]) ?? [:])
            .mapValues(Float.init)
    }
}
