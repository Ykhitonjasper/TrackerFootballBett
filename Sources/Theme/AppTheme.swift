import SwiftUI

/// 1xBet-inspired dark navy + brand blue palette (visual style only).
enum AppTheme {
    /// Brand blue ≈ #1475E1
    static let accent = Color(red: 0.08, green: 0.46, blue: 0.88)
    static let accentBright = Color(red: 0.20, green: 0.58, blue: 1.00)
    static let accentMuted = Color(red: 0.08, green: 0.46, blue: 0.88).opacity(0.22)

    /// Promo / odds highlight ≈ 1xBet yellow
    static let highlight = Color(red: 0.98, green: 0.75, blue: 0.10)

    static let danger = Color(red: 0.92, green: 0.28, blue: 0.32)
    static let warning = Color(red: 0.98, green: 0.72, blue: 0.18)
    static let info = Color(red: 0.35, green: 0.65, blue: 1.00)
    static let success = Color(red: 0.25, green: 0.72, blue: 0.95)

    /// Deep navy surfaces
    static let surface = Color(red: 0.09, green: 0.12, blue: 0.20)
    static let surfaceElevated = Color(red: 0.12, green: 0.16, blue: 0.27)
    static let surfaceDeep = Color(red: 0.05, green: 0.07, blue: 0.14)

    static let border = Color.white.opacity(0.10)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.64)
    static let textTertiary = Color.white.opacity(0.40)

    static let radiusS: CGFloat = 8
    static let radiusM: CGFloat = 12
    static let radiusL: CGFloat = 16
    static let radiusXL: CGFloat = 22

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32

    static let cardShadow = Color.black.opacity(0.45)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.06, blue: 0.14),
                Color(red: 0.06, green: 0.10, blue: 0.22),
                Color(red: 0.03, green: 0.05, blue: 0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.38, blue: 0.82),
                Color(red: 0.18, green: 0.55, blue: 0.98)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var balanceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.18, blue: 0.42),
                Color(red: 0.08, green: 0.35, blue: 0.78),
                Color(red: 0.10, green: 0.28, blue: 0.62)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var headerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.07, green: 0.14, blue: 0.32),
                Color(red: 0.05, green: 0.09, blue: 0.20)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension Color {
    init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct CardBackground: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .background(elevated ? AppTheme.surfaceElevated : AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusL, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusL, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isEnabled {
                        AppTheme.accentGradient.opacity(configuration.isPressed ? 0.85 : 1)
                    } else {
                        Color.gray.opacity(0.35)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusM, style: .continuous))
            .scaleEffect(configuration.isPressed && isEnabled ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.accentBright)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppTheme.accentMuted)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension View {
    func cardStyle(elevated: Bool = false) -> some View {
        modifier(CardBackground(elevated: elevated))
    }

    func screenBackground() -> some View {
        background(AppTheme.backgroundGradient.ignoresSafeArea())
    }
}
