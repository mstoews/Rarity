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
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.card2)
                    .overlay(Image(systemName: "sparkles").foregroundStyle(Theme.hint))
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                if let cat = cosmetic.category {
                    Text(cat.name.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.brand)
                        .kerning(0.5)
                }
                Text(cosmetic.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text(cosmetic.brand)
                    .font(.footnote)
                    .foregroundStyle(Theme.sub)

                if isSubscribed, let avg = cosmetic.avgRating, let count = cosmetic.reviewCount, count > 0 {
                    HStack(spacing: 4) {
                        StarRatingView(rating: avg, size: 11)
                        Text("(\(count))").font(.caption2).foregroundStyle(Theme.hint)
                    }
                }
            }

            Spacer(minLength: 0)

            if !isSubscribed {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.hint)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.hint)
            }
        }
        .padding(Metrics.cardPadding)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: Metrics.radiusCard).stroke(Theme.separator, lineWidth: 0.5))
    }
}
