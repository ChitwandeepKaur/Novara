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

