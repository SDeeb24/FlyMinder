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
            Image("menubar")
        }
        .menuBarExtraStyle(.window)
    }
}
