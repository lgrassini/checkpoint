import XCTest
@testable import Checkpoint

/// Uses the real Timer (with tiny intervals) to check behavior the fake
/// scheduler in AppStateTests can't: that cancelling from inside the timer's
/// own handler really stops it, which AppState relies on to pause the
/// countdown while a checkpoint is unanswered.
final class TimerSchedulerTests: XCTestCase {
    func testCancellingFromInsideTheHandlerStopsFurtherFires() {
        let scheduler = TimerScheduler()
        var fireCount = 0
        scheduler.schedule(every: 0.05) {
            fireCount += 1
            scheduler.cancel()
        }

        RunLoop.main.run(until: Date().addingTimeInterval(0.4))

        XCTAssertEqual(fireCount, 1)
    }

    func testSchedulingAgainAfterCancellingFiresAgain() {
        let scheduler = TimerScheduler()
        var fireCount = 0
        let handler = {
            fireCount += 1
            scheduler.cancel()
        }

        scheduler.schedule(every: 0.05, handler)
        RunLoop.main.run(until: Date().addingTimeInterval(0.25))
        XCTAssertEqual(fireCount, 1)

        scheduler.schedule(every: 0.05, handler)
        RunLoop.main.run(until: Date().addingTimeInterval(0.25))
        XCTAssertEqual(fireCount, 2)
    }
}
