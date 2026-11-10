import SwiftUI

public struct QuestsView: View {
    @ObservedObject var store: AppDataStore
    
    @State private var showingQuestEditor = false
    @State private var showingMiniEditor = false
    @State private var selectedQuestIdForDetail: UUID?
    @State private var isDetailSubQuest = true
    @State private var showingArchiveSheet = false
    
    private var activeMQ: MainQuest? {
        store.state.mainQuests.first(where: { $0.status == .active })
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                ParticleFieldView(particleCount: 25)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 1. Current Main Quest Card
                        renderMainQuestBanner()
                        miniQuestsSection
                        
                        // 2. Sub Quests (The Core Pathway)
                        renderSubQuestsSection()
                        
                        // 3. Side Quests & Habits
                        renderSideQuestsSection()
                    }
                    .padding()
                }
            }
            .navigationTitle("Quest Hierarchy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingArchiveSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "archivebox.fill")
                            Text("Archive")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(AscendTheme.textSecondary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingQuestEditor = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(AscendTheme.electricBlue)
                    }
                }
            }
            .sheet(isPresented: $showingMiniEditor) {
                MiniQuestEditorSheet(store: store)
            }
            .sheet(isPresented: $showingQuestEditor) {
                QuestEditorSheet(store: store)
            }
            .sheet(item: Binding<IdentifiableUUID?>(
                get: { selectedQuestIdForDetail.map { IdentifiableUUID(id: $0) } },
                set: { selectedQuestIdForDetail = $0?.id }
            )) { wrapper in
                QuestDetailSheet(questId: wrapper.id, isSubQuest: isDetailSubQuest, store: store)
            }
            .sheet(isPresented: $showingArchiveSheet) {
                QuestArchiveView(store: store)
            }
        }
    }
    
    @ViewBuilder
    private func renderMainQuestBanner() -> some View {
        if let mq = activeMQ {
            GlassCard(cornerRadius: 18, borderColor: AscendTheme.electricBlue) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("ACTIVE MAIN QUEST", systemImage: "crown.fill")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(AscendTheme.metallicGold)
                        Spacer()
                        Text("Active")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AscendTheme.emeraldRecovery)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(AscendTheme.emeraldRecovery.opacity(0.15)))
                    }
                    
                    Text(mq.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AscendTheme.textPrimary)
                    
                    if !mq.description.isEmpty {
                        Text(mq.description)
                            .font(.system(size: 13))
                            .foregroundColor(AscendTheme.textSecondary)
                    }
                    
                    // Priority Distribution
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PRIORITY ALLOCATION")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(AscendTheme.textTertiary)
                        
                        HStack(spacing: 4) {
                            // Career
                            Rectangle()
                                .fill(AscendTheme.electricBlue)
                                .frame(height: 6)
                                .frame(maxWidth: .infinity)
                            // Fitness
                            Rectangle()
                                .fill(AscendTheme.energeticCoral)
                                .frame(height: 6)
                                .frame(width: 40)
                            // Self-Care
                            Rectangle()
                                .fill(AscendTheme.cyberCyan)
                                .frame(height: 6)
                                .frame(width: 40)
                        }
                        .clipShape(Capsule())
                        
                        HStack {
                            Text("Career: \(Int(mq.priorityDistribution.careerWeight * 100))%")
                                .foregroundColor(AscendTheme.electricBlue)
                            Spacer()
                            Text("Fitness: \(Int(mq.priorityDistribution.fitnessWeight * 100))%")
                                .foregroundColor(AscendTheme.energeticCoral)
                            Spacer()
                            Text("Self-Care: \(Int(mq.priorityDistribution.selfCareWeight * 100))%")
                                .foregroundColor(AscendTheme.cyberCyan)
                        }
                        .font(.system(size: 11, weight: .medium))
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            QuestEngine.shared.pauseMainQuest(id: mq.id, in: &store.state)
                            HapticService.shared.triggerImpact(.medium)
                        } label: {
                            Text("Pause Journey")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AscendTheme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 8).fill(AscendTheme.cardBorder.opacity(0.5)))
                        }
                        
                        Spacer()
                        
                        Button {
                            let bonus = QuestEngine.shared.completeMainQuest(id: mq.id, in: &store.state)
                            XPEngine.shared.awardCompletionBonusXP(amount: bonus, questId: mq.id, questTitle: mq.title, in: &store.state)
                            WorldEngine.shared.triggerAscensionTransformation(in: &store.state)
                            HapticService.shared.triggerNotification(.success)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Ascend (Complete)")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(AscendTheme.goldGradient))
                        }
                    }
                    .padding(.top, 4)
                }
            }
        } else {
            GlassCard {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AscendTheme.electricBlue)
                    Text("No Active Main Quest")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AscendTheme.textPrimary)
                    Text("Select or create a new life journey to begin leveling your character and world.")
                        .font(.system(size: 13))
                        .foregroundColor(AscendTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    GlowingButton(title: "Create Main Quest", icon: "plus") {
                        showingQuestEditor = true
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private func renderSubQuestsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Sub Quests",
                subtitle: "Direct milestones contributing to your Main Quest",
                icon: "arrow.triangle.branch"
            )
            
            let subQuests = store.state.subQuests.filter { $0.miniQuestId == nil }
            if subQuests.isEmpty {
                GlassCard {
                    Text("No Sub Quests yet. Tap '+ Add' to break down your main goal.")
                        .font(.system(size: 13))
                        .foregroundColor(AscendTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(subQuests) { sq in
                        let prereqsMet = QuestEngine.shared.arePrerequisitesMet(for: sq, allSubQuests: subQuests)
                        
                        Button {
                            isDetailSubQuest = true
                            selectedQuestIdForDetail = sq.id
                        } label: {
                            GlassCard(cornerRadius: 14) {
                                HStack(alignment: .top, spacing: 14) {
                                    Circle()
                                        .fill(sq.status == .completed ? AscendTheme.emeraldRecovery.opacity(0.2) : (prereqsMet ? AscendTheme.electricBlue.opacity(0.15) : AscendTheme.cardBorder.opacity(0.4)))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Image(systemName: sq.status == .completed ? "checkmark" : (prereqsMet ? "flag.fill" : "lock.fill"))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(sq.status == .completed ? AscendTheme.emeraldRecovery : (prereqsMet ? AscendTheme.electricBlue : AscendTheme.textTertiary))
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(sq.title)
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundColor(sq.status == .completed ? AscendTheme.textSecondary : AscendTheme.textPrimary)
                                                .strikethrough(sq.status == .completed)
                                            Spacer()
                                            XPBadge(amount: sq.completionBonusXP, category: .completionBonus)
                                        }
                                        
                                        Text(sq.completionCondition.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(AscendTheme.textSecondary)
                                        
                                        if !sq.prerequisiteSubQuestIds.isEmpty && !prereqsMet {
                                            HStack(spacing: 4) {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(AscendTheme.metallicGold)
                                                Text("Requires prior milestone completion")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(AscendTheme.metallicGold)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderSideQuestsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Side Quests & Daily Habits",
                subtitle: "Supportive routines in fitness and self-care",
                icon: "sparkles"
            )
            
            let sideQuests = store.state.sideQuests
            if sideQuests.isEmpty {
                GlassCard {
                    Text("No side quests or habits defined yet.")
                        .font(.system(size: 13))
                        .foregroundColor(AscendTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(sideQuests) { sq in
                        GlassCard(cornerRadius: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: sq.category.iconName)
                                    .font(.system(size: 18))
                                    .foregroundColor(sq.category == .fitness ? AscendTheme.energeticCoral : AscendTheme.cyberCyan)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sq.title)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(AscendTheme.textPrimary)
                                    Text("\(sq.currentStreak) days completed")
                                        .font(.system(size: 11))
                                        .foregroundColor(AscendTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    completeSideQuest(sq)
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(AscendTheme.emeraldRecovery)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func completeSideQuest(_ sq: SideQuest) {
        if let idx = store.state.sideQuests.firstIndex(where: { $0.id == sq.id }) {
            store.state.sideQuests[idx].currentStreak += 1
            XPEngine.shared.awardEffortXP(minutes: 30, questId: sq.id, title: sq.title, in: &store.state)
            WorldEngine.shared.recordQuestProgress(category: sq.category, in: &store.state)
            HapticService.shared.triggerNotification(.success)
        }
    }
}

public struct IdentifiableUUID: Identifiable {
    public let id: UUID
}

public struct QuestArchiveView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppDataStore
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                
                let archived = store.state.mainQuests.filter { $0.status == .archived }
                if archived.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy")
                            .font(.system(size: 40))
                            .foregroundColor(AscendTheme.textTertiary)
                        Text("No Archived Journeys Yet")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AscendTheme.textSecondary)
                        Text("Completed Main Quests will be enshrined here forever.")
                            .font(.system(size: 13))
                            .foregroundColor(AscendTheme.textTertiary)
                    }
                    .padding()
                } else {
                    List(archived) { mq in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mq.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AscendTheme.textPrimary)
                            Text("Completed: \(mq.completedAt?.formatted(date: .abbreviated, time: .omitted) ?? "Archived")")
                                .font(.system(size: 12))
                                .foregroundColor(AscendTheme.textSecondary)
                        }
                        .listRowBackground(AscendTheme.cardBackground)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Hall of Journeys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

extension QuestsView {
    private var miniQuestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Mini Main Quests", subtitle: "Temporary goals alongside your main journey", icon: "calendar.badge.flag")
            Button { showingMiniEditor = true } label: {
                Label("Add Mini Main Quest", systemImage: "plus.circle.fill")
                    .foregroundColor(AscendTheme.cyberCyan)
            }
            if store.state.miniMainQuests.isEmpty {
                Text("Have something to finish by Christmas, a trip, or another date? Add your outcomes and we'll break them into focused sessions.")
                    .font(.subheadline).foregroundColor(AscendTheme.textSecondary)
            }
            ForEach(store.state.miniMainQuests) { mini in
                miniQuestCard(mini)
            }
        }
    }

    private func miniQuestCard(_ mini: MiniMainQuest) -> some View {
        let tasks = store.state.dailyQuests.filter { $0.miniQuestId == mini.id }
        let completed = tasks.filter { $0.status == .completed }.count
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(mini.title).font(.headline).foregroundColor(AscendTheme.textPrimary)
                Text("Due \(mini.targetDeadline.formatted(date: .abbreviated, time: .omitted)) • \(mini.status.rawValue)")
                    .font(.caption).foregroundColor(AscendTheme.cyberCyan)
                Text("\(completed)/\(tasks.count) sessions completed")
                    .font(.caption).foregroundColor(AscendTheme.textSecondary)
                ProgressView(value: Double(completed), total: Double(max(1, tasks.count)))
                if mini.status == .active && mini.targetDeadline < Date() {
                    Text("Past your target date: your progress is safe. Keep going at your own pace.")
                        .font(.caption).foregroundColor(AscendTheme.metallicGold)
                }
                ForEach(store.state.subQuests.filter { $0.miniQuestId == mini.id }) { milestone in
                    Label(milestone.title, systemImage: milestone.status == .completed ? "checkmark.circle.fill" : "flag")
                        .font(.subheadline).foregroundColor(AscendTheme.textPrimary)
                }
                DisclosureGroup("View sessions") {
                    ForEach(tasks) { task in
                        VStack(alignment: .leading, spacing: 3) {
                            Label(task.name, systemImage: task.status == .completed ? "checkmark.circle.fill" : "circle")
                            Text("\(task.estimatedDurationMinutes) minutes").font(.caption)
                        }.foregroundColor(AscendTheme.textSecondary).padding(.vertical, 4)
                    }
                }.foregroundColor(AscendTheme.cyberCyan)
                Text("Complete sessions in Plan → Checklist. The next session joins each day's schedule when you generate it.")
                    .font(.caption).foregroundColor(AscendTheme.textSecondary)
            }
        }
    }
}

struct MiniQuestEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppDataStore
    @State private var title = ""
    @State private var outcomesText = ""
    @State private var deadline = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
    @State private var category: QuestCategory = .career
    @State private var minutes = 30
    @State private var draft: [DailyQuest] = []
    @State private var error: String?
    @State private var saved = false
    @State private var generating = false
    @State private var showingOnlineServices = false

    private var maximumSessionMinutes: Int {
        min(60, max(15, Int(store.state.dailyPlan.availableWorkingHours * 15) / 15 * 15))
    }

    private var outcomes: [String] {
        outcomesText.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                if draft.isEmpty {
                    Section("Your temporary quest") {
                        TextField("e.g. Ready by Christmas", text: $title)
                        DatePicker("Target date", selection: $deadline, in: Calendar.current.startOfDay(for: Date())..., displayedComponents: .date)
                        Picker("Life domain", selection: $category) {
                            Text("Career").tag(QuestCategory.career)
                            Text("Fitness").tag(QuestCategory.fitness)
                            Text("Self-Care").tag(QuestCategory.selfCare)
                        }
                    }
                    Section {
                        TextEditor(text: $outcomesText).frame(minHeight: 120)
                            .accessibilityLabel("Outcomes, one per line")
                    } header: { Text("What do you want to accomplish? One outcome per line") }
                    footer: { Text("For example: Finish my portfolio; Make handmade gifts. Put each outcome on its own line.") }
                    Section {
                        Text("Free on-device planner").font(.caption)
                        Button("Cloud sync") { showingOnlineServices = true }
                        if generating { ProgressView("Preparing your sessions...") }
                        Stepper("Session length: \(minutes) minutes", value: $minutes, in: 15...maximumSessionMinutes, step: 15)
                        Button("Generate breakdown") {
                            generateBreakdown()
                        }.disabled(generating || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || outcomes.isEmpty)
                    }
                } else {
                    Section("Review your breakdown") {
                        Text(title).font(.headline)
                        Text("Due \(deadline.formatted(date: .abbreviated, time: .omitted))")
                        Text("Each outcome has planning, focused work, and verification sessions. Edit the session names and durations to match the work you need.")
                        Text("Up to 25% of daily focus time goes to mini quests, nearest deadline first. Today's existing appointments stay in place; if today is full, generate a new schedule in Plan to make room.")
                    }
                    ForEach($draft) { $task in
                        Section {
                            TextField("Session", text: $task.name, axis: .vertical)
                            Text(task.description).font(.caption)
                            Stepper("\(task.estimatedDurationMinutes) minutes", value: $task.estimatedDurationMinutes, in: 15...maximumSessionMinutes, step: 15)
                        }
                    }
                    Section {
                        Button("Back to goals") { draft = [] }
                        Button("Add quest & daily sessions") { save() }
                            .disabled(draft.contains { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                    }
                }
            }
            .navigationTitle("Mini Main Quest")
            .sheet(isPresented: $showingOnlineServices) { OnlineServicesSheet(store: store) }
            .onAppear { minutes = min(minutes, maximumSessionMinutes) }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .alert("Unable to add quest", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
            .alert("Mini quest added", isPresented: $saved) {
                Button("Done") { dismiss() }
            } message: { Text("Your sessions are in Plan → Checklist. Today's schedule gained a session if there was room. Generate a schedule in Plan to balance both quests within your focus hours.") }
        }
    }

    private func generateBreakdown() {
        guard !generating else { return }
        draft = QuestEngine.shared.miniQuestBreakdown(outcomes: outcomes, category: category, minutes: min(minutes, maximumSessionMinutes))
    }

    private func save() {
        do {
            var state = store.state
            try QuestEngine.shared.addMiniQuest(title: title, outcomes: outcomes, deadline: deadline, category: category, tasks: draft, in: &state)
            PlanningEngine.shared.appendMiniTasksToCurrentPlan(in: &state)
            store.state = state
            store.saveImmediately()
            saved = true
        } catch { self.error = error.localizedDescription }
    }
}
