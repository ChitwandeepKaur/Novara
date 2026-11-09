import SwiftUI

public struct SectionHeader: View {
    public let title: String
    public let subtitle: String?
    public let icon: String?
    
    public init(title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(AscendTheme.electricBlue)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AscendTheme.textPrimary)
            }
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AscendTheme.textSecondary)
            }
        }
    }
}

