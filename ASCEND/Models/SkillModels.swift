import Foundation

public enum SkillNodeState: String, Codable, CaseIterable, Sendable {
    case locked = "Locked"
    case available = "Available"
    case inProgress = "In Progress"
    case mastered = "Mastered"
}

public struct SkillNode: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var description: String
    public var category: QuestCategory
    public var tier: Int // 1 to 5
    public var prerequisiteNodeIds: [String]
    public var currentLevel: Int
    public var maxLevel: Int
    public var xpContributed: Int
    public var xpRequiredPerLevel: Int
    public var gridPositionX: Double // 0.0 to 1.0 (relative canvas placement)
    public var gridPositionY: Double // 0.0 to 1.0
    public var iconName: String
    
    public init(
        id: String,
        name: String,
        description: String,
        category: QuestCategory,
        tier: Int = 1,
        prerequisiteNodeIds: [String] = [],
        currentLevel: Int = 0,
        maxLevel: Int = 5,
        xpContributed: Int = 0,
        xpRequiredPerLevel: Int = 100,
        gridPositionX: Double = 0.5,
        gridPositionY: Double = 0.5,
        iconName: String = "bolt.circle.fill"
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.tier = tier
        self.prerequisiteNodeIds = prerequisiteNodeIds
        self.currentLevel = currentLevel
        self.maxLevel = maxLevel
        self.xpContributed = xpContributed
        self.xpRequiredPerLevel = xpRequiredPerLevel
        self.gridPositionX = gridPositionX
        self.gridPositionY = gridPositionY
        self.iconName = iconName
    }
    
    public var isMastered: Bool {
        currentLevel >= maxLevel
    }
    
    public var progressRatio: Double {
        if isMastered { return 1.0 }
        let totalNeeded = Double(maxLevel * xpRequiredPerLevel)
        guard totalNeeded > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(xpContributed) / totalNeeded))
    }
}

public struct SkillTreePresets {
    public static func defaultSkills() -> [SkillNode] {
        return [
            // CAREER SKILLS
            SkillNode(
                id: "career_programming",
                name: "Core Software Craft",
                description: "Clean code principles, architecture, debugging, and idiomatic engineering.",
                category: .career,
                tier: 1,
                prerequisiteNodeIds: [],
                currentLevel: 1,
                maxLevel: 5,
                xpContributed: 50,
                gridPositionX: 0.25,
                gridPositionY: 0.2,
                iconName: "chevron.left.forwardslash.chevron.right"
            ),
            SkillNode(
                id: "career_dsa",
                name: "Algorithms & Data Structures",
                description: "Array/String manipulation, trees, graphs, dynamic programming, and complexity mastery.",
                category: .career,
                tier: 2,
                prerequisiteNodeIds: ["career_programming"],
                currentLevel: 0,
                maxLevel: 5,
                gridPositionX: 0.25,
                gridPositionY: 0.45,
                iconName: "network"
            ),
            SkillNode(
                id: "career_system_design",
                name: "System Design & Architecture",
                description: "Distributed systems, scalability, load balancing, caching, databases, and microservices.",
                category: .career,
                tier: 3,
                prerequisiteNodeIds: ["career_programming"],
                currentLevel: 0,
                maxLevel: 5,
                gridPositionX: 0.65,
                gridPositionY: 0.45,
                iconName: "server.rack"
            ),
            SkillNode(
                id: "career_cloud_devops",
                name: "Cloud & Infrastructure",
                description: "Containerization, CI/CD pipelines, cloud platforms, and observability.",
                category: .career,
                tier: 3,
                prerequisiteNodeIds: ["career_system_design"],
                currentLevel: 0,
                maxLevel: 5,
                gridPositionX: 0.65,
                gridPositionY: 0.7,
                iconName: "cloud.fill"
            ),
            SkillNode(
                id: "career_interview_comm",
                name: "Interview Communication",
                description: "Behavioral storytelling, technical whiteboarding, and executive presence.",
                category: .career,
                tier: 4,
                prerequisiteNodeIds: ["career_dsa", "career_system_design"],
                currentLevel: 0,
                maxLevel: 5,
                gridPositionX: 0.45,
                gridPositionY: 0.85,
                iconName: "person.crop.circle.badge.checkmark"
            ),
            
            // FITNESS SKILLS
            SkillNode(
                id: "fitness_consistency",
                name: "Workout Discipline",
                description: "Showing up consistently, overcoming friction, and building training momentum.",
                category: .fitness,
                tier: 1,
                prerequisiteNodeIds: [],
                currentLevel: 1,
                maxLevel: 5,
                xpContributed: 20,
                gridPositionX: 0.3,
                gridPositionY: 0.2,
                iconName: "flame.fill"
            ),
            SkillNode(
                id: "fitness_strength",
                name: "Strength & Power",
                description: "Progressive overload, resistance training, and mechanical tension mastery.",
                category: .fitness,
                tier: 2,
                prerequisiteNodeIds: ["fitness_consistency"],
                currentLevel: 0,
                maxLevel: 5,
                gridPositionX: 0.2,
                gridPositionY: 0.55,
                iconName: "dumbbell.fill"
            ),
            SkillNode(
                id: "fitness_endurance",
                name: "Aerobic Capacity",
                description: "Cardiovascular resilience, steady-state zone 2 pacing, and stamina.",
                category: .fitness,
                tier: 2,
                prerequisiteNodeIds: ["fitness_consistency"],
                currentLevel: 0,
                maxLevel: 5,
                gridPositionX: 0.5,
                gridPositionY: 0.55,
                iconName: "figure.run"
            ),
            SkillNode(
                id: "fitness_mobility",
                name: "Mobility & Recovery",
                description: "Joint integrity, flexibility, active stretching, and active recovery.",
                category: .fitness,
                tier: 3,
                prerequisiteNodeIds: ["fitness_strength", "fitness_endurance"],
                currentLevel: 0,
                maxLevel: 5,
                gridPositionX: 0.35,
                gridPositionY: 0.85,
                iconName: "figure.flexibility"
            ),
            
            // SELF-CARE SKILLS
            SkillNode(
                id: "selfcare_mindfulness",
                name: "Mental Clarity & Stillness",
                description: "Meditation, emotional regulation, breathwork, and sensory grounding.",
                category: .selfCare,
                tier: 1,
                prerequisiteNodeIds: [],
                currentLevel: 1,
                maxLevel: 5,
                xpContributed: 30,
                gridPositionX: 0.3,
                gridPositionY: 0.25,
                iconName: "leaf.fill"
            ),
            SkillNode(
                id: "selfcare_sleep",
                name: "Sleep Optimization",
                description: "Circadian alignment, dark bedroom hygiene, and recovery rest architecture.",
                category: .selfCare,
                tier: 2,
                prerequisiteNodeIds: ["selfcare_mindfulness"],
                currentLevel: 0,
                maxLevel: 5,
                gridPositionX: 0.5,
                gridPositionY: 0.55,
                iconName: "moon.stars.fill"
            ),
            SkillNode(
                id: "selfcare_rituals",
                name: "Morning & Night Rituals",
                description: "Deliberate boundaries, skincare, hydration, and journal self-reflection.",
                category: .selfCare,
                tier: 3,
                prerequisiteNodeIds: ["selfcare_sleep"],
                currentLevel: 0,
                maxLevel: 5,
                gridPositionX: 0.5,
                gridPositionY: 0.85,
                iconName: "sun.haze.fill"
            )
        ]
    }
}
