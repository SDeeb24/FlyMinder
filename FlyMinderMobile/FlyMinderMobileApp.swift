import SwiftUI

@main
struct FlyMinderMobileApp: App {
    @StateObject private var controller = MobileAppController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controller)
                .environmentObject(FlyMinderSettings.shared)
        }
    }
}
