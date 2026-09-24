import Foundation
import Combine

/// Fires `onCheckpointDue` one interval after the countdown last started.
/// The countdown restarts when the interval setting changes, pauses while a
/// checkpoint is unanswered (so a second one can never stack on top of the
/// first), and restarts again — a full interval — once it's answered.
/// Doesn't know what to do when a checkpoint is due — that's wired up
/// separately (AppDelegate).
final class AppState {
    private let scheduler: CheckpointScheduling
    private var cancellable: AnyCancellable?
    private var isWaitingForAnswer = false

    // Kept separately rather than read from settings on demand: @Published
    // publishes in willSet, so inside the sink `settings.interval` is still
    // the OLD value. The sink's argument is the new one.
    private var interval: CheckpointInterval

    var onCheckpointDue: (() -> Void)?

    init(settings: AppSettings = .shared, scheduler: CheckpointScheduling = TimerScheduler()) {
        self.scheduler = scheduler
        self.interval = settings.interval

        cancellable = settings.$interval
            .sink { [weak self] interval in
                self?.interval = interval
                self?.restartCountdown()
            }
    }

    deinit {
        scheduler.cancel()
    }

    /// Call when the user has dealt with a checkpoint (logged, skipped, or
    /// closed it): the next one is due a full interval from now, not from
    /// whenever the previous countdown happened to start.
    func checkpointAnswered() {
        isWaitingForAnswer = false
        restartCountdown()
    }

    private func restartCountdown() {
        // No countdown runs while a checkpoint is unanswered; it starts
        // again from checkpointAnswered(), using whatever the interval is by
        // then (including one changed in Settings in the meantime).
        guard !isWaitingForAnswer else { return }
        scheduler.schedule(every: interval.seconds) { [weak self] in
            self?.checkpointFired()
        }
    }

    private func checkpointFired() {
        isWaitingForAnswer = true
        scheduler.cancel()
        onCheckpointDue?()
    }
}
