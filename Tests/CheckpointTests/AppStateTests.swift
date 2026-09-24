import XCTest
@testable import Checkpoint

final class AppStateTests: XCTestCase {
    private let suiteName = "AppStateTests"
    private var defaults: UserDefaults!
    private var settings: AppSettings!
    private var scheduler: FakeScheduler!
    private var appState: AppState!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        settings = AppSettings(defaults: defaults)
        scheduler = FakeScheduler()
        appState = AppState(settings: settings, scheduler: scheduler)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        appState = nil
        scheduler = nil
        settings = nil
        defaults = nil
        super.tearDown()
    }

    func testSchedulesUsingTheCurrentIntervalOnInit() {
        XCTAssertEqual(scheduler.scheduledInterval, AppSettings.defaultInterval.seconds)
    }

    func testReschedulesWhenIntervalSettingChanges() {
        settings.interval = .twentyFiveMinutes
        XCTAssertEqual(scheduler.scheduledInterval, CheckpointInterval.twentyFiveMinutes.seconds)

        settings.interval = .ninetyMinutes
        XCTAssertEqual(scheduler.scheduledInterval, CheckpointInterval.ninetyMinutes.seconds)
    }

    func testFiringTheSchedulerInvokesOnCheckpointDue() {
        var fireCount = 0
        appState.onCheckpointDue = { fireCount += 1 }

        scheduler.fire()

        XCTAssertEqual(fireCount, 1)
    }

    func testAnUnansweredCheckpointIsNotFiredAgain() {
        var fireCount = 0
        appState.onCheckpointDue = { fireCount += 1 }

        scheduler.fire()
        scheduler.fire()

        XCTAssertEqual(fireCount, 1)
    }

    func testFiringPausesTheCountdownUntilTheCheckpointIsAnswered() {
        scheduler.fire()

        XCTAssertEqual(scheduler.cancelCount, 1)
        XCTAssertEqual(scheduler.scheduleCount, 1)

        appState.checkpointAnswered()

        XCTAssertEqual(scheduler.scheduleCount, 2)
    }

    func testANewCheckpointFiresAfterTheLastOneWasAnswered() {
        var fireCount = 0
        appState.onCheckpointDue = { fireCount += 1 }

        scheduler.fire()
        appState.checkpointAnswered()
        scheduler.fire()

        XCTAssertEqual(fireCount, 2)
    }

    func testChangingTheIntervalWhileWaitingRestartsOnlyOnceAnswered() {
        scheduler.fire()

        settings.interval = .twentyFiveMinutes
        XCTAssertEqual(scheduler.scheduleCount, 1)

        appState.checkpointAnswered()

        XCTAssertEqual(scheduler.scheduleCount, 2)
        XCTAssertEqual(scheduler.scheduledInterval, CheckpointInterval.twentyFiveMinutes.seconds)
    }

    func testAnsweringACheckpointRestartsTheCountdown() {
        XCTAssertEqual(scheduler.scheduleCount, 1)

        appState.checkpointAnswered()

        XCTAssertEqual(scheduler.scheduleCount, 2)
        XCTAssertEqual(scheduler.scheduledInterval, AppSettings.defaultInterval.seconds)
    }

    func testRestartingAfterAnIntervalChangeUsesTheNewInterval() {
        settings.interval = .ninetyMinutes

        appState.checkpointAnswered()

        XCTAssertEqual(scheduler.scheduledInterval, CheckpointInterval.ninetyMinutes.seconds)
    }

    func testCancelsSchedulerOnDeinit() {
        appState = nil
        XCTAssertEqual(scheduler.cancelCount, 1)
    }
}

private final class FakeScheduler: CheckpointScheduling {
    private(set) var scheduledInterval: TimeInterval?
    private(set) var cancelCount = 0
    private(set) var scheduleCount = 0
    private var handler: (() -> Void)?

    func schedule(every interval: TimeInterval, _ handler: @escaping () -> Void) {
        scheduleCount += 1
        scheduledInterval = interval
        self.handler = handler
    }

    func cancel() {
        cancelCount += 1
        // Like a real cancelled Timer: firing afterwards does nothing.
        handler = nil
    }

    func fire() {
        handler?()
    }
}
