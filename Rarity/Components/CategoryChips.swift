import SwiftUI

struct CategoryChips: View {
    let categories: [Category]
    @Binding var selected: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 22) {
                chip(id: nil, name: "All")
                ForEach(categories) { cat in chip(id: cat.id, name: cat.name) }
            }
            .padding(.horizontal, Metrics.page)
            .padding(.top, 4)
            .padding(.bottom, 0)
        }
    }

    private func chip(id: String?, name: String) -> some View {
        let active = selected == id
        return Button { selected = id } label: {
            VStack(spacing: 6) {
                Text(name)
                    .font(.jost(active ? .semibold : .regular, size: 12))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(active ? Theme.ink : Theme.hint)
                    .fixedSize()
                Rectangle()
                    .fill(active ? Theme.brand : Color.clear)
                    .frame(height: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}
