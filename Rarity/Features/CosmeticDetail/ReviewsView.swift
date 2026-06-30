import SwiftUI

struct ReviewsView: View {
    let cosmeticID: String
    let api: APIClient

    @State private var reviews: [Review] = []
    @State private var isLoading = false
    @State private var cursor: String?
    @State private var hasMore = true

    var body: some View {
        VStack(spacing: 12) {
            if isLoading && reviews.isEmpty {
                ProgressView()
            } else if reviews.isEmpty {
                Text("No reviews yet. Be the first!")
                    .font(.subheadline).foregroundStyle(Theme.sub)
                    .padding(.vertical, 12)
            } else {
                ForEach(reviews) { review in
                    ReviewRowView(review: review)
                    if review.id != reviews.last?.id {
                        Divider().overlay(Theme.separator)
                    }
                }
                if hasMore {
                    Button("Load more") { Task { await loadMore() } }
                        .font(.subheadline).foregroundStyle(Theme.brand)
                        .padding(.top, 4)
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true; defer { isLoading = false }
        if let resp = try? await api.reviews(cosmeticID: cosmeticID, cursor: nil) {
            reviews = resp.reviews; cursor = resp.nextCursor; hasMore = resp.nextCursor != nil
        }
    }

    private func loadMore() async {
        guard hasMore, !isLoading, let c = cursor else { return }
        isLoading = true; defer { isLoading = false }
        if let resp = try? await api.reviews(cosmeticID: cosmeticID, cursor: c) {
            reviews.append(contentsOf: resp.reviews)
            cursor = resp.nextCursor; hasMore = resp.nextCursor != nil
        }
    }
}

struct ReviewRowView: View {
    let review: Review
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.user.username).font(.subheadline.bold()).foregroundStyle(Theme.ink)
                Spacer()
                StarRatingView(rating: Double(review.rating))
                Text(review.createdAt, style: .date).font(.caption).foregroundStyle(Theme.hint)
            }
            if let text = review.text, !text.isEmpty {
                Text(text).font(.subheadline).foregroundStyle(Theme.sub)
            }
            if let photoURL = review.photoURL {
                AsyncImage(url: URL(string: photoURL)) { img in
                    img.resizable().scaledToFill()
                } placeholder: { Color.gray.opacity(0.1) }
                .frame(maxWidth: .infinity).frame(height: 160)
                .clipped().cornerRadius(10)
            }
        }
        .padding(.vertical, 4)
    }
}
