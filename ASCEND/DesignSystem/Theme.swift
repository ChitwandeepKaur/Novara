import SwiftUI
import Observation

public enum AscendTheme {
    // Primary Atmospheric Colors
    public static var backgroundDark: Color { Color(hex: FairyAppearance.shared.selected.background) }
    public static var backgroundSurface: Color { backgroundDark.opacity(0.96) }
    public static var cardBackground: Color { Color(hex: FairyAppearance.shared.selected.surface).opacity(0.94) }
    public static var cardBorder: Color { deepViolet.opacity(0.32) }
    
    // Core Accent Colors
    public static var electricBlue: Color { Color(hex: FairyAppearance.shared.selected.accent) }
    public static var deepViolet: Color { Color(hex: FairyAppearance.shared.selected.secondary) }
    public static var cyberCyan: Color { Color(hex: FairyAppearance.shared.selected.light) }
    public static var metallicGold: Color { Color(hex: FairyAppearance.shared.selected.light) }
    public static let imperialPurple = Color(hex: "#6D28D9")
    public static let energeticCoral = Color(hex: "#FF6584")
    public static let emeraldRecovery = Color(hex: "#10B981")
    
    // Text Hierarchy
    public static let textPrimary = Color(hex: "#FAF3F2")
    public static let textSecondary = Color(hex: "#BCB5CB")
    public static let textTertiary = Color(hex: "#A29AAE")
    
    // Gradients
    public static var primaryGradient: LinearGradient { LinearGradient(
        colors: [electricBlue, deepViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    ) }
    
    public static let goldGradient = LinearGradient(
        colors: [Color(hex: "#FDE68A"), Color(hex: "#D97706")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static var worldIslandGradient: LinearGradient { LinearGradient(
        colors: [Color(hex: FairyAppearance.shared.selected.surface), backgroundDark],
        startPoint: .top,
        endPoint: .bottom
    ) }
    
    public static var celestialSkybox: LinearGradient { LinearGradient(
        colors: [
            backgroundDark,
            Color(hex: FairyAppearance.shared.selected.surface),
            backgroundDark
        ],
        startPoint: .top,
        endPoint: .bottom
    ) }
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


@Observable
public final class FairyAppearance {
    public static let shared = FairyAppearance()
    public private(set) var selected: FairyPalette = .flora
    public func apply(_ palette: FairyPalette) { selected = palette }
    private init() {}
}

/// Resolution-independent original wing illustration with botanical veins and celestial filigree.
public struct FairyWings: View {
    public init() {}
    public var body: some View {
        Canvas { context, size in
            let palette = FairyAppearance.shared.selected
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.53)
            let scale = min(size.width / 240, size.height / 200)
            for mirror in [-1.0, 1.0] {
                func point(_ x: Double, _ y: Double) -> CGPoint {
                    CGPoint(x: center.x + x * scale * mirror, y: center.y + y * scale)
                }
                var upper = Path()
                var lower = Path()
                upper.move(to: point(3, 3))
                lower.move(to: point(4, 8))
                switch palette {
                case .flora:
                    upper.addCurve(to: point(104, -84), control1: point(25, -64), control2: point(83, -57))
                    upper.addCurve(to: point(3, 3), control1: point(112, -10), control2: point(45, 19))
                    lower.addCurve(to: point(70, 68), control1: point(65, 3), control2: point(104, 60))
                    lower.addCurve(to: point(4, 8), control1: point(32, 91), control2: point(26, 37))
                case .aisha:
                    upper.addCurve(to: point(95, -83), control1: point(7, -80), control2: point(112, -104))
                    upper.addCurve(to: point(3, 3), control1: point(62, -16), control2: point(106, 13))
                    lower.addCurve(to: point(48, 82), control1: point(94, -6), control2: point(106, 85))
                    lower.addCurve(to: point(4, 8), control1: point(10, 62), control2: point(46, 39))
                case .tecna:
                    for (x, y) in [(34.0, -63.0), (101, -86), (82, -23), (3, 3)] { upper.addLine(to: point(x, y)) }
                    for (x, y) in [(78.0, 16.0), (66, 73), (20, 48), (4, 8)] { lower.addLine(to: point(x, y)) }
                case .musa:
                    upper.addCurve(to: point(101, -78), control1: point(38, -93), control2: point(128, -44))
                    upper.addCurve(to: point(3, 3), control1: point(66, -61), control2: point(82, 26))
                    lower.addCurve(to: point(88, 54), control1: point(77, -6), control2: point(112, 16))
                    lower.addCurve(to: point(4, 8), control1: point(34, 31), control2: point(57, 89))
                case .stella:
                    for (x, y) in [(29.0, -47.0), (38, -88), (61, -54), (108, -69), (89, -24), (3, 3)] { upper.addLine(to: point(x, y)) }
                    for (x, y) in [(71.0, 12.0), (91, 53), (55, 46), (34, 83), (4, 8)] { lower.addLine(to: point(x, y)) }
                case .bloom:
                    upper.addCurve(to: point(88, -91), control1: point(4, -68), control2: point(76, -42))
                    upper.addQuadCurve(to: point(105, -30), control: point(88, -21))
                    upper.addQuadCurve(to: point(3, 3), control: point(58, 5))
                    lower.addCurve(to: point(79, 72), control1: point(96, -12), control2: point(24, 47))
                    lower.addCurve(to: point(4, 8), control1: point(24, 55), control2: point(40, 81))
                }
                upper.closeSubpath()
                lower.closeSubpath()
                for wing in [upper, lower] {
                    context.fill(wing, with: .linearGradient(Gradient(colors: [AscendTheme.electricBlue.opacity(0.32), AscendTheme.deepViolet.opacity(0.08)]), startPoint: point(0, 0), endPoint: point(105, -70)))
                    context.stroke(wing, with: .color(AscendTheme.cyberCyan.opacity(0.72)), lineWidth: 0.8)
                }
                for index in 0..<5 {
                    let offset = Double(index)
                    var vein = Path()
                    vein.move(to: point(5, 4))
                    vein.addQuadCurve(to: point(94 - offset * 14, -68 + offset * 9), control: point(58 - offset * 5, -4 - offset * 9))
                    context.stroke(vein, with: .color(AscendTheme.metallicGold.opacity(0.35)), lineWidth: 0.5)
                }
                for index in 0..<3 {
                    var vein = Path()
                    vein.move(to: point(6, 9))
                    vein.addQuadCurve(to: point(67 - Double(index) * 14, 64), control: point(63, 26))
                    context.stroke(vein, with: .color(AscendTheme.cyberCyan.opacity(0.4)), lineWidth: 0.5)
                }
            }
            let gem = CGRect(x: center.x - 3 * scale, y: center.y - 12 * scale, width: 6 * scale, height: 24 * scale)
            context.fill(Path(ellipseIn: gem), with: .color(AscendTheme.metallicGold))
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

public struct FairyRealmBanner: View {
    public let name: String
    public init(name: String) { self.name = name }
    public var body: some View {
        let palette = FairyAppearance.shared.selected
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 9) {
                Label("\(palette.name.uppercased()) FAIRY", systemImage: palette.symbol)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.7)
                    .foregroundColor(AscendTheme.cyberCyan)
                Text(palette.invitation)
                    .font(.system(size: 26, weight: .regular, design: .serif))
                    .foregroundColor(AscendTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(palette.realmName). \(name.isEmpty ? "Welcome" : name).")
                    .font(.system(size: 12)).foregroundColor(AscendTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
            Spacer(minLength: 0)
            ZStack {
                Circle().stroke(AscendTheme.metallicGold.opacity(0.18), lineWidth: 0.5).padding(16)
                Circle().stroke(AscendTheme.deepViolet.opacity(0.3), style: StrokeStyle(lineWidth: 0.5, dash: [2, 8])).padding(3)
                FairyWings().padding(2)
                Image(systemName: palette.symbol).font(.system(size: 13, weight: .light))
                    .foregroundColor(AscendTheme.metallicGold).offset(y: -47)
            }
            .frame(width: 104, height: 142)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24).fill(AscendTheme.worldIslandGradient)
                .overlay { FairyOrnament(palette: palette).opacity(0.28).clipShape(RoundedRectangle(cornerRadius: 24)) }
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(AscendTheme.metallicGold.opacity(0.23), lineWidth: 0.7))
        }
    }
}

/// A small personal fairy sigil whose complexion, hair, and gown follow avatar choices.
public struct FairyAvatar: View {
    public let profile: AvatarProfile
    public init(profile: AvatarProfile) { self.profile = profile }
    public var body: some View {
        let skin = ["#FFDFBF", "#F3B28A", "#D18659", "#945633", "#4A2A18"]
        let hair = ["#24202B", "#885234", "#D4AF74", "#AD82C7", "#82C5D4"]
        ZStack {
            Circle().fill(AscendTheme.electricBlue.opacity(0.07))
            Circle().stroke(AscendTheme.metallicGold.opacity(0.3), lineWidth: 0.6).padding(5)
            FairyWings().padding(.horizontal, 1).padding(.vertical, 8)
            Capsule().fill(Color(hex: hair[abs(profile.hairColorIndex % hair.count)]))
                .frame(width: profile.hairStyleIndex == 3 ? 19 : 26, height: profile.hairStyleIndex == 4 ? 44 : 29)
                .offset(y: -15)
            Circle().fill(Color(hex: skin[abs(profile.skinToneIndex % skin.count)]))
                .frame(width: 18, height: 20).offset(y: -19)
            GeometryReader { geometry in
                Path { path in
                    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                        CGPoint(x: geometry.size.width * x, y: geometry.size.height * y)
                    }
                    path.move(to: point(0.43, 0.45))
                    path.addLine(to: point(0.57, 0.45))
                    path.addQuadCurve(to: point(0.72, 0.85), control: point(0.53, 0.6))
                    path.addQuadCurve(to: point(0.28, 0.85), control: point(0.5, 0.94))
                    path.addQuadCurve(to: point(0.43, 0.45), control: point(0.47, 0.6))
                }
                .fill(profile.outfitIndex == 2 ? AscendTheme.metallicGold : (profile.outfitIndex == 1 ? AscendTheme.deepViolet : AscendTheme.electricBlue))
            }
            Image(systemName: FairyAppearance.shared.selected.symbol)
                .font(.system(size: 8, weight: .light)).foregroundColor(AscendTheme.backgroundDark)
                .offset(y: 7)
        }
        .accessibilityLabel("Your fairy avatar")
    }
}

/// Original elemental linework shared by cards, realm backdrops, and navigation.
public struct FairyOrnament: View {
    public let palette: FairyPalette
    public init(palette: FairyPalette) { self.palette = palette }
    public var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let ink = Color(hex: palette.secondary)
            var lines = Path()
            switch palette {
            case .flora:
                for side in [0.0, 1.0] {
                    let x = w * (side == 0 ? 0.08 : 0.92)
                    lines.move(to: CGPoint(x: x, y: h))
                    lines.addCurve(to: CGPoint(x: x, y: 0), control1: CGPoint(x: x - 35, y: h * 0.65), control2: CGPoint(x: x + 35, y: h * 0.3))
                    for index in 0..<6 {
                        let y = h * CGFloat(index + 1) / 7
                        let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
                        var leaf = Path()
                        leaf.move(to: CGPoint(x: x, y: y))
                        leaf.addQuadCurve(to: CGPoint(x: x + 25 * direction, y: y - 22), control: CGPoint(x: x + 32 * direction, y: y + 3))
                        leaf.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - 2 * direction, y: y - 22))
                        context.fill(leaf, with: .color(ink.opacity(0.22)))
                        context.stroke(leaf, with: .color(ink), lineWidth: 0.7)
                    }
                }
            case .aisha:
                for index in 0..<7 {
                    let y = h * 0.55 + CGFloat(index) * 19
                    lines.move(to: CGPoint(x: -20, y: y))
                    lines.addCurve(to: CGPoint(x: w + 20, y: y - 20), control1: CGPoint(x: w * 0.35, y: y - 65), control2: CGPoint(x: w * 0.65, y: y + 55))
                }
                for index in 0..<4 {
                    let diameter = CGFloat(24 + index * 21)
                    lines.addEllipse(in: CGRect(x: w * 0.8 - diameter / 2, y: h * 0.24 - diameter / 2, width: diameter, height: diameter))
                }
            case .tecna:
                for index in 0..<6 {
                    let x = w * CGFloat(index + 1) / 7
                    lines.move(to: CGPoint(x: x, y: h))
                    lines.addLines([CGPoint(x: x, y: h * 0.68), CGPoint(x: x + 20, y: h * 0.68 - 20), CGPoint(x: x + 20, y: h * 0.18)])
                    lines.addEllipse(in: CGRect(x: x + 17, y: h * 0.18 - 3, width: 6, height: 6))
                }
            case .musa:
                for index in 0..<5 {
                    let y = h * 0.65 + CGFloat(index) * 12
                    lines.move(to: CGPoint(x: 0, y: y))
                    lines.addCurve(to: CGPoint(x: w, y: y - 30), control1: CGPoint(x: w * 0.35, y: y - 80), control2: CGPoint(x: w * 0.7, y: y + 50))
                }
                for index in 0..<9 {
                    let x = w * CGFloat(index + 1) / 10
                    let amplitude = CGFloat([12, 23, 38, 18, 29, 42, 22, 14, 30][index])
                    lines.move(to: CGPoint(x: x, y: h * 0.25 - amplitude / 2))
                    lines.addLine(to: CGPoint(x: x, y: h * 0.25 + amplitude / 2))
                }
            case .stella:
                let center = CGPoint(x: w * 0.83, y: h * 0.28)
                for radius in [24.0, 31, 48] {
                    lines.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                }
                for index in 0..<16 {
                    let angle = Double(index) * .pi / 8
                    lines.move(to: CGPoint(x: center.x + cos(angle) * 54, y: center.y + sin(angle) * 54))
                    lines.addLine(to: CGPoint(x: center.x + cos(angle) * 67, y: center.y + sin(angle) * 67))
                }
                lines.addArc(center: CGPoint(x: w * 0.15, y: h * 0.8), radius: 30, startAngle: .degrees(40), endAngle: .degrees(315), clockwise: false)
            case .bloom:
                for index in 0..<5 {
                    let x = w * CGFloat(index + 1) / 6
                    lines.move(to: CGPoint(x: x, y: h + 10))
                    lines.addCurve(to: CGPoint(x: x + 12, y: h * 0.2), control1: CGPoint(x: x - 65, y: h * 0.65), control2: CGPoint(x: x + 64, y: h * 0.54))
                    lines.addCurve(to: CGPoint(x: x, y: h + 10), control1: CGPoint(x: x - 20, y: h * 0.61), control2: CGPoint(x: x + 45, y: h * 0.76))
                }
            }
            context.stroke(lines, with: .color(ink), style: StrokeStyle(lineWidth: 0.8, lineCap: .round, lineJoin: .round))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
