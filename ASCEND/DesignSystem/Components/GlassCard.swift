import SwiftUI

public struct GlassCard<Content: View>: View {
    public let cornerRadius: CGFloat
    public let borderColor: Color
    public let content: Content
    
    public init(
        cornerRadius: CGFloat = 20,
        borderColor: Color = AscendTheme.cardBorder,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AscendTheme.cardBackground)
                    .overlay(alignment: .trailing) {
                        FairyOrnament(palette: FairyAppearance.shared.selected)
                            .frame(width: 100)
                            .opacity(0.16)
                            .mask(LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [AscendTheme.metallicGold.opacity(0.28), borderColor.opacity(0.2), borderColor.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.7
                            )
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)
            )
    }
}

