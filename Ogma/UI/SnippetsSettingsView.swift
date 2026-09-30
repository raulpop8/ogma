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
    @State private var searchText = ""

    private var visibleSnippets: [TextSnippet] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.snippets
            .filter { snippet in
                query.isEmpty || snippet.trigger.localizedCaseInsensitiveContains(query)
                    || snippet.replacement.localizedCaseInsensitiveContains(query)
            }
            .sorted { $0.trigger < $1.trigger }
    }

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
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search shortcuts or text", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(8)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 7))

                if visibleSnippets.isEmpty {
                    ContentUnavailableView("No Matching Shortcuts", systemImage: "magnifyingglass",
                        description: Text("Try a different shortcut name or replacement text."))
                } else {
                    List {
                        ForEach(visibleSnippets) { snippet in
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
                                    Text(snippet.replacement)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .help(snippet.replacement)
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
        }
        .padding(20)
        .sheet(item: $editor) { destination in
            SnippetEditorView(snippet: destination.snippet, validationError: { trigger, replacement in
                store.validationError(id: destination.snippet?.id, trigger: trigger, replacement: replacement)
            }) { trigger, replacement in
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
