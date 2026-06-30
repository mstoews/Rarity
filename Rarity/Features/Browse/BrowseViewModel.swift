import Foundation

@MainActor
final class BrowseViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var selectedCategoryID: String?
    @Published private(set) var categories: [Category] = []
    @Published private(set) var cosmetics: [CosmeticCard] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasMore = true
    @Published private(set) var error: String?

    private var cursor: String?
    private var searchTask: Task<Void, Never>?
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func loadInitial() async {
        cursor = nil; hasMore = true
        await load(reset: true)
    }

    func loadMore() async {
        guard hasMore, !isLoading else { return }
        await load(reset: false)
    }

    func onSearchChange() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await loadInitial()
        }
    }

    func loadCategories() async {
        guard categories.isEmpty else { return }
        categories = (try? await api.categories()) ?? []
    }

    private func load(reset: Bool) async {
        isLoading = true; error = nil; defer { isLoading = false }
        do {
            let resp = try await api.cosmetics(
                categoryID: selectedCategoryID,
                cursor: reset ? nil : cursor,
                query: searchQuery.isEmpty ? nil : searchQuery)
            if reset { cosmetics = resp.cosmetics } else { cosmetics.append(contentsOf: resp.cosmetics) }
            cursor = resp.nextCursor
            hasMore = resp.nextCursor != nil
        } catch {
            self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}
