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

    private enum Keys {
        static let logFolderPath = "logFolderPath"
        static let intervalMinutes = "intervalMinutes"
    }

    private let defaults: UserDefaults

    @Published var logFolder: URL {
        didSet { defaults.set(logFolder.path, forKey: Keys.logFolderPath) }
    }

    @Published var interval: CheckpointInterval {
        didSet { defaults.set(interval.rawValue, forKey: Keys.intervalMinutes) }
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
    }
}
