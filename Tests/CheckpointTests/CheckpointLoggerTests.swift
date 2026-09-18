import XCTest
@testable import Checkpoint

final class CheckpointLoggerTests: XCTestCase {
    private var tempFolder: URL!
    private var logger: CheckpointLogger!
    private var utc: Calendar!

    override func setUp() {
        super.setUp()
        tempFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("CheckpointLoggerTests-\(UUID().uuidString)", isDirectory: true)
        logger = CheckpointLogger()

        utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempFolder)
        tempFolder = nil
        logger = nil
        utc = nil
        super.tearDown()
    }

    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    func testFilenameIsDateFormattedWithCheckpointSuffix() {
        let date = date(year: 2026, month: 1, day: 5, hour: 9, minute: 0)
        XCTAssertEqual(CheckpointLogger.filename(for: date, calendar: utc), "2026-01-05-Checkpoint.txt")
    }

    func testAppendCreatesFolderIfMissing() throws {
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempFolder.path))

        _ = try logger.append("did stuff", to: tempFolder, at: date(year: 2026, month: 1, day: 5, hour: 9, minute: 30), calendar: utc)

        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: tempFolder.path, isDirectory: &isDirectory)
        XCTAssertTrue(exists)
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testAppendWritesTimestampedLine() throws {
        let fileURL = try logger.append(
            "wrote the roadmap",
            to: tempFolder,
            at: date(year: 2026, month: 1, day: 5, hour: 9, minute: 30),
            calendar: utc
        )

        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertEqual(contents, "[09:30] wrote the roadmap\n")
    }

    func testAppendUsesDateAsFilename() throws {
        let fileURL = try logger.append(
            "did stuff",
            to: tempFolder,
            at: date(year: 2026, month: 3, day: 17, hour: 14, minute: 5),
            calendar: utc
        )

        XCTAssertEqual(fileURL.lastPathComponent, "2026-03-17-Checkpoint.txt")
    }

    func testSecondAppendOnSameDayAppendsToSameFile() throws {
        let day = { (hour: Int, minute: Int) in
            self.date(year: 2026, month: 1, day: 5, hour: hour, minute: minute)
        }

        let first = try logger.append("first entry", to: tempFolder, at: day(9, 0), calendar: utc)
        let second = try logger.append("second entry", to: tempFolder, at: day(10, 15), calendar: utc)

        XCTAssertEqual(first, second)
        let contents = try String(contentsOf: second, encoding: .utf8)
        XCTAssertEqual(contents, "[09:00] first entry\n[10:15] second entry\n")
    }

    func testEntriesOnDifferentDaysGoToDifferentFiles() throws {
        let first = try logger.append(
            "day one",
            to: tempFolder,
            at: date(year: 2026, month: 1, day: 5, hour: 23, minute: 55),
            calendar: utc
        )
        let second = try logger.append(
            "day two",
            to: tempFolder,
            at: date(year: 2026, month: 1, day: 6, hour: 0, minute: 5),
            calendar: utc
        )

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(first.lastPathComponent, "2026-01-05-Checkpoint.txt")
        XCTAssertEqual(second.lastPathComponent, "2026-01-06-Checkpoint.txt")
    }
}
