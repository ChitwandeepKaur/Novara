import Foundation

public final class XPEngine: Sendable {
    public static let shared = XPEngine()
    
    public let dailyEffortXPCap: Int
    
    public init(dailyEffortXPCap: Int = 360) {
        self.dailyEffortXPCap = dailyEffortXPCap
    }
    
    // MARK: - Level Progression Formulas
    
    /// Total cumulative XP required to reach a specific level L.
    /// XP(L) = floor(100 * (L - 1) ^ 1.6)
    public func cumulativeXPRequired(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        let xp = floor(100.0 * pow(Double(level - 1), 1.6))
        return Int(xp)
    }
    
    /// Calculates player level from total cumulative XP.
    /// Guaranteed exact match with cumulativeXPRequired.
    public func calculateLevel(from totalCumulativeXP: Int) -> Int {
        guard totalCumulativeXP > 0 else { return 1 }
        let base = Double(totalCumulativeXP) / 100.0
        var level = max(1, Int(floor(pow(base, 1.0 / 1.6))) + 1)
        
        while totalCumulativeXP >= cumulativeXPRequired(forLevel: level + 1) {
            level += 1
        }
        while level > 1 && totalCumulativeXP < cumulativeXPRequired(forLevel: level) {
            level -= 1
        }
        return level
    }
    
    /// Full progress breakdown for current level and progress to next level.
    public func progressInfo(totalCumulativeXP: Int) -> XPProgressInfo {
        let level = calculateLevel(from: totalCumulativeXP)
        let currentLevelBaseXP = cumulativeXPRequired(forLevel: level)
        let nextLevelBaseXP = cumulativeXPRequired(forLevel: level + 1)
        
        let xpInCurrentLevel = max(0, totalCumulativeXP - currentLevelBaseXP)
        let xpNeededForNext = max(1, nextLevelBaseXP - currentLevelBaseXP)
        let progress = min(1.0, max(0.0, Double(xpInCurrentLevel) / Double(xpNeededForNext)))
        
        return XPProgressInfo(
            level: level,
            currentXP: xpInCurrentLevel,
            xpForCurrentLevel: currentLevelBaseXP,
            xpForNextLevel: nextLevelBaseXP,
            progressToNextLevel: progress
        )
    }
    
    // MARK: - Effort XP Calculation with Daily Cap
    
    /// Calculates total Effort XP earned today to enforce the daily cap.
    public func effortXPEarnedToday(in state: AppState, calendar: Calendar = .current) -> Int {
        let startOfDay = calendar.startOfDay(for: Date())
        return state.xpTransactions
            .filter { $0.category == .effort && $0.timestamp >= startOfDay }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Awards Effort XP for focused work time. Returns actual XP granted (capped).
    /// Effort tracking continues regardless of cap.
    @discardableResult
    public func awardEffortXP(
        minutes: Int,
        questId: UUID? = nil,
        title: String = "Focused Work Session",
        in state: inout AppState,
        calendar: Calendar = .current
    ) -> Int {
        guard minutes > 0 else { return 0 }
        
        let earnedToday = effortXPEarnedToday(in: state, calendar: calendar)
        let remainingCap = max(0, dailyEffortXPCap - earnedToday)
        let rawXP = minutes // 1 XP per minute
        let grantableXP = min(rawXP, remainingCap)
        
        if grantableXP > 0 {
            let tx = XPTransaction(
                amount: grantableXP,
                category: .effort,
                sourceQuestId: questId,
                title: title,
                details: "Logged \(minutes) mins focus time (\(grantableXP) XP awarded, daily cap: \(dailyEffortXPCap))."
            )
            applyTransaction(tx, in: &state)
        }
        
        return grantableXP
    }
    
    // MARK: - Achievement XP (Deduplicated)
    
    /// Awards Achievement XP. If the `achievementKey` has already been rewarded, grants 0 XP (anti-exploit).
    @discardableResult
    public func awardAchievementXP(
        amount: Int,
        achievementKey: String,
        questId: UUID? = nil,
        title: String,
        details: String = "",
        in state: inout AppState
    ) -> Int {
        guard amount > 0 else { return 0 }
        
        let alreadyAwarded = state.xpTransactions.contains { $0.achievementKey == achievementKey }
        guard !alreadyAwarded else { return 0 }
        
        let tx = XPTransaction(
            amount: amount,
            category: .achievement,
            sourceQuestId: questId,
            achievementKey: achievementKey,
            title: title,
            details: details
        )
        applyTransaction(tx, in: &state)
        return amount
    }
    
    // MARK: - Completion Bonus XP (One-off per Quest)
    
    /// Awards Completion Bonus XP when a quest is finished.
    /// Strictly awarded once per unique quest ID to prevent toggle farming.
    @discardableResult
    public func awardCompletionBonusXP(
        amount: Int,
        questId: UUID,
        questTitle: String,
        in state: inout AppState
    ) -> Int {
        guard amount > 0 else { return 0 }
        
        let completionKey = "completion_\(questId.uuidString)"
        let alreadyAwarded = state.xpTransactions.contains { $0.achievementKey == completionKey }
        guard !alreadyAwarded else { return 0 }
        
        let tx = XPTransaction(
            amount: amount,
            category: .completionBonus,
            sourceQuestId: questId,
            achievementKey: completionKey,
            title: "Quest Completed: \(questTitle)",
            details: "One-off completion bonus."
        )
        applyTransaction(tx, in: &state)
        return amount
    }
    
    // MARK: - Internal State Application
    
    private func applyTransaction(_ tx: XPTransaction, in state: inout AppState) {
        state.xpTransactions.append(tx)
        let previousXP = state.avatar.totalCumulativeXP
        state.avatar.totalCumulativeXP += tx.amount
        state.updateFairyProgress(previousXP: previousXP)
        
        let newLevel = calculateLevel(from: state.avatar.totalCumulativeXP)
        state.avatar.level = newLevel
        
        let info = progressInfo(totalCumulativeXP: state.avatar.totalCumulativeXP)
        state.avatar.currentXP = info.currentXP
        
        // Auto-unlock cosmetics matching level requirement
        for item in state.cosmeticCatalogue {
            if item.requiredLevel <= newLevel && !state.avatar.unlockedCosmeticIds.contains(item.id) {
                state.avatar.unlockedCosmeticIds.append(item.id)
            }
        }
    }
}
