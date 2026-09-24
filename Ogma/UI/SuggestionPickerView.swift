import SwiftUI

final class SuggestionPickerModel: ObservableObject {
    @Published var results: [SuggestionItem] = []
    @Published var selection = 0
}

struct SuggestionPickerView: View {
    @ObservedObject var model: SuggestionPickerModel

    var body: some View {
        VStack(spacing: 2) {
            ForEach(Array(model.results.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 10) {
                    leadingView(for: item)
                        .frame(width: 30)
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
            }
        }
        .padding(6)
        .frame(width: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.separator, lineWidth: 0.5))
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
