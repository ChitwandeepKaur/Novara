import SwiftUI

public struct GlowingButton: View {
    public let title: String
    public let icon: String?
    public let gradient: LinearGradient
    public let action: () -> Void
    
    public init(
        title: String,
        icon: String? = nil,
        gradient: LinearGradient = AscendTheme.primaryGradient,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            HapticService.shared.triggerImpact(.medium)
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(gradient)
                    .shadow(color: AscendTheme.electricBlue.opacity(0.35), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}
