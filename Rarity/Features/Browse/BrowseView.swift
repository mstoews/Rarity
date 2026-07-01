import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var subscriptions: SubscriptionManager
    @StateObject private var vm: BrowseViewModel
    @State private var showPaywall = false

    init() { _vm = StateObject(wrappedValue: BrowseViewModel(api: APIClient.shared)) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category chips stay pinned below nav
                if !vm.categories.isEmpty {
                    CategoryChips(categories: vm.categories, selected: $vm.selectedCategoryID)
                        .onChange(of: vm.selectedCategoryID) { Task { await vm.loadInitial() } }
                    Rectangle().fill(Theme.separator).frame(height: 0.5)
                }

                Group {
                    if vm.cosmetics.isEmpty && vm.isLoading {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let err = vm.error, vm.cosmetics.isEmpty {
                        ContentUnavailableView(err, systemImage: "exclamationmark.triangle")
                    } else if vm.cosmetics.isEmpty {
                        ContentUnavailableView(
                            "No products found",
                            systemImage: "sparkles",
                            description: Text("Try a different category or search term.")
                        )
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // Screen title
                                Text("Discover")
                                    .font(.atelierDisplay)
                                    .foregroundStyle(Theme.ink)
                                    .padding(.horizontal, Metrics.page)
                                    .padding(.top, 8)

                                // Editorial hero
                                featuredHero

                                // 2-column product grid
                                LazyVGrid(
                                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                                    spacing: Metrics.listGap
                                ) {
                                    ForEach(vm.cosmetics) { cosmetic in
                                        cosmeticCell(cosmetic)
                                            .onAppear {
                                                if cosmetic.id == vm.cosmetics.last?.id {
                                                    Task { await vm.loadMore() }
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal, Metrics.page)

                                if vm.isLoading {
                                    ProgressView().frame(maxWidth: .infinity).padding()
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .refreshable { await vm.loadInitial() }
                    }
                }
            }
            .background(Theme.page.ignoresSafeArea())
            .navigationTitle("Rarity")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $vm.searchQuery, prompt: "Search cosmetics, brands…")
            .onChange(of: vm.searchQuery) { vm.onSearchChange() }
            .sheet(isPresented: $showPaywall) {
                PaywallView { showPaywall = false }
            }
            .task {
                await vm.loadCategories()
                await vm.loadInitial()
            }
        }
    }

    // Static editorial card — "The Edit"
    private var featuredHero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: 0xEFD9DD), Color(hex: 0xE7D4CB)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(maxWidth: .infinity)
            .frame(height: 168)

            VStack(alignment: .leading, spacing: 6) {
                Text("The Edit")
                    .eyebrowStyle()
                Text("Rare finds for\nquiet rituals")
                    .font(.cormorant(size: 25))
                    .foregroundStyle(Theme.ink)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusCard))
        .padding(.horizontal, Metrics.page)
    }

    @ViewBuilder
    private func cosmeticCell(_ cosmetic: CosmeticCard) -> some View {
        if session.isSubscribed {
            NavigationLink(destination: CosmeticDetailView(cosmeticID: cosmetic.id)) {
                CosmeticGridCard(cosmetic: cosmetic, isSubscribed: true)
            }
            .buttonStyle(.plain)
        } else {
            Button { showPaywall = true } label: {
                CosmeticGridCard(cosmetic: cosmetic, isSubscribed: false)
            }
            .buttonStyle(.plain)
        }
    }
}
