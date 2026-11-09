import Foundation

public enum EvidenceType: String, Codable, CaseIterable, Sendable {
    case url = "Project Link / URL"
    case note = "Written Reflection"
    case imageRef = "Screenshot / Image"
    case documentRef = "Document / Certificate"
    
    public var iconName: String {
        switch self {
        case .url: return "link"
        case .note: return "note.text"
        case .imageRef: return "photo.fill"
        case .documentRef: return "doc.fill"
        }
    }
}

public struct EvidenceAttachment: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var questId: UUID?
    public var type: EvidenceType
    public var title: String
    public var content: String // URL string, note text, or local relative file path
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        questId: UUID? = nil,
        type: EvidenceType = .note,
        title: String,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.questId = questId
        self.type = type
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}

public struct Achievement: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var description: String
    public var category: QuestCategory
    public var iconName: String
    public var isUnlocked: Bool
    public var unlockedAt: Date?
    public var evidenceAttachmentIds: [UUID]
    public var rewardedCosmeticId: String?
    
    public init(
        id: String,
        title: String,
        description: String,
        category: QuestCategory = .career,
        iconName: String = "trophy.fill",
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        evidenceAttachmentIds: [UUID] = [],
        rewardedCosmeticId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.iconName = iconName
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.evidenceAttachmentIds = evidenceAttachmentIds
        self.rewardedCosmeticId = rewardedCosmeticId
    }
}

public struct AchievementCatalogue {
    public static func defaultAchievements() -> [Achievement] {
        return [
            Achievement(
                id: "ach_first_blood",
                title: "First Step into the Realm",
                description: "Completed your very first quest in ASCEND.",
                category: .career,
                iconName: "flag.fill",
                rewardedCosmeticId: "aura_whisper"
            ),
            Achievement(
                id: "ach_deep_focus",
                title: "Monk Mode Mastery",
                description: "Logged over 90 minutes of continuous focused study.",
                category: .career,
                iconName: "timer",
                rewardedCosmeticId: "tool_blade_of_focus"
            ),
            Achievement(
                id: "ach_proof_of_craft",
                title: "Proof of Craftsmanship",
                description: "Attached live evidence (GitHub, deployed link, or certificate) to a major quest.",
                category: .career,
                iconName: "rosette",
                rewardedCosmeticId: "tool_runic_quill"
            ),
            Achievement(
                id: "ach_iron_will",
                title: "Iron Will",
                description: "Maintained a 7-day side quest streak in fitness or self-care.",
                category: .fitness,
                iconName: "flame.circle.fill",
                rewardedCosmeticId: "outfit_cyber_monk"
            ),
            Achievement(
                id: "ach_citadel_architect",
                title: "Citadel Architect",
                description: "Upgraded all structures in Career Kingdom to Tier 2 or higher.",
                category: .career,
                iconName: "building.2.fill",
                rewardedCosmeticId: "outfit_grandmaster"
            ),
            Achievement(
                id: "ach_great_breakthrough",
                title: "Ascension Breakthrough",
                description: "Completed an entire Main Quest and reached your Future-Self destination.",
                category: .career,
                iconName: "crown.fill",
                rewardedCosmeticId: "title_breakthrough"
            )
        ]
    }
}
