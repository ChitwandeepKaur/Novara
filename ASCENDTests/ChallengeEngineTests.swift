import Foundation

public struct ChallengeEngineTests {
    public static func runAll() -> [String: Bool] {
        ["fiveGoalScoringAndOptionalFields": scoring(),
         "averagesIgnoreBlanksButIncludeZero": averages(),
         "streaksMatchSheetBlankDaySemantics": streaks(),
         "rollingCalendarWindowsAndComparison": trends(),
         "calendarBoundariesAndFinalPartialWeek": dates(),
         "validationAndUpsert": validation(),
         "challengeBackupAndLegacyCompatibility": persistence(),
         "defaultStartDateNovember9": defaultDate(),
         "challengeXPUpdatesCharacterAndDeduplicates": characterXP(),
         "weeklyAndRatedDayRewards": milestones(),
         "rewardKeysSurviveBackupsAndDateChanges": rewardPersistence(),
         "futureLogsCannotEarnXP": futureRewards()]
    }
    private static func fixture() -> Challenge75 {
        Challenge75(startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 28))!)
    }
    private static func scoring() -> Bool {
        var day = ChallengeDay(id: 1)
        guard day.completion == nil else { return false }
        day.nutrition = "On Track"; day.calories = 1500; day.treatMeal = false; day.rating = "Green"
        guard day.completion == nil else { return false }
        day.learningHours = 8; day.steps = 7000; day.movement = true; day.water = 2; day.sleep = 7
        guard day.goalsCompleted == 5, day.completion == 1 else { return false }
        day.water = 1.99; day.steps = 6999
        return day.goalsCompleted == 3 && day.completion == 0.6
    }
    private static func averages() -> Bool {
        var first = ChallengeDay(id: 1); first.learningHours = 0; first.nutrition = "Mostly On Track"; first.movement = false
        var second = ChallengeDay(id: 2); second.learningHours = 8; second.nutrition = "Off Track"; second.movement = true; second.treatMeal = true
        let summary = Dictionary(uniqueKeysWithValues: ChallengeEngine.summary([first, second, ChallengeDay(id: 3)]))
        return ChallengeEngine.average([nil, nil]) == nil && ChallengeEngine.average([nil, 0, 8]) == 4 &&
            summary["Nutrition consistency %"]! == 50 && summary["Movement completion %"]! == 50 && summary["Treat meals"]! == 1
    }
    private static func streaks() -> Bool {
        var challenge = fixture()
        for number in [1, 2, 4, 5] {
            var day = ChallengeDay(id: number); day.learningHours = 8; challenge.days.append(day)
        }
        let result = ChallengeEngine.streak(.learning, in: challenge, through: 6)
        guard result.current == 2, result.longest == 2 else { return false }
        var failed = ChallengeDay(id: 7); failed.learningHours = 0; challenge.days.append(failed)
        let after = ChallengeEngine.streak(.learning, in: challenge, through: 7)
        return after.current == 0 && after.longest == 2 && challenge.startDate == fixture().startDate
    }
    private static func trends() -> Bool {
        var challenge = fixture()
        for number in 1...14 {
            var day = ChallengeDay(id: number); day.learningHours = number <= 7 ? 4 : 8; challenge.days.append(day)
        }
        guard ChallengeEngine.trend(.learning, in: challenge, day: 13) == nil,
              ChallengeEngine.trend(.learning, in: challenge, day: 14) == 4,
              ChallengeEngine.rollingAverage(.learning, in: challenge, day: 14) == 8 else { return false }
        challenge.days.removeAll { $0.id >= 8 && $0.id < 14 }
        return ChallengeEngine.rollingAverage(.learning, in: challenge, day: 14) == 8
    }
    private static func dates() -> Bool {
        let challenge = fixture()
        return challenge.dayNumber(on: challenge.date(for: 1)) == 1 &&
            challenge.dayNumber(on: challenge.date(for: 0)) == 0 &&
            challenge.dayNumber(on: challenge.date(for: 75)) == 75 &&
            challenge.dayNumber(on: challenge.date(for: 76)) == 76 &&
            (71...75).allSatisfy { ($0 - 1) / 7 + 1 == 11 } &&
            Calendar.current.component(.day, from: challenge.date(for: 75)) == 10
    }
    private static func validation() -> Bool {
        var challenge = fixture()
        var day = ChallengeDay(id: 1); day.water = 2
        do {
            try ChallengeEngine.save(day, in: &challenge, now: challenge.date(for: 2))
            day.water = 3
            try ChallengeEngine.save(day, in: &challenge, now: challenge.date(for: 2))
            guard challenge.days.count == 1, challenge.entry(1).water == 3 else { return false }
        } catch { return false }
        for invalid in [-1.0, Double.infinity, Double.nan] {
            day.water = invalid
            do { try ChallengeEngine.save(day, in: &challenge, now: challenge.date(for: 2)); return false } catch { }
        }
        do { try ChallengeEngine.save(ChallengeDay(id: 3), in: &challenge, now: challenge.date(for: 2)); return false } catch { }
        do { try ChallengeEngine.save(ChallengeWeek(id: 2), in: &challenge, now: challenge.date(for: 2)); return false } catch { }
        return challenge.entry(1).water == 3
    }
    private static func persistence() -> Bool {
        var state = AppState(); state.challenge75 = fixture()
        var day = ChallengeDay(id: 1); day.rating = "Yellow"; day.notes = "Keep going"; day.learningHours = 0
        state.challenge75?.days = [day]
        var week = ChallengeWeek(id: 11); week.leg = 20; week.reflection = "Finished"
        state.challenge75?.weeks = [week]
        do {
            let data = try JSONEncoder().encode(state)
            let restored = try JSONDecoder().decode(AppState.self, from: data)
            guard restored.challenge75 == state.challenge75 else { return false }
            var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            object.removeValue(forKey: "challenge75")
            let legacy = try JSONDecoder().decode(AppState.self, from: JSONSerialization.data(withJSONObject: object))
            return legacy.challenge75 == nil
        } catch { return false }
    }
}

extension ChallengeEngineTests {
    private static func defaultDate() -> Bool {
        let challenge = Challenge75()
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: challenge.startDate)
        let end = Calendar.current.dateComponents([.year, .month, .day], from: challenge.date(for: 75))
        return parts.year == 2026 && parts.month == 11 && parts.day == 9 && end.year == 2027 && end.month == 1 && end.day == 22
    }

    private static func characterXP() -> Bool {
        var state = AppState(); let challenge = fixture(); state.challenge75 = challenge
        let now = challenge.date(for: 1)
        var day = ChallengeDay(id: 1); day.learningHours = 8
        do {
            try ChallengeEngine.saveDay(day, in: &state, now: now)
            guard state.avatar.totalCumulativeXP == 10 else { return false }
            day.steps = 7000; day.movement = true; day.water = 2; day.sleep = 7; day.rating = "Red"
            try ChallengeEngine.saveDay(day, in: &state, now: now)
            guard state.avatar.totalCumulativeXP == 75,
                  ChallengeEngine.earnedXP(in: state, day: 1) == 75,
                  state.avatar.level == XPEngine.shared.calculateLevel(from: 75),
                  state.xpTransactions.allSatisfy({ $0.category == .achievement }),
                  state.cosmeticCatalogue.filter({ $0.requiredLevel <= state.avatar.level }).allSatisfy({ state.avatar.unlockedCosmeticIds.contains($0.id) }) else { return false }
            day.water = 0; day.rating = ""
            try ChallengeEngine.saveDay(day, in: &state, now: now)
            day.water = 2; day.rating = "Green"
            try ChallengeEngine.saveDay(day, in: &state, now: now)
            return state.avatar.totalCumulativeXP == 75 && state.xpTransactions.count == 7
        } catch { return false }
    }

    private static func milestones() -> Bool {
        var state = AppState(); let challenge = fixture(); state.challenge75 = challenge
        let now = challenge.date(for: 75)
        var week = ChallengeWeek(id: 1); week.weight = 70
        do {
            try ChallengeEngine.saveWeek(week, in: &state, now: now)
            guard state.avatar.totalCumulativeXP == 0 else { return false }
            week.reflection = "I kept showing up"
            try ChallengeEngine.saveWeek(week, in: &state, now: now)
            try ChallengeEngine.saveWeek(week, in: &state, now: now)
            guard state.avatar.totalCumulativeXP == 50 else { return false }
            for number in 1...75 {
                var day = ChallengeDay(id: number); day.rating = "Yellow"
                try ChallengeEngine.saveDay(day, in: &state, now: now)
                if number == 7 && state.avatar.totalCumulativeXP != 220 { return false }
            }
            // 750 daily-rating XP + six 100-XP milestones + 500 finale + 50 weekly.
            return state.avatar.totalCumulativeXP == 1900 && ChallengeEngine.reconcileRewards(in: &state, now: now) == 0
        } catch { return false }
    }

    private static func rewardPersistence() -> Bool {
        var state = AppState(); var challenge = fixture(); challenge.rewardID = nil; state.challenge75 = challenge
        var day = ChallengeDay(id: 1); day.water = 2
        do {
            try ChallengeEngine.saveDay(day, in: &state, now: challenge.date(for: 2))
            let data = try JSONEncoder().encode(state)
            var restored = try JSONDecoder().decode(AppState.self, from: data)
            guard ChallengeEngine.reconcileRewards(in: &restored, now: challenge.date(for: 2)) == 0 else { return false }
            restored.challenge75?.startDate = challenge.date(for: 0)
            guard ChallengeEngine.reconcileRewards(in: &restored, now: challenge.date(for: 2)) == 0,
                  restored.avatar.totalCumulativeXP == 10 else { return false }
            let challengeData = try JSONEncoder().encode(Challenge75())
            var object = try JSONSerialization.jsonObject(with: challengeData) as! [String: Any]
            object.removeValue(forKey: "rewardID")
            let legacy = try JSONDecoder().decode(Challenge75.self, from: JSONSerialization.data(withJSONObject: object))
            return legacy.rewardID == nil && ChallengeEngine.rewardPrefix(for: legacy) == "challenge75_legacy_"
        } catch { return false }
    }

    private static func futureRewards() -> Bool {
        var state = AppState(); var challenge = fixture()
        var day = ChallengeDay(id: 2); day.learningHours = 8; day.rating = "Green"
        challenge.days = [day]; state.challenge75 = challenge
        guard ChallengeEngine.reconcileRewards(in: &state, now: challenge.date(for: 1)) == 0 else { return false }
        do { try ChallengeEngine.saveDay(day, in: &state, now: challenge.date(for: 1)); return false } catch { }
        return state.avatar.totalCumulativeXP == 0 && state.xpTransactions.isEmpty
    }
}
