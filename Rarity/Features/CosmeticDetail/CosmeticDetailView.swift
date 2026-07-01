import SwiftUI

struct CosmeticDetailView: View {
    let cosmeticID: String
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var subscriptions: SubscriptionManager
    @StateObject private var vm: CosmeticDetailViewModel
    @State private var inWishlist = false
    @State private var showAddReview = false

    init(cosmeticID: String) {
        self.cosmeticID = cosmeticID
        _vm = StateObject(wrappedValue: CosmeticDetailViewModel(cosmeticID: cosmeticID, api: APIClient.shared))
    }

    var body: some View {
        Group {
            if let detail = vm.detail {
                content(detail)
            } else if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = vm.error {
                ContentUnavailableView(err, systemImage: "exclamationmark.triangle")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $vm.showPaywall) {
            PaywallView { vm.showPaywall = false }
        }
        .sheet(isPresented: $showAddReview) {
            AddReviewView(cosmeticID: cosmeticID, api: session.api) { await vm.load() }
        }
        .task { await vm.load() }
    }

    private func content(_ d: CosmeticDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image
                AsyncImage(url: d.imageURL.flatMap(URL.init)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Theme.card2
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(Theme.hint)
                        )
                }
                .frame(maxWidth: .infinity).frame(height: 280)
                .clipped()

                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        if let cat = d.category {
                            Text("\(d.brand) · \(cat.name)")
                                .eyebrowStyle()
                        } else {
                            Text(d.brand).eyebrowStyle()
                        }

                        Text(d.name)
                            .font(.atelierTitle)
                            .foregroundStyle(Theme.ink)

                        if d.reviewCount > 0 {
                            HStack(spacing: 8) {
                                StarRatingView(rating: d.avgRating)
                                Text(String(format: "%.1f", d.avgRating))
                                    .font(.cormorant(size: 17))
                                    .foregroundStyle(Theme.ink)
                                Text("\(d.reviewCount) reviews")
                                    .font(.atelierCaption)
                                    .foregroundStyle(Theme.hint)
                            }
                        }
                    }

                    Rectangle().fill(Theme.separator).frame(height: 0.5)

                    // Description
                    if let desc = d.description {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("About")
                                .font(.jost(.semibold, size: 11))
                                .tracking(2)
                                .textCase(.uppercase)
                                .foregroundStyle(Theme.sub)
                            Text(desc)
                                .font(.atelierBody)
                                .foregroundStyle(Theme.sub)
                                .lineSpacing(4)
                        }
                    }

                    // Ingredients
                    if let ing = d.ingredients {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ingredients")
                                .font(.jost(.semibold, size: 11))
                                .tracking(2)
                                .textCase(.uppercase)
                                .foregroundStyle(Theme.sub)
                            Text(ing)
                                .font(.atelierCaption)
                                .foregroundStyle(Theme.sub)
                                .lineSpacing(3)
                        }
                    }

                    Rectangle().fill(Theme.separator).frame(height: 0.5)

                    // Store locations
                    if !d.stores.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Where to find it")
                                .font(.jost(.semibold, size: 11))
                                .tracking(2)
                                .textCase(.uppercase)
                                .foregroundStyle(Theme.sub)
                                .padding(.bottom, 12)

                            ForEach(Array(d.stores.enumerated()), id: \.element.id) { i, store in
                                NavigationLink(destination: StoreDetailView(storeID: store.id)) {
                                    StoreRowView(store: store)
                                }
                                .buttonStyle(.plain)

                                if i < d.stores.count - 1 {
                                    Rectangle().fill(Theme.separator).frame(height: 0.5)
                                }
                            }
                        }

                        Rectangle().fill(Theme.separator).frame(height: 0.5)
                    }

                    // Reviews
                    HStack {
                        Text("Reviews")
                            .font(.jost(.semibold, size: 11))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundStyle(Theme.sub)
                        Spacer()
                        Button("Write a Review") { showAddReview = true }
                            .font(.jost(size: 13))
                            .foregroundStyle(Theme.brand)
                    }

                    ReviewsView(cosmeticID: cosmeticID, api: session.api)
                }
                .padding(Metrics.page)
            }
        }
        .background(Theme.page.ignoresSafeArea())
        .navigationTitle(d.name)
        .safeAreaInset(edge: .bottom) {
            wishlistCTA
        }
    }

    private var wishlistCTA: some View {
        Button {
            Task {
                if inWishlist { try? await session.api.removeFromWishlist(cosmeticID: cosmeticID) }
                else          { try? await session.api.addToWishlist(cosmeticID: cosmeticID) }
                inWishlist.toggle()
            }
        } label: {
            Text(inWishlist ? "Saved" : "Save")
                .primaryButtonLabel()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(inWishlist ? Theme.brand : .white)
                .background(inWishlist ? Theme.brandSoft : Theme.ink)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusButton))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Metrics.page)
        .padding(.vertical, 14)
        .background(Theme.page.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.separator).frame(height: 0.5)
        }
    }
}

struct StoreRowView: View {
    let store: StoreCard
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.brand)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.name)
                    .font(.atelierCardName)
                    .foregroundStyle(Theme.ink)
                if let city = store.city {
                    Text(city).font(.atelierCaption).foregroundStyle(Theme.sub)
                }
                if let notes = store.notes {
                    Text(notes).font(.atelierCaption).foregroundStyle(Theme.hint)
                }
            }
            Spacer()
            if store.inStock == false {
                Text("Out of stock")
                    .font(.atelierCaption)
                    .foregroundStyle(Theme.destructive)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.hint)
        }
        .padding(.vertical, 14)
    }
}
