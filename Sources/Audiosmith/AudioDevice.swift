import CoreAudio

struct AudioDevice: Identifiable, Equatable, Hashable {
    let id: AudioDeviceID
    let uid: String
    let name: String
    let inputChannelCount: Int

    static func selectableInputs(from devices: [AudioDevice]) -> [AudioDevice] {
        devices.filter { device in
            device.inputChannelCount > 0
                && !device.uid.localizedCaseInsensitiveContains("blackhole")
                && !device.name.localizedCaseInsensitiveContains("blackhole")
                && !device.uid.localizedCaseInsensitiveContains("audiosmith")
                && !device.name.localizedCaseInsensitiveContains("audiosmith")
                && !device.uid.hasPrefix("CADefaultDeviceAggregate")
        }
    }
}
