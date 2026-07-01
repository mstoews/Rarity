import SwiftUI

struct CosmeticGridCard: View {
    let cosmetic: CosmeticCard
    var isSubscribed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Product image tile — 4:3.6 aspect ratio
            AsyncImage(url: cosmetic.imageURL.flatMap(URL.init)) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Theme.card2
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(Theme.hint)
                    )
            }
            .aspectRatio(4 / 3.6, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusTile))
            .overlay(alignment: .topTrailing) {
                if !isSubscribed {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.hint)
                        .padding(8)
                }
            }

            // Text block
            VStack(alignment: .leading, spacing: 2) {
                if let cat = cosmetic.category {
                    Text(cat.name)
                        .eyebrowStyle()
                        .font(.jost(.semibold, size: 9))
                        .tracking(1.5)
                        .padding(.top, 9)
                }
                Text(cosmetic.name)
                    .font(.cormorant(size: 18))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(cosmetic.brand)
                    .font(.jost(size: 12))
                    .foregroundStyle(Theme.sub)
                    .padding(.top, 1)
            }
        }
    }
}
