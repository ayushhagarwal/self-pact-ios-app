import SwiftUI

// MARK: - App Colors
struct AppColors {
    // Backgrounds
    static let background = Color(hex: "FDFBF7")
    static let backgroundElevated = Color(hex: "F7F3EC")
    static let surface = Color(hex: "FFFFFF")
    static let surfaceLight = Color(hex: "FCFAF6")
    static let surfaceHighlight = Color(hex: "F2EDE4")
    static let border = Color(hex: "E7DED2")
    static let borderLight = Color(hex: "E7DED2").opacity(0.7)

    // Text
    static let textPrimary = Color(hex: "1F2A2E")
    static let textSecondary = Color(hex: "66736D")
    static let textTertiary = Color(hex: "66736D").opacity(0.75)
    static let textMuted = Color(hex: "66736D").opacity(0.55)

    // Primary action
    static let accent = Color(hex: "3F8F68")
    static let accentLight = Color(hex: "8CC6A7")
    static let accentStrong = Color(hex: "2F6F4F")
    static let accentDim = Color(hex: "3F8F68").opacity(0.7)
    static let accentGlow = Color(hex: "DCEFE5")
    static let accentGlowStrong = Color(hex: "C7E6D5")

    // Commitment and reflection states
    static let commitment = Color(hex: "27443B")
    static let commitmentLight = Color(hex: "5E8174")
    static let commitmentGlow = Color(hex: "DCE7E0")
    static let review = Color(hex: "9A6B22")
    static let reviewGlow = Color(hex: "F5E7C8")

    // Legacy tokens mapped to the new semantic palette
    static let gold = review
    static let goldLight = Color(hex: "D1A85A")
    static let goldDim = review.opacity(0.7)
    static let goldMuted = review.opacity(0.55)
    static let goldGlow = reviewGlow
    static let goldGlowStrong = Color(hex: "EED69C")

    static let indigo = commitment
    static let indigoLight = commitmentLight
    static let indigoDim = commitment.opacity(0.7)
    static let indigoGlow = commitmentGlow

    static let success = accent
    static let successGlow = accentGlow
    static let warning = review
    static let warningGlow = reviewGlow
    static let error = Color(hex: "B85C5C")
    static let errorGlow = Color(hex: "F6DEDC")

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
                Color(hex: "FDFBF7"),
                Color(hex: "F7F3EC")
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
