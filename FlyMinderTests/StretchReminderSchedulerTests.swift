import XCTest
@testable import FlyMinder

@MainActor
final class StretchReminderSchedulerTests: XCTestCase {

    func testDefaultIntervalIsThirtyMinutes() {
        XCTAssertEqual(StretchReminderScheduler.defaultIntervalMinutes, 30)
    }

    func testStartSetsNextReminderDate() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 1)
        scheduler.start()

        guard let next = scheduler.nextReminderDate else {
            return XCTFail("Expected nextReminderDate after start")
        }

        let secondsUntil = next.timeIntervalSinceNow
        XCTAssertGreaterThan(secondsUntil, 59)
        XCTAssertLessThanOrEqual(secondsUntil, 60)
    }

    func testStopClearsNextReminderDate() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 5)
        scheduler.start()
        scheduler.stop()

        XCTAssertNil(scheduler.nextReminderDate)
    }

    func testUpdateIntervalReschedules() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 5)
        scheduler.start()
        scheduler.updateInterval(10)

        guard let next = scheduler.nextReminderDate else {
            return XCTFail("Expected nextReminderDate after updateInterval")
        }

        let secondsUntil = next.timeIntervalSinceNow
        XCTAssertGreaterThan(secondsUntil, 9 * 60)
        XCTAssertLessThanOrEqual(secondsUntil, 10 * 60)
    }

    func testMessageProviderUsedWhenReminderFires() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 1)
        let expectation = expectation(description: "reminder fired")
        var received = ""

        scheduler.messageProvider = { "Walk time!" }
        scheduler.onReminder = { message in
            received = message
            expectation.fulfill()
        }

        scheduler.triggerNow()

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(received, "Walk time!")
    }

    func testRefreshAfterWakeKeepsFutureScheduleWhenNotOverdue() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 5)
        scheduler.start()
        scheduler.refreshAfterWake()

        guard let next = scheduler.nextReminderDate else {
            return XCTFail("Expected rescheduled date")
        }
        XCTAssertGreaterThan(next.timeIntervalSinceNow, 0)
    }

    func testResetCountdownWithoutFiring() {
        let scheduler = StretchReminderScheduler(intervalMinutes: 2)
        var fireCount = 0

        scheduler.onReminder = { _ in fireCount += 1 }
        scheduler.start()
        scheduler.resetCountdown()

        XCTAssertEqual(fireCount, 0)
        XCTAssertNotNil(scheduler.nextReminderDate)
    }
}
