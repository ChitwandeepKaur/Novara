import Foundation

public struct TimeSlot: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var startTime: Date
    public var endTime: Date
    public var dailyQuestId: UUID?
    public var title: String
    public var category: QuestCategory
    public var isFixedCommitment: Bool
    public var isBreak: Bool
    public var isCompleted: Bool
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        dailyQuestId: UUID? = nil,
        title: String,
        category: QuestCategory = .career,
        isFixedCommitment: Bool = false,
        isBreak: Bool = false,
        isCompleted: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.dailyQuestId = dailyQuestId
        self.title = title
        self.category = category
        self.isFixedCommitment = isFixedCommitment
        self.isBreak = isBreak
        self.isCompleted = isCompleted
        self.notes = notes
    }
    
    public var durationMinutes: Int {
        max(5, Int(endTime.timeIntervalSince(startTime) / 60))
    }
}

public struct FocusSession: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var dailyQuestId: UUID?
    public var questTitle: String
    public var startTime: Date
    public var endTime: Date?
    public var durationMinutes: Int
    public var xpAwarded: Int
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        dailyQuestId: UUID? = nil,
        questTitle: String,
        startTime: Date = Date(),
        endTime: Date? = nil,
        durationMinutes: Int = 0,
        xpAwarded: Int = 0,
        notes: String = ""
    ) {
        self.id = id
        self.dailyQuestId = dailyQuestId
        self.questTitle = questTitle
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.xpAwarded = xpAwarded
        self.notes = notes
    }
}

public struct ReplanProposal: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var generatedAt: Date
    public var rationale: String
    public var shortenedTasks: [String]
    public var movedTasks: [String]
    public var deferredTasks: [String]
    public var proposedSlots: [TimeSlot]
    
    public init(
        id: UUID = UUID(),
        generatedAt: Date = Date(),
        rationale: String,
        shortenedTasks: [String] = [],
        movedTasks: [String] = [],
        deferredTasks: [String] = [],
        proposedSlots: [TimeSlot] = []
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.rationale = rationale
        self.shortenedTasks = shortenedTasks
        self.movedTasks = movedTasks
        self.deferredTasks = deferredTasks
        self.proposedSlots = proposedSlots
    }
}

public struct DailyPlan: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var date: Date
    public var slots: [TimeSlot]
    public var isApprovedByUser: Bool
    public var availableWorkingHours: Double
    public var pendingReplanProposal: ReplanProposal?
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        slots: [TimeSlot] = [],
        isApprovedByUser: Bool = false,
        availableWorkingHours: Double = 6.0,
        pendingReplanProposal: ReplanProposal? = nil
    ) {
        self.id = id
        self.date = date
        self.slots = slots
        self.isApprovedByUser = isApprovedByUser
        self.availableWorkingHours = availableWorkingHours
        self.pendingReplanProposal = pendingReplanProposal
    }
}

public struct SubQuestDraft: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var description: String
    public var completionConditionDescription: String
    public var category: QuestCategory
    public var completionBonusXP: Int
    public var linkedSkillName: String
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        completionConditionDescription: String = "Complete all associated milestones",
        category: QuestCategory = .career,
        completionBonusXP: Int = 300,
        linkedSkillName: String = "Craftsmanship"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.completionConditionDescription = completionConditionDescription
        self.category = category
        self.completionBonusXP = completionBonusXP
        self.linkedSkillName = linkedSkillName
    }
}

public struct DailyQuestDraft: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var category: QuestCategory
    public var priority: QuestPriority
    public var estimatedDurationMinutes: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: QuestCategory = .career,
        priority: QuestPriority = .high,
        estimatedDurationMinutes: Int = 60
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.priority = priority
        self.estimatedDurationMinutes = estimatedDurationMinutes
    }
}

public struct SideHabitDraft: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var category: QuestCategory
    
    public init(
        id: UUID = UUID(),
        title: String,
        category: QuestCategory = .fitness
    ) {
        self.id = id
        self.title = title
        self.category = category
    }
}

public struct FutureSelfStageDraft: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var stageIndex: Int
    public var title: String
    public var tagline: String
    public var milestoneRequirement: String
    
    public init(
        id: String,
        stageIndex: Int,
        title: String,
        tagline: String,
        milestoneRequirement: String
    ) {
        self.id = id
        self.stageIndex = stageIndex
        self.title = title
        self.tagline = tagline
        self.milestoneRequirement = milestoneRequirement
    }
}

public struct CustomPlanDraft: Codable, Equatable, Sendable {
    public var goalTitle: String
    public var goalDescription: String
    public var category: QuestCategory
    public var priorityAllocation: PriorityAllocation
    public var subQuests: [SubQuestDraft]
    public var dailyQuests: [DailyQuestDraft]
    public var sideHabits: [SideHabitDraft]
    public var futureSelfStages: [FutureSelfStageDraft]
    public var explanation: String
    
    public init(
        goalTitle: String,
        goalDescription: String = "",
        category: QuestCategory = .career,
        priorityAllocation: PriorityAllocation = PriorityAllocation(careerWeight: 0.8, fitnessWeight: 0.1, selfCareWeight: 0.1),
        subQuests: [SubQuestDraft] = [],
        dailyQuests: [DailyQuestDraft] = [],
        sideHabits: [SideHabitDraft] = [],
        futureSelfStages: [FutureSelfStageDraft] = [],
        explanation: String = ""
    ) {
        self.goalTitle = goalTitle
        self.goalDescription = goalDescription
        self.category = category
        self.priorityAllocation = priorityAllocation
        self.subQuests = subQuests
        self.dailyQuests = dailyQuests
        self.sideHabits = sideHabits
        self.futureSelfStages = futureSelfStages
        self.explanation = explanation
    }
}

