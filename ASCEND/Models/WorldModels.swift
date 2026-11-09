import Foundation

public enum WorldRegionType: String, Codable, CaseIterable, Sendable {
    case careerKingdom = "Career Kingdom"
    case fitnessGrounds = "Fitness Grounds"
    case selfCareSanctuary = "Self-Care Sanctuary"
    case custom = "Custom Haven"
}

public struct WorldStructure: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var subtitle: String
    public var tier: Int // 1: Ruin / Blueprint, 2: Workshop / Outpost, 3: Guildhall, 4: Celestial Citadel
    public var maxTier: Int
    public var isUnlocked: Bool
    public var linkedSubQuestId: UUID?
    public var linkedSkillId: String?
    public var iconName: String
    public var xOffsetRatio: Double // relative canvas coordinates (0.0 to 1.0)
    public var yOffsetRatio: Double
    
    public init(
        id: String,
        name: String,
        subtitle: String,
        tier: Int = 1,
        maxTier: Int = 4,
        isUnlocked: Bool = false,
        linkedSubQuestId: UUID? = nil,
        linkedSkillId: String? = nil,
        iconName: String = "building.columns.fill",
        xOffsetRatio: Double = 0.5,
        yOffsetRatio: Double = 0.5
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.tier = tier
        self.maxTier = maxTier
        self.isUnlocked = isUnlocked
        self.linkedSubQuestId = linkedSubQuestId
        self.linkedSkillId = linkedSkillId
        self.iconName = iconName
        self.xOffsetRatio = xOffsetRatio
        self.yOffsetRatio = yOffsetRatio
    }
}

public struct WorldRegion: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var regionType: WorldRegionType
    public var name: String
    public var title: String
    public var description: String
    public var illuminationLevel: Double // 0.0 to 1.0
    public var structures: [WorldStructure]
    public var themeColorHex: String
    public var secondaryColorHex: String
    public var islandCenterX: Double // Canvas center coordinate (0.0 to 1.0)
    public var islandCenterY: Double
    public var islandRadius: Double
    
    public init(
        id: String,
        regionType: WorldRegionType,
        name: String,
        title: String,
        description: String,
        illuminationLevel: Double = 0.2,
        structures: [WorldStructure] = [],
        themeColorHex: String = "#00D2FF",
        secondaryColorHex: String = "#7B2CBF",
        islandCenterX: Double = 0.5,
        islandCenterY: Double = 0.5,
        islandRadius: Double = 120.0
    ) {
        self.id = id
        self.regionType = regionType
        self.name = name
        self.title = title
        self.description = description
        self.illuminationLevel = illuminationLevel
        self.structures = structures
        self.themeColorHex = themeColorHex
        self.secondaryColorHex = secondaryColorHex
        self.islandCenterX = islandCenterX
        self.islandCenterY = islandCenterY
        self.islandRadius = islandRadius
    }
}

public struct WorldState: Codable, Equatable, Sendable {
    public var regions: [WorldRegion]
    public var activeBridgesCount: Int
    public var celestialSkyboxPhase: Int // 0: Night, 1: Aurora, 2: Solar Eclipse, 3: Ascended Dawn
    public var totalIllumination: Double
    
    public init(
        regions: [WorldRegion] = WorldPresets.defaultRegions(),
        activeBridgesCount: Int = 1,
        celestialSkyboxPhase: Int = 1,
        totalIllumination: Double = 0.3
    ) {
        self.regions = regions
        self.activeBridgesCount = activeBridgesCount
        self.celestialSkyboxPhase = celestialSkyboxPhase
        self.totalIllumination = totalIllumination
    }
}

public struct WorldPresets {
    public static func defaultRegions() -> [WorldRegion] {
        return [
            // 1. Career Kingdom (Central Grand Island)
            WorldRegion(
                id: "region_career",
                regionType: .careerKingdom,
                name: "The Grand Citadel",
                title: "Career Kingdom",
                description: "The intellectual capital of your realm. Rises into the clouds with glowing data towers, algorithm spires, and modern architectural marvels as your career milestones are achieved.",
                illuminationLevel: 0.35,
                structures: [
                    WorldStructure(
                        id: "struct_code_forge",
                        name: "Code Foundry",
                        subtitle: "Portfolio & Software Engineering",
                        tier: 1,
                        isUnlocked: true,
                        linkedSkillId: "career_programming",
                        iconName: "hammer.fill",
                        xOffsetRatio: 0.35,
                        yOffsetRatio: 0.4
                    ),
                    WorldStructure(
                        id: "struct_algo_spire",
                        name: "Algorithmic Spire",
                        subtitle: "Data Structures & Computational Logic",
                        tier: 1,
                        isUnlocked: false,
                        linkedSkillId: "career_dsa",
                        iconName: "network",
                        xOffsetRatio: 0.65,
                        yOffsetRatio: 0.35
                    ),
                    WorldStructure(
                        id: "struct_architecture_colosseum",
                        name: "System Design Archive",
                        subtitle: "Scalable Distributed Infrastructure",
                        tier: 1,
                        isUnlocked: false,
                        linkedSkillId: "career_system_design",
                        iconName: "server.rack",
                        xOffsetRatio: 0.5,
                        yOffsetRatio: 0.6
                    )
                ],
                themeColorHex: "#00D2FF",
                secondaryColorHex: "#7B2CBF",
                islandCenterX: 0.5,
                islandCenterY: 0.42,
                islandRadius: 130.0
            ),
            
            // 2. Fitness Grounds (South-West Floating Island)
            WorldRegion(
                id: "region_fitness",
                regionType: .fitnessGrounds,
                name: "The Colosseum of Vitality",
                title: "Fitness Grounds",
                description: "A fortified athletic plateau carved into floating volcanic obsidian and illuminated by radiant celestial flame.",
                illuminationLevel: 0.25,
                structures: [
                    WorldStructure(
                        id: "struct_iron_bastion",
                        name: "Iron Bastion",
                        subtitle: "Strength & Resistance Training",
                        tier: 1,
                        isUnlocked: true,
                        linkedSkillId: "fitness_strength",
                        iconName: "dumbbell.fill",
                        xOffsetRatio: 0.45,
                        yOffsetRatio: 0.5
                    ),
                    WorldStructure(
                        id: "struct_wind_track",
                        name: "Gale Path",
                        subtitle: "Endurance & Heart Rate Mastery",
                        tier: 1,
                        isUnlocked: false,
                        linkedSkillId: "fitness_endurance",
                        iconName: "figure.run",
                        xOffsetRatio: 0.7,
                        yOffsetRatio: 0.65
                    )
                ],
                themeColorHex: "#FF6584",
                secondaryColorHex: "#FF416C",
                islandCenterX: 0.22,
                islandCenterY: 0.75,
                islandRadius: 85.0
            ),
            
            // 3. Self-Care Sanctuary (South-East Floating Island)
            WorldRegion(
                id: "region_self_care",
                regionType: .selfCareSanctuary,
                name: "The Celestial Grove",
                title: "Self-Care Sanctuary",
                description: "A tranquil sanctuary filled with bioluminescent waterfalls, ancient moss, and peaceful mist that revitalizes your spirit.",
                illuminationLevel: 0.3,
                structures: [
                    WorldStructure(
                        id: "struct_reflection_pool",
                        name: "Pool of Serenity",
                        subtitle: "Mindfulness & Stillness",
                        tier: 1,
                        isUnlocked: true,
                        linkedSkillId: "selfcare_mindfulness",
                        iconName: "leaf.fill",
                        xOffsetRatio: 0.5,
                        yOffsetRatio: 0.45
                    ),
                    WorldStructure(
                        id: "struct_lunar_shrine",
                        name: "Lunar Rest Shrine",
                        subtitle: "Sleep Architecture & Rejuvenation",
                        tier: 1,
                        isUnlocked: false,
                        linkedSkillId: "selfcare_sleep",
                        iconName: "moon.stars.fill",
                        xOffsetRatio: 0.65,
                        yOffsetRatio: 0.7
                    )
                ],
                themeColorHex: "#00F2FE",
                secondaryColorHex: "#4FACFE",
                islandCenterX: 0.78,
                islandCenterY: 0.75,
                islandRadius: 85.0
            )
        ]
    }
}

