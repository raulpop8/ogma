import Combine
import Foundation

final class SnippetStore: ObservableObject {
    enum StoreError: LocalizedError {
        case invalidTrigger
        case emptyReplacement
        case duplicateTrigger
        case unavailable

        var errorDescription: String? {
            switch self {
            case .invalidTrigger: return "Use 1–32 letters, numbers, underscores, +, or - for a shortcut."
            case .emptyReplacement: return "Enter replacement text."
            case .duplicateTrigger: return "That shortcut already exists."
            case .unavailable: return "Saved shortcuts could not be read. The file was left unchanged."
            }
        }
    }

    @Published private(set) var snippets: [TextSnippet] = []
    private let fileURL: URL
    private(set) var loadError: Error?

    init(fileURL: URL? = nil) {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.fileURL = fileURL ?? support.appendingPathComponent("com.raulpop.Ogma/snippets.json")
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: self.fileURL)
            snippets = try JSONDecoder().decode([TextSnippet].self, from: data)
        } catch {
            loadError = error
        }
    }

    func save(id: UUID? = nil, trigger rawTrigger: String, replacement: String) throws {
        guard loadError == nil else { throw StoreError.unavailable }
        let trigger = rawTrigger.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_+-")
        guard (1...32).contains(trigger.count),
              trigger.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            throw StoreError.invalidTrigger
        }
        guard !replacement.isEmpty else { throw StoreError.emptyReplacement }
        guard !snippets.contains(where: { $0.trigger == trigger && $0.id != id }) else {
            throw StoreError.duplicateTrigger
        }
        var updated = snippets
        if let id, let index = updated.firstIndex(where: { $0.id == id }) {
            updated[index].trigger = trigger
            updated[index].replacement = replacement
        } else {
            updated.append(TextSnippet(id: UUID(), trigger: trigger, replacement: replacement, isEnabled: true))
        }
        try persist(updated)
    }

    func setEnabled(_ enabled: Bool, for id: UUID) throws {
        guard loadError == nil else { throw StoreError.unavailable }
        var updated = snippets
        guard let index = updated.firstIndex(where: { $0.id == id }) else { return }
        updated[index].isEnabled = enabled
        try persist(updated)
    }

    func delete(_ id: UUID) throws {
        guard loadError == nil else { throw StoreError.unavailable }
        try persist(snippets.filter { $0.id != id })
    }

    private func persist(_ updated: [TextSnippet]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(updated)
        try data.write(to: fileURL, options: .atomic)
        snippets = updated
    }
}
