import Foundation

public struct QuestEngineTests {
    public static func runAll() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        results["testSingleActiveMainQuest"] = testSingleActiveMainQuest()
        results["testPausingMainQuestPreservesProgress"] = testPausingMainQuestPreservesProgress()
        results["testSubQuestPrerequisiteHandling"] = testSubQuestPrerequisiteHandling()
        results["testCircularDependencyCycleDetection"] = testCircularDependencyCycleDetection()
        results["testNumericalCompletionCondition"] = testNumericalCompletionCondition()
        results["testMainQuestArchivingAndPreservation"] = testMainQuestArchivingAndPreservation()
        
        return results
    }
    
    private static func testSingleActiveMainQuest() -> Bool {
        var state = AppState()
        let mq1 = MainQuest(title: "Land a Job", status: .active)
        let mq2 = MainQuest(title: "Become a Marathon Runner", status: .paused)
        state.mainQuests = [mq1, mq2]
        
        // Activating mq2 should pause mq1
        QuestEngine.shared.activateMainQuest(id: mq2.id, in: &state)
        
        let active = state.mainQuests.filter { $0.status == .active }
        let paused = state.mainQuests.filter { $0.status == .paused }
        
        return active.count == 1 && active.first?.id == mq2.id && paused.contains(where: { $0.id == mq1.id })
    }
    
    private static func testPausingMainQuestPreservesProgress() -> Bool {
        var state = AppState()
        let mq = MainQuest(title: "Land a Job", status: .active)
        state.mainQuests = [mq]
        state.avatar.totalCumulativeXP = 500
        
        QuestEngine.shared.pauseMainQuest(id: mq.id, in: &state)
        
        let found = state.mainQuests.first(where: { $0.id == mq.id })
        return found?.status == .paused && state.avatar.totalCumulativeXP == 500
    }
    
    private static func testSubQuestPrerequisiteHandling() -> Bool {
        let dummyMainId = UUID()
        let sqA = SubQuest(mainQuestId: dummyMainId, title: "Learn Fundamentals", status: .inProgress)
        let sqB = SubQuest(mainQuestId: dummyMainId, title: "Build Project", prerequisiteSubQuestIds: [sqA.id], status: .notStarted)
        
        // When sqA is in progress, sqB prerequisites are not met
        let notMet = !QuestEngine.shared.arePrerequisitesMet(for: sqB, allSubQuests: [sqA, sqB])
        
        // When sqA is completed, sqB prerequisites are met
        var sqACompleted = sqA
        sqACompleted.status = .completed
        let met = QuestEngine.shared.arePrerequisitesMet(for: sqB, allSubQuests: [sqACompleted, sqB])
        
        return notMet && met
    }
    
    private static func testCircularDependencyCycleDetection() -> Bool {
        let dummyMainId = UUID()
        let sq1 = SubQuest(mainQuestId: dummyMainId, title: "A")
        let sq2 = SubQuest(mainQuestId: dummyMainId, title: "B", prerequisiteSubQuestIds: [sq1.id])
        let sq3 = SubQuest(mainQuestId: dummyMainId, title: "C", prerequisiteSubQuestIds: [sq2.id])
        
        let all = [sq1, sq2, sq3]
        
        // Attempting to make sq1 depend on sq3 would create cycle: A -> C -> B -> A
        let wouldCycle = QuestEngine.shared.wouldCreateCycle(subQuestId: sq1.id, newPrerequisiteId: sq3.id, allSubQuests: all)
        
        // Adding independent sq4 should not create cycle
        let sq4 = SubQuest(mainQuestId: dummyMainId, title: "D")
        let wouldNotCycle = !QuestEngine.shared.wouldCreateCycle(subQuestId: sq4.id, newPrerequisiteId: sq1.id, allSubQuests: all + [sq4])
        
        return wouldCycle && wouldNotCycle
    }
    
    private static func testNumericalCompletionCondition() -> Bool {
        var state = AppState()
        let sq = SubQuest(
            mainQuestId: UUID(),
            title: "Solve 5 DSA Problems",
            completionCondition: .numericalTarget(target: 5, current: 2, unit: "problems")
        )
        state.subQuests = [sq]
        
        // Increment by 2 -> current = 4 (not completed yet)
        let done1 = QuestEngine.shared.recordNumericalProgress(subQuestId: sq.id, increment: 2, in: &state)
        
        // Increment by 1 -> current = 5 (completed!)
        let done2 = QuestEngine.shared.recordNumericalProgress(subQuestId: sq.id, increment: 1, in: &state)
        
        let updated = state.subQuests.first(where: { $0.id == sq.id })
        return !done1 && done2 && updated?.status == .completed
    }
    
    private static func testMainQuestArchivingAndPreservation() -> Bool {
        var state = AppState()
        let mq = MainQuest(title: "First Life Quest", status: .active, completionBonusXP: 2500)
        state.mainQuests = [mq]
        state.avatar.totalCumulativeXP = 1200
        
        let bonus = QuestEngine.shared.completeMainQuest(id: mq.id, in: &state)
        
        let updated = state.mainQuests.first(where: { $0.id == mq.id })
        return bonus == 2500 && updated?.status == .archived && state.avatar.totalCumulativeXP == 1200
    }
}
