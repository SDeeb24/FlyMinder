import SwiftUI

@main
struct FlyMinderApp: App {
    @StateObject private var controller = AppController()

    var body: some Scene {
        // Menu bar only — LSUIElement hides the Dock icon.
        MenuBarExtra {
            MenuBarView()
                .environmentObject(controller)
        } label: {
            // SF Symbol stays visible in light and dark menu bars;
            // the custom "menubar" asset was a solid black square (invisible when dark).
            Label("FlyMinder", systemImage: "airplane")
        }
        .menuBarExtraStyle(.window)
    }
}
