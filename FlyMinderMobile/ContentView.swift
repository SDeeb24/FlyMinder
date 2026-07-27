import SwiftUI

struct ContentView: View {
    @EnvironmentObject var controller: MobileAppController
    @EnvironmentObject var settings: FlyMinderSettings

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.88, green: 0.94, blue: 1.0), Color(red: 0.78, green: 0.88, blue: 0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("FlyMinder")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Hot air balloon reminders — synced with your Mac via iCloud.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Banner message")
                            .font(.headline)
                        TextField("Type your banner text…", text: Binding(
                            get: { settings.bannerMessage },
                            set: { settings.setBannerMessage($0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                        Text("\(settings.bannerMessage.count)/\(FlyMinderSettings.maxBannerMessageLength) characters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    Toggle("Reminders on", isOn: Binding(
                        get: { controller.remindersEnabled },
                        set: { controller.setRemindersEnabled($0) }
                    ))

                    if controller.remindersEnabled {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Next reminder in")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(controller.countdownText)
                                .font(.system(size: 36, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Remind me every")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Picker("Interval", selection: Binding(
                                get: { settings.intervalMinutes },
                                set: { settings.setIntervalMinutes($0) }
                            )) {
                                Text("20 min").tag(FlyMinderSettings.interval20)
                                Text("30 min").tag(FlyMinderSettings.interval30)
                                Text("45 min").tag(FlyMinderSettings.interval45)
                                Text("60 min").tag(FlyMinderSettings.interval60)
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    Button {
                        controller.testReminder()
                    } label: {
                        Label("Test balloon", systemImage: "balloon.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
                .padding(20)
            }

            if controller.showBalloon {
                BalloonReminderView(message: controller.activeMessage) {
                    controller.onBalloonFinished()
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

private extension MobileAppController {
    var countdownText: String {
        let total = secondsUntilNextReminder
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
        .environmentObject(MobileAppController())
        .environmentObject(FlyMinderSettings.shared)
}
