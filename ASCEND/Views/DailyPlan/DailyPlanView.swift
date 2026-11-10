import SwiftUI

public enum DailyViewMode: String, CaseIterable {
    case timeline = "Timeline View"
    case checklist = "Checklist View"
}

public struct DailyPlanView: View {
    @ObservedObject var store: AppDataStore
    
    @State private var showingWeeklyPlan = false
    @State private var selectedDate = Date()
    @State private var viewMode: DailyViewMode = .timeline
    @State private var showingFocusTimer = false
    @State private var selectedQuestForTimer: DailyQuest?
    @State private var showingDailyRecap = false
    @State private var showingReplanSheet = false
    @State private var availableHours: Double = 6.0
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                ParticleFieldView(particleCount: 20)
                
                VStack(spacing: 0) {
                    HStack {
                        DatePicker("Plan date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact).font(.subheadline)
                        Button { showingWeeklyPlan = true } label: {
                            Label("Week", systemImage: "square.and.arrow.down")
                        }.foregroundColor(AscendTheme.cyberCyan)
                    }.padding(.horizontal).padding(.top, 8)
                    Stepper("Focus budget: \(availableHours, specifier: "%.1f") hours", value: $availableHours, in: 1...14, step: 0.5)
                        .font(.caption).foregroundColor(AscendTheme.textSecondary)
                        .padding(.horizontal).padding(.vertical, 4)
                    // Replan Alert Banner if proposal exists
                    if let proposal = store.state.dailyPlan.pendingReplanProposal,
                       Calendar.current.isDate(store.state.dailyPlan.date, inSameDayAs: selectedDate) {
                        renderReplanAlertBanner(proposal)
                    }
                    
                    // View Mode Switcher & Focus Bar
                    HStack {
                        Picker("View Mode", selection: $viewMode) {
                            ForEach(DailyViewMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            FairyRealmBanner(name: store.state.avatar.name)
                            if let session = store.state.activeFocusSession {
                                Button {
                                    selectedQuestForTimer = store.state.dailyQuests.first { $0.id == session.dailyQuestId }
                                    showingFocusTimer = true
                                } label: {
                                    GlassCard {
                                        HStack {
                                            Image(systemName: session.runStartedAt == nil ? "pause.circle" : "timer")
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(session.questTitle).font(.headline)
                                                Text(session.runStartedAt == nil ? "Session paused. Tap to resume." : "Focus in progress. Tap to open.")
                                                    .font(.caption)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }.foregroundStyle(AscendTheme.cyberCyan)
                                    }
                                }.buttonStyle(.plain)
                            }
                            if Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
                                ChallengeDailyPanel(store: store)
                            }
                            renderNonNegotiables()
                            if store.state.dailyQuests.isEmpty && store.state.dailyPlan.slots.isEmpty {
                                renderEmptyPlanPrompt()
                            } else {
                                if viewMode == .timeline {
                                    renderTimelineView()
                                } else {
                                    renderChecklistView()
                                }
                            }
                        }
                        .padding().padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Daily Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingDailyRecap = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.stars.fill")
                            Text("Recap")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(AscendTheme.metallicGold)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            generateSchedule()
                        } label: {
                            Label("Regenerate Smart Schedule", systemImage: "sparkles")
                        }
                        
                        Button {
                            checkAndTriggerReplan()
                        } label: {
                            Label("Check for Scheduling Conflicts", systemImage: "arrow.triangle.swap")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AscendTheme.electricBlue)
                    }
                }
            }
            .onAppear {
                var updated = store.state
                WeeklyPlanEngine.installStarterWeek(in: &updated)
                store.state = updated
                adoptDayBudget()
            }
            .onChange(of: selectedDate) { _, _ in adoptDayBudget() }
            .sheet(isPresented: $showingWeeklyPlan, onDismiss: { adoptDayBudget() }) {
                WeeklyPlanImportSheet(store: store, weekOf: selectedDate)
            }
            .sheet(isPresented: $showingFocusTimer) {
                FocusTimerSheet(quest: selectedQuestForTimer, store: store)
            }
            .sheet(isPresented: $showingDailyRecap) {
                DailyRecapSheet(store: store)
            }
            .sheet(isPresented: $showingReplanSheet) {
                if let proposal = store.state.dailyPlan.pendingReplanProposal {
                    ReplanApprovalSheet(proposal: proposal, store: store)
                }
            }
        }
    }
    
    // MARK: - Replan Alert Banner
    
    @ViewBuilder
    private func renderReplanAlertBanner(_ proposal: ReplanProposal) -> some View {
        Button {
            showingReplanSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bolt.badge.clock.fill")
                    .foregroundColor(AscendTheme.metallicGold)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Schedule Adjustment Suggested")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(AscendTheme.textPrimary)
                    Text("Tasks fell behind schedule. Tap to review proposed adaptation.")
                        .font(.system(size: 11))
                        .foregroundColor(AscendTheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AscendTheme.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#23180D"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AscendTheme.metallicGold.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Timeline View
    
    @ViewBuilder
    private func renderTimelineView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(
                    title: "Chronological Flow",
                    subtitle: "Optimized according to your priority weights",
                    icon: "calendar.badge.clock"
                )
                Spacer()
                Button {
                    selectedQuestForTimer = nil
                    showingFocusTimer = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text("Timer")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AscendTheme.cyberCyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(AscendTheme.cyberCyan.opacity(0.15)))
                }
            }
            
            if store.state.dailyPlan.slots.isEmpty || !Calendar.current.isDate(store.state.dailyPlan.date, inSameDayAs: selectedDate) {
                GlassCard {
                    VStack(spacing: 8) {
                        Text("No schedule generated yet.")
                            .foregroundColor(AscendTheme.textSecondary)
                        GlowingButton(title: "Generate Smart Schedule", icon: "sparkles") {
                            generateSchedule()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(store.state.dailyPlan.slots) { slot in
                    if slot.isBreak {
                        // Break indicator
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(AscendTheme.cardBorder.opacity(0.5))
                                .frame(height: 1)
                            Text("☕ \(slot.title)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(AscendTheme.textTertiary)
                            Rectangle()
                                .fill(AscendTheme.cardBorder.opacity(0.5))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 4)
                    } else {
                        GlassCard(cornerRadius: 12) {
                            HStack(alignment: .top, spacing: 14) {
                                // Time Column
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(slot.startTime.formatted(date: .omitted, time: .shortened))
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(AscendTheme.electricBlue)
                                    Text("\(slot.durationMinutes)m")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AscendTheme.textTertiary)
                                }
                                .frame(width: 60, alignment: .trailing)
                                
                                // Divider Line
                                Rectangle()
                                    .fill(slot.isCompleted ? AscendTheme.emeraldRecovery : AscendTheme.cardBorder)
                                    .frame(width: 2)
                                
                                // Content
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(slot.title)
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(slot.isCompleted ? AscendTheme.textSecondary : AscendTheme.textPrimary)
                                            .strikethrough(slot.isCompleted)
                                        Spacer()
                                        
                                        // Timer Quick Launch
                                        Button {
                                            if let dqId = slot.dailyQuestId {
                                                selectedQuestForTimer = store.state.dailyQuests.first(where: { $0.id == dqId })
                                            } else {
                                                selectedQuestForTimer = nil
                                            }
                                            showingFocusTimer = true
                                        } label: {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(AscendTheme.electricBlue)
                                        }
                                    }
                                    
                                    if !slot.notes.isEmpty {
                                        Text(slot.notes)
                                            .font(.system(size: 11))
                                            .foregroundColor(AscendTheme.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderNonNegotiables() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Daily non-negotiables", subtitle: "Every day, every week", icon: "checkmark.seal.fill")
            let tasks = WeeklyPlanEngine.tasks(on: selectedDate, in: store.state)
            ForEach(DailyNonNegotiable.allCases, id: \.rawValue) { kind in
                if let task = tasks.first(where: { $0.nonNegotiableKey == kind.rawValue }) {
                    GlassCard(cornerRadius: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Button { toggleTaskCompletion(task) } label: {
                                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(task.status == .completed ? AscendTheme.emeraldRecovery : AscendTheme.textTertiary)
                            }
                            .accessibilityLabel("Mark \(kind.title) \(task.status == .completed ? "incomplete" : "complete")")
                            VStack(alignment: .leading, spacing: 5) {
                                Text(kind.title).font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AscendTheme.textPrimary).strikethrough(task.status == .completed)
                                if !task.description.isEmpty {
                                    Text(task.description).font(.caption).foregroundColor(AscendTheme.textSecondary)
                                }
                                Text("\(task.estimatedDurationMinutes) mins\(kind.outsideCore ? " • Outside core" : "")")
                                    .font(.caption).foregroundColor(AscendTheme.cyberCyan)
                            }
                            Spacer(minLength: 0)
                            Button {
                                selectedQuestForTimer = task
                                showingFocusTimer = true
                            } label: {
                                Image(systemName: "play.circle.fill").font(.title3).foregroundColor(AscendTheme.electricBlue)
                            }.accessibilityLabel("Focus on \(kind.title)")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Checklist View
    
    @ViewBuilder
    private func renderChecklistView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Daily Quest Checklist",
                subtitle: "Directly synchronized with your schedule",
                icon: "checklist"
            )
            
            let dailyQuests = WeeklyPlanEngine.tasks(on: selectedDate, in: store.state).filter { $0.nonNegotiableKey == nil }
            if dailyQuests.isEmpty {
                GlassCard {
                    Text("No daily quests available. Tap '+' in Quests to add tasks.")
                        .font(.system(size: 13))
                        .foregroundColor(AscendTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                ForEach(dailyQuests) { quest in
                    GlassCard(cornerRadius: 12) {
                        HStack(spacing: 12) {
                            Button {
                                toggleTaskCompletion(quest)
                            } label: {
                                Image(systemName: quest.status == .completed ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(quest.status == .completed ? AscendTheme.emeraldRecovery : AscendTheme.textTertiary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(quest.name)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(quest.status == .completed ? AscendTheme.textSecondary : AscendTheme.textPrimary)
                                    .strikethrough(quest.status == .completed)
                                
                                HStack(spacing: 8) {
                                    Text("\(quest.estimatedDurationMinutes) mins")
                                        .font(.system(size: 11))
                                        .foregroundColor(AscendTheme.textTertiary)
                                    Text("•")
                                        .foregroundColor(AscendTheme.textTertiary)
                                    Text(quest.isOptional == true ? "Optional" : quest.isExternalCommitment == true ? "Outside core" : quest.miniQuestId.flatMap { id in store.state.miniMainQuests.first { $0.id == id }?.title } ?? quest.priority.rawValue)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AscendTheme.energeticCoral)
                                }
                            }
                            
                            Spacer()
                            
                            XPBadge(amount: quest.xpReward, category: .effort)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderEmptyPlanPrompt() -> some View {
        GlassCard {
            VStack(spacing: 14) {
                Image(systemName: "sun.haze.fill")
                    .font(.system(size: 38))
                    .foregroundColor(AscendTheme.metallicGold)
                Text("Design Your Focused Day")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AscendTheme.textPrimary)
                Text("Novara's deterministic planning engine turns your active Main Quest and Side Habits into an achievable, structured daily schedule.")
                    .font(.system(size: 13))
                    .foregroundColor(AscendTheme.textSecondary)
                    .multilineTextAlignment(.center)
                
                GlowingButton(title: "Generate Daily Schedule", icon: "sparkles") {
                    generateSchedule()
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Actions
    
    private func adoptDayBudget() {
        var updated = store.state
        WeeklyPlanEngine.ensureNonNegotiables(forWeek: selectedDate, in: &updated)
        store.state = updated
        let datedCore = WeeklyPlanEngine.tasks(on: selectedDate, in: store.state).filter {
            $0.weeklyPlanID != nil && $0.isOptional != true && $0.isExternalCommitment != true
        }
        availableHours = datedCore.isEmpty ? store.state.dailyPlan.availableWorkingHours : min(14, max(1, Double(datedCore.reduce(0) { $0 + $1.estimatedDurationMinutes }) / 60))
    }

    private func generateSchedule() {
        let plan = PlanningEngine.shared.generateSuggestedPlan(
            for: selectedDate,
            availableHours: availableHours,
            in: store.state
        )
        store.state.dailyPlan = plan
        store.state.dailyPlan.isApprovedByUser = true
        HapticService.shared.triggerNotification(.success)
    }
    
    private func checkAndTriggerReplan() {
        if let proposal = PlanningEngine.shared.detectAndProposeReplan(for: store.state.dailyPlan) {
            store.state.dailyPlan.pendingReplanProposal = proposal
            showingReplanSheet = true
            HapticService.shared.triggerNotification(.warning)
        } else {
            HapticService.shared.triggerNotification(.success)
        }
    }
    
    private func toggleTaskCompletion(_ quest: DailyQuest) {
        guard let idx = store.state.dailyQuests.firstIndex(where: { $0.id == quest.id }) else { return }
        
        if store.state.dailyQuests[idx].status == .completed {
            store.state.dailyQuests[idx].status = .notStarted
            store.state.dailyQuests[idx].completedAt = nil
            for slotIndex in store.state.dailyPlan.slots.indices where store.state.dailyPlan.slots[slotIndex].dailyQuestId == quest.id {
                store.state.dailyPlan.slots[slotIndex].isCompleted = false
            }
        } else {
            store.state.dailyQuests[idx].status = .completed
            store.state.dailyQuests[idx].completedAt = Date()
            
            // Award Effort / Task XP
            let alreadyRewardedMiniTask = (quest.miniQuestId != nil || quest.nonNegotiableKey != nil) && store.state.xpTransactions.contains { $0.sourceQuestId == quest.id && $0.category == .effort }
            XPEngine.shared.awardEffortXP(
                minutes: alreadyRewardedMiniTask ? 0 : quest.estimatedDurationMinutes,
                questId: quest.id,
                title: quest.name,
                in: &store.state
            )
            
            // Upgrade matching region illumination
            WorldEngine.shared.recordQuestProgress(category: quest.category, in: &store.state)
            
            // Attribute to skill trees
            SkillEngine.shared.attributeQuestCompletion(
                category: quest.category,
                linkedSkillIds: [],
                xpAmount: quest.xpReward,
                in: &store.state
            )
            
            // Sync with matching slot in dailyPlan
            for sIdx in store.state.dailyPlan.slots.indices {
                if store.state.dailyPlan.slots[sIdx].dailyQuestId == quest.id {
                    store.state.dailyPlan.slots[sIdx].isCompleted = true
                }
            }
            
            HapticService.shared.triggerNotification(.success)
        }
        QuestEngine.shared.refreshMiniQuestProgress(in: &store.state)
    }
}

public struct ReplanApprovalSheet: View {
    @Environment(\.dismiss) private var dismiss
    let proposal: ReplanProposal
    @ObservedObject var store: AppDataStore
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    GlassCard(cornerRadius: 16, borderColor: AscendTheme.metallicGold) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                    .foregroundColor(AscendTheme.metallicGold)
                                Text("Smart Replanning Proposal")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(AscendTheme.textPrimary)
                            }
                            Text(proposal.rationale)
                                .font(.system(size: 13))
                                .foregroundColor(AscendTheme.textSecondary)
                                .lineSpacing(3)
                        }
                    }
                    
                    if !proposal.shortenedTasks.isEmpty {
                        SectionHeader(title: "Compressed Tasks", icon: "arrow.down.right.and.arrow.up.left")
                        ForEach(proposal.shortenedTasks, id: \.self) { item in
                            Text("• \(item)")
                                .font(.system(size: 13))
                                .foregroundColor(AscendTheme.textSecondary)
                        }
                    }
                    
                    if !proposal.movedTasks.isEmpty {
                        SectionHeader(title: "Shifted Ahead", icon: "clock.arrow.2.circlepath")
                        ForEach(proposal.movedTasks, id: \.self) { item in
                            Text("• \(item)")
                                .font(.system(size: 13))
                                .foregroundColor(AscendTheme.cyberCyan)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button {
                            PlanningEngine.shared.dismissReplanProposal(in: &store.state.dailyPlan)
                            dismiss()
                        } label: {
                            Text("Keep Current Plan")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AscendTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(AscendTheme.cardBackground))
                        }
                        
                        GlowingButton(title: "Approve Schedule", icon: "checkmark") {
                            PlanningEngine.shared.applyReplanProposal(proposal, to: &store.state.dailyPlan)
                            HapticService.shared.triggerNotification(.success)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Schedule Adjustment")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
