import Foundation

public struct WeeklyPlanEngineTests {
    public static func runAll() -> [String: Bool] {
        ["oneTaskPerHeading": parsing(),
         "datedImportsAndDuplicateProtection": imports(),
         "starterWeekInstallsOnlyOnce": starter(),
         "onlySelectedDayIsScheduled": scheduling(),
         "weeklyBackupAndLegacyTasks": persistence(),
         "displayPunctuationMigration": copyMigration(),
         "fullWeekHeadingsOnly": fullWeek(),
         "previousPresetIsMigratedWithoutLosingHistory": migration(),
         "nonNegotiablesRepeatAndKeepIndependentCompletion": recurringActivities(),
         "uploadedTopicsReuseNonNegotiables": linkedTopics()]
    }
    private static let monday = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 9))!

    private static func parsing() -> Bool {
        let text = """
        # Monday, November 9
        - [ ] **Python \u{2014} Collections and mutability (60 min)**
          - [ ] Nested practice (10 min)
        - [ ] DSA: Hashmaps (120 min core; 45\u{2013}90 min optional)
        ## Tuesday
        CLI: Setup (1.5 hours)
        ### Sunday
        Weekly review (30 minutes)
        """
        let result = WeeklyPlanEngine.parse(text)
        return result.items.count == 4 && result.items.map { $0.weekday } == [0,0,1,6] &&
            result.items.map { $0.minutes } == [60,120,90,30] && !result.items[1].optional && result.items[1].notes.contains("45-90") &&
            result.items[0].title == "Python: Collections and mutability" &&
            WeeklyPlanEngine.parse("Python (60 min)").items.isEmpty &&
            WeeklyPlanEngine.parse("Monday\nPython (900 min)").items.isEmpty &&
            WeeklyPlanEngine.parse("Monday\nDSA (120 min + optional)").items.first?.optional == false
    }
    private static func imports() -> Bool {
        var state = AppState()
        let existing = DailyQuest(name: "Existing main task")
        state.dailyQuests = [existing]
        let parsed = WeeklyPlanEngine.parse("Monday\nPython (60 min)\nTuesday\nDesign (90 min)")
        do {
            let added = try WeeklyPlanEngine.importItems(parsed.items, weekOf: monday, source: "Week 1", in: &state)
            let duplicate = try WeeklyPlanEngine.importItems(parsed.items, weekOf: monday, source: "Week 1 again", in: &state)
            let tuesday = Calendar.current.date(byAdding: .day, value: 1, to: monday)!
            return added == 2 && duplicate == 0 && state.dailyQuests.contains(existing) && state.weeklyPlans.count == 1 &&
                WeeklyPlanEngine.tasks(on: monday, in: state).filter { $0.nonNegotiableKey == nil }.map { $0.name } == ["Existing main task", "Python"] &&
                WeeklyPlanEngine.tasks(on: tuesday, in: state).filter { $0.nonNegotiableKey == nil }.map { $0.name } == ["Existing main task", "Design"]
        } catch { return false }
    }
    private static func starter() -> Bool {
        var state = AppState()
        WeeklyPlanEngine.installStarterWeek(in: &state)
        WeeklyPlanEngine.installStarterWeek(in: &state)
        return state.dailyQuests.count == 56 && state.weeklyPlans.count == 1 &&
            state.dailyQuests.filter { $0.isOptional == true }.isEmpty &&
            Set(state.dailyQuests.map { Calendar.current.component(.weekday, from: $0.plannedDate!) }).count == 7 &&
            state.dailyQuests.filter { $0.isExternalCommitment == true }.count == 14
    }
    private static func scheduling() -> Bool {
        var state = AppState()
        let parsed = WeeklyPlanEngine.parse("Monday\nPython (60 min)\nTuesday\nDesign (90 min core; 45 min optional)")
        do {
            try WeeklyPlanEngine.importItems(parsed.items, weekOf: monday, source: "Test", in: &state)
            let tuesday = Calendar.current.date(byAdding: .day, value: 1, to: monday)!
            let mondayPlan = PlanningEngine.shared.generateSuggestedPlan(for: monday, availableHours: 8, in: state)
            let tuesdayPlan = PlanningEngine.shared.generateSuggestedPlan(for: tuesday, availableHours: 8, in: state)
            let mondayNames = mondayPlan.slots.filter { !$0.isBreak }.map { $0.title }
            let tuesdayNames = tuesdayPlan.slots.filter { !$0.isBreak }.map { $0.title }
            return mondayNames.contains("Python") && !mondayNames.contains("Design") &&
                tuesdayNames.contains("Design") && !tuesdayNames.contains("Python") &&
                DailyNonNegotiable.allCases.allSatisfy { mondayNames.contains($0.title) && tuesdayNames.contains($0.title) }
        } catch { return false }
    }
    private static func persistence() -> Bool {
        var state = AppState(); WeeklyPlanEngine.installStarterWeek(in: &state)
        do {
            let data = try JSONEncoder().encode(state)
            let restored = try JSONDecoder().decode(AppState.self, from: data)
            guard restored.weeklyPlans == state.weeklyPlans, restored.dailyQuests == state.dailyQuests else { return false }
            var legacy = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            legacy.removeValue(forKey: "weeklyPlans")
            var tasks = legacy["dailyQuests"] as! [[String: Any]]
            for index in tasks.indices {
                tasks[index].removeValue(forKey: "plannedDate")
                tasks[index].removeValue(forKey: "weeklyPlanID")
                tasks[index].removeValue(forKey: "isOptional")
            }
            legacy["dailyQuests"] = tasks
            let old = try JSONDecoder().decode(AppState.self, from: JSONSerialization.data(withJSONObject: legacy))
            return old.weeklyPlans.isEmpty && old.dailyQuests.allSatisfy { $0.plannedDate == nil && $0.isOptional == nil }
        } catch { return false }
    }
    private static func copyMigration() -> Bool {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("weekly_copy_\(UUID()).json")
        let store = AppDataStore(customFileURL: url)
        store.state.dailyQuests.append(DailyQuest(name: "Python \u{2014} Collections"))
        guard store.state.dailyQuests[0].name == "Python: Collections" else { return false }
        store.saveImmediately()
        let restored = AppDataStore(customFileURL: url)
        try? FileManager.default.removeItem(at: url)
        return restored.state.dailyQuests[0].name == "Python: Collections"
    }
}

extension WeeklyPlanEngineTests {
    private static func fullWeek() -> Bool {
        var state = AppState()
        WeeklyPlanEngine.installStarterWeek(in: &state)
        for offset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: offset, to: monday)!
            let plan = PlanningEngine.shared.generateSuggestedPlan(for: date, availableHours: 8, in: state)
            let work = plan.slots.filter { !$0.isBreak }
            let external = work.filter { $0.notes == "Outside core focus budget" }
            let expectedExternal = 180
            guard work.reduce(0, { $0 + $1.durationMinutes }) == 420 + expectedExternal,
                  external.reduce(0, { $0 + $1.durationMinutes }) == expectedExternal,
                  !work.contains(where: { $0.title.contains("optional extension") }) else { return false }
        }
        return true
    }
}

extension WeeklyPlanEngineTests {
    private static func migration() -> Bool {
        var state = AppState()
        WeeklyPlanEngine.installStarterWeek(in: &state)
        let previous = UUID(uuidString: "351D9D44-EABB-445E-BAFE-202611090002")!
        for i in state.dailyQuests.indices { state.dailyQuests[i].weeklyPlanID = previous }
        state.weeklyPlans[0].id = previous
        let pythonID = state.dailyQuests[0].id
        state.dailyQuests[0].status = .completed
        state.dailyQuests[0].completedAt = monday
        let extra = DailyQuest(name: "Submit ten actual job applications", estimatedDurationMinutes: 60,
                               status: .completed, plannedDate: monday, weeklyPlanID: previous)
        let personal = DailyQuest(name: "My own task", plannedDate: monday)
        state.dailyQuests += [extra, personal]
        XPEngine.shared.awardEffortXP(minutes: 60, questId: extra.id, in: &state)
        state.focusSessions = [FocusSession(dailyQuestId: extra.id, questTitle: extra.name, durationMinutes: 60)]
        state.dailyPlan.slots = [TimeSlot(startTime: monday, endTime: monday.addingTimeInterval(3600), dailyQuestId: extra.id, title: extra.name)]
        WeeklyPlanEngine.installStarterWeek(in: &state)
        WeeklyPlanEngine.installStarterWeek(in: &state)
        return state.weeklyPlans.count == 1 && state.weeklyPlans[0].taskIDs.count == 56 &&
            state.dailyQuests.first(where: { $0.id == pythonID })?.status == .completed &&
            state.dailyQuests.first(where: { $0.id == extra.id })?.status == .archived &&
            state.dailyQuests.contains(personal) && state.avatar.totalCumulativeXP == 60 &&
            state.focusSessions.count == 1 && state.dailyPlan.slots.isEmpty &&
            !WeeklyPlanEngine.tasks(on: monday, in: state).contains(where: { $0.id == extra.id })
    }
}

extension WeeklyPlanEngineTests {
    private static func recurringActivities() -> Bool {
        var state = AppState()
        WeeklyPlanEngine.ensureNonNegotiables(forWeek: monday, in: &state)
        WeeklyPlanEngine.ensureNonNegotiables(forWeek: monday, in: &state)
        guard state.dailyQuests.count == 28 else { return false }
        let first = state.dailyQuests.firstIndex { $0.nonNegotiableKey == "dsa" && Calendar.current.isDate($0.plannedDate!, inSameDayAs: monday) }!
        state.dailyQuests[first].status = .completed
        state.dailyQuests[first].completedAt = monday
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: monday)!
        WeeklyPlanEngine.ensureNonNegotiables(forWeek: nextWeek, in: &state)
        guard state.dailyQuests.count == 56 else { return false }
        for offset in 0..<14 {
            let date = Calendar.current.date(byAdding: .day, value: offset, to: monday)!
            let tasks = WeeklyPlanEngine.tasks(on: date, in: state)
            guard tasks.count == 4, Set(tasks.map { $0.name }) == Set(DailyNonNegotiable.allCases.map { $0.title }) else { return false }
        }
        return state.dailyQuests[first].status == .completed &&
            WeeklyPlanEngine.tasks(on: nextWeek, in: state).allSatisfy { $0.status != .completed }
    }

    private static func linkedTopics() -> Bool {
        var state = AppState()
        WeeklyPlanEngine.ensureNonNegotiables(forWeek: monday, in: &state)
        let dsaID = WeeklyPlanEngine.tasks(on: monday, in: state).first { $0.name == "DSA Practice" }!.id
        let items = WeeklyPlanEngine.parse("Monday\nDSA: Hashmaps (120 min)\nCLI: Project setup (90 min)").items
        do {
            try WeeklyPlanEngine.importItems(items, weekOf: monday, source: "Test", in: &state)
            try WeeklyPlanEngine.importItems(items, weekOf: monday, source: "Repeated", in: &state)
            let tasks = WeeklyPlanEngine.tasks(on: monday, in: state)
            return state.dailyQuests.count == 28 && tasks.count == 4 &&
                tasks.first { $0.name == "DSA Practice" }?.id == dsaID &&
                tasks.first { $0.name == "DSA Practice" }?.description.contains("DSA: Hashmaps") == true &&
                tasks.first { $0.name == "Portfolio Work" }?.description.contains("CLI: Project setup") == true
        } catch { return false }
    }
}
