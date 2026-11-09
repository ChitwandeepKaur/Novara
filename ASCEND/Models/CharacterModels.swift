import Foundation

public enum CosmeticSlot: String, Codable, CaseIterable, Sendable {
    case outfit = "Outfit"
    case headwear = "Headwear"
    case weaponOrTool = "Artifact / Tool"
    case accessory = "Accessory"
    case aura = "Celestial Aura"
    case title = "Title"
}

public enum CosmeticRarity: String, Codable, CaseIterable, Sendable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    case celestial = "Celestial"
    
    public var glowColorHex: String {
        switch self {
        case .common: return "#9E9E9E"
        case .rare: return "#00D2FF"
        case .epic: return "#9B51E0"
        case .legendary: return "#F2C94C"
        case .celestial: return "#FF6584"
        }
    }
}

public struct CosmeticItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var description: String
    public var slot: CosmeticSlot
    public var rarity: CosmeticRarity
    public var unlockRequirement: String
    public var requiredLevel: Int
    public var iconName: String
    public var visualAssetKey: String
    
    public init(
        id: String,
        name: String,
        description: String = "",
        slot: CosmeticSlot,
        rarity: CosmeticRarity = .common,
        unlockRequirement: String = "",
        requiredLevel: Int = 1,
        iconName: String,
        visualAssetKey: String
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.slot = slot
        self.rarity = rarity
        self.unlockRequirement = unlockRequirement
        self.requiredLevel = requiredLevel
        self.iconName = iconName
        self.visualAssetKey = visualAssetKey
    }
}

public struct AvatarProfile: Codable, Equatable, Sendable {
    public var name: String
    public var title: String
    public var level: Int
    public var currentXP: Int
    public var totalCumulativeXP: Int
    public var skinToneIndex: Int
    public var hairStyleIndex: Int
    public var hairColorIndex: Int
    public var outfitIndex: Int
    public var accessoryIndex: Int
    public var auraEffectIndex: Int
    public var equippedCosmeticIds: [String: String] // Slot name -> CosmeticItem id
    public var unlockedCosmeticIds: [String]
    
    public init(
        name: String = "Traveler",
        title: String = "The Initiate",
        level: Int = 1,
        currentXP: Int = 0,
        totalCumulativeXP: Int = 0,
        skinToneIndex: Int = 0,
        hairStyleIndex: Int = 0,
        hairColorIndex: Int = 0,
        outfitIndex: Int = 0,
        accessoryIndex: Int = 0,
        auraEffectIndex: Int = 0,
        equippedCosmeticIds: [String: String] = [:],
        unlockedCosmeticIds: [String] = ["title_initiate", "outfit_apprentice", "aura_whisper"]
    ) {
        self.name = name
        self.title = title
        self.level = level
        self.currentXP = currentXP
        self.totalCumulativeXP = totalCumulativeXP
        self.skinToneIndex = skinToneIndex
        self.hairStyleIndex = hairStyleIndex
        self.hairColorIndex = hairColorIndex
        self.outfitIndex = outfitIndex
        self.accessoryIndex = accessoryIndex
        self.auraEffectIndex = auraEffectIndex
        self.equippedCosmeticIds = equippedCosmeticIds
        self.unlockedCosmeticIds = unlockedCosmeticIds
    }
}

public struct CosmeticCatalogue {
    public static let allItems: [CosmeticItem] = [
        CosmeticItem(
            id: "title_initiate",
            name: "The Initiate",
            description: "One who has stepped onto the path of transformation.",
            slot: .title,
            rarity: .common,
            unlockRequirement: "Starting Title",
            requiredLevel: 1,
            iconName: "sparkles",
            visualAssetKey: "title_initiate"
        ),
        CosmeticItem(
            id: "title_builder",
            name: "The Artisan Builder",
            description: "Forged in the fires of consistent creation.",
            slot: .title,
            rarity: .rare,
            unlockRequirement: "Reach Level 5 and build first project",
            requiredLevel: 5,
            iconName: "hammer.fill",
            visualAssetKey: "title_builder"
        ),
        CosmeticItem(
            id: "title_contender",
            name: "The Resolute Contender",
            description: "Ready to test their mettle against the greatest trials.",
            slot: .title,
            rarity: .epic,
            unlockRequirement: "Reach Level 10 and unlock 3 skills",
            requiredLevel: 10,
            iconName: "shield.fill",
            visualAssetKey: "title_contender"
        ),
        CosmeticItem(
            id: "title_breakthrough",
            name: "The Breakthrough Self",
            description: "Transcended the threshold to enter a new epoch.",
            slot: .title,
            rarity: .celestial,
            unlockRequirement: "Complete your Main Quest",
            requiredLevel: 15,
            iconName: "crown.fill",
            visualAssetKey: "title_breakthrough"
        ),
        CosmeticItem(
            id: "outfit_apprentice",
            name: "Apprentice Robes",
            description: "Durable travel clothing woven with subtle mana threads.",
            slot: .outfit,
            rarity: .common,
            unlockRequirement: "Unlocked at start",
            requiredLevel: 1,
            iconName: "tshirt.fill",
            visualAssetKey: "outfit_apprentice"
        ),
        CosmeticItem(
            id: "outfit_cyber_monk",
            name: "Cyber-Monk Vestments",
            description: "Sleek biometric fibers with responsive glowing trims.",
            slot: .outfit,
            rarity: .rare,
            unlockRequirement: "Reach Level 4",
            requiredLevel: 4,
            iconName: "tshirt.fill",
            visualAssetKey: "outfit_cyber_monk"
        ),
        CosmeticItem(
            id: "outfit_grandmaster",
            name: "Grand Architect Coat",
            description: "Regal ceremonial mantle embroidered with celestial constellations.",
            slot: .outfit,
            rarity: .legendary,
            unlockRequirement: "Reach Level 12",
            requiredLevel: 12,
            iconName: "tshirt.fill",
            visualAssetKey: "outfit_grandmaster"
        ),
        CosmeticItem(
            id: "aura_whisper",
            name: "Dawn Whisper",
            description: "A faint, soothing cyan luminescence dancing around your silhouette.",
            slot: .aura,
            rarity: .common,
            unlockRequirement: "Unlocked at start",
            requiredLevel: 1,
            iconName: "sun.min.fill",
            visualAssetKey: "aura_whisper"
        ),
        CosmeticItem(
            id: "aura_celestial_flame",
            name: "Celestial Plasma",
            description: "Dancing violet flames charged with high-octane creative energy.",
            slot: .aura,
            rarity: .epic,
            unlockRequirement: "Reach Level 8",
            requiredLevel: 8,
            iconName: "flame.fill",
            visualAssetKey: "aura_celestial_flame"
        ),
        CosmeticItem(
            id: "aura_singularity",
            name: "Golden Singularity",
            description: "Orbiting rings of radiant starlight and golden particles.",
            slot: .aura,
            rarity: .celestial,
            unlockRequirement: "Reach Level 15",
            requiredLevel: 15,
            iconName: "star.fill",
            visualAssetKey: "aura_singularity"
        ),
        CosmeticItem(
            id: "tool_runic_quill",
            name: "Holographic Codex",
            description: "Projects glowing interactive algorithms and diagrams in thin air.",
            slot: .weaponOrTool,
            rarity: .rare,
            unlockRequirement: "Reach Level 3",
            requiredLevel: 3,
            iconName: "book.fill",
            visualAssetKey: "tool_runic_quill"
        ),
        CosmeticItem(
            id: "tool_blade_of_focus",
            name: "Chrono-Focus Blade",
            description: "Cleaves through distraction, procrastination, and noise.",
            slot: .weaponOrTool,
            rarity: .legendary,
            unlockRequirement: "Complete 10 Focus Sessions",
            requiredLevel: 7,
            iconName: "wand.and.stars",
            visualAssetKey: "tool_blade_of_focus"
        )
    ]
}

