import CoreAudio
import Foundation

final class AggregateDeviceController {
    enum AggregateError: Error {
        case creationFailed(OSStatus)
        case noInputs
    }

    private(set) var aggregateID: AudioDeviceID?

    func create(inputs: [AudioDevice], outputUID: String) throws -> AudioDeviceID {
        destroy()
        guard let master = inputs.first else { throw AggregateError.noInputs }

        var subDevices: [[String: Any]] = inputs.map { device in
            [
                kAudioSubDeviceUIDKey: device.uid,
                kAudioSubDeviceDriftCompensationKey: device.uid == master.uid ? 0 : 1
            ]
        }
        subDevices.append([
            kAudioSubDeviceUIDKey: outputUID,
            kAudioSubDeviceDriftCompensationKey: 1
        ])

        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey: "Audiosmith Aggregate",
            kAudioAggregateDeviceUIDKey: "com.yefri.audiosmith.aggregate",
            kAudioAggregateDeviceIsPrivateKey: 1,
            kAudioAggregateDeviceMainSubDeviceKey: master.uid,
            kAudioAggregateDeviceSubDeviceListKey: subDevices
        ]

        var newID = AudioDeviceID(0)
        let status = AudioHardwareCreateAggregateDevice(description as CFDictionary, &newID)
        guard status == noErr else { throw AggregateError.creationFailed(status) }
        aggregateID = newID
        return newID
    }

    func destroy() {
        if let id = aggregateID {
            AudioHardwareDestroyAggregateDevice(id)
            aggregateID = nil
        }
    }

    static func findDeviceUID(named nameFragment: String) -> String? {
        DeviceManager.allDevices()
            .first { $0.name.localizedCaseInsensitiveContains(nameFragment) }?
            .uid
    }

    deinit { destroy() }
}
