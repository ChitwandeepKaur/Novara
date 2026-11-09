import Foundation

public struct XPEngineTests {
    public static func runAll() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        results["testLevelCalculationCurve"] = testLevelCalculationCurve()
        results["testEffortXPDailyCap"] = testEffortXPDailyCap()
        results["testAchievementXPDeduplication"] = testAchievementXPDeduplication()
        results["testCompletionBonusOneOffRule"] = testCompletionBonusOneOffRule()
        results["testTransactionsAuditableHistory"] = testTransactionsAuditableHistory()
        
        return results
    }
    
    private static func testLevelCalculationCurve() -> Bool {
        let engine = XPEngine.shared
        
        let lvl1 = engine.calculateLevel(from: 0)
        let lvl2 = engine.calculateLevel(from: 100)
        let lvl3 = engine.calculateLevel(from: 303) // 100 * 2^1.6 = ~303
        
        let xpFor1 = engine.cumulativeXPRequired(forLevel: 1)
        let xpFor2 = engine.cumulativeXPRequired(forLevel: 2)
        
        return lvl1 == 1 && lvl2 == 2 && lvl3 == 3 && xpFor1 == 0 && xpFor2 == 100
    }
    
    private static func testEffortXPDailyCap() -> Bool {
        let engine = XPEngine(dailyEffortXPCap: 100)
        var state = AppState()
        
        // Award 60 minutes -> grants 60 XP
        let granted1 = engine.awardEffortXP(minutes: 60, in: &state)
        
        // Award another 60 minutes -> cap is 100, so only 40 XP granted
        let granted2 = engine.awardEffortXP(minutes: 60, in: &state)
        
        // Third award -> 0 XP granted (cap reached)
        let granted3 = engine.awardEffortXP(minutes: 30, in: &state)
        
        let totalEffortXP = engine.effortXPEarnedToday(in: state)
        
        return granted1 == 60 && granted2 == 40 && granted3 == 0 && totalEffortXP == 100
    }
    
    private static func testAchievementXPDeduplication() -> Bool {
        let engine = XPEngine.shared
        var state = AppState()
        
        let key = "solve_first_medium_dsa"
        let firstAward = engine.awardAchievementXP(amount: 50, achievementKey: key, title: "First Medium Solved", in: &state)
        
        // Second award with identical key should grant 0 XP
        let secondAward = engine.awardAchievementXP(amount: 50, achievementKey: key, title: "Duplicate Trigger", in: &state)
        
        return firstAward == 50 && secondAward == 0 && state.avatar.totalCumulativeXP == 50
    }
    
    private static func testCompletionBonusOneOffRule() -> Bool {
        let engine = XPEngine.shared
        var state = AppState()
        
        let questId = UUID()
        let bonus1 = engine.awardCompletionBonusXP(amount: 250, questId: questId, questTitle: "Portfolio Deployed", in: &state)
        
        // Simulating user unchecking and re-checking quest
        let bonus2 = engine.awardCompletionBonusXP(amount: 250, questId: questId, questTitle: "Portfolio Deployed", in: &state)
        
        return bonus1 == 250 && bonus2 == 0 && state.avatar.totalCumulativeXP == 250
    }
    
    private static func testTransactionsAuditableHistory() -> Bool {
        let engine = XPEngine.shared
        var state = AppState()
        
        engine.awardEffortXP(minutes: 45, title: "Study", in: &state)
        engine.awardAchievementXP(amount: 100, achievementKey: "ach_1", title: "Milestone", in: &state)
        
        let hasEffort = state.xpTransactions.contains { $0.category == .effort && $0.amount == 45 }
        let hasAchievement = state.xpTransactions.contains { $0.category == .achievement && $0.amount == 100 }
        
        return state.xpTransactions.count == 2 && hasEffort && hasAchievement
    }
}

