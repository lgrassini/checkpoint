import XCTest
@testable import Checkpoint

final class AppSettingsTests: XCTestCase {
    private let suiteName = "AppSettingsTests"
    private var defaults: UserDefaults!
    private var settings: AppSettings!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        settings = AppSettings(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        settings = nil
        super.tearDown()
    }

    func testDefaultLogFolderIsUserCheckpointFolder() {
        XCTAssertEqual(settings.logFolder, AppSettings.defaultLogFolder)
        XCTAssertEqual(settings.logFolder.path, NSString(string: "~/Checkpoint").expandingTildeInPath)
    }

    func testDefaultIntervalIsSixtyMinutes() {
        XCTAssertEqual(settings.interval, .sixtyMinutes)
    }

    func testLogFolderPersistsAcrossInstances() {
        let custom = URL(fileURLWithPath: "/tmp/MyCheckpoints", isDirectory: true)
        settings.logFolder = custom
        XCTAssertEqual(settings.logFolder, custom)

        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.logFolder, custom)
    }

    func testIntervalPersistsAcrossInstancesForEveryAllowedValue() {
        for interval in CheckpointInterval.allCases {
            settings.interval = interval
            XCTAssertEqual(settings.interval, interval)

            let reloaded = AppSettings(defaults: defaults)
            XCTAssertEqual(reloaded.interval, interval)
        }
    }

    func testOnlyTheFourSpecifiedIntervalsAreAllowed() {
        XCTAssertEqual(Set(CheckpointInterval.allCases.map(\.minutes)), [25, 40, 60, 90])
    }

    func testInvalidStoredIntervalFallsBackToDefaultOnLoad() {
        defaults.set(999, forKey: "intervalMinutes")
        let reloaded = AppSettings(defaults: defaults)
        XCTAssertEqual(reloaded.interval, AppSettings.defaultInterval)
    }
}
