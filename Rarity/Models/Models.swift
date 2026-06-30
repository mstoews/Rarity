import Foundation

// MARK: - Auth

struct AuthUser: Codable, Identifiable {
    let id: String
    let email: String?
    let username: String
    let subscriptionStatus: String?
    let subExpiresAt: Date?
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: AuthUser
}

struct RefreshResponse: Codable { let accessToken: String }

// MARK: - Subscription

struct SubscriptionStatus: Codable {
    let subscriptionStatus: String
    let isActive: Bool
    let subExpiresAt: Date?
}

struct VerifyResponse: Codable {
    let subscriptionStatus: String
    let isActive: Bool
    let subExpiresAt: Date?
}

// MARK: - Categories

struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
}

struct CategoriesResponse: Codable {
    let categories: [Category]
}

// MARK: - Cosmetics

/// Returned for all users — name/brand/image only in free tier.
struct CosmeticCard: Codable, Identifiable {
    let id: String
    let name: String
    let brand: String
    let tagline: String?
    let imageURL: String?
    let category: Category?
    let avgRating: Double?
    let reviewCount: Int?
}

/// Full detail — only returned for paid subscribers.
struct CosmeticDetail: Codable, Identifiable {
    let id: String
    let name: String
    let brand: String
    let tagline: String?
    let description: String?
    let ingredients: String?
    let imageURL: String?
    let images: [String]
    let category: Category?
    let avgRating: Double
    let reviewCount: Int
    let stores: [StoreCard]
}

struct CosmeticsResponse: Codable {
    let cosmetics: [CosmeticCard]
    let nextCursor: String?
}

// MARK: - Stores

struct StoreCard: Codable, Identifiable {
    let id: String
    let name: String
    let address: String?
    let city: String?
    let latitude: Double?
    let longitude: Double?
    let inStock: Bool?
    let notes: String?
}

struct StoreDetail: Codable, Identifiable {
    let id: String
    let name: String
    let address: String?
    let city: String?
    let latitude: Double?
    let longitude: Double?
    let website: String?
    let openingHours: String?
    let cosmetics: [CosmeticCard]
}

struct StoresResponse: Codable {
    let stores: [StoreCard]
}

// MARK: - Reviews

struct Review: Codable, Identifiable {
    let id: String
    let rating: Int
    let text: String?
    let photoURL: String?
    let createdAt: Date
    let user: ReviewUser
}

struct ReviewUser: Codable {
    let id: String
    let username: String
}

struct ReviewsResponse: Codable {
    let reviews: [Review]
    let nextCursor: String?
}

// MARK: - Wishlist

struct WishlistResponse: Codable {
    let cosmetics: [CosmeticCard]
}

// MARK: - Upload

struct PresignedURLResponse: Codable {
    let uploadURL: String
    let imageURL: String
}
