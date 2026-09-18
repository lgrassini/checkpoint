import Foundation

struct CheckpointLogger {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Appends a timestamped entry to the day's log file, creating the
    /// folder and/or file as needed. New files get a date header up top.
    /// Returns the URL of the file written to.
    @discardableResult
    func append(_ text: String, to folder: URL, at date: Date = Date(), calendar: Calendar = .current) throws -> URL {
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        let fileURL = folder.appendingPathComponent(Self.filename(for: date, calendar: calendar))
        let entryBlock = "[\(Self.timestamp(for: date, calendar: calendar))] \n\(text)\n\n\n"

        if fileManager.fileExists(atPath: fileURL.path) {
            let handle = try FileHandle(forWritingTo: fileURL)
            defer { try? handle.close() }
            handle.seekToEndOfFile()
            handle.write(Data(entryBlock.utf8))
        } else {
            let header = "\(Self.dateHeader(for: date, calendar: calendar))\n\n"
            try (header + entryBlock).write(to: fileURL, atomically: true, encoding: .utf8)
        }

        return fileURL
    }

    static func filename(for date: Date, calendar: Calendar = .current) -> String {
        "\(dateOnlyFormatter(for: calendar).string(from: date))-Checkpoint.txt"
    }

    /// e.g. "Fri Sep, 18 2026" — written once at the top of each day's file.
    static func dateHeader(for date: Date, calendar: Calendar = .current) -> String {
        dateHeaderFormatter(for: calendar).string(from: date)
    }

    private static func timestamp(for date: Date, calendar: Calendar) -> String {
        timeOnlyFormatter(for: calendar).string(from: date)
    }

    private static func dateOnlyFormatter(for calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private static func timeOnlyFormatter(for calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    private static func dateHeaderFormatter(for calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEE MMM, d yyyy"
        return formatter
    }
}
