import Foundation
import Security

enum KeychainStore {
    private static let service = "com.mapleon.rarity"
    private static let account = "auth-tokens"

    static func save(_ data: Data) {
        let q: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                   kSecAttrService: service, kSecAttrAccount: account, kSecValueData: data]
        SecItemDelete(q as CFDictionary)
        SecItemAdd(q as CFDictionary, nil)
    }
    static func load() -> Data? {
        let q: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: service,
                                   kSecAttrAccount: account, kSecReturnData: true, kSecMatchLimit: kSecMatchLimitOne]
        var result: AnyObject?
        SecItemCopyMatching(q as CFDictionary, &result)
        return result as? Data
    }
    static func clear() {
        let q: [CFString: Any] = [kSecClass: kSecClassGenericPassword,
                                   kSecAttrService: service, kSecAttrAccount: account]
        SecItemDelete(q as CFDictionary)
    }
}
