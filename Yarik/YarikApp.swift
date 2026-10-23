import SwiftUI

@main
struct YarikApp: App {
    var body: some Scene {
        WindowGroup {
            YarikRootView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #endif
    }
}
