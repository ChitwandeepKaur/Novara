import Foundation

public struct QuestEngineError: LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

public final class QuestEngine: Sendable {
    public static let shared = QuestEngine()
    
    public init() {}
    
    // MARK: - Main Quest Rules
    
    /// Activates the given MainQuest. Exactly one MainQuest can be active at a time.
    /// If another MainQuest was active, it is transitioned to `.paused` without losing any progress or rewards.
    public func activateMainQuest(id: UUID, in state: inout AppState) {
        for index in state.mainQuests.indices {
            if state.mainQuests[index].id == id {
                state.mainQuests[index].status = .active
            } else if state.mainQuests[index].status == .active {
                state.mainQuests[index].status = .paused
            }
        }
    }
    
    /// Pauses an active MainQuest. Does not delete progress, XP, or milestones.
    public func pauseMainQuest(id: UUID, in state: inout AppState) {
        if let index = state.mainQuests.firstIndex(where: { $0.id == id }) {
            state.mainQuests[index].status = .paused
        }
    }
    
    /// Completes and archives a MainQuest. Returns bonus XP earned.
    public func completeMainQuest(id: UUID, in state: inout AppState) -> Int {
        guard let index = state.mainQuests.firstIndex(where: { $0.id == id }) else { return 0 }
        state.mainQuests[index].status = .archived
        state.mainQuests[index].completedAt = Date()
        
        let bonusXP = state.mainQuests[index].completionBonusXP
        return bonusXP
    }
    
    public func activeMainQuest(in state: AppState) -> MainQuest? {
        state.mainQuests.first(where: { $0.status == .active })
    }
    
    // MARK: - Sub Quest Dependency Graph (DAG) & Cycle Detection
    
    /// Checks whether adding a dependency where `subQuestId` depends on `prerequisiteId` would create a cycle.
    /// Uses Depth-First Search (DFS) graph traversal.
    public func wouldCreateCycle(
        subQuestId: UUID,
        newPrerequisiteId: UUID,
        allSubQuests: [SubQuest]
    ) -> Bool {
        // Direct self-dependency is an immediate cycle
        if subQuestId == newPrerequisiteId { return true }
        
        // Build adjacency map: node -> list of prerequisites
        var prereqMap: [UUID: [UUID]] = [:]
        for sq in allSubQuests {
            prereqMap[sq.id] = sq.prerequisiteSubQuestIds
        }
        
        // Speculatively add the new edge
        var existing = prereqMap[subQuestId] ?? []
        existing.append(newPrerequisiteId)
        prereqMap[subQuestId] = existing
        
        // Cycle check: from newPrerequisiteId, can we reach subQuestId?
        var visited = Set<UUID>()
        func canReach(current: UUID, target: UUID) -> Bool {
            if current == target { return true }
            if visited.contains(current) { return false }
            visited.insert(current)
            
            for next in (prereqMap[current] ?? []) {
                if canReach(current: next, target: target) {
                    return true
                }
            }
            return false
        }
        
        return canReach(current: newPrerequisiteId, target: subQuestId)
    }
    
    /// Safely adds a prerequisite to a SubQuest, rejecting cycles.
    public func addPrerequisite(
        to subQuestId: UUID,
        prerequisiteId: UUID,
        in state: inout AppState
    ) throws {
        guard let index = state.subQuests.firstIndex(where: { $0.id == subQuestId }) else {
            throw QuestEngineError("SubQuest not found.")
        }
        
        guard state.subQuests.contains(where: { $0.id == prerequisiteId }) else {
            throw QuestEngineError("Prerequisite SubQuest does not exist.")
        }
        
        if wouldCreateCycle(subQuestId: subQuestId, newPrerequisiteId: prerequisiteId, allSubQuests: state.subQuests) {
            throw QuestEngineError("Cannot add prerequisite: circular dependency detected.")
        }
        
        if !state.subQuests[index].prerequisiteSubQuestIds.contains(prerequisiteId) {
            state.subQuests[index].prerequisiteSubQuestIds.append(prerequisiteId)
        }
    }
    
    /// Evaluates if a SubQuest's prerequisites are all completed.
    public func arePrerequisitesMet(for subQuest: SubQuest, allSubQuests: [SubQuest]) -> Bool {
        guard !subQuest.prerequisiteSubQuestIds.isEmpty else { return true }
        let completedIds = Set(allSubQuests.filter { $0.status == .completed }.map { $0.id })
        return subQuest.prerequisiteSubQuestIds.allSatisfy { completedIds.contains($0) }
    }
    
    // MARK: - Completion Evaluation
    
    /// Evaluates whether a SubQuest satisfies its completion requirements.
    public func isSubQuestComplete(subQuest: SubQuest, linkedTasks: [DailyQuest]) -> Bool {
        switch subQuest.completionCondition {
        case .allTasksCompleted:
            guard !linkedTasks.isEmpty else { return false }
            return linkedTasks.allSatisfy { $0.status == .completed }
        case .numericalTarget(let target, let current, _):
            return current >= target
        case .milestoneReached, .deliverableCompleted, .manualConfirmation:
            return subQuest.status == .completed
        }
    }
    
    /// Updates progress for a numerical target condition.
    public func recordNumericalProgress(
        subQuestId: UUID,
        increment: Double,
        in state: inout AppState
    ) -> Bool {
        guard let index = state.subQuests.firstIndex(where: { $0.id == subQuestId }) else { return false }
        var sq = state.subQuests[index]
        if case .numericalTarget(let target, let current, let unit) = sq.completionCondition {
            let newCurrent = current + increment
            sq.completionCondition = .numericalTarget(target: target, current: newCurrent, unit: unit)
            let isNowDone = newCurrent >= target
            if isNowDone && sq.status != .completed {
                sq.status = .completed
                sq.completedAt = Date()
            }
            state.subQuests[index] = sq
            return isNowDone
        }
        return false
    }
}

