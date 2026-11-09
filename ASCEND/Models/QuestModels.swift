import Foundation

public enum QuestStatus: String, Codable, CaseIterable, Sendable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case active = "Active"
    case paused = "Paused"
    case completed = "Completed"
    case blocked = "Blocked"
    case skipped = "Skipped"
    case archived = "Archived"
    
    public var isTerminal: Bool {
        self == .completed || self == .archived || self == .skipped
    }
}

public enum QuestCategory: Codable, Hashable, Sendable {
    case career
    case fitness
    case selfCare
    case custom(String)
    
    public var displayName: String {
        switch self {
        case .career: return "Career"
        case .fitness: return "Fitness"
        case .selfCare: return "Self-Care"
        case .custom(let name): return name
        }
    }
    
    public var iconName: String {
        switch self {
        case .career: return "briefcase.fill"
        case .fitness: return "bolt.heart.fill"
        case .selfCare: return "sparkles"
        case .custom: return "star.fill"
        }
    }
}

public enum QuestPriority: String, Codable, CaseIterable, Comparable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    private var sortOrder: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    public static func < (lhs: QuestPriority, rhs: QuestPriority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

public enum QuestDifficulty: String, Codable, CaseIterable, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case epic = "Epic"
    
    public var defaultXP: Int {
        switch self {
        case .easy: return 25
        case .medium: return 50
        case .hard: return 100
        case .epic: return 250
        }
    }
}

public enum CompletionCondition: Codable, Hashable, Sendable {
    case allTasksCompleted
    case numericalTarget(target: Double, current: Double, unit: String)
    case milestoneReached(description: String)
    case deliverableCompleted(deliverableName: String)
    case manualConfirmation
    
    public var description: String {
        switch self {
        case .allTasksCompleted:
            return "Complete all associated tasks"
        case .numericalTarget(let target, let current, let unit):
            return "Reach \(Int(current))/\(Int(target)) \(unit)"
        case .milestoneReached(let desc):
            return "Milestone: \(desc)"
        case .deliverableCompleted(let deliverable):
            return "Deliverable: \(deliverable)"
        case .manualConfirmation:
            return "Manual confirmation of achievement"
        }
    }
    
    public var isSatisfied: Bool {
        switch self {
        case .allTasksCompleted:
            return false // Evaluated dynamically against tasks
        case .numericalTarget(let target, let current, _):
            return current >= target
        case .milestoneReached, .deliverableCompleted, .manualConfirmation:
            return false // Checked when marked
        }
    }
}

public struct DailyQuest: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var description: String
    public var mainQuestId: UUID?
    public var subQuestId: UUID?
    public var sideQuestId: UUID?
    public var category: QuestCategory
    public var priority: QuestPriority
    public var estimatedDurationMinutes: Int
    public var actualDurationMinutes: Int
    public var scheduledStartTime: Date?
    public var scheduledEndTime: Date?
    public var deadline: Date?
    public var isRecurring: Bool
    public var recurrenceDays: [Int] // 1 = Sunday, 2 = Monday, ...
    public var completionCondition: CompletionCondition
    public var difficulty: QuestDifficulty
    public var xpReward: Int
    public var status: QuestStatus
    public var notes: String
    public var evidenceIds: [UUID]
    public var completedAt: Date?
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        mainQuestId: UUID? = nil,
        subQuestId: UUID? = nil,
        sideQuestId: UUID? = nil,
        category: QuestCategory = .career,
        priority: QuestPriority = .medium,
        estimatedDurationMinutes: Int = 60,
        actualDurationMinutes: Int = 0,
        scheduledStartTime: Date? = nil,
        scheduledEndTime: Date? = nil,
        deadline: Date? = nil,
        isRecurring: Bool = false,
        recurrenceDays: [Int] = [],
        completionCondition: CompletionCondition = .manualConfirmation,
        difficulty: QuestDifficulty = .medium,
        xpReward: Int? = nil,
        status: QuestStatus = .notStarted,
        notes: String = "",
        evidenceIds: [UUID] = [],
        completedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.mainQuestId = mainQuestId
        self.subQuestId = subQuestId
        self.sideQuestId = sideQuestId
        self.category = category
        self.priority = priority
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.actualDurationMinutes = actualDurationMinutes
        self.scheduledStartTime = scheduledStartTime
        self.scheduledEndTime = scheduledEndTime
        self.deadline = deadline
        self.isRecurring = isRecurring
        self.recurrenceDays = recurrenceDays
        self.completionCondition = completionCondition
        self.difficulty = difficulty
        self.xpReward = xpReward ?? difficulty.defaultXP
        self.status = status
        self.notes = notes
        self.evidenceIds = evidenceIds
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
}

public struct SubQuest: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var mainQuestId: UUID
    public var title: String
    public var description: String
    public var category: QuestCategory
    public var prerequisiteSubQuestIds: [UUID]
    public var completionCondition: CompletionCondition
    public var targetDeadline: Date?
    public var status: QuestStatus
    public var orderIndex: Int
    public var completionBonusXP: Int
    public var linkedSkillIds: [String]
    public var completedAt: Date?
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        mainQuestId: UUID,
        title: String,
        description: String = "",
        category: QuestCategory = .career,
        prerequisiteSubQuestIds: [UUID] = [],
        completionCondition: CompletionCondition = .allTasksCompleted,
        targetDeadline: Date? = nil,
        status: QuestStatus = .notStarted,
        orderIndex: Int = 0,
        completionBonusXP: Int = 200,
        linkedSkillIds: [String] = [],
        completedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.mainQuestId = mainQuestId
        self.title = title
        self.description = description
        self.category = category
        self.prerequisiteSubQuestIds = prerequisiteSubQuestIds
        self.completionCondition = completionCondition
        self.targetDeadline = targetDeadline
        self.status = status
        self.orderIndex = orderIndex
        self.completionBonusXP = completionBonusXP
        self.linkedSkillIds = linkedSkillIds
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
}

public enum SideQuestType: String, Codable, CaseIterable, Sendable {
    case simpleHabit = "Simple Habit"
    case questChain = "Quest Chain"
}

public struct SideQuest: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var description: String
    public var type: SideQuestType
    public var category: QuestCategory
    public var isRecurring: Bool
    public var recurrenceDays: [Int]
    public var status: QuestStatus
    public var xpPerCompletion: Int
    public var currentStreak: Int
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        type: SideQuestType = .simpleHabit,
        category: QuestCategory = .fitness,
        isRecurring: Bool = true,
        recurrenceDays: [Int] = [1, 2, 3, 4, 5, 6, 7],
        status: QuestStatus = .inProgress,
        xpPerCompletion: Int = 30,
        currentStreak: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.category = category
        self.isRecurring = isRecurring
        self.recurrenceDays = recurrenceDays
        self.status = status
        self.xpPerCompletion = xpPerCompletion
        self.currentStreak = currentStreak
        self.createdAt = createdAt
    }
}

public struct PriorityAllocation: Codable, Equatable, Sendable {
    public var careerWeight: Double
    public var fitnessWeight: Double
    public var selfCareWeight: Double
    
    public init(careerWeight: Double = 0.8, fitnessWeight: Double = 0.1, selfCareWeight: Double = 0.1) {
        let total = careerWeight + fitnessWeight + selfCareWeight
        if total > 0 {
            self.careerWeight = careerWeight / total
            self.fitnessWeight = fitnessWeight / total
            self.selfCareWeight = selfCareWeight / total
        } else {
            self.careerWeight = 0.8
            self.fitnessWeight = 0.1
            self.selfCareWeight = 0.1
        }
    }
}

public struct MainQuest: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var description: String
    public var targetDeadline: Date?
    public var status: QuestStatus
    public var priorityDistribution: PriorityAllocation
    public var futureSelfRoadmapId: UUID?
    public var completionBonusXP: Int
    public var completedAt: Date?
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        targetDeadline: Date? = nil,
        status: QuestStatus = .active,
        priorityDistribution: PriorityAllocation = PriorityAllocation(),
        futureSelfRoadmapId: UUID? = nil,
        completionBonusXP: Int = 2500,
        completedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetDeadline = targetDeadline
        self.status = status
        self.priorityDistribution = priorityDistribution
        self.futureSelfRoadmapId = futureSelfRoadmapId
        self.completionBonusXP = completionBonusXP
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
}
