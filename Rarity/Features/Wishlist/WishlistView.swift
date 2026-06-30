import SwiftUI

@MainActor
final class WishlistViewModel: ObservableObject {
    @Published private(set) var cosmetics: [CosmeticCard] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let api: APIClient
    init(api: APIClient) { self.api = api }

    func load() async {
        isLoading = true; error = nil; defer { isLoading = false }
        do { cosmetics = try await api.wishlist().cosmetics }
        catch { self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription }
    }

    func remove(cosmeticID: String) async {
        try? await api.removeFromWishlist(cosmeticID: cosmeticID)
        cosmetics.removeAll { $0.id == cosmeticID }
    }
}

struct WishlistView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var subscriptions: SubscriptionManager
    @StateObject private var vm: WishlistViewModel
    @State private var showPaywall = false

    init() { _vm = StateObject(wrappedValue: WishlistViewModel(api: APIClient())) }

    var body: some View {
        NavigationStack {
            Group {
                if !session.isSubscribed {
                    paywallPrompt
                } else if vm.isLoading && vm.cosmetics.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.cosmetics.isEmpty {
                    ContentUnavailableView("Your wishlist is empty",
                                           systemImage: "heart.slash",
                                           description: Text("Save cosmetics you love to revisit later."))
                } else {
                    List {
                        ForEach(vm.cosmetics) { cosmetic in
                            NavigationLink(destination: CosmeticDetailView(cosmeticID: cosmetic.id)) {
                                CosmeticCardView(cosmetic: cosmetic, isSubscribed: true)
                                    .listRowInsets(.init(top: 4, leading: Metrics.page, bottom: 4, trailing: Metrics.page))
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { idx in
                            let ids = idx.map { vm.cosmetics[$0].id }
                            Task { for id in ids { await vm.remove(cosmeticID: id) } }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.load() }
                }
            }
            .background(Theme.page.ignoresSafeArea())
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) { PaywallView { showPaywall = false } }
            .task {
                if session.isSubscribed { await vm.load() }
            }
            .onChange(of: session.isSubscribed) { subscribed in
                if subscribed { Task { await vm.load() } }
            }
        }
    }

    private var paywallPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 60)).foregroundStyle(Theme.wishlist)
            Text("Unlock Wishlist").font(.title2.bold()).foregroundStyle(Theme.ink)
            Text("Save cosmetics and get full store locations with Rarity+")
                .font(.subheadline).foregroundStyle(Theme.sub).multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Get Rarity+") { showPaywall = true }
                .buttonStyle(.borderedProminent).tint(Theme.brand)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
