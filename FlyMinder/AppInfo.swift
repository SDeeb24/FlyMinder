import Foundation

enum AppInfo {
    static let name = "FlyMinder"
    static let supportEmail = "support@flyminder.app"
    static let websiteURL = URL(string: "https://flyminder.app")!
    static let privacyPolicyURL = URL(string: "https://flyminder.app/privacy.html")!

    static var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    static var copyrightLine: String {
        Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String
            ?? "Copyright © 2026 FlyMinder. All rights reserved."
    }
}
