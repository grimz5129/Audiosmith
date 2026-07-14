import AVFoundation
import ServiceManagement
import SwiftUI

struct ContentView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Merge active", isOn: Binding(
                get: { state.settings.mergeEnabled },
                set: { state.setMerge($0) }
            ))
            .toggleStyle(.switch)
            .font(.headline)

            Divider()

            Text("Input devices").font(.caption).foregroundStyle(.secondary)
            if state.deviceManager.inputDevices.isEmpty {
                Text("No input devices found").foregroundStyle(.secondary)
            }
            ForEach(state.deviceManager.inputDevices) { device in
                Toggle(device.name, isOn: Binding(
                    get: { state.settings.selectedDeviceUIDs.contains(device.uid) },
                    set: { _ in state.toggleDevice(device) }
                ))
            }

            Divider()

            HStack {
                Text("Output").font(.caption).foregroundStyle(.secondary)
                LevelBar(level: state.engine.outputLevel)
            }

            Toggle("Launch at login", isOn: Binding(
                get: { SMAppService.mainApp.status == .enabled },
                set: { enabled in
                    try? enabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                }
            ))
            .font(.caption)

            if let error = state.engine.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            if AVCaptureDevice.authorizationStatus(for: .audio) == .denied {
                Button("Microphone access denied — open Privacy settings") {
                    NSWorkspace.shared.open(
                        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
                    )
                }
                .font(.caption)
            }

            Divider()

            Text(state.engine.isRunning
                 ? "Select “BlackHole 2ch” as microphone in your call app"
                 : "Merge is off")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Quit Audify") {
                state.engine.stop()
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}

struct LevelBar: View {
    let level: Float

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(.quaternary)
                RoundedRectangle(cornerRadius: 3)
                    .fill(level > 0.9 ? .red : .green)
                    .frame(width: geometry.size.width * CGFloat(level))
            }
        }
        .frame(height: 8)
        .animation(.linear(duration: 0.1), value: level)
    }
}
