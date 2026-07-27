import XCTest
@testable import FlyMinder

final class ControllableClock: StretchReminderClock, @unchecked Sendable {
    var now: Date

    init(_ now: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.now = now
    }

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}

@MainActor
final class StretchReminderSchedulerTests: XCTestCase {

    private var clock: ControllableClock!

    override func setUp() {
        super.setUp()
        clock = ControllableClock()
    }

    func testStartSetsNextReminderDateToNowPlusInterval() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 30, clock: clock)
        scheduler.start()

        guard let next = scheduler.nextReminderDate else {
            return XCTFail("Expected nextReminderDate after start")
        }

        XCTAssertEqual(next.timeIntervalSince(clock.now), 30 * 60, accuracy: 0.001)
    }

    func testStopClearsTimerAndNextReminderDate() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 5, clock: clock)
        scheduler.start()
        XCTAssertNotNil(scheduler.nextReminderDate)

        scheduler.stop()

        XCTAssertNil(scheduler.nextReminderDate)
    }

    func testRefreshAfterWakeFiresImmediatelyWhenDateIsPast() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 10, clock: clock)
        var fireCount = 0
        scheduler.onReminder = { _ in fireCount += 1 }

        scheduler.start()
        clock.advance(by: 11 * 60)

        scheduler.refreshAfterWake()

        XCTAssertEqual(fireCount, 1)
        guard let next = scheduler.nextReminderDate else {
            return XCTFail("Expected a new schedule after overdue wake")
        }
        XCTAssertEqual(next.timeIntervalSince(clock.now), 10 * 60, accuracy: 0.001)
    }

    func testRefreshAfterWakeReschedulesRemainderWhenDateIsFuture() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 10, clock: clock)
        var fireCount = 0
        var scheduleCount = 0
        scheduler.onReminder = { _ in fireCount += 1 }
        scheduler.onSchedule = { scheduleCount += 1 }

        scheduler.start()
        XCTAssertEqual(scheduleCount, 1)

        let originalNext = scheduler.nextReminderDate
        clock.advance(by: 3 * 60)

        scheduler.refreshAfterWake()

        XCTAssertEqual(fireCount, 0)
        XCTAssertEqual(scheduleCount, 1, "Should not re-fire onSchedule when only rebuilding the timer")
        XCTAssertEqual(scheduler.nextReminderDate, originalNext)
    }

    func testUpdateIntervalPreservesElapsedProgress() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 30, clock: clock)
        scheduler.start()

        // 10 minutes into a 30-minute cycle → 20 remaining.
        clock.advance(by: 10 * 60)
        scheduler.updateInterval(60)

        // Elapsed 10 of the old cycle; new remaining should be 60 − 10 = 50 minutes.
        guard let next = scheduler.nextReminderDate else {
            return XCTFail("Expected nextReminderDate after updateInterval")
        }
        XCTAssertEqual(next.timeIntervalSince(clock.now), 50 * 60, accuracy: 0.001)
        XCTAssertEqual(scheduler.intervalMinutes, 60)
    }

    func testUpdateIntervalFiresWhenElapsedMeetsNewInterval() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 30, clock: clock)
        var fireCount = 0
        scheduler.onReminder = { _ in fireCount += 1 }

        scheduler.start()
        clock.advance(by: 20 * 60)
        scheduler.updateInterval(15)

        XCTAssertEqual(fireCount, 1)
        guard let next = scheduler.nextReminderDate else {
            return XCTFail("Expected reschedule after immediate fire")
        }
        XCTAssertEqual(next.timeIntervalSince(clock.now), 15 * 60, accuracy: 0.001)
    }

    func testUpdateIntervalWhenStoppedStartsFresh() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 30, clock: clock)
        scheduler.updateInterval(45)

        guard let next = scheduler.nextReminderDate else {
            return XCTFail("Expected nextReminderDate after updateInterval while stopped")
        }
        XCTAssertEqual(next.timeIntervalSince(clock.now), 45 * 60, accuracy: 0.001)
        XCTAssertEqual(scheduler.intervalMinutes, 45)
    }

    func testMessageProviderUsedWhenReminderFires() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 1, clock: clock)
        var received = ""

        scheduler.messageProvider = { "Walk time!" }
        scheduler.onReminder = { message in received = message }
        scheduler.triggerNow()

        XCTAssertEqual(received, "Walk time!")
    }
}
