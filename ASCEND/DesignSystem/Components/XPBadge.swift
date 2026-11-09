import SwiftUI

public struct XPBadge: View {
    public let amount: Int
    public let category: XPRewardCategory
    
    public init(amount: Int, category: XPRewardCategory = .effort) {
        self.amount = amount
        self.category = category
    }
    
    private var color: Color {
        Color(hex: category.badgeColorHex)
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .bold))
            Text("+\(amount) XP")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(color.opacity(0.4), lineWidth: 1)
                )
        )
    }
}
