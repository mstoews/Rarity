import Foundation

enum AppConfig {
    static var baseURL: URL {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["RARITY_API_BASE_URL"],
           let url = URL(string: raw) { return url }
        return URL(string: "http://localhost:8092")!
        #else
        return URL(string: "https://api.rarity.example.com")!
        #endif
    }

    static let annualProductID  = "com.mapleon.rarity.sub.annual"
    static let monthlyProductID = "com.mapleon.rarity.sub.monthly"
    static let subscriptionProductIDs = [annualProductID, monthlyProductID]
}
