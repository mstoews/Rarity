import SwiftUI

struct CosmeticCardView: View {
    let cosmetic: CosmeticCard
    var isSubscribed: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            AsyncImage(url: cosmetic.imageURL.flatMap(URL.init)) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: Metrics.radiusTile)
                    .fill(Theme.card2)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Theme.hint)
                    )
            }
            .frame(width: 66, height: 66)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusTile))

            VStack(alignment: .leading, spacing: 2) {
                if let cat = cosmetic.category {
                    Text(cat.name)
                        .font(.jost(.semibold, size: 9))
                        .tracking(1.5)
                        .textCase(.uppercase)
                        .foregroundStyle(Theme.brand)
                }
                Text(cosmetic.name)
                    .font(.atelierCardName)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text(cosmetic.brand)
                    .font(.jost(size: 12))
                    .foregroundStyle(Theme.sub)

                if isSubscribed, let avg = cosmetic.avgRating,
                   let count = cosmetic.reviewCount, count > 0 {
                    HStack(spacing: 4) {
                        StarRatingView(rating: avg, size: 11)
                        Text("(\(count))")
                            .font(.atelierCaption)
                            .foregroundStyle(Theme.hint)
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: isSubscribed ? "chevron.right" : "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.hint)
        }
        .padding(Metrics.cardPadding)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusTile))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.radiusTile)
                .stroke(Theme.separator, lineWidth: 0.5)
        )
    }
}
