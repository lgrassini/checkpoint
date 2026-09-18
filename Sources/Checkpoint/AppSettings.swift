import Foundation
import Combine

enum CheckpointInterval: Int, CaseIterable {
    case twentyFiveMinutes = 25
    case fortyMinutes = 40
    case sixtyMinutes = 60
    case ninetyMinutes = 90

    var minutes: Int { rawValue }
    var seconds: TimeInterval { TimeInterval(rawValue * 60) }
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    static let defaultLogFolder = URL(
        fileURLWithPath: NSString(string: "~/Checkpoint").expandingTildeInPath,
        isDirectory: true
    )
    static let defaultInterval = CheckpointInterval.sixtyMinutes
    static let defaultNotificationsEnabled = true

    private enum Keys {
        static let logFolderPath = "logFolderPath"
        static let intervalMinutes = "intervalMinutes"
        static let notificationsEnabled = "notificationsEnabled"
    }

    private let defaults: UserDefaults

    @Published var logFolder: URL {
        didSet { defaults.set(logFolder.path, forKey: Keys.logFolderPath) }
    }

    @Published var interval: CheckpointInterval {
        didSet { defaults.set(interval.rawValue, forKey: Keys.intervalMinutes) }
    }

    /// Whether a checkpoint firing should play a sound and blink the menu
    /// bar icon (PRs 11/12). Defaults to on.
    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let path = defaults.string(forKey: Keys.logFolderPath) {
            logFolder = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            logFolder = Self.defaultLogFolder
        }

        let rawInterval = defaults.integer(forKey: Keys.intervalMinutes)
        interval = CheckpointInterval(rawValue: rawInterval) ?? Self.defaultInterval

        if let storedNotificationsEnabled = defaults.object(forKey: Keys.notificationsEnabled) as? Bool {
            notificationsEnabled = storedNotificationsEnabled
        } else {
            notificationsEnabled = Self.defaultNotificationsEnabled
        }
    }
}
