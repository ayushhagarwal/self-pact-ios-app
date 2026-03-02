import SwiftUI

// MARK: - App Colors
struct AppColors {
    // Backgrounds
    static let background = Color(hex: "0D0D12")
    static let backgroundElevated = Color(hex: "131318")
    static let surface = Color(hex: "1A1A22")
    static let surfaceLight = Color(hex: "22222C")
    static let surfaceHighlight = Color(hex: "2A2A36")
    static let border = Color(hex: "2A2A35")
    static let borderLight = Color(hex: "363644")
    
    // Text
    static let textPrimary = Color(hex: "ECEAE4")
    static let textSecondary = Color(hex: "908D85")
    static let textTertiary = Color(hex: "5F5D57")
    static let textMuted = Color(hex: "44423D")
    
    // Gold
    static let gold = Color(hex: "D4A843")
    static let goldLight = Color(hex: "E8C35E")
    static let goldDim = Color(hex: "8A6F2A")
    static let goldMuted = Color(hex: "6B5722")
    static let goldGlow = Color(hex: "D4A843").opacity(0.12)
    static let goldGlowStrong = Color(hex: "D4A843").opacity(0.22)
    
    // Indigo
    static let indigo = Color(hex: "6872CF")
    static let indigoLight = Color(hex: "8B94E8")
    static let indigoDim = Color(hex: "454B8A")
    static let indigoGlow = Color(hex: "6872CF").opacity(0.12)
    
    // Accent
    static let accent = Color(hex: "6872CF")
    static let accentLight = Color(hex: "8B94E8")
    
    // Status
    static let success = Color(hex: "4EA87A")
    static let successGlow = Color(hex: "4EA87A").opacity(0.12)
    static let warning = Color(hex: "D4983F")
    static let error = Color(hex: "CF5858")
    static let errorGlow = Color(hex: "CF5858").opacity(0.10)
    
    // Overlays
    static let overlay = Color.black.opacity(0.75)
    static let overlayLight = Color.black.opacity(0.45)
    static let overlayDark = Color.black.opacity(0.88)
    
    // Reveal background
    static let revealBackground = Color(hex: "060608")
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
