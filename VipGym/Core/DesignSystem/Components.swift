import SwiftUI

struct VGCard: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 0.5))
    }
}

extension View {
    func vgCard(padding: CGFloat = 16) -> some View { modifier(VGCard(padding: padding)) }
}

/// Mały nagłówek sekcji: kapitaliki z rozstrzelonymi literami.
struct VGSectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased(with: Localizer.locale))
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.8)
            .foregroundStyle(Theme.textSecondary)
    }
}

/// Znak firmowy aplikacji.
struct VGWordmark: View {
    var size: CGFloat = 22
    var body: some View {
        HStack(spacing: 0) {
            Text("VIP").foregroundStyle(Theme.textPrimary)
            Text("GYM").foregroundStyle(Theme.accent)
        }
        .font(.system(size: size, weight: .heavy, design: .default))
        .tracking(size * 0.18)
    }
}

struct VGPrimaryButtonStyle: ButtonStyle {
    var compact = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 15 : 17, weight: .semibold))
            .foregroundStyle(Theme.onAccent)
            .frame(maxWidth: compact ? nil : .infinity)
            .padding(.vertical, compact ? 10 : 16)
            .padding(.horizontal, compact ? 16 : 20)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.control + 2, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct VGGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct VGChip: View {
    let title: String
    var selected: Bool
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(selected ? Theme.onAccent : Theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? Theme.accent : Theme.surfaceHigh, in: Capsule())
            .overlay(Capsule().strokeBorder(selected ? .clear : Theme.stroke, lineWidth: 0.5))
    }
}

struct VGStatTile: View {
    let label: String
    let value: String
    var unit: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VGSectionLabel(label)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(Theme.mono(26, .bold)).foregroundStyle(Theme.textPrimary)
                if let unit { Text(unit).font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textSecondary) }
            }
            .minimumScaleFactor(0.6).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .vgCard()
    }
}
