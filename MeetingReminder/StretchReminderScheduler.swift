import Foundation
import os

@MainActor
final class StretchReminderScheduler {
    static let defaultIntervalMinutes: Double = 30

    var onReminder: ((String) -> Void)?
    var onSchedule: (() -> Void)?
    var messageProvider: (() -> String)?

    private(set) var nextReminderDate: Date?

    private var timer: Timer?
    private var intervalMinutes: Double
    private let log = Logger(subsystem: "com.flyminder.app", category: "StretchReminderScheduler")

    init(intervalMinutes: Double = defaultIntervalMinutes) {
        self.intervalMinutes = intervalMinutes
    }

    func start() {
        stop()
        scheduleNext(after: intervalMinutes * 60)
        log.info("Started — next reminder in \(self.intervalMinutes) min")
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

    /// Restart the countdown without firing a reminder.
    func resetCountdown() {
        start()
    }

    /// Fire a reminder immediately (for testing) and restart the countdown.
    func triggerNow() {
        fireReminder()
        start()
    }

    /// Re-sync the timer after sleep/wake — fires immediately if overdue.
    func refreshAfterWake() {
        guard let next = nextReminderDate else {
            start()
            return
        }
        timer?.invalidate()
        timer = nil
        let remaining = next.timeIntervalSince(Date())
        if remaining <= 0 {
            fireReminder()
            start()
        } else {
            scheduleNext(after: remaining)
        }
    }

    // MARK: Private

    private func scheduleNext(after seconds: TimeInterval) {
        nextReminderDate = Date().addingTimeInterval(seconds)
        onSchedule?()
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.fireReminder()
                self?.start()
            }
        }
    }

    private func fireReminder() {
        let message = messageProvider?() ?? "Get up and stretch!"
        log.info("FIRING reminder: '\(message)'")
        onReminder?(message)
    }
}
