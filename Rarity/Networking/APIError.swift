import Foundation

enum APIError: LocalizedError {
    case transport(Error)
    case invalidResponse
    case unauthorized
    case paymentRequired
    case notFound
    case server(status: Int, message: String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .transport(let e):    return e.localizedDescription
        case .invalidResponse:     return "Invalid server response."
        case .unauthorized:        return "Session expired. Please sign in again."
        case .paymentRequired:     return "This content requires a Rarity+ subscription."
        case .notFound:            return "Not found."
        case .server(_, let msg):  return msg.isEmpty ? "Server error." : msg
        case .decoding(let e):     return "Response error: \(e.localizedDescription)"
        }
    }

    var isPaymentRequired: Bool {
        if case .paymentRequired = self { return true }
        return false
    }
}
