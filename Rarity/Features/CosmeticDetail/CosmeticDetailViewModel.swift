import Foundation

@MainActor
final class CosmeticDetailViewModel: ObservableObject {
    @Published private(set) var detail: CosmeticDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published var showPaywall = false

    private let api: APIClient
    let cosmeticID: String

    init(cosmeticID: String, api: APIClient) { self.cosmeticID = cosmeticID; self.api = api }

    func load() async {
        isLoading = true; error = nil; defer { isLoading = false }
        do { detail = try await api.cosmeticDetail(id: cosmeticID) }
        catch let e as APIError where e.isPaymentRequired { showPaywall = true }
        catch { self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription }
    }
}
