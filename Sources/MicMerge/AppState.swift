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

    private func applyEngineState() {
        let devices = selectedDevices
        if settings.mergeEnabled && !devices.isEmpty {
            engine.restart(inputs: devices, stereoOutput: settings.stereoOutput)
        } else {
            engine.stop()
        }
    }
}
