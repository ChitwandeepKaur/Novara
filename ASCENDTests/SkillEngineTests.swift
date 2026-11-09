import Foundation

public struct SkillEngineTests {
    public static func runAll() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        results["testSkillNodeStatesAndPrerequisites"] = testSkillNodeStatesAndPrerequisites()
        results["testSkillLevelUpProgression"] = testSkillLevelUpProgression()
        results["testQuestCompletionAttribution"] = testQuestCompletionAttribution()
        
        return results
    }
    
    private static func testSkillNodeStatesAndPrerequisites() -> Bool {
        let rootNode = SkillNode(id: "prog_root", name: "Programming Root", description: "", category: .career, currentLevel: 0)
        let childNode = SkillNode(id: "prog_child", name: "Advanced DSA", description: "", category: .career, prerequisiteNodeIds: ["prog_root"], currentLevel: 0)
        
        // Root has no prereqs -> .available
        let rootState = SkillEngine.shared.state(for: rootNode, allNodes: [rootNode, childNode])
        
        // Child's prereq root has level 0 -> .locked
        let childStateLocked = SkillEngine.shared.state(for: childNode, allNodes: [rootNode, childNode])
        
        // Level up root to 1 -> Child becomes .available
        var rootNodeLevel1 = rootNode
        rootNodeLevel1.currentLevel = 1
        let childStateAvailable = SkillEngine.shared.state(for: childNode, allNodes: [rootNodeLevel1, childNode])
        
        return rootState == .available && childStateLocked == .locked && childStateAvailable == .available
    }
    
    private static func testSkillLevelUpProgression() -> Bool {
        var state = AppState()
        let node = SkillNode(
            id: "test_node",
            name: "Test Skill",
            description: "",
            category: .career,
            currentLevel: 0,
            maxLevel: 5,
            xpContributed: 0,
            xpRequiredPerLevel: 100
        )
        state.skillNodes = [node]
        
        // Add 50 XP -> currentLevel stays 0
        let leveledUp1 = SkillEngine.shared.addXP(amount: 50, to: "test_node", in: &state)
        
        // Add 60 XP -> total 110 XP -> currentLevel becomes 1!
        let leveledUp2 = SkillEngine.shared.addXP(amount: 60, to: "test_node", in: &state)
        
        let updated = state.skillNodes.first(where: { $0.id == "test_node" })
        return !leveledUp1 && leveledUp2 && updated?.currentLevel == 1
    }
    
    private static func testQuestCompletionAttribution() -> Bool {
        var state = AppState()
        let node = SkillNode(id: "fitness_str", name: "Strength", description: "", category: .fitness, xpContributed: 0)
        state.skillNodes = [node]
        
        SkillEngine.shared.attributeQuestCompletion(category: .fitness, linkedSkillIds: ["fitness_str"], xpAmount: 100, in: &state)
        
        let updated = state.skillNodes.first(where: { $0.id == "fitness_str" })
        return (updated?.xpContributed ?? 0) > 0
    }
}

