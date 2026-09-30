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
                            ForEach(model.results.indices, id: \.self) { index in
                                gridCell(at: index).id(index)
                            }
                        }
                    } else {
                        LazyVStack(spacing: 2) {
                            ForEach(model.results.indices, id: \.self) { index in
                                listRow(at: index).id(index)
                            }
                        }
                    }
                }
                .scrollIndicators(.visible)
                if isGrid, model.results.indices.contains(model.selection) {
                    Divider()
                    HStack(spacing: 8) {
                        Text(model.results[model.selection].title)
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
            .onChange(of: model.selection) { _, index in
                withAnimation(.easeOut(duration: 0.12)) { scroll.scrollTo(index, anchor: .center) }
            }
            .onChange(of: model.revision) { _, _ in scroll.scrollTo(0, anchor: .top) }
        }
        .padding(6)
        .frame(width: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.separator, lineWidth: 0.5))
    }

    private func listRow(at index: Int) -> some View {
        let item = model.results[index]
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
        .background(index == model.selection ? Color.accentColor.opacity(0.18) : .clear,
                    in: RoundedRectangle(cornerRadius: 6))
        .overlay(selectionOutline(for: index))
        .contentShape(Rectangle())
        .accessibilityValue(index == model.selection ? "Selected" : "")
        .onTapGesture { choose(index) }
    }

    private func gridCell(at index: Int) -> some View {
        let item = model.results[index]
        return Text(item.replacement)
            .font(.system(size: 27))
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(index == model.selection ? Color.accentColor.opacity(0.18) : .clear,
                        in: RoundedRectangle(cornerRadius: 6))
            .overlay(selectionOutline(for: index))
            .contentShape(Rectangle())
            .help(item.title)
            .accessibilityLabel(item.title)
            .accessibilityValue(index == model.selection ? "Selected" : "")
            .onTapGesture { choose(index) }
    }

    private func selectionOutline(for index: Int) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(index == model.selection ? Color.accentColor.opacity(0.75) : .clear, lineWidth: 1)
            .allowsHitTesting(false)
    }

    private func choose(_ index: Int) {
        guard model.results.indices.contains(index) else { return }
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
        }
    }
}
