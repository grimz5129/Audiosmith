import SwiftUI

@main
struct AudifyApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra("Audify", systemImage: state.engine.isRunning ? "mic.fill.badge.plus" : "mic.badge.plus") {
            ContentView(state: state)
        }
        .menuBarExtraStyle(.window)
    }
}
