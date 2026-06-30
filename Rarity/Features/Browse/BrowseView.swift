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
                // Category chips
                if !vm.categories.isEmpty {
                    CategoryChips(categories: vm.categories, selected: $vm.selectedCategoryID)
                        .onChange(of: vm.selectedCategoryID) { Task { await vm.loadInitial() } }
                }

                Divider().overlay(Theme.separator)

                Group {
                    if vm.cosmetics.isEmpty && vm.isLoading {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let err = vm.error, vm.cosmetics.isEmpty {
                        ContentUnavailableView(err, systemImage: "exclamationmark.triangle")
                    } else if vm.cosmetics.isEmpty {
                        ContentUnavailableView("No products found", systemImage: "sparkles",
                                              description: Text("Try a different category or search term."))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(vm.cosmetics) { cosmetic in
                                    cosmeticRow(cosmetic)
                                        .onAppear {
                                            if cosmetic.id == vm.cosmetics.last?.id {
                                                Task { await vm.loadMore() }
                                            }
                                        }
                                }
                                if vm.isLoading { ProgressView().padding() }
                            }
                            .padding(.horizontal, Metrics.page)
                            .padding(.vertical, 12)
                        }
                        .refreshable { await vm.loadInitial() }
                    }
                }
            }
            .background(Theme.page.ignoresSafeArea())
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
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

    @ViewBuilder
    private func cosmeticRow(_ cosmetic: CosmeticCard) -> some View {
        if session.isSubscribed {
            NavigationLink(destination: CosmeticDetailView(cosmeticID: cosmetic.id)) {
                CosmeticCardView(cosmetic: cosmetic, isSubscribed: true)
            }
            .buttonStyle(.plain)
        } else {
            Button { showPaywall = true } label: {
                CosmeticCardView(cosmetic: cosmetic, isSubscribed: false)
            }
            .buttonStyle(.plain)
        }
    }
}
