import Combine
import Foundation

private struct StoredTokens: Codable {
    var accessToken: String
    var refreshToken: String
}

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var user: AuthUser? { didSet { persistUser() } }
    @Published private(set) var subscription: SubscriptionStatus?
    @Published private(set) var isAuthenticated = false
    @Published var authError: String?
    @Published private(set) var isWorking = false

    private static let userKey = "rarity.cachedUser"
    let api = APIClient.shared

    private var tokens: StoredTokens? { didSet { isAuthenticated = tokens != nil } }

    init() {
        api.tokenProvider = { [weak self] in self?.tokens?.accessToken }
        api.tokenRefresher = { [weak self] in await self?.refreshTokens() ?? false }
        restore()
    }

    var isSubscribed: Bool { subscription?.isActive ?? false }

    func bootstrap() async {
        guard isAuthenticated else { return }
        await loadSubscription()
    }

    // MARK: - Auth

    func signInWithApple(identityToken: String, email: String?) async {
        authError = nil; isWorking = true; defer { isWorking = false }
        do { apply(try await api.appleSignIn(identityToken: identityToken, email: email)) }
        catch { authError = msg(error) }
    }
    func logout() {
        tokens = nil; user = nil; subscription = nil
        KeychainStore.clear()
        UserDefaults.standard.removeObject(forKey: Self.userKey)
    }

    // MARK: - Subscription

    func loadSubscription() async {
        do { subscription = try await api.subscriptionStatus() }
        catch APIError.unauthorized { logout() }
        catch {}
    }

    func verifySubscription(signedTransaction: String) async throws {
        let resp = try await api.verifySubscription(signedTransaction: signedTransaction)
        subscription = SubscriptionStatus(subscriptionStatus: resp.subscriptionStatus,
                                          isActive: resp.isActive,
                                          subExpiresAt: resp.subExpiresAt)
    }

    // MARK: - Private

    private func apply(_ resp: LoginResponse) {
        tokens = StoredTokens(accessToken: resp.accessToken, refreshToken: resp.refreshToken)
        user = resp.user
        if let d = try? JSONEncoder().encode(tokens) { KeychainStore.save(d) }
        Task { await loadSubscription() }
    }

    private func refreshTokens() async -> Bool {
        guard let rt = tokens?.refreshToken else { return false }
        do {
            let resp = try await api.refresh(refreshToken: rt)
            tokens?.accessToken = resp.accessToken
            if let d = try? JSONEncoder().encode(tokens) { KeychainStore.save(d) }
            return true
        } catch { logout(); return false }
    }

    private func restore() {
        if let d = KeychainStore.load(), let t = try? JSONDecoder().decode(StoredTokens.self, from: d) { tokens = t }
        if let d = UserDefaults.standard.data(forKey: Self.userKey),
           let u = try? JSONDecoder().decode(AuthUser.self, from: d) { user = u }
    }

    private func persistUser() {
        if let u = user, let d = try? JSONEncoder().encode(u) {
            UserDefaults.standard.set(d, forKey: Self.userKey)
        }
    }

    private func msg(_ error: Error) -> String {
        (error as? APIError)?.errorDescription ?? error.localizedDescription
    }
}
