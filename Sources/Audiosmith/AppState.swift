import Combine
import Foundation

final class AppState: ObservableObject {
    let deviceManager = DeviceManager()
    let engine = AudioEngine()
    let settings = SettingsStore()

    private var cancellables = Set<AnyCancellable>()

    var selectedDevices: [AudioDevice] {
        deviceManager.inputDevices.filter { settings.selectedDeviceUIDs.contains($0.uid) }
    }

    init() {
        deviceManager.onDevicesChanged = { [weak self] in
            self?.applyEngineState()
        }
        deviceManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        engine.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        applyEngineState()
    }

    func toggleDevice(_ device: AudioDevice) {
        if settings.selectedDeviceUIDs.contains(device.uid) {
            settings.selectedDeviceUIDs.remove(device.uid)
        } else {
            settings.selectedDeviceUIDs.insert(device.uid)
        }
        applyEngineState()
    }

    func setMerge(_ enabled: Bool) {
        settings.mergeEnabled = enabled
        applyEngineState()
    }

    func setGain(_ device: AudioDevice, to value: Float) {
        settings.deviceGains[device.uid] = value
        engine.updateGains(inputs: selectedDevices, gains: settings.deviceGains)
    }

    private var appliedDeviceUIDs: Set<String>?

    // Starting/stopping the engine destroys/recreates the aggregate device, which
    // itself fires the devices-changed notification that calls this method — so an
    // unconditional restart here loops forever, flashing the mic indicator.
    private func applyEngineState() {
        let devices = selectedDevices
        let shouldRun = settings.mergeEnabled && !devices.isEmpty
        let config = shouldRun ? Set(devices.map(\.uid)) : nil
        guard config != appliedDeviceUIDs else { return }
        appliedDeviceUIDs = config
        if shouldRun {
            engine.restart(inputs: devices, gains: settings.deviceGains)
        } else {
            engine.stop()
        }
    }
}
