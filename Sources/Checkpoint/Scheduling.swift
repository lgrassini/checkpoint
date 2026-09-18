import Foundation

/// Abstracts "run this repeatedly" so orchestration logic (AppState) can be
/// unit tested with a fake, instead of waiting on a real Timer.
protocol CheckpointScheduling {
    func schedule(every interval: TimeInterval, _ handler: @escaping () -> Void)
    func cancel()
}

final class TimerScheduler: CheckpointScheduling {
    private var timer: Timer?

    func schedule(every interval: TimeInterval, _ handler: @escaping () -> Void) {
        cancel()
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            handler()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }
}
