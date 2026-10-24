import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

extension Color {
    /// Kolor dopasowany do trybu jasnego i ciemnego.
    init(light: UInt32, dark: UInt32) {
        self = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

/// VipGym: grafit + szampańskie złoto. Jeden akcent, reszta w odcieniach neutralnych.
enum Theme {
    static let bg            = Color(light: 0xF4F2EC, dark: 0x0A0B0D)
    static let surface       = Color(light: 0xFFFFFF, dark: 0x131519)
    static let surfaceHigh   = Color(light: 0xEDEAE2, dark: 0x1B1E24)
    static let stroke        = Color(light: 0xDDD8CB, dark: 0x2A2E36)
    static let textPrimary   = Color(light: 0x14151A, dark: 0xF1EFE9)
    static let textSecondary = Color(light: 0x6B6F78, dark: 0x8C919B)
    static let accent        = Color(light: 0x8F6F26, dark: 0xD4B26A)
    static let accentSoft    = Color(light: 0x8F6F26, dark: 0xD4B26A).opacity(0.14)
    static let onAccent      = Color(light: 0xFFFFFF, dark: 0x0A0B0D)
    static let success       = Color(light: 0x2E7D52, dark: 0x6FCF97)
    static let danger        = Color(light: 0xB3392F, dark: 0xE5675B)

    enum Radius {
        static let card: CGFloat = 20
        static let control: CGFloat = 12
    }

    /// Liczby: font monospace, żeby cyfry nie "skakały".
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
