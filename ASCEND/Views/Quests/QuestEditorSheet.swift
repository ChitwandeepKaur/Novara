import SwiftUI

public struct QuestEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppDataStore
    
    public enum EditorMode: String, CaseIterable {
        case subQuest = "Sub Quest"
        case dailyQuest = "Daily Task"
        case sideQuest = "Side Quest / Habit"
        case mainQuest = "Main Quest"
    }
    
    @State private var mode: EditorMode = .dailyQuest
    
    // Common Fields
    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var category: QuestCategory = .career
    @State private var priority: QuestPriority = .medium
    @State private var difficulty: QuestDifficulty = .medium
    @State private var durationMinutes: Int = 60
    
    // SubQuest Specific
    @State private var selectedPrereqIds: Set<UUID> = []
    @State private var completionConditionType: Int = 0 // 0: All Tasks, 1: Numerical, 2: Milestone, 3: Deliverable, 4: Manual
    @State private var numericalTarget: Double = 10
    @State private var numericalUnit: String = "items"
    @State private var milestoneDesc: String = ""
    @State private var deliverableName: String = ""
    
    // Validation alert
    @State private var errorMessage: String?
    @State private var showErrorAlert: Bool = false
    
    private var activeMQ: MainQuest? {
        store.state.mainQuests.first(where: { $0.status == .active })
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                
                Form {
                    Section("Quest Category & Type") {
                        Picker("Type", selection: $mode) {
                            ForEach(EditorMode.allCases, id: \.self) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Picker("Life Domain", selection: $category) {
                            Text("Career").tag(QuestCategory.career)
                            Text("Fitness").tag(QuestCategory.fitness)
                            Text("Self-Care").tag(QuestCategory.selfCare)
                        }
                    }
                    .listRowBackground(AscendTheme.cardBackground)
                    
                    Section("Core Details") {
                        TextField("Quest Title", text: $title)
                            .foregroundColor(AscendTheme.textPrimary)
                        
                        TextField("Description & Objectives", text: $descriptionText, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundColor(AscendTheme.textPrimary)
                    }
                    .listRowBackground(AscendTheme.cardBackground)
                    
                    if mode == .dailyQuest {
                        Section("Planning & Scheduling") {
                            Picker("Priority", selection: $priority) {
                                ForEach(QuestPriority.allCases, id: \.self) { prio in
                                    Text(prio.rawValue).tag(prio)
                                }
                            }
                            
                            Picker("Difficulty", selection: $difficulty) {
                                ForEach(QuestDifficulty.allCases, id: \.self) { diff in
                                    Text("\(diff.rawValue) (\(diff.defaultXP) XP)").tag(diff)
                                }
                            }
                            
                            Stepper("Est. Duration: \(durationMinutes) mins", value: $durationMinutes, in: 15...240, step: 15)
                        }
                        .listRowBackground(AscendTheme.cardBackground)
                    }
                    
                    if mode == .subQuest {
                        Section("Completion Criteria") {
                            Picker("Condition Type", selection: $completionConditionType) {
                                Text("All Tasks").tag(0)
                                Text("Numerical Target").tag(1)
                                Text("Milestone").tag(2)
                                Text("Deliverable").tag(3)
                                Text("Manual").tag(4)
                            }
                            
                            if completionConditionType == 1 {
                                HStack {
                                    Text("Target:")
                                    TextField("Amount", value: $numericalTarget, format: .number)
                                        .keyboardType(.decimalPad)
                                    TextField("Unit (e.g. problems)", text: $numericalUnit)
                                }
                            } else if completionConditionType == 2 {
                                TextField("Milestone Name", text: $milestoneDesc)
                            } else if completionConditionType == 3 {
                                TextField("Deliverable (e.g. Live URL)", text: $deliverableName)
                            }
                        }
                        .listRowBackground(AscendTheme.cardBackground)
                        
                        Section("Prerequisites (DAG Dependency)") {
                            let availableSubQuests = store.state.subQuests
                            if availableSubQuests.isEmpty {
                                Text("No other Sub Quests available yet.")
                                    .font(.system(size: 13))
                                    .foregroundColor(AscendTheme.textSecondary)
                            } else {
                                ForEach(availableSubQuests) { sq in
                                    Toggle(sq.title, isOn: Binding(
                                        get: { selectedPrereqIds.contains(sq.id) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedPrereqIds.insert(sq.id)
                                            } else {
                                                selectedPrereqIds.remove(sq.id)
                                            }
                                        }
                                    ))
                                }
                            }
                        }
                        .listRowBackground(AscendTheme.cardBackground)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Create \(mode.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AscendTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveQuest()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AscendTheme.electricBlue)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Cannot Save Quest", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    private func saveQuest() {
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        guard !cleanTitle.isEmpty else { return }
        
        switch mode {
        case .mainQuest:
            let newMQ = MainQuest(
                title: cleanTitle,
                description: descriptionText,
                status: .active,
                priorityDistribution: PriorityAllocation(careerWeight: 0.8, fitnessWeight: 0.1, selfCareWeight: 0.1)
            )
            store.state.mainQuests.append(newMQ)
            QuestEngine.shared.activateMainQuest(id: newMQ.id, in: &store.state)
            dismiss()
            
        case .subQuest:
            guard let mq = activeMQ else {
                errorMessage = "No active Main Quest found. Please create a Main Quest first."
                showErrorAlert = true
                return
            }
            
            let condition: CompletionCondition
            switch completionConditionType {
            case 0: condition = .allTasksCompleted
            case 1: condition = .numericalTarget(target: numericalTarget, current: 0, unit: numericalUnit)
            case 2: condition = .milestoneReached(description: milestoneDesc.isEmpty ? cleanTitle : milestoneDesc)
            case 3: condition = .deliverableCompleted(deliverableName: deliverableName.isEmpty ? cleanTitle : deliverableName)
            default: condition = .manualConfirmation
            }
            
            let tempId = UUID()
            // Check cycle prevention
            for prereqId in selectedPrereqIds {
                if QuestEngine.shared.wouldCreateCycle(subQuestId: tempId, newPrerequisiteId: prereqId, allSubQuests: store.state.subQuests) {
                    errorMessage = "Cannot save: circular prerequisite detected."
                    showErrorAlert = true
                    return
                }
            }
            
            let newSQ = SubQuest(
                id: tempId,
                mainQuestId: mq.id,
                title: cleanTitle,
                description: descriptionText,
                category: category,
                prerequisiteSubQuestIds: Array(selectedPrereqIds),
                completionCondition: condition,
                orderIndex: store.state.subQuests.count,
                completionBonusXP: 250
            )
            store.state.subQuests.append(newSQ)
            dismiss()
            
        case .dailyQuest:
            let newDQ = DailyQuest(
                name: cleanTitle,
                description: descriptionText,
                category: category,
                priority: priority,
                estimatedDurationMinutes: durationMinutes,
                difficulty: difficulty,
                xpReward: difficulty.defaultXP
            )
            store.state.dailyQuests.append(newDQ)
            dismiss()
            
        case .sideQuest:
            let newSide = SideQuest(
                title: cleanTitle,
                description: descriptionText,
                type: .simpleHabit,
                category: category,
                xpPerCompletion: 30
            )
            store.state.sideQuests.append(newSide)
            dismiss()
        }
    }
}
