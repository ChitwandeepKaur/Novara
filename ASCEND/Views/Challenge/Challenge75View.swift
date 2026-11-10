import SwiftUI
import Charts

struct Challenge75View: View {
    @ObservedObject var store: AppDataStore
    @State private var startDate = Challenge75().startDate
    @State private var page = "Dashboard"
    @State private var selectedDay = 1
    @State private var selectedWeek = 1
    @State private var editingDay: ChallengeDay?
    @State private var editingWeek: ChallengeWeek?
    @Environment(\.scenePhase) private var scenePhase
    private let pages = ["Dashboard", "Daily", "Weekly", "Trends"]

    var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                ParticleFieldView(particleCount: 18)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let challenge = store.state.challenge75 {
                            Picker("Challenge section", selection: $page) {
                                ForEach(pages, id: \.self) { Text($0) }
                            }.pickerStyle(.segmented)
                            switch page {
                            case "Daily": daily(challenge)
                            case "Weekly": weekly(challenge)
                            case "Trends": ChallengeTrendsView(challenge: challenge)
                            default: dashboard(challenge)
                            }
                        } else {
                            setup
                        }
                        Text("Consistency over perfection: one off day never restarts the challenge.")
                            .font(.footnote).foregroundColor(AscendTheme.textSecondary)
                        Link("Based on your Google Sheets tracker", destination: URL(string: Challenge75.sourceURL)!)
                            .font(.caption).foregroundColor(AscendTheme.cyberCyan)
                        Text("Stored offline in Novara. Updates here do not sync back to Google Sheets.")
                            .font(.caption).foregroundColor(AscendTheme.textTertiary)
                    }
                    .padding().padding(.bottom, 85)
                }
            }
            .navigationTitle("75-Day Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { selectToday() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { selectToday() } }
            .sheet(item: $editingDay) { ChallengeDayEditor(store: store, entry: $0) }
            .sheet(item: $editingWeek) { ChallengeWeekEditor(store: store, entry: $0) }
        }
    }

    private func selectToday() {
        var updated = store.state
        if ChallengeEngine.reconcileRewards(in: &updated) > 0 { store.state = updated }
        guard let challenge = store.state.challenge75 else { return }
        selectedDay = min(75, max(1, challenge.dayNumber()))
        selectedWeek = (selectedDay - 1) / 7 + 1
    }

    private var setup: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                FairyWings().frame(height: 100)
                Text("75 days of showing up").font(.system(size: 28, design: .serif))
                Text("Your tracker: 8+ learning hours, 7,000+ steps, 30+ minutes of movement, 2+ L water, and 7+ hours of sleep. Nutrition, treat meals, calories, and reflection have their own logs.")
                    .font(.subheadline).foregroundColor(AscendTheme.textSecondary)
                DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                Text("Your default start date is November 9, 2026. Keep it or choose another date.")
                    .font(.caption).foregroundColor(AscendTheme.textSecondary)
                GlowingButton(title: "Add challenge", icon: "sparkles") {
                    store.state.challenge75 = Challenge75(startDate: startDate)
                    store.saveImmediately()
                    selectToday()
                }
            }.foregroundColor(AscendTheme.textPrimary)
        }
    }

    private func dashboard(_ challenge: Challenge75) -> some View {
        let day = min(75, max(0, challenge.dayNumber()))
        let logged = challenge.days.filter { !$0.rating.isEmpty }.count
        return VStack(alignment: .leading, spacing: 18) {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Day \(day) of 75").font(.system(size: 30, design: .serif))
                    Text("\(challenge.startDate.formatted(date: .abbreviated, time: .omitted)) – \(challenge.date(for: 75).formatted(date: .abbreviated, time: .omitted))").font(.caption)
                    Text("\(logged) days completed • \(75 - logged) remaining • \(Int(Double(logged) / 75 * 100))%")
                    ProgressView(value: Double(logged), total: 75).tint(AscendTheme.electricBlue)
                    Text("Like the sheet, a day counts as completed when you give it a Green, Yellow, or Red rating. Calendar progress is separate.").font(.caption)
                }.foregroundColor(AscendTheme.textPrimary)
            }
            ChallengeDailyPanel(store: store)
            ChallengeXPCard(store: store)
            SectionHeader(title: "Overall performance", icon: "chart.bar")
            ChallengeSummaryRows(days: challenge.days)
            SectionHeader(title: "Current / longest streak", icon: "flame")
            GlassCard {
                VStack(spacing: 12) {
                    ForEach(ChallengeMetric.allCases) { metric in
                        let streak = ChallengeEngine.streak(metric, in: challenge, through: day)
                        stat(metric.title, "\(streak.current) / \(streak.longest)")
                    }
                }
            }
            SectionHeader(title: "Personal bests", icon: "trophy")
            GlassCard {
                VStack(spacing: 12) {
                    stat("Highest learning hours", number(challenge.days.compactMap { $0.learningHours }.max()))
                    stat("Highest step count", number(challenge.days.compactMap { $0.steps }.max()))
                    ForEach([ChallengeMetric.learning, .steps, .movement, .green]) { metric in
                        stat("Longest \(metric.title.lowercased()) streak", "\(ChallengeEngine.streak(metric, in: challenge, through: day).longest)")
                    }
                }
            }
            SectionHeader(title: "Recent trends", subtitle: "Last 7 calendar days vs previous 7", icon: "arrow.up.right")
            GlassCard {
                VStack(spacing: 12) {
                    ForEach([ChallengeMetric.learning, .steps, .water, .sleep]) { metric in
                        let change = ChallengeEngine.trend(metric, in: challenge, day: day)
                        stat(metric.title, day < 14 ? "Need 14 days" : change.map { "\($0 >= 0 ? "↑" : "↓") \(number(abs($0)))" } ?? "No data")
                    }
                }
            }
            SectionHeader(title: "Milestones", subtitle: "Calendar milestones, as in the tracker", icon: "flag")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                ForEach([7, 14, 21, 30, 45, 60, 75], id: \.self) { milestone in
                    Label("Day \(milestone)", systemImage: day >= milestone ? "checkmark.seal.fill" : "seal")
                        .font(.caption).foregroundColor(day >= milestone ? AscendTheme.metallicGold : AscendTheme.textSecondary)
                        .padding(10).background(AscendTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func daily(_ challenge: Challenge75) -> some View {
        let entry = challenge.entry(selectedDay)
        return VStack(alignment: .leading, spacing: 16) {
            Picker("Day", selection: $selectedDay) {
                ForEach(1...75, id: \.self) { day in
                    Text("Day \(day) • \(challenge.date(for: day).formatted(date: .abbreviated, time: .omitted))").tag(day)
                }
            }
            Text("Week \((selectedDay - 1) / 7 + 1)").foregroundColor(AscendTheme.textSecondary)
            ChallengeGoalRows(entry: entry)
            Text("Character XP earned for this day: \(ChallengeEngine.earnedXP(in: store.state, day: selectedDay))")
                .font(.subheadline).foregroundColor(AscendTheme.metallicGold)
            GlassCard {
                VStack(spacing: 12) {
                    stat("Calories (optional)", number(entry.calories))
                    stat("Nutrition", entry.nutrition.isEmpty ? "Not logged" : entry.nutrition)
                    stat("Treat meal", entry.treatMeal.map { $0 ? "Yes" : "No" } ?? "Not logged")
                    stat("Overall day rating", entry.rating.isEmpty ? "Not rated" : entry.rating)
                    stat("Daily goals completed", entry.goalsCompleted.map { "\($0)/5" } ?? "Not logged")
                    stat("Completion", entry.completion.map { "\(Int($0 * 100))%" } ?? "Not logged")
                    if !entry.notes.isEmpty { Text(entry.notes).frame(maxWidth: .infinity, alignment: .leading) }
                }.foregroundColor(AscendTheme.textPrimary)
            }
            if selectedDay <= challenge.dayNumber() {
                GlowingButton(title: "Log / edit day", icon: "square.and.pencil") { editingDay = entry }
            } else {
                Text("This day hasn't started yet.").foregroundColor(AscendTheme.textSecondary)
            }
        }
    }

    private func weekly(_ challenge: Challenge75) -> some View {
        let week = challenge.week(selectedWeek)
        let first = (selectedWeek - 1) * 7 + 1
        let last = min(75, first + 6)
        return VStack(alignment: .leading, spacing: 16) {
            Picker("Week", selection: $selectedWeek) {
                ForEach(1...11, id: \.self) { Text("Week \($0)").tag($0) }
            }
            Text("\(challenge.date(for: first).formatted(date: .abbreviated, time: .omitted)) – \(challenge.date(for: last).formatted(date: .abbreviated, time: .omitted))")
                .font(.caption).foregroundColor(AscendTheme.textSecondary)
            ChallengeSummaryRows(days: challenge.days.filter { (first...last).contains($0.id) })
            GlassCard {
                VStack(spacing: 12) {
                    stat("Weight (kg)", number(week.weight))
                    stat("Waist (in)", number(week.waist))
                    stat("Chest (in)", number(week.chest))
                    stat("Arm (in)", number(week.arm))
                    stat("Leg (in)", number(week.leg))
                    reflection("Gym progress / personal bests", week.gymProgress)
                    reflection("Weekly reflection", week.reflection)
                    reflection("What went well", week.wentWell)
                    reflection("What needs improvement", week.improve)
                }
            }
            if first <= challenge.dayNumber() {
                GlowingButton(title: "Weekly check-in", icon: "square.and.pencil") { editingWeek = week }
            }
        }
    }

    private func reflection(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(AscendTheme.cyberCyan)
            Text(value.isEmpty ? "Not logged" : value).font(.subheadline).foregroundColor(AscendTheme.textSecondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private func number(_ value: Double?) -> String {
    value.map { $0.formatted(.number.precision(.fractionLength(0...2))) } ?? "Not logged"
}

private func stat(_ title: String, _ value: String) -> some View {
    HStack(alignment: .firstTextBaseline) {
        Text(title).foregroundColor(AscendTheme.textSecondary)
        Spacer(minLength: 12)
        Text(value).foregroundColor(AscendTheme.textPrimary).multilineTextAlignment(.trailing)
    }.font(.subheadline)
}

private struct ChallengeSummaryRows: View {
    let days: [ChallengeDay]
    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                ForEach(ChallengeEngine.summary(days), id: \.0) { item in stat(item.0, number(item.1)) }
            }
        }
    }
}

struct ChallengeDailyPanel: View {
    @ObservedObject var store: AppDataStore
    @State private var editing: ChallengeDay?
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let today = timeline.date
            if let challenge = store.state.challenge75, (1...75).contains(challenge.dayNumber(on: today)) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "75-day daily goals", subtitle: "Day \(challenge.dayNumber(on: today)) • Shared with your challenge tracker", icon: "calendar.badge.checkmark")
                    ChallengeGoalRows(entry: challenge.entry(challenge.dayNumber(on: today)))
                    Button {
                        editing = challenge.entry(challenge.dayNumber(on: Date()))
                    } label: {
                        Label("Log goals, nutrition, calories & reflection", systemImage: "square.and.pencil")
                            .font(.subheadline).foregroundColor(AscendTheme.cyberCyan)
                    }
                    Text("Record actual totals here. Learning and movement can include work you already do for your Main Quest.")
                        .font(.caption).foregroundColor(AscendTheme.textSecondary)
                }
            }
        }
        .sheet(item: $editing) { ChallengeDayEditor(store: store, entry: $0) }
    }
}

private struct ChallengeGoalRows: View {
    let entry: ChallengeDay
    var body: some View {
        GlassCard {
            VStack(spacing: 14) {
                ForEach([ChallengeMetric.learning, .steps, .movement, .water, .sleep]) { metric in
                    HStack {
                        let value = metric.value(entry)
                        Image(systemName: (value ?? -1) >= metric.target ? "checkmark.circle.fill" : "circle")
                            .foregroundColor((value ?? -1) >= metric.target ? AscendTheme.emeraldRecovery : AscendTheme.textTertiary)
                            .accessibilityLabel((value ?? -1) >= metric.target ? "Completed" : "Pending")
                        Text(metric.title).foregroundColor(AscendTheme.textPrimary)
                        Spacer()
                        Text(metric == .movement ? entry.movement.map { $0 ? "Yes" : "No" } ?? "Not logged" : number(value))
                            .foregroundColor(AscendTheme.cyberCyan)
                    }.font(.subheadline)
                }
            }
        }
    }
}

struct ChallengeDayEditor: View {
    @ObservedObject var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State var entry: ChallengeDay
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Five daily goals") {
                    numeric("Learning hours (target 8+)", $entry.learningHours)
                    numeric("Steps (target 7,000+)", $entry.steps)
                    choice("30+ minutes movement", $entry.movement)
                    numeric("Water litres (target 2+)", $entry.water)
                    numeric("Sleep hours (target 7+)", $entry.sleep)
                }
                if loggedMinutes(.career) > 0 || loggedMinutes(.fitness) > 0 {
                    Section("Reuse your logged focus sessions") {
                        if loggedMinutes(.career) > 0 {
                            Button("Use logged career focus time (\(number(Double(loggedMinutes(.career)) / 60)) hrs)") {
                                entry.learningHours = min(24, Double(loggedMinutes(.career)) / 60)
                            }
                        }
                        if loggedMinutes(.fitness) >= 30 {
                            Button("Count logged fitness focus time as movement") { entry.movement = true }
                        }
                        Text("Uses sessions linked to Career or Fitness tasks on this date. Focused minutes are not awarded again; newly met challenge goals can earn their one-time bonuses.").font(.caption)
                    }
                }
                Section("Nutrition & optional calories") {
                    numeric("Calories (optional)", $entry.calories)
                    Picker("Nutrition status", selection: $entry.nutrition) {
                        ForEach(["", "On Track", "Mostly On Track", "Off Track"], id: \.self) {
                            Text($0.isEmpty ? "Not logged" : $0).tag($0)
                        }
                    }
                    choice("Treat meal", $entry.treatMeal)
                }
                Section("Daily reflection") {
                    Picker("Overall day rating", selection: $entry.rating) {
                        ForEach(["", "Green", "Yellow", "Red"], id: \.self) {
                            Text($0.isEmpty ? "Not rated" : $0).tag($0)
                        }
                    }
                    TextField("Notes", text: $entry.notes, axis: .vertical).lineLimit(3...8)
                }
                Section {
                    Text("Goals completed: \(entry.goalsCompleted.map { "\($0)/5" } ?? "Not logged")")
                    Text("Earn \(ChallengeEngine.goalXP) character XP per goal, \(ChallengeEngine.fullDayBonusXP) extra for all five, and \(ChallengeEngine.reflectionXP) for rating your day. Saving awards only newly earned rewards.")
                        .font(.caption)
                    Text("Blank values are excluded from averages; zero and No count as recorded values. Ratings are your choice and never reset the challenge.")
                        .font(.caption)
                }
            }
            .navigationTitle("Day \(entry.id)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            var updated = store.state
                            try ChallengeEngine.saveDay(entry, in: &updated)
                            store.state = updated
                            store.saveImmediately()
                            dismiss()
                        } catch { self.error = error.localizedDescription }
                    }
                }
            }
            .alert("Check your entry", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
        }
    }
    private func loggedMinutes(_ category: QuestCategory) -> Int {
        guard let challenge = store.state.challenge75 else { return 0 }
        let date = challenge.date(for: entry.id)
        let questIDs = Set(store.state.dailyQuests.filter { $0.category == category }.map { $0.id })
        return store.state.focusSessions.filter { session in
            Calendar.current.isDate(session.startTime, inSameDayAs: date) && session.dailyQuestId.map { questIDs.contains($0) } == true
        }.reduce(0) { $0 + $1.durationMinutes }
    }

}

private func numeric(_ title: String, _ value: Binding<Double?>) -> some View {
    HStack {
        Text(title)
        Spacer()
        TextField("Not logged", value: value, format: .number)
            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
            .frame(maxWidth: 100).accessibilityLabel(title)
    }
}

private func choice(_ title: String, _ value: Binding<Bool?>) -> some View {
    Picker(title, selection: Binding<String>(
        get: { value.wrappedValue.map { $0 ? "Yes" : "No" } ?? "" },
        set: { value.wrappedValue = $0.isEmpty ? nil : $0 == "Yes" }
    )) {
        Text("Not logged").tag("")
        Text("Yes").tag("Yes")
        Text("No").tag("No")
    }
}

struct ChallengeWeekEditor: View {
    @ObservedObject var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State var entry: ChallengeWeek
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Body measurements") {
                    numeric("Weight (kg)", $entry.weight)
                    numeric("Waist (in)", $entry.waist)
                    numeric("Chest (in)", $entry.chest)
                    numeric("Arm (in)", $entry.arm)
                    numeric("Leg (in)", $entry.leg)
                }
                Section("Weekly reflection") {
                    TextField("Gym progress / personal bests", text: $entry.gymProgress, axis: .vertical)
                    TextField("Weekly reflection", text: $entry.reflection, axis: .vertical)
                    TextField("What went well", text: $entry.wentWell, axis: .vertical)
                    TextField("What needs improvement", text: $entry.improve, axis: .vertical)
                }
                Section { Text("Weekly averages, movement days, treat meals, ratings, and goal completion are calculated from your daily logs.").font(.caption) }
            }
            .navigationTitle("Week \(entry.id) check-in")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            var updated = store.state
                            try ChallengeEngine.saveWeek(entry, in: &updated)
                            store.state = updated
                            store.saveImmediately()
                            dismiss()
                        } catch { self.error = error.localizedDescription }
                    }
                }
            }
            .alert("Check your entry", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
        }
    }
}

private struct ChallengeTrendsView: View {
    let challenge: Challenge75
    @State private var bodyMetric = "Weight (kg)"
    private var end: Int { min(75, max(1, challenge.dayNumber())) }
    private let bodyMetrics = ["Weight (kg)", "Waist (in)", "Chest (in)", "Arm (in)", "Leg (in)"]
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Progress & trends", subtitle: "Daily totals, 7-day averages, and targets", icon: "chart.xyaxis.line")
            ForEach([ChallengeMetric.learning, .steps, .water, .sleep]) { metric in
                ChallengeMetricChart(challenge: challenge, metric: metric, end: end)
            }
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily goal completion").font(.headline).foregroundColor(AscendTheme.textPrimary)
                    Chart(challenge.days.sorted { $0.id < $1.id }) { day in
                        if let completion = day.completion {
                            BarMark(x: .value("Day", day.id), y: .value("Completion %", completion * 100))
                                .foregroundStyle(AscendTheme.electricBlue)
                        }
                    }.chartYScale(domain: 0...100).chartXScale(domain: 1...75)
                        .chartXAxisLabel("Challenge day").frame(height: 170)
                    if challenge.days.allSatisfy({ $0.completion == nil }) { Text("Log daily goals to see this chart.").font(.caption) }
                }
            }
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily rating breakdown").font(.headline).foregroundColor(AscendTheme.textPrimary)
                    Chart(["Green", "Yellow", "Red"], id: \.self) { rating in
                        BarMark(x: .value("Rating", rating), y: .value("Days", challenge.days.filter { $0.rating == rating }.count))
                            .foregroundStyle(rating == "Green" ? AscendTheme.emeraldRecovery : rating == "Yellow" ? AscendTheme.metallicGold : AscendTheme.energeticCoral)
                    }.frame(height: 150)
                }
            }
            GlassCard {
                let count = challenge.days.filter { !$0.rating.isEmpty }.count
                VStack(alignment: .leading, spacing: 12) {
                    Text("Challenge completion").font(.headline).foregroundColor(AscendTheme.textPrimary)
                    Chart {
                        SectorMark(angle: .value("Completed", count), innerRadius: .ratio(0.7))
                            .foregroundStyle(AscendTheme.electricBlue)
                        SectorMark(angle: .value("Remaining", 75 - count), innerRadius: .ratio(0.7))
                            .foregroundStyle(AscendTheme.deepViolet.opacity(0.25))
                    }.frame(height: 160)
                    Text("\(count) rated days completed • \(75 - count) remaining").font(.caption)
                }
            }
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly body measurement trend").font(.headline).foregroundColor(AscendTheme.textPrimary)
                    Picker("Measurement", selection: $bodyMetric) { ForEach(bodyMetrics, id: \.self) { Text($0).tag($0) } }
                    Chart(challenge.weeks.sorted { $0.id < $1.id }) { week in
                        if let value = bodyValue(week) {
                            LineMark(x: .value("Week", week.id), y: .value(bodyMetric, value))
                                .foregroundStyle(AscendTheme.electricBlue).symbol(.circle)
                        }
                    }.chartXScale(domain: 1...11).chartXAxisLabel("Challenge week").frame(height: 180)
                    if challenge.weeks.allSatisfy({ bodyValue($0) == nil }) { Text("Add a weekly check-in to see measurements here.").font(.caption) }
                }
            }
        }.foregroundColor(AscendTheme.textSecondary)
    }
    private func bodyValue(_ week: ChallengeWeek) -> Double? {
        switch bodyMetric {
        case "Weight (kg)": return week.weight
        case "Waist (in)": return week.waist
        case "Chest (in)": return week.chest
        case "Arm (in)": return week.arm
        default: return week.leg
        }
    }
}

private struct ChallengeMetricChart: View {
    let challenge: Challenge75
    let metric: ChallengeMetric
    let end: Int
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(metric.title).font(.headline).foregroundColor(AscendTheme.textPrimary)
                Chart {
                    ForEach(1...end, id: \.self) { day in
                        if let value = metric.value(challenge.entry(day)) {
                            LineMark(x: .value("Day", day), y: .value("Value", value), series: .value("Series", "Daily"))
                                .foregroundStyle(by: .value("Series", "Daily")).symbol(.circle)
                        }
                        if let rolling = ChallengeEngine.rollingAverage(metric, in: challenge, day: day) {
                            LineMark(x: .value("Day", day), y: .value("Value", rolling), series: .value("Series", "7-day average"))
                                .foregroundStyle(by: .value("Series", "7-day average"))
                        }
                    }
                    RuleMark(y: .value("Target", metric.target))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4])).foregroundStyle(AscendTheme.metallicGold)
                }
                .chartForegroundStyleScale(["Daily": AscendTheme.electricBlue, "7-day average": AscendTheme.deepViolet])
                .chartXScale(domain: 1...max(7, end)).chartXAxisLabel("Challenge day")
                .frame(height: 185)
                Text("Dashed line: target \(number(metric.target)). Blank entries are excluded from rolling averages.")
                    .font(.caption).foregroundColor(AscendTheme.textSecondary)
            }
        }
    }
}

private struct ChallengeXPCard: View {
    @ObservedObject var store: AppDataStore
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("\(ChallengeEngine.earnedXP(in: store.state)) Character XP earned", systemImage: "sparkles")
                    .font(.headline).foregroundColor(AscendTheme.metallicGold)
                Text("\(ChallengeEngine.goalXP) XP per daily goal • \(ChallengeEngine.fullDayBonusXP) bonus for all five • \(ChallengeEngine.reflectionXP) for a daily rating, whatever its color • \(ChallengeEngine.weeklyReflectionXP) for a weekly reflection.")
                Text("Rated-day milestones: 100 XP at 7, 14, 21, 30, 45, and 60 days; 500 XP at 75 days.")
                Text("Rewards increase your character's XP, level, and level-based cosmetic unlocks. Each reward is earned once. Editing or missing a day never removes XP.")
            }.font(.subheadline).foregroundColor(AscendTheme.textSecondary)
        }
    }
}
