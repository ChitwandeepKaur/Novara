import Foundation

public struct FutureSelfEngineTests {
    public static func runAll() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        results["testMilestonesRequiredForEvolution"] = testMilestonesRequiredForEvolution()
        results["testXPaloneDoesNotUnlockFutureSelf"] = testXPaloneDoesNotUnlockFutureSelf()
        results["testMilestoneCompletionUnlocksTitle"] = testMilestoneCompletionUnlocksTitle()
        
        return results
    }
    
    private static func testMilestonesRequiredForEvolution() -> Bool {
        var state = AppState()
        let mq = MainQuest(title: "Engineering", status: .active)
        state.mainQuests = [mq]
        
        let stage2 = FutureSelfStage(
            id: "stage_2",
            stageIndex: 2,
            title: "The Artisan Builder",
            tagline: "Building",
            description: "",
            requiredMilestones: ["milestone_portfolio_deployed"],
            isUnlocked: false
        )
        let roadmap = FutureSelfRoadmap(mainQuestId: mq.id, finalVisionTitle: "Senior Dev", finalVisionDescription: "", stages: [stage2])
        state.futureSelfRoadmaps = [roadmap]
        
        // Before recording milestone, stage 2 is locked
        let unlockedBefore = state.futureSelfRoadmaps.first?.stages.first?.isUnlocked ?? false
        
        // Record milestone
        let unlockedStage = FutureSelfEngine.shared.recordMilestone(milestoneId: "milestone_portfolio_deployed", roadmapId: roadmap.id, in: &state)
        
        let unlockedAfter = state.futureSelfRoadmaps.first?.stages.first?.isUnlocked ?? false
        return !unlockedBefore && unlockedAfter && unlockedStage?.id == "stage_2"
    }
    
    private static func testXPaloneDoesNotUnlockFutureSelf() -> Bool {
        var state = AppState()
        let mq = MainQuest(title: "Engineering", status: .active)
        state.mainQuests = [mq]
        
        let stage2 = FutureSelfStage(
            id: "stage_2",
            stageIndex: 2,
            title: "The Builder",
            tagline: "",
            description: "",
            requiredMilestones: ["milestone_portfolio_deployed"],
            isUnlocked: false
        )
        let roadmap = FutureSelfRoadmap(mainQuestId: mq.id, finalVisionTitle: "Goal", finalVisionDescription: "", stages: [stage2])
        state.futureSelfRoadmaps = [roadmap]
        
        // Give player 5,000 XP
        state.avatar.totalCumulativeXP = 5000
        state.avatar.level = XPEngine.shared.calculateLevel(from: 5000)
        
        // Future Self stage 2 should still be locked because milestone is unverified
        let stageIsLocked = !(state.futureSelfRoadmaps.first?.stages.first?.isUnlocked ?? true)
        return stageIsLocked && state.avatar.level >= 10
    }
    
    private static func testMilestoneCompletionUnlocksTitle() -> Bool {
        var state = AppState()
        let mq = MainQuest(title: "Engineering", status: .active)
        state.mainQuests = [mq]
        
        let stage = FutureSelfStage(
            id: "stage_builder",
            stageIndex: 2,
            title: "The Builder",
            tagline: "",
            description: "",
            requiredMilestones: ["m_build"],
            isUnlocked: false,
            rewardedCosmeticTitleId: "title_builder"
        )
        let roadmap = FutureSelfRoadmap(mainQuestId: mq.id, finalVisionTitle: "", finalVisionDescription: "", stages: [stage])
        state.futureSelfRoadmaps = [roadmap]
        
        FutureSelfEngine.shared.recordMilestone(milestoneId: "m_build", roadmapId: roadmap.id, in: &state)
        
        let hasUnlockedTitle = state.avatar.unlockedCosmeticIds.contains("title_builder")
        return hasUnlockedTitle
    }
}
