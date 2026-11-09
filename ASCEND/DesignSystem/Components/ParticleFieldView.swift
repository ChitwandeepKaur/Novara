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
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: reduceMotion ? 1.0 : 0.033)) { timeline in
                Canvas { context, size in
                    guard !reduceMotion else {
                        // Static particles if reduce motion is enabled
                        for p in particles {
                            let rect = CGRect(x: p.x * size.width, y: p.y * size.height, width: p.radius * 2, height: p.radius * 2)
                            context.fill(Path(ellipseIn: rect), with: .color(AscendTheme.cyberCyan.opacity(p.opacity * 0.4)))
                        }
                        return
                    }
                    
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    for p in particles {
                        let animatedY = (p.y - CGFloat(time * Double(p.speed) * 0.05)).truncatingRemainder(dividingBy: 1.0)
                        let normalizedY = animatedY < 0 ? animatedY + 1.0 : animatedY
                        let animatedX = (p.x + sin(CGFloat(time + p.hueShift)) * 0.02).truncatingRemainder(dividingBy: 1.0)
                        let normalizedX = animatedX < 0 ? animatedX + 1.0 : animatedX
                        
                        let rect = CGRect(
                            x: normalizedX * size.width,
                            y: normalizedY * size.height,
                            width: p.radius * 2,
                            height: p.radius * 2
                        )
                        
                        let color = p.hueShift > 0.5 ? AscendTheme.electricBlue : AscendTheme.deepViolet
                        context.fill(Path(ellipseIn: rect), with: .color(color.opacity(p.opacity)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
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
