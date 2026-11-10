import SwiftUI

public struct Particle: Identifiable, Sendable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var radius: CGFloat
    public var speed: CGFloat
    public var opacity: Double
    public var hueShift: Double
}

public struct ParticleFieldView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let particleCount: Int
    @State private var particles: [Particle]
    
    public init(particleCount: Int = 35) {
        self.particleCount = particleCount
        _particles = State(initialValue: Self.generateParticles(count: particleCount))
    }
    
    public var body: some View {
        ZStack {
            FairyOrnament(palette: FairyAppearance.shared.selected)
                .opacity(0.13)
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
                Canvas { context, size in
                    let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                    guard let symbol = context.resolveSymbol(id: "element") else { return }
                    for p in particles {
                        let y = (p.y - CGFloat(time * Double(p.speed) * 0.025)).truncatingRemainder(dividingBy: 1)
                        let x = p.x + (reduceMotion ? 0 : sin(CGFloat(time * 0.3 + p.hueShift)) * 0.02)
                        var particleContext = context
                        particleContext.opacity = p.opacity * 0.6
                        particleContext.draw(symbol, at: CGPoint(x: x * size.width, y: (y < 0 ? y + 1 : y) * size.height))
                    }
                } symbols: {
                    Image(systemName: FairyAppearance.shared.selected.particleSymbol)
                        .font(.system(size: 8, weight: .ultraLight))
                        .foregroundColor(AscendTheme.cyberCyan)
                        .tag("element")
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
    
    private static func generateParticles(count: Int) -> [Particle] {
        var list: [Particle] = []
        for _ in 0..<count {
            list.append(Particle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                radius: CGFloat.random(in: 1.0...2.5),
                speed: CGFloat.random(in: 0.2...0.8),
                opacity: Double.random(in: 0.2...0.6),
                hueShift: Double.random(in: 0...1)
            ))
        }
        return list
    }
}
