import Foundation

public final class SkillEngine: Sendable {
    public static let shared = SkillEngine()
    
    public init() {}
    
    // MARK: - Node State Evaluation
    
    public func state(for node: SkillNode, allNodes: [SkillNode]) -> SkillNodeState {
        if node.isMastered {
            return .mastered
        }
        
        if node.currentLevel > 0 || node.xpContributed > 0 {
            return .inProgress
        }
        
        // If no prerequisites, it's immediately available
        guard !node.prerequisiteNodeIds.isEmpty else {
            return .available
        }
        
        // Check if all prerequisites have at least 1 level
        let prereqNodes = allNodes.filter { node.prerequisiteNodeIds.contains($0.id) }
        let allSatisfied = prereqNodes.count == node.prerequisiteNodeIds.count &&
            prereqNodes.allSatisfy { $0.currentLevel >= 1 }
        
        return allSatisfied ? .available : .locked
    }
    
    // MARK: - XP Contribution & Level Up
    
    /// Awards XP to a specific skill node. Returns true if the skill leveled up.
    @discardableResult
    public func addXP(
        amount: Int,
        to skillId: String,
        in state: inout AppState
    ) -> Bool {
        guard amount > 0, let index = state.skillNodes.firstIndex(where: { $0.id == skillId }) else {
            return false
        }
        
        var node = state.skillNodes[index]
        guard !node.isMastered else { return false }
        
        let previousLevel = node.currentLevel
        node.xpContributed += amount
        
        // Calculate new level based on threshold
        let newLevel = min(node.maxLevel, node.xpContributed / node.xpRequiredPerLevel)
        node.currentLevel = max(node.currentLevel, newLevel)
        state.skillNodes[index] = node
        
        return node.currentLevel > previousLevel
    }
    
    /// Automatically attributes progress from completed quests to relevant skills.
    public func attributeQuestCompletion(
        category: QuestCategory,
        linkedSkillIds: [String],
        xpAmount: Int,
        in state: inout AppState
    ) {
        let skillBonusXP = max(10, xpAmount / 2)
        
        if !linkedSkillIds.isEmpty {
            for skillId in linkedSkillIds {
                addXP(amount: skillBonusXP, to: skillId, in: &state)
            }
        } else {
            // Find first available skill in that category
            if let target = state.skillNodes.first(where: { $0.category == category && !$0.isMastered }) {
                addXP(amount: skillBonusXP, to: target.id, in: &state)
            }
        }
    }
}

