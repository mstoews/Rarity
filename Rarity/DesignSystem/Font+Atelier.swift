import SwiftUI

// Atelier type scale — Cormorant Garamond (display) + Jost (UI).
// Add the font files to the Xcode target and register them in Info.plist
// under UIAppFonts. Until then these resolve to the system fallback font.
extension Font {
    static func cormorant(size: CGFloat) -> Font {
        .custom("CormorantGaramond-Medium", size: size)
    }

    static func jost(_ weight: Weight = .regular, size: CGFloat) -> Font {
        let name: String
        switch weight {
        case .light:    name = "Jost-Light"
        case .medium:   name = "Jost-Medium"
        case .semibold: name = "Jost-SemiBold"
        default:        name = "Jost-Regular"
        }
        return .custom(name, size: size)
    }

    // Named styles
    static let atelierDisplay  = Font.cormorant(size: 40)   // screen title
    static let atelierTitle    = Font.cormorant(size: 32)   // product name on detail
    static let atelierCardName = Font.cormorant(size: 19)   // list row / card name
    static let atelierPrice    = Font.cormorant(size: 24)   // detail sticky CTA
    static let atelierBody     = Font.jost(.light, size: 15)
    static let atelierCaption  = Font.jost(size: 11)
}

// Eyebrow label — Jost 600 11pt uppercase +2.5 tracking
struct EyebrowStyle: ViewModifier {
    var color: Color = Theme.brand
    func body(content: Content) -> some View {
        content
            .font(.jost(.semibold, size: 11))
            .tracking(2.5)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

extension View {
    func eyebrowStyle(color: Color = Theme.brand) -> some View {
        modifier(EyebrowStyle(color: color))
    }
}

// Primary button label — Jost 500 12pt uppercase +2 tracking
struct PrimaryButtonLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.jost(.medium, size: 12))
            .tracking(2)
            .textCase(.uppercase)
    }
}

extension View {
    func primaryButtonLabel() -> some View {
        modifier(PrimaryButtonLabelStyle())
    }
}
