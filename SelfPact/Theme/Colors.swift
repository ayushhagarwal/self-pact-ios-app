import SwiftUI

// MARK: - App Colors
struct AppColors {
    // Backgrounds
    static let background = Color(hex: "FFFFFF")
    static let backgroundElevated = Color(hex: "F9FAFB")
    static let surface = Color(hex: "FFFFFF")
    static let surfaceLight = Color(hex: "F9FAFB")
    static let surfaceHighlight = Color(hex: "F9FAFB")
    static let border = Color(hex: "E5E7EB")
    static let borderLight = Color(hex: "E5E7EB").opacity(0.7)

    // Text
    static let textPrimary = Color(hex: "111827")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary = Color(hex: "6B7280").opacity(0.75)
    static let textMuted = Color(hex: "6B7280").opacity(0.55)

    // Matcha Accents
    static let accent = Color(hex: "7FB77E")
    static let accentLight = Color(hex: "A8D5BA")
    static let accentStrong = Color(hex: "4D8B4D")
    static let accentDim = Color(hex: "7FB77E").opacity(0.7)
    static let accentGlow = Color(hex: "A8D5BA").opacity(0.35)
    static let accentGlowStrong = Color(hex: "A8D5BA").opacity(0.6)

    // Legacy tokens mapped to matcha palette
    static let gold = accent
    static let goldLight = accentLight
    static let goldDim = accentDim
    static let goldMuted = accentDim
    static let goldGlow = accentGlow
    static let goldGlowStrong = accentGlowStrong

    static let indigo = accent
    static let indigoLight = accentLight
    static let indigoDim = accentDim
    static let indigoGlow = accentGlow

    static let success = accent
    static let successGlow = accentGlow
    static let warning = accentDim
    static let error = Color.red
    static let errorGlow = Color.red.opacity(0.10)

    // Overlays
    static let overlay = Color.black.opacity(0.08)
    static let overlayLight = Color.black.opacity(0.04)
    static let overlayDark = Color.black.opacity(0.12)

    // Reveal background
    static let revealBackground = background

    // Gradients for subtle depth
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "FFFFFF"),
                Color(hex: "F9FAFB")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
