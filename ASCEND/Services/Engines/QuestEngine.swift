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


// MARK: - Temporary goals alongside the main journey
extension QuestEngine {
    /// Each outcome becomes a milestone with three editable, concrete work sessions.
    public func miniQuestBreakdown(outcomes: [String], category: QuestCategory, minutes: Int) -> [DailyQuest] {
        outcomes.flatMap { outcome in
            [
                DailyQuest(name: "Plan: \(outcome)", description: "Define what done looks like, gather resources, and write the first steps for: \(outcome)", category: category, estimatedDurationMinutes: minutes),
                DailyQuest(name: "Make progress: \(outcome)", description: "Work through the steps and produce a first result for: \(outcome)", category: category, estimatedDurationMinutes: minutes),
                DailyQuest(name: "Finish & verify: \(outcome)", description: "Review the result against your success criteria and finish: \(outcome)", category: category, estimatedDurationMinutes: minutes)
            ]
        }
    }

    @discardableResult
    public func addMiniQuest(title: String, outcomes: [String], deadline: Date,
                             category: QuestCategory, tasks: [DailyQuest],
                             now: Date = Date(), in state: inout AppState) throws -> UUID {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanOutcomes = outcomes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !cleanTitle.isEmpty, !cleanOutcomes.isEmpty,
              tasks.count == cleanOutcomes.count * 3,
              tasks.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.estimatedDurationMinutes > 0 }),
              Calendar.current.startOfDay(for: deadline) >= Calendar.current.startOfDay(for: now) else {
            throw QuestEngineError("Enter a title, at least one outcome, and a deadline of today or later. Review all generated sessions before saving.")
        }
        let endOfDeadline = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: deadline))!.addingTimeInterval(-1)
        var mini = MiniMainQuest(title: cleanTitle, visionDescription: cleanOutcomes.joined(separator: "\n"), targetDeadline: endOfDeadline, category: category)
        for (index, outcome) in cleanOutcomes.enumerated() {
            let milestone = SubQuest(miniQuestId: mini.id, title: outcome, category: category,
                                     completionCondition: .allTasksCompleted, targetDeadline: endOfDeadline, orderIndex: index)
            mini.subQuestIds.append(milestone.id)
            state.subQuests.append(milestone)
            for offset in 0..<3 {
                var task = tasks[index * 3 + offset]
                task.id = UUID()
                task.mainQuestId = nil
                task.subQuestId = milestone.id
                task.miniQuestId = mini.id
                task.deadline = endOfDeadline
                task.status = .notStarted
                mini.dailyQuestIds.append(task.id)
                state.dailyQuests.append(task)
            }
        }
        state.miniMainQuests.append(mini)
        return mini.id
    }

    public func refreshMiniQuestProgress(in state: inout AppState) {
        for index in state.subQuests.indices where state.subQuests[index].miniQuestId != nil {
            let milestone = state.subQuests[index]
            let tasks = state.dailyQuests.filter { $0.subQuestId == milestone.id }
            let done = !tasks.isEmpty && tasks.allSatisfy { $0.status == .completed }
            state.subQuests[index].status = done ? .completed : .inProgress
            state.subQuests[index].completedAt = done ? (milestone.completedAt ?? Date()) : nil
            if done {
                XPEngine.shared.awardCompletionBonusXP(amount: milestone.completionBonusXP, questId: milestone.id, questTitle: milestone.title, in: &state)
            }
        }
        for index in state.miniMainQuests.indices {
            let mini = state.miniMainQuests[index]
            guard mini.status != .archived else { continue }
            let tasks = state.dailyQuests.filter { $0.miniQuestId == mini.id }
            let done = !tasks.isEmpty && tasks.allSatisfy { $0.status == .completed }
            state.miniMainQuests[index].status = done ? .completed : .active
            state.miniMainQuests[index].completedAt = done ? (mini.completedAt ?? Date()) : nil
            if done {
                XPEngine.shared.awardCompletionBonusXP(amount: mini.completionBonusXP, questId: mini.id, questTitle: mini.title, in: &state)
            }
        }
    }
}
