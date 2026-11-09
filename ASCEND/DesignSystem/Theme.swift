import SwiftUI

public enum AscendTheme {
    // Primary Atmospheric Colors
    public static let backgroundDark = Color(hex: "#090B10")
    public static let backgroundSurface = Color(hex: "#101422")
    public static let cardBackground = Color(hex: "#161B2E").opacity(0.85)
    public static let cardBorder = Color(hex: "#26304D")
    
    // Core Accent Colors
    public static let electricBlue = Color(hex: "#00D2FF")
    public static let deepViolet = Color(hex: "#8B5CF6")
    public static let cyberCyan = Color(hex: "#06B6D4")
    public static let metallicGold = Color(hex: "#F59E0B")
    public static let imperialPurple = Color(hex: "#6D28D9")
    public static let energeticCoral = Color(hex: "#FF6584")
    public static let emeraldRecovery = Color(hex: "#10B981")
    
    // Text Hierarchy
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "#94A3B8")
    public static let textTertiary = Color(hex: "#64748B")
    
    // Gradients
    public static let primaryGradient = LinearGradient(
        colors: [electricBlue, deepViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let goldGradient = LinearGradient(
        colors: [Color(hex: "#FDE68A"), Color(hex: "#D97706")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let worldIslandGradient = LinearGradient(
        colors: [Color(hex: "#1E2640"), Color(hex: "#0F1424")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    public static let celestialSkybox = LinearGradient(
        colors: [
            Color(hex: "#07090E"),
            Color(hex: "#0D1120"),
            Color(hex: "#15102A"),
            Color(hex: "#090B10")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

public extension Color {
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
            (a, r, g, b) = (255, 0, 0, 0)
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
