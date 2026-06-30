import SwiftUI

/// Rarity design tokens — deep rose/mauve palette for a premium beauty brand.
enum Theme {
    // Brand — deep rose
    static let brand     = Color.adaptive(light: Color(hex: 0x9B4F6E), dark: Color(hex: 0xBD6F90))
    static let brand600  = Color(hex: 0x9B4F6E)
    static let brand700  = Color(hex: 0x7D3A57)
    static let brand800  = Color(hex: 0x5E2840)
    static let brandSoft = Color(hex: 0x9B4F6E, alpha: 0.10)

    // Surfaces
    static let page      = Color.adaptive(light: Color(hex: 0xFAF8F9), dark: .black)
    static let card      = Color.adaptive(light: .white,               dark: Color(hex: 0x1C1C1E))
    static let card2     = Color.adaptive(light: Color(hex: 0xF0EBEe), dark: Color(hex: 0x2C2C2E))
    static let ink       = Color.adaptive(light: Color(hex: 0x1A0F14), dark: Color(hex: 0xF8F3F6))
    static let sub       = Color.adaptive(light: Color(hex: 0x6B5060), dark: Color(white: 0.92, opacity: 0.62))
    static let hint      = Color.adaptive(light: Color(hex: 0xA890A0), dark: Color(white: 0.92, opacity: 0.38))
    static let separator = Color.adaptive(light: Color(hex: 0x3C3C43, alpha: 0.12), dark: Color(white: 1, opacity: 0.10))

    // Accents
    static let star      = Color(hex: 0xE8A830)
    static let systemRed = Color(hex: 0xFF3B30)
    static let wishlist  = Color(hex: 0xE05080)
}

enum Metrics {
    static let page: CGFloat        = 16
    static let cardPadding: CGFloat = 14
    static let radiusRow: CGFloat   = 14
    static let radiusCard: CGFloat  = 16
    static let radiusSheet: CGFloat = 22
    static let avatarSM: CGFloat    = 32
    static let avatarMD: CGFloat    = 44
}
