import SwiftUI

@main
struct AudiosmithApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra("Audiosmith", systemImage: state.engine.isRunning ? "mic.fill.badge.plus" : "mic.badge.plus") {
            ContentView(state: state)
        }
        .menuBarExtraStyle(.window)
    }
}
