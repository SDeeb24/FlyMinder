import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var controller: AppController
    @ObservedObject private var settings = FlyMinderSettings.shared
    @State private var showAbout = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if controller.showWelcomeHint {
                    welcomeBanner
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Banner message")
                        .font(.system(size: 12, weight: .semibold))

                    TextField("Type your banner text…", text: Binding(
                        get: { settings.bannerMessage },
                        set: { settings.setBannerMessage($0) }
                    ))
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.secondary.opacity(0.35))
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .textBackgroundColor)))
                    )
                    .frame(minHeight: 28)
                    .accessibilityLabel("Banner message")

                    Text("\(settings.bannerMessage.count)/\(AppController.maxBannerMessageLength) characters")
                        .font(.system(size: 10))
                        .foregroundStyle(
                            settings.bannerMessage.count >= AppController.maxBannerMessageLength
                                ? .orange : .secondary
                        )
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Divider()

                Toggle("Reminders on", isOn: Binding(
                    get: { controller.remindersEnabled },
                    set: { controller.setRemindersEnabled($0) }
                ))
                .toggleStyle(.switch)
                .font(.system(size: 13, weight: .medium))
                .accessibilityLabel("Reminders on")

                if controller.remindersEnabled {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next reminder in")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(controller.countdownText)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .accessibilityLabel("Next reminder in \(controller.countdownText)")

                        Button {
                            controller.walkNow()
                        } label: {
                            Label("Walk Now", systemImage: "figure.walk")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel("Walk Now — reset the reminder countdown")
                        .help("Restart the countdown from a full interval")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remind me every")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Picker("Interval", selection: Binding(
                            get: { settings.intervalMinutes },
                            set: { controller.setIntervalMinutes($0) }
                        )) {
                            Text("20 min").tag(AppController.interval20)
                            Text("30 min").tag(AppController.interval30)
                            Text("45 min").tag(AppController.interval45)
                            Text("60 min").tag(AppController.interval60)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .accessibilityLabel("Reminder interval")
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Banner speed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Picker("Banner speed", selection: $controller.flightDuration) {
                        Text("Slow").tag(AppController.slowSpeed)
                        Text("Normal").tag(AppController.normalSpeed)
                        Text("Fast").tag(AppController.fastSpeed)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .accessibilityLabel("Banner speed")
                }

                Divider()

                Toggle("Start at login", isOn: Binding(
                    get: { controller.launchAtLogin },
                    set: { controller.setLaunchAtLogin($0) }
                ))
                .toggleStyle(.switch)
                .font(.system(size: 13))
                .accessibilityLabel("Start at login")

                Divider()

                Button {
                    controller.testReminder()
                } label: {
                    Label("Test reminder", systemImage: "airplane")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Test reminder")

                Button {
                    showAbout = true
                } label: {
                    Label("About FlyMinder", systemImage: "info.circle")
                }
                .buttonStyle(.plain)

                Divider()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit FlyMinder", systemImage: "power")
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
        .frame(width: 280, height: 500)
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }

    private var welcomeBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Welcome to FlyMinder!")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button {
                    controller.dismissWelcome()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss welcome message")
            }

            Text("Click the airplane in your menu bar anytime to edit your banner message, set a reminder interval, and preview the animation with Test reminder.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.12))
        )
    }
}

private extension AppController {
    var countdownText: String {
        let total = secondsUntilNextReminder
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
