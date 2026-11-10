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


/// Fairy affinities unlock from lifetime XP, independently of character level.
public enum FairyPalette: String, Codable, CaseIterable, Identifiable, Sendable {
    case flora, aisha, tecna, musa, stella, bloom
    public var realmName: String {
        switch self {
        case .flora: return "The enchanted garden"
        case .aisha: return "The tidal sanctuary"
        case .tecna: return "The prismatic atelier"
        case .musa: return "The midnight symphony"
        case .stella: return "The solar observatory"
        case .bloom: return "The dragon flame sanctum"
        }
    }
    public var invitation: String {
        switch self {
        case .flora: return "Give your\ndreams roots."
        case .aisha: return "Find strength\nin your flow."
        case .tecna: return "Design your\nnext possibility."
        case .musa: return "Find your\nown rhythm."
        case .stella: return "Let your\nlight unfold."
        case .bloom: return "Keep your\ninner fire alive."
        }
    }
    public var designDetails: String {
        switch self {
        case .flora: return "Rose petals, climbing vines, and a woodland glow"
        case .aisha: return "Ocean ripples, pearl droplets, and flowing wings"
        case .tecna: return "Prismatic circuits, crystal facets, and geometric wings"
        case .musa: return "Musical staves, sound waves, and midnight shimmer"
        case .stella: return "Sunbursts, crescent moons, and golden constellations"
        case .bloom: return "Dragon flame, rising embers, and sapphire light"
        }
    }
    public var particleSymbol: String {
        switch self {
        case .flora: return "leaf.fill"
        case .aisha: return "drop.fill"
        case .tecna: return "diamond.fill"
        case .musa: return "music.note"
        case .stella: return "sparkle"
        case .bloom: return "flame.fill"
        }
    }
    public var requiredXP: Int { Self.allCases.firstIndex(of: self)! * 10_000 }
    public func isUnlocked(totalXP: Int) -> Bool { totalXP >= requiredXP }
    public static func highestUnlocked(totalXP: Int) -> Self {
        allCases.last(where: { $0.isUnlocked(totalXP: totalXP) }) ?? .flora
    }
    public static func nextUnlock(totalXP: Int) -> Self? {
        allCases.first(where: { !$0.isUnlocked(totalXP: totalXP) })
    }
    public var id: String { rawValue }
    public var name: String { rawValue.capitalized }
    public var element: String {
        switch self {
        case .bloom: return "Dragon flame"
        case .stella: return "Solar radiance"
        case .flora: return "Enchanted garden"
        case .musa: return "Midnight melody"
        case .tecna: return "Prismatic intelligence"
        case .aisha: return "Tidal energy"
        }
    }
    public var symbol: String {
        switch self {
        case .bloom: return "flame"
        case .stella: return "sun.max"
        case .flora: return "leaf"
        case .musa: return "waveform"
        case .tecna: return "cpu"
        case .aisha: return "drop"
        }
    }
    public var accent: String {
        switch self {
        case .bloom: return "#EF927A"
        case .stella: return "#E9BD78"
        case .flora: return "#E6A6C3"
        case .musa: return "#EF91AD"
        case .tecna: return "#B8A2F0"
        case .aisha: return "#76CDBE"
        }
    }
    public var secondary: String {
        switch self {
        case .bloom: return "#8FADF0"
        case .stella: return "#D58DBA"
        case .flora: return "#93BCA0"
        case .musa: return "#9D9AEF"
        case .tecna: return "#7DC8BE"
        case .aisha: return "#9FAAE9"
        }
    }
    public var light: String {
        switch self {
        case .bloom: return "#F5C5AC"
        case .stella: return "#F4DDAB"
        case .flora: return "#D9E6C5"
        case .musa: return "#E6C9E9"
        case .tecna: return "#D6C9FA"
        case .aisha: return "#BDE8E0"
        }
    }
    public var background: String {
        switch self {
        case .bloom: return "#131B2D"
        case .stella: return "#251B26"
        case .flora: return "#15191B"
        case .musa: return "#1D1428"
        case .tecna: return "#131A28"
        case .aisha: return "#101C22"
        }
    }
    public var surface: String {
        switch self {
        case .bloom: return "#202F49"
        case .stella: return "#3A2C3B"
        case .flora: return "#252B2B"
        case .musa: return "#34233F"
        case .tecna: return "#242D43"
        case .aisha: return "#1C3037"
        }
    }
}

