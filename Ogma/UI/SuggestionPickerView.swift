import SwiftUI

enum EmojiPickerLayout: String, CaseIterable {
    case list
    case grid

    var title: String { self == .list ? "List" : "Grid" }
}

final class SuggestionPickerModel: ObservableObject {
    @Published var results: [SuggestionItem] = []
    @Published var selection = 0
    @Published var revision = 0
    var onSelect: ((SuggestionItem) -> Void)?

    var selectedItem: SuggestionItem? {
        guard results.indices.contains(selection) else { return nil }
        return results[selection]
    }

    var showsEmoji: Bool {
        guard let first = results.first else { return false }
        if case .emoji = first { return true }
        return false
    }
}

struct SuggestionPickerView: View {
    @ObservedObject var model: SuggestionPickerModel
    @AppStorage("emojiPickerLayout") private var layoutName = EmojiPickerLayout.grid.rawValue

    private var isGrid: Bool {
        model.showsEmoji && layoutName == EmojiPickerLayout.grid.rawValue
    }

    var body: some View {
        ScrollViewReader { scroll in
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    if isGrid {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 5), spacing: 2) {
                            ForEach(model.results) { item in
                                gridCell(for: item).id(item.id)
                            }
                        }
                    } else {
                        LazyVStack(spacing: 2) {
                            ForEach(model.results) { item in
                                listRow(for: item).id(item.id)
                            }
                        }
                    }
                }
                .scrollIndicators(.visible)
                if isGrid, let selectedItem = model.selectedItem {
                    Divider()
                    HStack(spacing: 8) {
                        Text(selectedItem.title)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text("\(model.selection + 1) / \(model.results.count)")
                            .monospacedDigit()
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .frame(height: 23)
                }
            }
            .onChange(of: model.selection) { _, _ in
                guard let item = model.selectedItem else { return }
                withAnimation(.easeOut(duration: 0.12)) { scroll.scrollTo(item.id, anchor: .center) }
            }
            .onChange(of: model.revision) { _, _ in
                if let first = model.results.first { scroll.scrollTo(first.id, anchor: .top) }
            }
        }
        .padding(6)
        .frame(width: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.separator, lineWidth: 0.5))
    }

    private func listRow(for item: SuggestionItem) -> some View {
        return HStack(spacing: 10) {
            leadingView(for: item).frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium,
                                  design: item.detail == nil ? .default : .monospaced))
                    .lineLimit(1)
                if let detail = item.detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: item.rowHeight - 2)
        .background(isSelected(item) ? Color.accentColor.opacity(0.18) : .clear,
                    in: RoundedRectangle(cornerRadius: 6))
        .overlay(selectionOutline(for: item))
        .contentShape(Rectangle())
        .accessibilityValue(isSelected(item) ? "Selected" : "")
        .onTapGesture { choose(item) }
    }

    private func gridCell(for item: SuggestionItem) -> some View {
        return Text(item.replacement)
            .font(.system(size: 27))
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(isSelected(item) ? Color.accentColor.opacity(0.18) : .clear,
                        in: RoundedRectangle(cornerRadius: 6))
            .overlay(selectionOutline(for: item))
            .contentShape(Rectangle())
            .help(item.title)
            .accessibilityLabel(item.title)
            .accessibilityValue(isSelected(item) ? "Selected" : "")
            .onTapGesture { choose(item) }
    }

    private func isSelected(_ item: SuggestionItem) -> Bool {
        model.selectedItem?.id == item.id
    }

    private func selectionOutline(for item: SuggestionItem) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(isSelected(item) ? Color.accentColor.opacity(0.75) : .clear, lineWidth: 1)
            .allowsHitTesting(false)
    }

    private func choose(_ item: SuggestionItem) {
        guard let index = model.results.firstIndex(where: { $0.id == item.id }) else { return }
        model.selection = index
        model.onSelect?(model.results[index])
    }

    @ViewBuilder
    private func leadingView(for item: SuggestionItem) -> some View {
        switch item {
        case .emoji(let emoji):
            Text(emoji.emoji).font(.system(size: 21))
        case .snippet:
            Image(systemName: "text.quote")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        case .date:
            Image(systemName: "calendar")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
    }
}
