import Foundation

public struct XPEngineTests {
    public static func runAll() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        results["testLevelCalculationCurve"] = testLevelCalculationCurve()
        results["testEffortXPDailyCap"] = testEffortXPDailyCap()
        results["testAchievementXPDeduplication"] = testAchievementXPDeduplication()
        results["testCompletionBonusOneOffRule"] = testCompletionBonusOneOffRule()
        results["testTransactionsAuditableHistory"] = testTransactionsAuditableHistory()
        
        results["testFairyUnlockBoundaries"] = testFairyUnlockBoundaries()
        results["testFairyAutoEquipAndSelection"] = testFairyAutoEquipAndSelection()
        results["testFairyBackupAndLegacyMigration"] = testFairyBackupAndLegacyMigration()
        return results
    }
    
    private static func testFairyUnlockBoundaries() -> Bool {
        let order: [FairyPalette] = [.flora, .aisha, .tecna, .musa, .stella, .bloom]
        guard FairyPalette.allCases == order else { return false }
        for (index, fairy) in order.enumerated() {
            let threshold = index * 10_000
            guard fairy.requiredXP == threshold,
                  fairy.isUnlocked(totalXP: threshold),
                  FairyPalette.highestUnlocked(totalXP: threshold) == fairy else { return false }
            if index > 0 && fairy.isUnlocked(totalXP: threshold - 1) { return false }
            if index > 0 && FairyPalette.highestUnlocked(totalXP: threshold - 1) != order[index - 1] { return false }
        }
        return FairyPalette.highestUnlocked(totalXP: 100_000) == .bloom
            && FairyPalette.highestUnlocked(totalXP: -1) == .flora
            && FairyPalette.nextUnlock(totalXP: 50_000) == nil
            && FairyPalette.nextUnlock(totalXP: 9_999) == .aisha
    }

    private static func testFairyAutoEquipAndSelection() -> Bool {
        var state = AppState()
        guard state.selectedFairy == .flora else { return false }
        state.avatar.totalCumulativeXP = 9_999
        XPEngine.shared.awardAchievementXP(amount: 1, achievementKey: "fairy_first", title: "Milestone", in: &state)
        guard state.selectedFairy == .aisha else { return false }
        state.selectedFairy = .flora
        XPEngine.shared.awardEffortXP(minutes: 1, in: &state)
        guard state.selectedFairy == .flora else { return false }
        XPEngine.shared.awardCompletionBonusXP(amount: 9_999, questId: UUID(), questTitle: "Next", in: &state)
        guard state.selectedFairy == .tecna else { return false }
        state.selectedFairy = .bloom
        state.updateFairyProgress()
        guard state.selectedFairy == .tecna else { return false }
        XPEngine.shared.awardAchievementXP(amount: 40_000, achievementKey: "fairy_jump", title: "Milestones", in: &state)
        return state.selectedFairy == .bloom && state.avatar.totalCumulativeXP == 60_000
    }

    private static func testFairyBackupAndLegacyMigration() -> Bool {
        var state = AppState()
        state.avatar.totalCumulativeXP = 35_000
        state.selectedFairy = .aisha
        do {
            let data = try JSONEncoder().encode(state)
            let restored = try JSONDecoder().decode(AppState.self, from: data)
            guard restored.selectedFairy == .aisha else { return false }
            var legacy = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            legacy.removeValue(forKey: "selectedFairy")
            let migrated = try JSONDecoder().decode(AppState.self, from: JSONSerialization.data(withJSONObject: legacy))
            guard migrated.selectedFairy == .musa else { return false }
            var locked = state
            locked.selectedFairy = .bloom
            let repaired = try JSONDecoder().decode(AppState.self, from: JSONEncoder().encode(locked))
            return repaired.selectedFairy == .musa && AppState().selectedFairy == .flora
        } catch { return false }
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

