import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image("menubar")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            Text(AppInfo.name)
                .font(.system(size: 22, weight: .bold))

            Text("Version \(AppInfo.versionString)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Text("A friendly menu bar reminder to get up, walk, and stretch — with a banner that flies across your screen.")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                Link("Website", destination: AppInfo.websiteURL)
                Link("Privacy Policy", destination: AppInfo.privacyPolicyURL)
                Link("Support", destination: URL(string: "mailto:\(AppInfo.supportEmail)")!)
            }
            .font(.system(size: 12))

            Text(AppInfo.copyrightLine)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Text("Includes open-source components licensed under the MIT License.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 320)
    }
}
