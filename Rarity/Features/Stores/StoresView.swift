import SwiftUI

@MainActor
final class StoresViewModel: ObservableObject {
    @Published private(set) var stores: [StoreCard] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let api: APIClient
    init(api: APIClient) { self.api = api }

    func load() async {
        isLoading = true; error = nil; defer { isLoading = false }
        do { stores = try await api.nearbyStores(lat: 49.2827, lng: -123.1207).stores }
        catch { self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription }
    }
}

struct StoresView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var vm: StoresViewModel
    @State private var searchQuery = ""

    init() { _vm = StateObject(wrappedValue: StoresViewModel(api: APIClient())) }

    private var filtered: [StoreCard] {
        guard !searchQuery.isEmpty else { return vm.stores }
        return vm.stores.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            ($0.city ?? "").localizedCaseInsensitiveContains(searchQuery) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.stores.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = vm.error, vm.stores.isEmpty {
                    ContentUnavailableView(err, systemImage: "mappin.slash")
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchQuery)
                } else {
                    List(filtered) { store in
                        NavigationLink(destination: StoreDetailView(storeID: store.id)) {
                            StoreListRow(store: store)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { await vm.load() }
                }
            }
            .background(Theme.page.ignoresSafeArea())
            .navigationTitle("Stores")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchQuery, prompt: "Search stores…")
            .task { await vm.load() }
        }
    }
}

private struct StoreListRow: View {
    let store: StoreCard
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill").font(.system(size: 28)).foregroundStyle(Theme.brand)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.name).font(.subheadline.bold()).foregroundStyle(Theme.ink)
                if let city = store.city { Text(city).font(.footnote).foregroundStyle(Theme.sub) }
            }
        }
        .padding(.vertical, 4)
    }
}
