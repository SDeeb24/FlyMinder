import SwiftUI
import UserNotifications
import Combine

@MainActor
final class MobileAppController: ObservableObject {
    @Published var remindersEnabled: Bool {
        didSet { UserDefaults.standard.set(remindersEnabled, forKey: "mobileRemindersEnabled") }
    }
    @Published var secondsUntilNextReminder: Int = 0
    @Published var showBalloon = false
    @Published var activeMessage = FlyMinderSettings.defaultBannerMessage

    private let settings = FlyMinderSettings.shared
    private var scheduler: StretchReminderScheduler?
    private var countdownTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        if UserDefaults.standard.object(forKey: "mobileRemindersEnabled") == nil {
            remindersEnabled = true
        } else {
            remindersEnabled = UserDefaults.standard.bool(forKey: "mobileRemindersEnabled")
        }

        settings.$intervalMinutes
            .dropFirst()
            .sink { [weak self] minutes in
                self?.scheduler?.updateInterval(minutes)
            }
            .store(in: &cancellables)

        requestNotificationPermission()
        startSchedulerIfReady()
    }

    func setRemindersEnabled(_ enabled: Bool) {
        remindersEnabled = enabled
        startSchedulerIfReady()
    }

    func testReminder() {
        presentBalloon(message: settings.effectiveBannerMessage)
        scheduler?.resetCountdown()
        updateCountdown()
    }

    func onBalloonFinished() {
        showBalloon = false
    }

    // MARK: Private

    private func startSchedulerIfReady() {
        scheduler?.stop()
        scheduler = nil
        stopCountdownTimer()
        guard remindersEnabled else { return }

        let s = StretchReminderScheduler(intervalMinutes: settings.intervalMinutes)
        s.messageProvider = { [weak self] in
            self?.settings.effectiveBannerMessage ?? FlyMinderSettings.defaultBannerMessage
        }
        s.onReminder = { [weak self] message in
            self?.presentBalloon(message: message)
            self?.scheduleNotification()
        }
        s.onSchedule = { [weak self] in
            self?.updateCountdown()
        }
        s.start()
        scheduler = s
        startCountdownTimer()
        scheduleNotification()
    }

    private func presentBalloon(message: String) {
        activeMessage = message
        showBalloon = true
    }

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        updateCountdown()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCountdown()
            }
        }
    }

    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        secondsUntilNextReminder = 0
    }

    private func updateCountdown() {
        guard remindersEnabled, let next = scheduler?.nextReminderDate else {
            secondsUntilNextReminder = 0
            return
        }
        secondsUntilNextReminder = max(0, Int(next.timeIntervalSinceNow.rounded(.down)))
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func scheduleNotification() {
        guard remindersEnabled, let next = scheduler?.nextReminderDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "FlyMinder"
        content.body = settings.effectiveBannerMessage
        content.sound = .default

        let interval = max(1, next.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "flyminder.next", content: content, trigger: trigger)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["flyminder.next"])
        UNUserNotificationCenter.current().add(request)
    }
}
