import SwiftUI

struct PromptView: View {
    let intervalMinutes: Int
    var onSubmit: (String) -> Void
    var onCancel: () -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What did you spend the last \(intervalMinutes) minutes on?")
                .font(.headline)

            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor))
                )
                .focused($isFocused)
                .frame(minHeight: 80, maxHeight: .infinity)

            HStack {
                Spacer()
                Button("Skip", role: .cancel, action: onCancel)
                    .keyboardShortcut(.escape)

                Button("Log It", action: submit)
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                    .disabled(trimmedText.isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 320, maxWidth: .infinity, minHeight: 160, maxHeight: .infinity)
        .background(
            // Return alone inserts a newline while the text editor is
            // focused; Cmd+Return submits from anywhere in the window.
            Button("", action: submit)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(trimmedText.isEmpty)
                .opacity(0)
                .accessibilityHidden(true)
        )
        .onAppear { isFocused = true }
    }

    private func submit() {
        guard !trimmedText.isEmpty else { return }
        onSubmit(trimmedText)
    }
}
