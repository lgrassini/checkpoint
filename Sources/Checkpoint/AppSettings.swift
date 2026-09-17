import Foundation

enum CheckpointInterval: Int, CaseIterable {
    case twentyFiveMinutes = 25
    case fortyMinutes = 40
    case sixtyMinutes = 60
    case ninetyMinutes = 90

    var minutes: Int { rawValue }
    var seconds: TimeInterval { TimeInterval(rawValue * 60) }
}

final class AppSettings {
    static let shared = AppSettings()

    static let defaultLogFolder = URL(
        fileURLWithPath: NSString(string: "~/Checkpoint").expandingTildeInPath,
        isDirectory: true
    )
    static let defaultInterval = CheckpointInterval.sixtyMinutes

    private enum Keys {
        static let logFolderPath = "logFolderPath"
        static let intervalMinutes = "intervalMinutes"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var logFolder: URL {
        get {
            guard let path = defaults.string(forKey: Keys.logFolderPath) else {
                return Self.defaultLogFolder
            }
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        set {
            defaults.set(newValue.path, forKey: Keys.logFolderPath)
        }
    }

    var interval: CheckpointInterval {
        get {
            let rawValue = defaults.integer(forKey: Keys.intervalMinutes)
            return CheckpointInterval(rawValue: rawValue) ?? Self.defaultInterval
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.intervalMinutes)
        }
    }
}
