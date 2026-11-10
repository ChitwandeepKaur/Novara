import Foundation

public enum WeeklyPlanEngine {
    public static let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    public static let starterID = UUID(uuidString: "351D9D44-EABB-445E-BAFE-202611090003")!
    public static let starterText = """
    Monday, November 9
    Python: Collections and mutability (60 min)
    Advanced Python CLI: Project setup (90 min)
    DSA: Hashmaps, arrays and Big-O (120 min core; 45-90 min optional)
    System design: Foundations (60 min)
    Systems coding / Linux: Terminal and files (30 min)
    InternPro AI Accelerator: Module 1: AI Mental Models (60 min)

    Tuesday, November 10
    Python: Functions, scope, and arguments (60 min)
    CLI: Argument parsing (90 min)
    DSA: Prefix/suffix arrays and data representation (120 min + optional)
    System design: HTTP and API contracts (60 min)
    Systems coding: Streams and processes (30 min)
    AI Accelerator: Module 1, Hour 2 (60 min)

    Wednesday, November 11
    Python: Closures and decorators (60 min)
    CLI: Filtering and aggregation (90 min)
    DSA: Two pointers (120 min + optional)
    System design: Databases (60 min)
    Systems coding: File descriptors and permissions (30 min)
    AI Accelerator: Module 1, Hour 3 (60 min)

    Thursday, November 12
    Python: Iterators, generators, and exceptions (60 min)
    CLI: Streaming large log files (90 min)
    DSA: Sliding windows and stacks (120 min + optional)
    System design: Scaling and caching (60 min)
    Linux / systems coding: Processes (30 min)
    AI Accelerator: Module 1, Hour 4 (60 min)

    Friday, November 13
    Python: OOP and dataclasses (60 min)
    CLI: Local database persistence (90 min)
    DSA: Stacks and binary search (120 min + optional)
    System design: Queues and reliability (60 min)
    Systems coding: Networking fundamentals (30 min)
    AI Accelerator: Finish Module 1 (60 min)

    Saturday, November 14
    Python: Testing and code quality (60 min)
    CLI: Automated testing (90 min)
    DSA: Binary search patterns and linked lists (120 min + optional)
    System design: URL shortener (60 min)
    Systems coding: Processes and concurrency experiment (30 min)
    AI Accelerator: Module 2: Prompting Mastery (60 min)

    Sunday, November 15
    Python: Concurrency introduction and weekly review (60 min)
    CLI: Integration and documentation (90 min)
    DSA: Linked lists and binary trees (120 min + optional)
    System design: Mock interview (60 min)
    Systems coding / Linux: Consolidation (30 min)
    AI Accelerator: Module 2, Hour 2 (60 min)
    """

    public static func monday(containing date: Date, calendar: Calendar = .current) -> Date {
        let offset = (calendar.component(.weekday, from: date) + 5) % 7
        return calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: date))!
    }

    public static func parse(_ text: String) -> WeeklyPlanImport {
        var result = WeeklyPlanImport()
        var weekday: Int?
        let dayPattern = try! NSRegularExpression(pattern: "(?i)^(?:#{1,6}\\s*)?(?:day\\s+\\d+\\s*[:.-]\\s*)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\\b")
        let timePattern = try! NSRegularExpression(pattern: "(?i)([0-9]+(?:\\.[0-9]+)?)(?:\\s*-\\s*([0-9]+(?:\\.[0-9]+)?))?\\s*(min(?:ute)?s?|hours?|hrs?)\\b")
        for (index, raw) in text.components(separatedBy: .newlines).enumerated() {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let line = AscendText.clean(trimmed).replacingOccurrences(of: "\u{2013}", with: "-")
                .replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "`", with: "")
            let range = NSRange(line.startIndex..., in: line)
            if let match = dayPattern.firstMatch(in: line, range: range), let dayRange = Range(match.range(at: 1), in: line) {
                weekday = weekdays.firstIndex { $0.lowercased() == line[dayRange].lowercased() }
                continue
            }
            // Nested practice checklists stay out of the main task list.
            if raw.hasPrefix("  ") || raw.hasPrefix("\t") { continue }
            guard let open = line.lastIndex(of: "("), line.hasSuffix(")") else { continue }
            let timing = String(line[line.index(after: open)..<line.index(before: line.endIndex)])
            let matches = timePattern.matches(in: timing, range: NSRange(timing.startIndex..., in: timing))
            guard !matches.isEmpty else { continue }
            guard let day = weekday else {
                result.warnings.append("Line \(index + 1): add a weekday heading before this task.")
                continue
            }
            var title = String(line[..<open]).trimmingCharacters(in: .whitespacesAndNewlines)
            title = title.replacingOccurrences(of: "^(?:#{1,6}\\s*|[-*]\\s*(?:\\[[ xX]\\]\\s*)?|\\d+[.)]\\s*)", with: "", options: .regularExpression)
            guard !title.isEmpty else { continue }
            for match in matches.prefix(1) {
                guard let valueRange = Range(match.range(at: 1), in: timing),
                      let unitRange = Range(match.range(at: 3), in: timing),
                      let value = Double(timing[valueRange]) else { continue }
                let unit = timing[unitRange].lowercased()
                let duration = Int((value * (unit.hasPrefix("h") ? 60 : 1)).rounded())
                guard (5...720).contains(duration) else {
                    result.warnings.append("Line \(index + 1): duration must be 5 to 720 minutes.")
                    continue
                }
                let following = String(timing[Range(match.range, in: timing)!.upperBound...])
                let clause = following.components(separatedBy: ";").first ?? following
                let optional = clause.lowercased().contains("optional") && !clause.lowercased().contains("core") && !clause.lowercased().contains("+ optional")
                result.items.append(WeeklyPlanItem(weekday: day,
                    title: title,
                    minutes: duration, optional: optional, external: timing.lowercased().contains("outside"), notes: timing))
            }
        }
        if result.items.isEmpty { result.warnings.append("No task headings found. Use a weekday heading followed by task names ending in a duration, such as Python: Collections (60 min).") }
        return result
    }

    @discardableResult
    public static func importItems(_ items: [WeeklyPlanItem], weekOf date: Date, source: String,
                                   planID: UUID = UUID(), in state: inout AppState) throws -> Int {
        let selected = items.filter { $0.included }
        guard !selected.isEmpty, selected.allSatisfy({ (0...6).contains($0.weekday) && (5...720).contains($0.minutes) && !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw QuestEngineError("Choose at least one task with a title, a day, and a duration of 5 to 720 minutes.")
        }
        let start = monday(containing: date)
        var ids: [UUID] = []
        var insertedCount = 0
        for item in selected {
            let planned = Calendar.current.date(byAdding: .day, value: item.weekday, to: start)!
            let title = AscendText.clean(item.title.trimmingCharacters(in: .whitespacesAndNewlines))
            let kind = DailyNonNegotiable.matching(title)
            if let kind, let existing = state.dailyQuests.firstIndex(where: {
                $0.status != .archived && $0.plannedDate.map { Calendar.current.isDate($0, inSameDayAs: planned) } == true &&
                ($0.nonNegotiableKey == kind.rawValue || DailyNonNegotiable.matching($0.name) == kind)
            }) {
                let detail = title == kind.title ? AscendText.clean(item.notes) : title + "\n" + AscendText.clean(item.notes)
                if state.dailyQuests[existing].description != detail || state.dailyQuests[existing].estimatedDurationMinutes != item.minutes || state.dailyQuests[existing].weeklyPlanID == nil {
                    state.dailyQuests[existing].weeklyPlanID = planID
                    state.dailyQuests[existing].description = detail
                    state.dailyQuests[existing].estimatedDurationMinutes = item.minutes
                    state.dailyQuests[existing].xpReward = item.minutes
                    ids.append(state.dailyQuests[existing].id)
                }
                state.dailyQuests[existing].name = kind.title
                state.dailyQuests[existing].nonNegotiableKey = kind.rawValue
                state.dailyQuests[existing].isExternalCommitment = kind.outsideCore
                state.dailyQuests[existing].isOptional = false
                continue
            }
            guard !state.dailyQuests.contains(where: { quest in
                quest.status != .archived && quest.plannedDate.map { Calendar.current.isDate($0, inSameDayAs: planned) } == true &&
                AscendText.clean(quest.name).caseInsensitiveCompare(title) == .orderedSame
            }) else { continue }
            let detail = kind != nil && title != kind!.title ? title + "\n" + AscendText.clean(item.notes) : AscendText.clean(item.notes)
            let task = DailyQuest(name: kind?.title ?? title, description: detail,
                                  mainQuestId: QuestEngine.shared.activeMainQuest(in: state)?.id,
                                  category: .career, priority: kind != nil ? .critical : (item.optional ? .low : .high),
                                  estimatedDurationMinutes: item.minutes, deadline: planned.addingTimeInterval(86399),
                                  xpReward: item.minutes, plannedDate: planned, weeklyPlanID: planID, isOptional: kind == nil ? item.optional : false, isExternalCommitment: kind?.outsideCore ?? item.external, nonNegotiableKey: kind?.rawValue)
            state.dailyQuests.append(task)
            ids.append(task.id)
            insertedCount += 1
        }
        if !ids.isEmpty {
            state.weeklyPlans.append(ImportedWeeklyPlan(id: planID, weekStart: start, sourceName: AscendText.clean(source), taskIDs: ids, importedAt: Date()))
        }
        ensureNonNegotiables(forWeek: start, in: &state)
        return insertedCount
    }

    /// One task per main subject heading. Archive previous preset extras while
    /// retaining their completion records, focus sessions, and earned XP.
    public static func installStarterWeek(in state: inout AppState) {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 9))!
        guard !state.weeklyPlans.contains(where: { $0.id == starterID }) else {
            ensureNonNegotiables(forWeek: date, in: &state)
            return
        }
        let items = parse(starterText).items
        let previousIDs: Set<UUID> = [
            UUID(uuidString: "351D9D44-EABB-445E-BAFE-202611090001")!,
            UUID(uuidString: "351D9D44-EABB-445E-BAFE-202611090002")!
        ]
        var archived = Set<UUID>()
        for index in state.dailyQuests.indices {
            let task = state.dailyQuests[index]
            guard let owner = task.weeklyPlanID, previousIDs.contains(owner) else { continue }
            let retainedActivity = task.nonNegotiableKey != nil || DailyNonNegotiable.matching(task.name).map { $0.outsideCore && task.isOptional != true } == true
            let retained = retainedActivity || items.contains { item in
                let planned = Calendar.current.date(byAdding: .day, value: item.weekday, to: date)!
                return task.plannedDate.map { Calendar.current.isDate($0, inSameDayAs: planned) } == true &&
                    (AscendText.clean(task.name).caseInsensitiveCompare(item.title) == .orderedSame ||
                     (task.nonNegotiableKey != nil && task.nonNegotiableKey == DailyNonNegotiable.matching(item.title)?.rawValue))
            }
            if retained {
                state.dailyQuests[index].weeklyPlanID = starterID
            } else {
                state.dailyQuests[index].status = .archived
                archived.insert(task.id)
            }
        }
        state.dailyPlan.slots.removeAll { $0.dailyQuestId.map { archived.contains($0) } == true }
        if state.dailyPlan.pendingReplanProposal?.proposedSlots.contains(where: { $0.dailyQuestId.map { archived.contains($0) } == true }) == true {
            state.dailyPlan.pendingReplanProposal = nil
        }
        state.weeklyPlans.removeAll { previousIDs.contains($0.id) }
        _ = try? importItems(items, weekOf: date, source: "Week 1: main subject headings", planID: starterID, in: &state)
        let taskIDs = state.dailyQuests.filter { $0.weeklyPlanID == starterID && $0.status != .archived }.map { $0.id }
        if let index = state.weeklyPlans.firstIndex(where: { $0.id == starterID }) {
            state.weeklyPlans[index].taskIDs = taskIDs
        } else {
            state.weeklyPlans.append(ImportedWeeklyPlan(id: starterID, weekStart: date, sourceName: "Week 1: main subject headings", taskIDs: taskIDs, importedAt: Date()))
        }
    }

    public static func tasks(on date: Date, in state: AppState) -> [DailyQuest] {
        state.dailyQuests.filter { quest in
            quest.status != .archived && (quest.plannedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? true)
        }
    }
}

extension WeeklyPlanEngine {
    /// Materialize separate dated occurrences, never reset another day's completion.
    /// Existing DSA and CLI headings become the activity's topic instead of duplicate tasks.
    public static func ensureNonNegotiables(forWeek date: Date, in state: inout AppState) {
        let start = monday(containing: date)
        for offset in 0..<7 {
            let planned = Calendar.current.date(byAdding: .day, value: offset, to: start)!
            for kind in DailyNonNegotiable.allCases {
                let activeMatch = state.dailyQuests.firstIndex { task in
                    task.status != .archived && task.miniQuestId == nil && task.plannedDate.map { Calendar.current.isDate($0, inSameDayAs: planned) } == true &&
                    (task.nonNegotiableKey == kind.rawValue || DailyNonNegotiable.matching(task.name) == kind)
                }
                let legacyOwners: Set<UUID> = [
                    UUID(uuidString: "351D9D44-EABB-445E-BAFE-202611090001")!,
                    UUID(uuidString: "351D9D44-EABB-445E-BAFE-202611090002")!
                ]
                let archivedMatch = state.dailyQuests.firstIndex { task in
                    task.status == .archived && task.isOptional != true &&
                    task.weeklyPlanID.map { legacyOwners.contains($0) } == true &&
                    task.plannedDate.map { Calendar.current.isDate($0, inSameDayAs: planned) } == true &&
                    DailyNonNegotiable.matching(task.name) == kind
                }
                if let index = activeMatch ?? archivedMatch {
                    if state.dailyQuests[index].status == .archived {
                        state.dailyQuests[index].status = state.dailyQuests[index].completedAt == nil ? .notStarted : .completed
                    }
                    if state.dailyQuests[index].name != kind.title {
                        state.dailyQuests[index].description = state.dailyQuests[index].name + "\n" + state.dailyQuests[index].description
                    }
                    state.dailyQuests[index].name = kind.title
                    state.dailyQuests[index].nonNegotiableKey = kind.rawValue
                    state.dailyQuests[index].priority = .critical
                    state.dailyQuests[index].isOptional = false
                    state.dailyQuests[index].isExternalCommitment = kind.outsideCore
                } else {
                    state.dailyQuests.append(DailyQuest(name: kind.title, category: .career, priority: .critical,
                        estimatedDurationMinutes: kind.minutes, deadline: Calendar.current.date(byAdding: .day, value: 1, to: planned)!.addingTimeInterval(-1),
                        xpReward: kind.minutes, plannedDate: planned, isExternalCommitment: kind.outsideCore, nonNegotiableKey: kind.rawValue))
                }
            }
        }
    }
}
