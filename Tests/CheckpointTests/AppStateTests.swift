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
        scheduler.fire()

        XCTAssertEqual(fireCount, 2)
    }

    func testCancelsSchedulerOnDeinit() {
        appState = nil
        XCTAssertEqual(scheduler.cancelCount, 1)
    }
}

private final class FakeScheduler: CheckpointScheduling {
    private(set) var scheduledInterval: TimeInterval?
    private(set) var cancelCount = 0
    private var handler: (() -> Void)?

    func schedule(every interval: TimeInterval, _ handler: @escaping () -> Void) {
        scheduledInterval = interval
        self.handler = handler
    }

    func cancel() {
        cancelCount += 1
    }

    func fire() {
        handler?()
    }
}
