import SwiftUI

@main
struct MicMergeApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra("MicMerge", systemImage: state.engine.isRunning ? "mic.fill.badge.plus" : "mic.badge.plus") {
            ContentView(state: state)
        }
        .menuBarExtraStyle(.window)
    }
}
