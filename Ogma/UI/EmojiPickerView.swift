import SwiftUI

final class EmojiPickerModel: ObservableObject {
    @Published var results: [EmojiItem] = []
    @Published var selection = 0
}

struct EmojiPickerView: View {
    @ObservedObject var model: EmojiPickerModel

    var body: some View {
        VStack(spacing: 2) {
            ForEach(Array(model.results.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 10) {
                    Text(item.emoji)
                        .font(.system(size: 21))
                        .frame(width: 30)
                    Text(item.name)
                        .font(.system(size: 13))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .frame(height: 32)
                .background(index == model.selection ? Color.accentColor.opacity(0.18) : .clear,
                            in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(6)
        .frame(width: 300)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.separator, lineWidth: 0.5))
    }
}
