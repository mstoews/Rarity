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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        if inWishlist { try? await session.api.removeFromWishlist(cosmeticID: cosmeticID) }
                        else          { try? await session.api.addToWishlist(cosmeticID: cosmeticID) }
                        inWishlist.toggle()
                    }
                } label: {
                    Image(systemName: inWishlist ? "heart.fill" : "heart")
                        .foregroundStyle(inWishlist ? Theme.wishlist : Theme.sub)
                }
            }
        }
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
                    Rectangle().fill(Theme.card2)
                        .overlay(Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(Theme.hint))
                }
                .frame(maxWidth: .infinity).frame(height: 280)
                .clipped()

                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        if let cat = d.category {
                            Text(cat.name.uppercased())
                                .font(.system(size: 11, weight: .semibold)).kerning(0.6)
                                .foregroundStyle(Theme.brand)
                        }
                        Text(d.name).font(.title2.bold()).foregroundStyle(Theme.ink)
                        Text(d.brand).font(.subheadline).foregroundStyle(Theme.sub)
                        if d.reviewCount > 0 {
                            HStack(spacing: 6) {
                                StarRatingView(rating: d.avgRating)
                                Text(String(format: "%.1f", d.avgRating)).font(.subheadline.bold()).foregroundStyle(Theme.ink)
                                Text("(\(d.reviewCount) reviews)").font(.footnote).foregroundStyle(Theme.hint)
                            }
                        }
                    }

                    Divider().overlay(Theme.separator)

                    // Description
                    if let desc = d.description {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("About").font(.headline).foregroundStyle(Theme.ink)
                            Text(desc).font(.body).foregroundStyle(Theme.sub)
                        }
                    }

                    // Ingredients
                    if let ing = d.ingredients {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ingredients").font(.headline).foregroundStyle(Theme.ink)
                            Text(ing).font(.footnote).foregroundStyle(Theme.sub)
                        }
                    }

                    Divider().overlay(Theme.separator)

                    // Stores
                    if !d.stores.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Where to find it").font(.headline).foregroundStyle(Theme.ink)
                            ForEach(d.stores) { store in
                                NavigationLink(destination: StoreDetailView(storeID: store.id)) {
                                    StoreRowView(store: store)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider().overlay(Theme.separator)

                    // Reviews header
                    HStack {
                        Text("Reviews").font(.headline).foregroundStyle(Theme.ink)
                        Spacer()
                        Button("Write a Review") { showAddReview = true }
                            .font(.subheadline).foregroundStyle(Theme.brand)
                    }

                    ReviewsView(cosmeticID: cosmeticID, api: session.api)
                }
                .padding(Metrics.page)
            }
        }
        .background(Theme.page.ignoresSafeArea())
        .navigationTitle(d.name)
    }
}

struct StoreRowView: View {
    let store: StoreCard
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 22)).foregroundStyle(Theme.brand)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.name).font(.subheadline.bold()).foregroundStyle(Theme.ink)
                if let city = store.city {
                    Text(city).font(.footnote).foregroundStyle(Theme.sub)
                }
                if let notes = store.notes {
                    Text(notes).font(.caption).foregroundStyle(Theme.hint)
                }
            }
            Spacer()
            if store.inStock == false {
                Text("Out of stock").font(.caption).foregroundStyle(Theme.systemRed)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.hint)
        }
        .padding(12)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusRow))
        .overlay(RoundedRectangle(cornerRadius: Metrics.radiusRow).stroke(Theme.separator, lineWidth: 0.5))
    }
}
