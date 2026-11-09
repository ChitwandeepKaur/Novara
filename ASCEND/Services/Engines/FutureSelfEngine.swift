import Foundation

public final class FutureSelfEngine: Sendable {
    public static let shared = FutureSelfEngine()
    
    public init() {}
    
    /// Records a milestone accomplishment and evaluates whether a new Future-Self stage has been unlocked.
    /// Returns the newly unlocked stage if an evolution was triggered.
    @discardableResult
    public func recordMilestone(
        milestoneId: String,
        roadmapId: UUID? = nil,
        in state: inout AppState
    ) -> FutureSelfStage? {
        // Find matching roadmap or the active Main Quest's roadmap
        guard let roadmapIndex = state.futureSelfRoadmaps.firstIndex(where: { rm in
            if let targetId = roadmapId { return rm.id == targetId }
            if let activeMQ = state.mainQuests.first(where: { $0.status == .active }) {
                return rm.mainQuestId == activeMQ.id
            }
            return true
        }) else {
            return nil
        }
        
        var roadmap = state.futureSelfRoadmaps[roadmapIndex]
        var newlyUnlockedStage: FutureSelfStage?
        
        for stageIdx in roadmap.stages.indices {
            var stage = roadmap.stages[stageIdx]
            
            // Add milestone if required and not already present
            if stage.requiredMilestones.contains(milestoneId) && !stage.completedMilestones.contains(milestoneId) {
                stage.completedMilestones.append(milestoneId)
            }
            
            // If eligible and not yet unlocked, trigger transformation!
            if !stage.isUnlocked && stage.isEligibleForUnlock {
                stage.isUnlocked = true
                stage.unlockedAt = Date()
                newlyUnlockedStage = stage
                
                // Reward corresponding title and aura to avatar
                if let titleId = stage.rewardedCosmeticTitleId {
                    if let item = state.cosmeticCatalogue.first(where: { $0.id == titleId }) {
                        state.avatar.title = item.name
                        if !state.avatar.unlockedCosmeticIds.contains(titleId) {
                            state.avatar.unlockedCosmeticIds.append(titleId)
                        }
                    }
                }
            }
            
            roadmap.stages[stageIdx] = stage
        }
        
        state.futureSelfRoadmaps[roadmapIndex] = roadmap
        return newlyUnlockedStage
    }
}

