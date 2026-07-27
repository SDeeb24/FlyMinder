import Foundation
import AppKit
import Combine
import ServiceManagement

// Central coordinator: owns the stretch scheduler and triggers the flying banner.
@MainActor
final class AppController: ObservableObject {
    @Published var remindersEnabled: Bool {
        didSet { UserDefaults.standard.set(remindersEnabled, forKey: "remindersEnabled") }
    }
    @Published var flightDuration: Double {
        didSet { UserDefaults.standard.set(flightDuration, forKey: "flightDuration") }
    }
    @Published var launchAtLogin: Bool = false
    @Published var secondsUntilNextReminder: Int = 0
    @Published var showWelcomeHint: Bool = !UserDefaults.standard.bool(forKey: "hasSeenWelcome")

    let settings = FlyMinderSettings.shared

    static let maxBannerMessageLength = FlyMinderSettings.maxBannerMessageLength
    static let defaultBannerMessage = FlyMinderSettings.defaultBannerMessage

    /// Preset speeds (seconds for the banner to cross the screen).
    static let slowSpeed:   Double = 22
    static let normalSpeed: Double = 14
    static let fastSpeed:   Double = 8

    /// Reminder interval presets (minutes between alerts).
    static let interval20 = FlyMinderSettings.interval20
    static let interval30 = FlyMinderSettings.interval30
    static let interval45 = FlyMinderSettings.interval45
    static let interval60 = FlyMinderSettings.interval60

    private var scheduler: StretchReminderScheduler?
    private var overlayWindows: [AirplaneOverlayWindow] = []
    private var countdownTimer: Timer?
    private var wakeObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()

    init() {
        let savedSpeed = UserDefaults.standard.double(forKey: "flightDuration")
        self.flightDuration = savedSpeed > 0 ? savedSpeed : Self.normalSpeed

        if UserDefaults.standard.object(forKey: "remindersEnabled") == nil {
            self.remindersEnabled = true
        } else {
            self.remindersEnabled = UserDefaults.standard.bool(forKey: "remindersEnabled")
        }

        launchAtLogin = SMAppService.mainApp.status == .enabled

        settings.$intervalMinutes
            .dropFirst()
            .sink { [weak self] minutes in
                self?.scheduler?.updateInterval(minutes)
            }
            .store(in: &cancellables)

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleWakeFromSleep()
            }
        }

        startSchedulerIfReady()
    }

    deinit {
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
    }

    // MARK: Public

    var bannerMessage: String {
        get { settings.bannerMessage }
        set { settings.setBannerMessage(newValue) }
    }

    var intervalMinutes: Double {
        get { settings.intervalMinutes }
        set { settings.setIntervalMinutes(newValue) }
    }

    func setRemindersEnabled(_ enabled: Bool) {
        remindersEnabled = enabled
        startSchedulerIfReady()
    }

    func setIntervalMinutes(_ minutes: Double) {
        settings.setIntervalMinutes(minutes)
        scheduler?.updateInterval(minutes)
    }

    func setBannerMessage(_ text: String) {
        settings.setBannerMessage(text)
    }

    func dismissWelcome() {
        showWelcomeHint = false
        UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
    }

    /// Enable or disable launching the app automatically at login.
    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Failed to update launch-at-login: \(error.localizedDescription)")
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    /// Manual trigger — shows the banner immediately and resets the countdown.
    func testReminder() {
        showBanner(message: effectiveBannerMessage)
        scheduler?.resetCountdown()
        updateCountdown()
    }

    var effectiveBannerMessage: String {
        settings.effectiveBannerMessage
    }

    static func clampBannerMessage(_ text: String) -> String {
        FlyMinderSettings.clampBannerMessage(text)
    }

    // MARK: Private

    private func startSchedulerIfReady() {
        scheduler?.stop()
        scheduler = nil
        stopCountdownTimer()
        guard remindersEnabled else { return }

        let s = StretchReminderScheduler(intervalMinutes: settings.intervalMinutes)
        s.messageProvider = { [weak self] in
            self?.effectiveBannerMessage ?? Self.defaultBannerMessage
        }
        s.onReminder = { [weak self] message in
            self?.showBanner(message: message)
        }
        s.onSchedule = { [weak self] in
            self?.updateCountdown()
        }
        s.start()
        scheduler = s
        startCountdownTimer()
    }

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        updateCountdown()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
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

    private func handleWakeFromSleep() {
        scheduler?.refreshAfterWake()
        updateCountdown()
    }

    private func showBanner(message: String) {
        let duration = flightDuration
        DispatchQueue.main.async {
            let screens = NSScreen.screens.isEmpty ? [NSScreen.main].compactMap { $0 } : NSScreen.screens
            for screen in screens {
                let window = AirplaneOverlayWindow(
                    message:        message,
                    flightDuration: duration,
                    screen:         screen
                )
                window.makeKeyAndOrderFront(nil)
                self.overlayWindows.append(window)

                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1.5) {
                    self.overlayWindows.removeAll { $0 === window }
                    window.close()
                }
            }
        }
    }
}
