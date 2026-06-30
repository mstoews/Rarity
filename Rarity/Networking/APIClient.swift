import Foundation

final class APIClient {
    let baseURL: URL
    var tokenProvider: () -> String? = { nil }
    var tokenRefresher: () async -> Bool = { false }

    private let decoder: JSONDecoder
    private let encoder = JSONEncoder()

    init(baseURL: URL = AppConfig.baseURL) {
        self.baseURL = baseURL
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Auth

    func register(email: String, password: String, username: String) async throws -> LoginResponse {
        try await send(path: "/auth/register", method: "POST",
                       body: RegisterBody(email: email, password: password, username: username),
                       authorized: false)
    }
    func login(email: String, password: String) async throws -> LoginResponse {
        try await send(path: "/auth/login", method: "POST",
                       body: LoginBody(email: email, password: password), authorized: false)
    }
    func appleSignIn(identityToken: String, email: String?) async throws -> LoginResponse {
        try await send(path: "/auth/apple", method: "POST",
                       body: AppleSignInBody(identityToken: identityToken, email: email),
                       authorized: false)
    }
    func refresh(refreshToken: String) async throws -> RefreshResponse {
        try await send(path: "/auth/refresh", method: "POST",
                       body: RefreshBody(refreshToken: refreshToken),
                       authorized: false, allowRefresh: false)
    }

    // MARK: - Subscription

    func subscriptionStatus() async throws -> SubscriptionStatus {
        try await send(path: "/subscription/status", authorized: true)
    }
    func verifySubscription(signedTransaction: String) async throws -> VerifyResponse {
        try await send(path: "/subscription/verify", method: "POST",
                       body: VerifyBody(signedTransaction: signedTransaction), authorized: true)
    }

    // MARK: - Categories

    func categories() async throws -> [Category] {
        let resp: CategoriesResponse = try await send(path: "/categories", authorized: false)
        return resp.categories
    }

    // MARK: - Cosmetics

    func cosmetics(categoryID: String?, cursor: String?, query: String?) async throws -> CosmeticsResponse {
        var q: [URLQueryItem] = []
        if let c = categoryID { q.append(.init(name: "category_id", value: c)) }
        if let c = cursor      { q.append(.init(name: "cursor",      value: c)) }
        if let s = query, !s.isEmpty { q.append(.init(name: "q", value: s)) }
        return try await send(path: "/cosmetics", query: q, authorized: true)
    }
    func cosmeticDetail(id: String) async throws -> CosmeticDetail {
        try await send(path: "/cosmetics/\(id)", authorized: true)
    }

    // MARK: - Stores

    func stores(cosmeticID: String) async throws -> StoresResponse {
        try await send(path: "/cosmetics/\(cosmeticID)/stores", authorized: true)
    }
    func nearbyStores(lat: Double, lng: Double) async throws -> StoresResponse {
        try await send(path: "/stores",
                       query: [.init(name: "lat", value: "\(lat)"),
                                .init(name: "lng", value: "\(lng)")],
                       authorized: true)
    }
    func storeDetail(id: String) async throws -> StoreDetail {
        try await send(path: "/stores/\(id)", authorized: true)
    }

    // MARK: - Reviews

    func reviews(cosmeticID: String, cursor: String?) async throws -> ReviewsResponse {
        var q: [URLQueryItem] = []
        if let c = cursor { q.append(.init(name: "cursor", value: c)) }
        return try await send(path: "/cosmetics/\(cosmeticID)/reviews", query: q, authorized: true)
    }
    func addReview(cosmeticID: String, rating: Int, text: String?, photoURL: String?) async throws -> Review {
        try await send(path: "/cosmetics/\(cosmeticID)/reviews", method: "POST",
                       body: AddReviewBody(rating: rating, text: text, photoURL: photoURL),
                       authorized: true)
    }
    func deleteReview(id: String) async throws {
        let _: EmptyResponse = try await send(path: "/reviews/\(id)", method: "DELETE", authorized: true)
    }

    // MARK: - Wishlist

    func wishlist() async throws -> WishlistResponse {
        try await send(path: "/wishlist", authorized: true)
    }
    func addToWishlist(cosmeticID: String) async throws {
        let _: EmptyResponse = try await send(path: "/wishlist/\(cosmeticID)", method: "POST", authorized: true)
    }
    func removeFromWishlist(cosmeticID: String) async throws {
        let _: EmptyResponse = try await send(path: "/wishlist/\(cosmeticID)", method: "DELETE", authorized: true)
    }

    // MARK: - Upload

    func presignedURL(filename: String) async throws -> PresignedURLResponse {
        try await send(path: "/upload/presigned-url", method: "POST",
                       body: PresignedURLBody(filename: filename), authorized: true)
    }
    func uploadImage(to uploadURL: URL, data: Data) async throws {
        var req = URLRequest(url: uploadURL)
        req.httpMethod = "PUT"
        req.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: req, from: data)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
    }

    // MARK: - Core

    private func send<T: Decodable>(
        path: String, method: String = "GET",
        query: [URLQueryItem] = [], body: Encodable? = nil,
        authorized: Bool, allowRefresh: Bool = true
    ) async throws -> T {
        guard var comps = URLComponents(url: baseURL.appendingPathComponent(path),
                                        resolvingAgainstBaseURL: false) else {
            throw APIError.invalidResponse
        }
        if !query.isEmpty { comps.queryItems = query }
        guard let url = comps.url else { throw APIError.invalidResponse }

        var req = URLRequest(url: url)
        req.httpMethod = method
        if let body {
            req.httpBody = try encoder.encode(AnyEncodable(body))
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if authorized, let token = tokenProvider() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do { (data, response) = try await URLSession.shared.data(for: req) }
        catch { throw APIError.transport(error) }

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        switch http.statusCode {
        case 200...299:
            if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T { return empty }
            do { return try decoder.decode(T.self, from: data) }
            catch { throw APIError.decoding(error) }
        case 401:
            if authorized, allowRefresh, await tokenRefresher() {
                return try await send(path: path, method: method, query: query,
                                      body: body, authorized: authorized, allowRefresh: false)
            }
            throw APIError.unauthorized
        case 402: throw APIError.paymentRequired
        case 404: throw APIError.notFound
        default:  throw APIError.server(status: http.statusCode, message: Self.extractMessage(data))
        }
    }

    private static func extractMessage(_ data: Data) -> String {
        struct ErrBody: Decodable { let error: String? }
        return (try? JSONDecoder().decode(ErrBody.self, from: data))?.error ?? ""
    }
}

// MARK: - Bodies

private struct RegisterBody: Encodable { let email, password, username: String }
private struct LoginBody: Encodable { let email, password: String }
private struct AppleSignInBody: Encodable {
    let identityToken: String; let email: String?
    enum CodingKeys: String, CodingKey { case identityToken = "identity_token"; case email }
}
private struct RefreshBody: Encodable {
    let refreshToken: String
    enum CodingKeys: String, CodingKey { case refreshToken = "refresh_token" }
}
private struct VerifyBody: Encodable { let signedTransaction: String }
private struct AddReviewBody: Encodable { let rating: Int; let text: String?; let photoURL: String? }
private struct PresignedURLBody: Encodable { let filename: String }
private struct EmptyResponse: Decodable { init() {} }

private struct AnyEncodable: Encodable {
    private let encodeTo: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { encodeTo = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encodeTo(encoder) }
}
