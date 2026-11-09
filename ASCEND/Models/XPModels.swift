import Foundation

public enum XPRewardCategory: String, Codable, CaseIterable, Sendable {
    case effort = "Effort XP"
    case achievement = "Achievement XP"
    case completionBonus = "Completion Bonus XP"
    
    public var badgeColorHex: String {
        switch self {
        case .effort: return "#00D2FF" // Electric blue
        case .achievement: return "#9B51E0" // Violet
        case .completionBonus: return "#F2C94C" // Gold
        }
    }
}

public struct XPTransaction: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var timestamp: Date
    public var amount: Int
    public var category: XPRewardCategory
    public var sourceQuestId: UUID?
    public var achievementKey: String? // For deduplication
    public var title: String
    public var details: String
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        amount: Int,
        category: XPRewardCategory,
        sourceQuestId: UUID? = nil,
        achievementKey: String? = nil,
        title: String,
        details: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.amount = amount
        self.category = category
        self.sourceQuestId = sourceQuestId
        self.achievementKey = achievementKey
        self.title = title
        self.details = details
    }
}

public struct XPProgressInfo: Equatable, Sendable {
    public let level: Int
    public let currentXP: Int
    public let xpForCurrentLevel: Int
    public let xpForNextLevel: Int
    public let progressToNextLevel: Double // 0.0 to 1.0
}
