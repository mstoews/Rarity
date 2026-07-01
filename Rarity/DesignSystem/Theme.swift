import SwiftUI

/// Rarity design tokens — Atelier direction (quiet luxury, blush & nude palette).
enum Theme {
    // MARK: - Brand
    static let brand      = Color.adaptive(light: Color(hex: 0x8C4A5E), dark: Color(hex: 0xD08AA0))
    static let brandDeep  = Color.adaptive(light: Color(hex: 0x6F3A4A), dark: Color(hex: 0xB86E84))
    static let brandSoft  = Color.adaptive(light: Color(hex: 0xF3E3E5), dark: Color(hex: 0x3A2A30))

    // MARK: - Surfaces
    static let page       = Color.adaptive(light: Color(hex: 0xFBF7F3), dark: Color(hex: 0x161213))
    static let card       = Color.adaptive(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1F1A1B))
    static let card2      = Color.adaptive(light: Color(hex: 0xF1E7E0), dark: Color(hex: 0x2A2325))

    // MARK: - Text
    static let ink        = Color.adaptive(light: Color(hex: 0x2A211E), dark: Color(hex: 0xF4ECEC))
    static let sub        = Color.adaptive(light: Color(hex: 0x8A7D77), dark: Color(hex: 0xB9ABA9))
    static let hint       = Color.adaptive(light: Color(hex: 0xA89C95), dark: Color(hex: 0x8A7C7A))
    static let separator  = Color.adaptive(light: Color(hex: 0xECE2DB), dark: Color(hex: 0xFFFFFF, alpha: 0.10))

    // MARK: - Accents
    static let star        = Color.adaptive(light: Color(hex: 0xC99A5B), dark: Color(hex: 0xD6A867))
    static let destructive = Color.adaptive(light: Color(hex: 0xB0473F), dark: Color(hex: 0xE0796E))

    // keep until structural pass replaces with brand
    static let wishlist   = Color.adaptive(light: Color(hex: 0x8C4A5E), dark: Color(hex: 0xD08AA0))
}

enum Metrics {
    // MARK: - Spacing (4 pt grid)
    static let hairline: CGFloat    = 4
    static let gapInline: CGFloat   = 8
    static let cardPadding: CGFloat = 14
    static let listGap: CGFloat     = 16
    static let page: CGFloat        = 22

    // MARK: - Corner radii
    static let radiusButton: CGFloat = 6
    static let radiusTile: CGFloat   = 8
    static let radiusCard: CGFloat   = 10
    static let radiusSheet: CGFloat  = 22

    // keep until structural pass updates call sites
    static let radiusRow: CGFloat    = 8

    // MARK: - Avatars
    static let avatarSM: CGFloat     = 32
    static let avatarMD: CGFloat     = 44
}
