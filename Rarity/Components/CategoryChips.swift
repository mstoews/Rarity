import SwiftUI

struct CategoryChips: View {
    let categories: [Category]
    @Binding var selected: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(id: nil, name: "All")
                ForEach(categories) { cat in chip(id: cat.id, name: cat.name) }
            }
            .padding(.horizontal, Metrics.page)
            .padding(.vertical, 6)
        }
    }

    private func chip(id: String?, name: String) -> some View {
        let active = selected == id
        return Button { selected = id } label: {
            Text(name)
                .font(.subheadline.weight(active ? .semibold : .regular))
                .foregroundStyle(active ? .white : Theme.ink)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(active ? Theme.brand : Theme.card2)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
