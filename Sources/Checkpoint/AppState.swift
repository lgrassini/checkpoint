import Foundation
import Combine

/// Fires `onCheckpointDue` every interval, rescheduling automatically
/// whenever the configured interval setting changes. Doesn't know what to
/// do when a checkpoint is due — that's wired up separately (PR 8).
final class AppState {
    private let scheduler: CheckpointScheduling
    private var cancellable: AnyCancellable?

    var onCheckpointDue: (() -> Void)?

    init(settings: AppSettings = .shared, scheduler: CheckpointScheduling = TimerScheduler()) {
        self.scheduler = scheduler

        cancellable = settings.$interval
            .sink { [weak self] interval in
                guard let self else { return }
                self.scheduler.schedule(every: interval.seconds) { [weak self] in
                    self?.onCheckpointDue?()
                }
            }
    }

    deinit {
        scheduler.cancel()
    }
}
