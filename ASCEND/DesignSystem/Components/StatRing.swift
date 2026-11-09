import SwiftUI

public struct StatRing: View {
    public let progress: Double // 0.0 to 1.0
    public let lineWidth: CGFloat
    public let gradient: LinearGradient
    public let backgroundTint: Color
    
    public init(
        progress: Double,
        lineWidth: CGFloat = 8,
        gradient: LinearGradient = AscendTheme.primaryGradient,
        backgroundTint: Color = AscendTheme.cardBorder.opacity(0.4)
    ) {
        self.progress = min(1.0, max(0.0, progress))
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.backgroundTint = backgroundTint
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundTint, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

