import Foundation

@MainActor
final class MobileReminderScheduler {
    var onReminder: ((String) -> Void)?
    var onSchedule: (() -> Void)?
    var messageProvider: (() -> String)?

    private(set) var nextReminderDate: Date?

    private var timer: Timer?
    private var intervalMinutes: Double

    init(intervalMinutes: Double) {
        self.intervalMinutes = intervalMinutes
    }

    func start() {
        stop()
        scheduleNext(after: intervalMinutes * 60)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        nextReminderDate = nil
    }

    func updateInterval(_ minutes: Double) {
        intervalMinutes = minutes
        start()
    }

    func resetCountdown() {
        start()
    }

    private func scheduleNext(after seconds: TimeInterval) {
        nextReminderDate = Date().addingTimeInterval(seconds)
        onSchedule?()
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.fireReminder()
                self?.start()
            }
        }
    }

    private func fireReminder() {
        let message = messageProvider?() ?? FlyMinderSettings.defaultBannerMessage
        onReminder?(message)
    }
}
