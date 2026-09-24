import SwiftUI

struct SnippetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var trigger: String
    @State private var replacement: String
    @State private var errorMessage: String?

    let snippet: TextSnippet?
    let onSave: (String, String) throws -> Void

    init(snippet: TextSnippet?, onSave: @escaping (String, String) throws -> Void) {
        self.snippet = snippet
        self.onSave = onSave
        _trigger = State(initialValue: snippet?.trigger ?? "")
        _replacement = State(initialValue: snippet?.replacement ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(snippet == nil ? "New Shortcut" : "Edit Shortcut")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Trigger")
                HStack(spacing: 0) {
                    Text("/")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    TextField("email", text: $trigger)
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(.plain)
                }
                .padding(9)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 7))
                Text("Use letters, numbers, underscores, +, or -. Up to 32 characters.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Replacement text")
                TextEditor(text: $replacement)
                    .font(.system(size: 13))
                    .frame(minHeight: 150)
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(.separator, lineWidth: 0.5))
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    do {
                        try onSave(trigger, replacement)
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                .disabled(trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || replacement.isEmpty)
            }
        }
        .padding(22)
        .frame(width: 480)
        .alert("Shortcut could not be saved", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
