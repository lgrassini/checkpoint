import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    private static let intervals = CheckpointInterval.allCases

    var body: some View {
        Form {
            Section("Log Folder") {
                HStack {
                    Text(settings.logFolder.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Choose…", action: chooseFolder)
                }
            }

            Section("Checkpoint Interval in Minutes") {
                VStack(alignment: .leading, spacing: 8) {
                    Slider(value: intervalIndexBinding, in: 0...Double(Self.intervals.count - 1), step: 1)
                    HStack {
                        ForEach(Self.intervals, id: \.self) { interval in
                            Text("\(interval.minutes)")
                                .font(.caption)
                                .foregroundStyle(interval == settings.interval ? .primary : .secondary)
                            if interval != Self.intervals.last {
                                Spacer()
                            }
                        }
                    }
                }
            }

            Section("Notifications") {
                Toggle("Play a sound and blink the menu bar icon", isOn: $settings.notificationsEnabled)
                    .toggleStyle(.checkbox)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private var intervalIndexBinding: Binding<Double> {
        Binding(
            get: {
                Double(Self.intervals.firstIndex(of: settings.interval) ?? Self.intervals.count / 2)
            },
            set: { newValue in
                let index = Int(newValue.rounded())
                settings.interval = Self.intervals[index]
            }
        )
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = settings.logFolder
        panel.prompt = "Choose"

        if panel.runModal() == .OK, let url = panel.url {
            settings.logFolder = url
        }
    }
}
