import Foundation

public enum ChallengeEngine {
    public static func save(_ day: ChallengeDay, in challenge: inout Challenge75, now: Date = Date()) throws {
        let values = [day.learningHours, day.steps, day.calories, day.water, day.sleep].compactMap { $0 }
        guard (1...75).contains(day.id), day.id <= challenge.dayNumber(on: now),
              values.allSatisfy({ $0.isFinite && $0 >= 0 }),
              (day.learningHours ?? 0) <= 24, (day.sleep ?? 0) <= 24,
              ["", "On Track", "Mostly On Track", "Off Track"].contains(day.nutrition),
              ["", "Green", "Yellow", "Red"].contains(day.rating) else {
            throw QuestEngineError("Use nonnegative values, at most 24 learning or sleep hours, and a day that has already started.")
        }
        challenge.days.removeAll { $0.id == day.id }
        challenge.days.append(day)
    }

    public static func save(_ week: ChallengeWeek, in challenge: inout Challenge75, now: Date = Date()) throws {
        guard (1...11).contains(week.id), (week.id - 1) * 7 < challenge.dayNumber(on: now),
              [week.weight, week.waist, week.chest, week.arm, week.leg].compactMap({ $0 }).allSatisfy({ $0.isFinite && $0 >= 0 }) else {
            throw QuestEngineError("Enter nonnegative measurements for a week that has already started.")
        }
        challenge.weeks.removeAll { $0.id == week.id }
        challenge.weeks.append(week)
    }

    public static func average(_ values: [Double?]) -> Double? {
        let present = values.compactMap { $0 }
        return present.isEmpty ? nil : present.reduce(0, +) / Double(present.count)
    }

    /// Spreadsheet denominators ignore empty cells; explicit zero and No remain recorded values.
    public static func summary(_ days: [ChallengeDay]) -> [(String, Double?)] {
        let nutrition = days.filter { !$0.nutrition.isEmpty }
        let movement = days.compactMap { $0.movement }
        return [
            ("Average learning hours", average(days.map { $0.learningHours })),
            ("Average daily steps", average(days.map { $0.steps })),
            ("Average calories", average(days.map { $0.calories })),
            ("Average water (L)", average(days.map { $0.water })),
            ("Average sleep (hrs)", average(days.map { $0.sleep })),
            ("Nutrition consistency %", nutrition.isEmpty ? nil : Double(nutrition.filter { ["On Track", "Mostly On Track"].contains($0.nutrition) }.count) / Double(nutrition.count) * 100),
            ("Movement completion %", movement.isEmpty ? nil : Double(movement.filter { $0 }.count) / Double(movement.count) * 100),
            ("Goal completion %", average(days.map { $0.completion }).map { $0 * 100 }),
            ("Movement days", Double(movement.filter { $0 }.count)),
            ("Treat meals", Double(days.filter { $0.treatMeal == true }.count)),
            ("Green days", Double(days.filter { $0.rating == "Green" }.count)),
            ("Yellow days", Double(days.filter { $0.rating == "Yellow" }.count)),
            ("Red days", Double(days.filter { $0.rating == "Red" }.count))
        ]
    }

    /// Matches the Sheet's streak helpers: a blank day breaks the following streak,
    /// while Current shows the last explicitly logged result for that metric.
    public static func streak(_ metric: ChallengeMetric, in challenge: Challenge75, through day: Int) -> (current: Int, longest: Int) {
        guard day > 0 else { return (0, 0) }
        var running = 0, current = 0, longest = 0
        for number in 1...min(75, day) {
            guard let value = metric.value(challenge.entry(number)) else { running = 0; continue }
            running = value >= metric.target ? running + 1 : 0
            current = running
            longest = max(longest, running)
        }
        return (current, longest)
    }

    public static func rollingAverage(_ metric: ChallengeMetric, in challenge: Challenge75, day: Int) -> Double? {
        guard (1...75).contains(day) else { return nil }
        return average((max(1, day - 6)...day).map { metric.value(challenge.entry($0)) })
    }

    public static func trend(_ metric: ChallengeMetric, in challenge: Challenge75, day: Int) -> Double? {
        guard day >= 14 else { return nil }
        let end = min(day, 75)
        guard let recent = average((end-6...end).map({ metric.value(challenge.entry($0)) })),
              let previous = average((end-13...end-7).map({ metric.value(challenge.entry($0)) })) else { return nil }
        return recent - previous
    }
}

// MARK: - Character XP rewards
extension ChallengeEngine {
    public static let goalXP = 10
    public static let fullDayBonusXP = 15
    public static let reflectionXP = 10
    public static let weeklyReflectionXP = 50
    public static let milestoneDays = [7, 14, 21, 30, 45, 60, 75]

    /// Old backups without a reward ID use one stable namespace, so restoring them
    /// cannot manufacture a fresh set of rewards.
    public static func rewardPrefix(for challenge: Challenge75) -> String {
        "challenge75_\(challenge.rewardID?.uuidString ?? "legacy")_"
    }

    public static func earnedXP(in state: AppState, day: Int? = nil) -> Int {
        guard let challenge = state.challenge75 else { return 0 }
        let prefix = rewardPrefix(for: challenge) + (day.map { "day_\($0)_" } ?? "")
        return state.xpTransactions.filter { $0.achievementKey?.hasPrefix(prefix) == true }.reduce(0) { $0 + $1.amount }
    }

    public static func saveDay(_ day: ChallengeDay, in state: inout AppState, now: Date = Date()) throws {
        guard var challenge = state.challenge75 else { throw QuestEngineError("Add a challenge first.") }
        try save(day, in: &challenge, now: now)
        state.challenge75 = challenge
        reconcileRewards(in: &state, now: now)
    }

    public static func saveWeek(_ week: ChallengeWeek, in state: inout AppState, now: Date = Date()) throws {
        guard var challenge = state.challenge75 else { throw QuestEngineError("Add a challenge first.") }
        try save(week, in: &challenge, now: now)
        state.challenge75 = challenge
        reconcileRewards(in: &state, now: now)
    }

    /// Reconciles existing logs too, granting only missing rewards through the shared
    /// XP engine. These are achievement bonuses, not another award of focused minutes.
    @discardableResult
    public static func reconcileRewards(in state: inout AppState, now: Date = Date()) -> Int {
        guard let challenge = state.challenge75 else { return 0 }
        let prefix = rewardPrefix(for: challenge)
        let through = min(75, challenge.dayNumber(on: now))
        guard through >= 1 else { return 0 }
        let previousXP = state.avatar.totalCumulativeXP
        let metrics: [ChallengeMetric] = [.learning, .steps, .movement, .water, .sleep]
        for day in challenge.days where (1...through).contains(day.id) {
            for metric in metrics where (metric.value(day) ?? -1) >= metric.target {
                XPEngine.shared.awardAchievementXP(amount: goalXP,
                    achievementKey: prefix + "day_\(day.id)_\(metric.rawValue)",
                    title: "75 Days • Day \(day.id): \(metric.title)", in: &state)
            }
            if day.goalsCompleted == 5 {
                XPEngine.shared.awardAchievementXP(amount: fullDayBonusXP,
                    achievementKey: prefix + "day_\(day.id)_all_goals",
                    title: "75 Days • Day \(day.id): all five goals", in: &state)
            }
            if ["Green", "Yellow", "Red"].contains(day.rating) {
                XPEngine.shared.awardAchievementXP(amount: reflectionXP,
                    achievementKey: prefix + "day_\(day.id)_reflection",
                    title: "75 Days • Day \(day.id): daily reflection", in: &state)
            }
        }
        for week in challenge.weeks where (1...11).contains(week.id) && (week.id - 1) * 7 < through {
            let hasReflection = [week.gymProgress, week.reflection, week.wentWell, week.improve].contains {
                !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if hasReflection {
                XPEngine.shared.awardAchievementXP(amount: weeklyReflectionXP,
                    achievementKey: prefix + "week_\(week.id)_reflection",
                    title: "75 Days • Week \(week.id): reflection", in: &state)
            }
        }
        let ratedDays = Set(challenge.days.filter {
            (1...through).contains($0.id) && ["Green", "Yellow", "Red"].contains($0.rating)
        }.map { $0.id }).count
        for milestone in milestoneDays where ratedDays >= milestone {
            XPEngine.shared.awardAchievementXP(amount: milestone == 75 ? 500 : 100,
                achievementKey: prefix + "milestone_\(milestone)",
                title: "75 Days • \(milestone) rated days completed", in: &state)
        }
        return state.avatar.totalCumulativeXP - previousXP
    }
}
