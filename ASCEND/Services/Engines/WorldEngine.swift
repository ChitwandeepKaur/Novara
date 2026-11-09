import Foundation

public final class WorldEngine: Sendable {
    public static let shared = WorldEngine()
    
    public init() {}
    
    /// Upgrades illumination for a region when a daily quest or habit is finished.
    public func recordQuestProgress(category: QuestCategory, in state: inout AppState) {
        let targetRegionType: WorldRegionType
        switch category {
        case .career: targetRegionType = .careerKingdom
        case .fitness: targetRegionType = .fitnessGrounds
        case .selfCare, .custom: targetRegionType = .selfCareSanctuary
        }
        
        if let idx = state.worldState.regions.firstIndex(where: { $0.regionType == targetRegionType }) {
            state.worldState.regions[idx].illuminationLevel = min(1.0, state.worldState.regions[idx].illuminationLevel + 0.05)
        }
        
        // Recalculate total world illumination
        let total = state.worldState.regions.reduce(0.0) { $0 + $1.illuminationLevel }
        state.worldState.totalIllumination = total / Double(max(1, state.worldState.regions.count))
    }
    
    /// Upgrades a specific structure in a region (e.g., when a SubQuest or Skill completes).
    public func upgradeStructure(
        structureId: String,
        in state: inout AppState
    ) -> WorldStructure? {
        for rIdx in state.worldState.regions.indices {
            if let sIdx = state.worldState.regions[rIdx].structures.firstIndex(where: { $0.id == structureId }) {
                var structure = state.worldState.regions[rIdx].structures[sIdx]
                structure.isUnlocked = true
                structure.tier = min(structure.maxTier, structure.tier + 1)
                state.worldState.regions[rIdx].structures[sIdx] = structure
                
                // Also illuminate the region further
                state.worldState.regions[rIdx].illuminationLevel = min(1.0, state.worldState.regions[rIdx].illuminationLevel + 0.15)
                return structure
            }
        }
        return nil
    }
    
    /// Activates an additional Leyline Bridge connecting floating islands.
    public func unlockNextBridge(in state: inout AppState) {
        state.worldState.activeBridgesCount = min(3, state.worldState.activeBridgesCount + 1)
    }
    
    /// Triggers world ascension celebration when the Main Quest is completed.
    public func triggerAscensionTransformation(in state: inout AppState) {
        state.worldState.celestialSkyboxPhase = 3 // Ascended Dawn
        for idx in state.worldState.regions.indices {
            state.worldState.regions[idx].illuminationLevel = 1.0
            for sIdx in state.worldState.regions[idx].structures.indices {
                state.worldState.regions[idx].structures[sIdx].tier = state.worldState.regions[idx].structures[sIdx].maxTier
                state.worldState.regions[idx].structures[sIdx].isUnlocked = true
            }
        }
        state.worldState.activeBridgesCount = 3
    }
}

