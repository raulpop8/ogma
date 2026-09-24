import SwiftUI

struct SnippetsSettingsView: View {
    private struct EditorDestination: Identifiable {
        let id = UUID()
        let snippet: TextSnippet?
    }

    @ObservedObject var store: SnippetStore
    @State private var editor: EditorDestination?
    @State private var pendingDelete: TextSnippet?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Text Shortcuts").font(.headline)
                    Text("Type a slash shortcut in another app, then press Return to insert its text.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Add Shortcut") { editor = EditorDestination(snippet: nil) }
                    .disabled(store.loadError != nil)
            }

            if store.loadError != nil {
                ContentUnavailableView("Shortcuts Unavailable", systemImage: "exclamationmark.triangle",
                    description: Text("The saved shortcuts file could not be read. It has not been changed."))
            } else if store.snippets.isEmpty {
                ContentUnavailableView("No Shortcuts Yet", systemImage: "text.quote",
                    description: Text("Add a shortcut such as /email or /thanks."))
            } else {
                List {
                    ForEach(store.snippets.sorted { $0.trigger < $1.trigger }) { snippet in
                        HStack(spacing: 12) {
                            Toggle("", isOn: Binding(
                                get: { snippet.isEnabled },
                                set: { enabled in perform { try store.setEnabled(enabled, for: snippet.id) } }
                            ))
                            .labelsHidden()
                            .accessibilityLabel("Enable /\(snippet.trigger)")
                            VStack(alignment: .leading, spacing: 3) {
                                Text("/" + snippet.trigger)
                                    .font(.system(.body, design: .monospaced).weight(.medium))
                                Text(snippet.replacement.replacingOccurrences(of: "\n", with: " ↵ "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 8)
                            Button("Edit") { editor = EditorDestination(snippet: snippet) }
                            Button("Delete") { pendingDelete = snippet }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
        .padding(20)
        .sheet(item: $editor) { destination in
            SnippetEditorView(snippet: destination.snippet) { trigger, replacement in
                try store.save(id: destination.snippet?.id, trigger: trigger, replacement: replacement)
            }
        }
        .confirmationDialog("Delete /\(pendingDelete?.trigger ?? "")?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Delete Shortcut", role: .destructive) {
                if let pendingDelete { perform { try store.delete(pendingDelete.id) } }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        }
        .alert("Shortcut change failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func perform(_ action: () throws -> Void) {
        do { try action() }
        catch { errorMessage = error.localizedDescription }
    }
}
