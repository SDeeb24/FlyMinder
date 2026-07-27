import Foundation
import os

/// Provides the current time so tests can advance a fake clock without waiting.
protocol StretchReminderClock: Sendable {
    var now: Date { get }
}

struct SystemStretchReminderClock: StretchReminderClock {
    var now: Date { Date() }
}

@MainActor
final class StretchReminderScheduler {
    static let defaultIntervalMinutes: Double = 30

    var onReminder: ((String) -> Void)?
    var onSchedule: (() -> Void)?
    var messageProvider: (() -> String)?

    private(set) var nextReminderDate: Date?
    private(set) var intervalMinutes: Double

    private var timer: Timer?
    private let clock: StretchReminderClock
    private let log = Logger(subsystem: "com.flyminder.app", category: "StretchReminderScheduler")

    init(
        intervalMinutes: Double = defaultIntervalMinutes,
        clock: StretchReminderClock = SystemStretchReminderClock()
    ) {
        self.intervalMinutes = intervalMinutes
        self.clock = clock
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

    /// Apply a new interval while preserving elapsed progress when possible.
    /// If elapsed already meets or exceeds the new interval, fires immediately
    /// and starts a fresh cycle.
    func updateInterval(_ minutes: Double) {
        let previousInterval = intervalMinutes
        intervalMinutes = minutes

        guard let next = nextReminderDate else {
            start()
            return
        }

        let remaining = next.timeIntervalSince(clock.now)
        let elapsed = max(0, previousInterval * 60 - max(0, remaining))
        let newRemaining = minutes * 60 - elapsed

        timer?.invalidate()
        timer = nil

        if newRemaining <= 0 {
            fireReminder()
            start()
        } else {
            scheduleNext(after: newRemaining)
        }
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
        let remaining = next.timeIntervalSince(clock.now)
        if remaining <= 0 {
            fireReminder()
            start()
        } else {
            // Keep the same target date; only rebuild the timer.
            scheduleTimer(after: remaining)
        }
    }

    // MARK: Private

    private func scheduleNext(after seconds: TimeInterval) {
        nextReminderDate = clock.now.addingTimeInterval(seconds)
        onSchedule?()
        scheduleTimer(after: seconds)
    }

    private func scheduleTimer(after seconds: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: max(0, seconds), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.fireReminder()
                self?.start()
            }
        }
    }

    private func fireReminder() {
        let message = messageProvider?() ?? FlyMinderSettings.defaultBannerMessage
        log.info("FIRING reminder: '\(message)'")
        onReminder?(message)
    }
}
