import SwiftUI

public enum OnboardingInputMode: String, CaseIterable {
    case smartGenerator = "AI / Smart Generator"
    case manualBuilder = "Build Custom Plan"
}

public struct OnboardingFlowView: View {
    @ObservedObject var store: AppDataStore
    
    @State private var currentStep = 0
    @State private var playerName = ""
    @State private var inputMode: OnboardingInputMode = .smartGenerator
    
    // Smart Generator inputs
    @State private var userGoalPrompt: String = ""
    @State private var selectedTimelineMonths: Int = 3
    @State private var isGenerating = false
    
    // Active Plan Draft
    @State private var planDraft: CustomPlanDraft = CustomPlanDraft(
        goalTitle: "Land a Software Engineering Job",
        goalDescription: "Structured technical transformation to land a top software engineering role.",
        category: .career,
        priorityAllocation: PriorityAllocation(careerWeight: 0.8, fitnessWeight: 0.1, selfCareWeight: 0.1)
    )
    
    // Refinement / Request Changes
    @State private var refinementRequest: String = ""
    @State private var isRefining = false
    @State private var refinementMessage: String?
    
    // Manual additions
    @State private var showingAddMilestone = false
    @State private var newMilestoneTitle = ""
    @State private var newMilestoneDesc = ""
    
    @State private var showingAddTask = false
    @State private var newTaskName = ""
    @State private var newTaskDuration = 60
    
    // Finalize
    @State private var workingHours: Double = 6.0
    
    let inspirationPills = [
        "💻 Land a Software Engineering Role",
        "🏃 Train for Marathon & Peak Fitness",
        "🚀 Launch an Indie App / Startup",
        "🎸 Master Guitar & Creative Discipline",
        "📚 Ace the Bar Exam / Certification",
        "🇯🇵 Learn Japanese & Conversational Fluency"
    ]
    
    public var body: some View {
        ZStack {
            AscendTheme.celestialSkybox.ignoresSafeArea()
            ParticleFieldView(particleCount: 30)
            
            VStack(spacing: 0) {
                // Header Step Progress Bar
                HStack(spacing: 8) {
                    ForEach(0..<4) { idx in
                        Rectangle()
                            .fill(idx <= currentStep ? AscendTheme.electricBlue : AscendTheme.cardBorder.opacity(0.4))
                            .frame(height: 4)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 14)
                .padding(.bottom, 10)
                
                // Step Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch currentStep {
                        case 0:
                            renderStep0Welcome()
                        case 1:
                            renderStep1GoalInput()
                        case 2:
                            renderStep2ReviewAndRefine()
                        case 3:
                            renderStep3AvailableHours()
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                // Bottom Navigation Bar
                VStack(spacing: 0) {
                    Divider().background(AscendTheme.cardBorder.opacity(0.3))
                    
                    HStack(spacing: 16) {
                        if currentStep > 0 {
                            Button {
                                withAnimation(.easeInOut) {
                                    currentStep -= 1
                                }
                                HapticService.shared.triggerImpact(.light)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AscendTheme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }
                        
                        Spacer()
                        
                        if currentStep == 1 {
                            GlowingButton(
                                title: inputMode == .smartGenerator ? "Generate Plan ✨" : "Review Plan ➔",
                                icon: inputMode == .smartGenerator ? "sparkles" : "arrow.right"
                            ) {
                                handleStep1Continue()
                            }
                        } else if currentStep == 2 {
                            GlowingButton(title: "Approve Plan ➔", icon: "checkmark") {
                                withAnimation(.easeInOut) {
                                    currentStep = 3
                                }
                                HapticService.shared.triggerImpact(.medium)
                            }
                        } else if currentStep == 3 {
                            GlowingButton(title: "Enter the Realm ⚡", icon: "bolt.fill") {
                                finalizeAndEnterRealm()
                            }
                        } else {
                            GlowingButton(title: "Continue ➔", icon: "arrow.right") {
                                withAnimation(.easeInOut) {
                                    currentStep = 1
                                }
                                HapticService.shared.triggerImpact(.medium)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(AscendTheme.cardBackground)
                }
            }
        }
        .sheet(isPresented: $showingAddMilestone) {
            addMilestoneSheet
        }
        .sheet(isPresented: $showingAddTask) {
            addTaskSheet
        }
    }
    
    // MARK: - Step 0: Welcome & Traveler Name
    
    @ViewBuilder
    private func renderStep0Welcome() -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AscendTheme.primaryGradient.opacity(0.25))
                    .frame(width: 96, height: 96)
                    .overlay(Circle().stroke(AscendTheme.electricBlue.opacity(0.6), lineWidth: 2))
                
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 46))
                    .foregroundColor(AscendTheme.cyberCyan)
            }
            .padding(.top, 20)
            
            VStack(spacing: 8) {
                Text("WELCOME TO ASCEND")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(AscendTheme.electricBlue)
                
                Text("A Real-Life RPG")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AscendTheme.textPrimary)
                
                Text("Your avatar represents who you are becoming.\nYour world represents the life you are building.")
                    .font(.system(size: 14))
                    .foregroundColor(AscendTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR TRAVELER NAME")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(AscendTheme.textTertiary)
                
                TextField("e.g. Alex Rivera", text: $playerName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AscendTheme.textPrimary)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(AscendTheme.cardBackground))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AscendTheme.cardBorder, lineWidth: 1))
            }
            .padding(.horizontal, 8)
            .padding(.top, 12)
        }
    }
    
    // MARK: - Step 1: Input What You Want To Do
    
    @ViewBuilder
    private func renderStep1GoalInput() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("DEFINE YOUR PRIME OBJECTIVE")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(AscendTheme.electricBlue)
                
                Text("What do you want to accomplish?")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AscendTheme.textPrimary)
                
                Text("Type what you want to do. We'll generate a custom roadmap of milestones and daily tasks you can approve or customize.")
                    .font(.system(size: 13))
                    .foregroundColor(AscendTheme.textSecondary)
                    .lineSpacing(3)
            }
            
            // Mode Selector: Smart Generator vs Manual
            Picker("Mode", selection: $inputMode) {
                ForEach(OnboardingInputMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)
            
            if inputMode == .smartGenerator {
                // Text input hero area
                VStack(alignment: .leading, spacing: 10) {
                    Text("YOUR VISION OR GOAL")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(AscendTheme.textTertiary)
                    
                    ZStack(alignment: .topLeading) {
                        if userGoalPrompt.isEmpty {
                            Text("Describe what you want to achieve... (e.g. 'I want to land a full stack software engineering job in 4 months while maintaining a gym routine', 'Train for my first half marathon', 'Build and launch an iOS indie app')")
                                .font(.system(size: 14))
                                .foregroundColor(AscendTheme.textTertiary)
                                .padding(14)
                        }
                        
                        TextEditor(text: $userGoalPrompt)
                            .font(.system(size: 15))
                            .foregroundColor(AscendTheme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 110)
                            .padding(10)
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(AscendTheme.cardBackground))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AscendTheme.electricBlue.opacity(0.4), lineWidth: 1.2))
                    
                    // Quick Inspiration Pills
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NEED IDEAS? TAP TO FILL:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(AscendTheme.textTertiary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(inspirationPills, id: \.self) { pill in
                                    Button {
                                        userGoalPrompt = pill.replacingOccurrences(of: "^[^ ]+ ", with: "", options: .regularExpression)
                                        HapticService.shared.triggerImpact(.light)
                                    } label: {
                                        Text(pill)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(AscendTheme.textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(AscendTheme.cardBackground))
                                            .overlay(Capsule().stroke(AscendTheme.cardBorder, lineWidth: 1))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                    
                    // Target Timeline
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ESTIMATED TARGET TIMELINE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(AscendTheme.textTertiary)
                        
                        HStack(spacing: 10) {
                            timelineButton(label: "1 Month Sprint", months: 1)
                            timelineButton(label: "3 Months", months: 3)
                            timelineButton(label: "6 Months", months: 6)
                            timelineButton(label: "1 Year", months: 12)
                        }
                    }
                    .padding(.top, 8)
                }
            } else {
                // Manual Builder Mode
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MAIN QUEST TITLE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(AscendTheme.textTertiary)
                        
                        TextField("e.g. Master iOS Development & Ship 3 Apps", text: $planDraft.goalTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AscendTheme.textPrimary)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(AscendTheme.cardBackground))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AscendTheme.cardBorder, lineWidth: 1))
                    }
                    
                    HStack {
                        SectionHeader(title: "Sub Quests / Milestones", subtitle: "\(planDraft.subQuests.count) defined", icon: "flag.fill")
                        Spacer()
                        Button("+ Add Milestone") {
                            showingAddMilestone = true
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AscendTheme.electricBlue)
                    }
                    
                    if planDraft.subQuests.isEmpty {
                        GlassCard {
                            Text("No milestones added yet. Tap '+ Add Milestone' to add what all you want to do.")
                                .font(.system(size: 13))
                                .foregroundColor(AscendTheme.textSecondary)
                        }
                    } else {
                        ForEach(planDraft.subQuests) { sq in
                            HStack {
                                Image(systemName: "flag.fill").foregroundColor(AscendTheme.cyberCyan)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sq.title).font(.system(size: 14, weight: .bold)).foregroundColor(AscendTheme.textPrimary)
                                    Text(sq.description).font(.system(size: 12)).foregroundColor(AscendTheme.textSecondary)
                                }
                                Spacer()
                                Button {
                                    planDraft.subQuests.removeAll(where: { $0.id == sq.id })
                                } label: {
                                    Image(systemName: "trash").font(.system(size: 12)).foregroundColor(AscendTheme.textTertiary)
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(AscendTheme.cardBackground))
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func timelineButton(label: String, months: Int) -> some View {
        let isSelected = selectedTimelineMonths == months
        Button {
            selectedTimelineMonths = months
            HapticService.shared.triggerImpact(.light)
        } label: {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : AscendTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? AscendTheme.electricBlue : AscendTheme.cardBackground)
                )
        }
    }
    
    // MARK: - Step 2: Review, Approve or Request Changes
    
    @ViewBuilder
    private func renderStep2ReviewAndRefine() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PROPOSED QUEST BLUEPRINT")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(AscendTheme.cyberCyan)
                
                Text("Review & Customize Plan")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AscendTheme.textPrimary)
                
                Text("You're in complete control. Approve this plan, edit any items, or request adjustments below.")
                    .font(.system(size: 13))
                    .foregroundColor(AscendTheme.textSecondary)
                    .lineSpacing(3)
            }
            
            // Hero Main Quest Banner
            GlassCard(cornerRadius: 18, borderColor: AscendTheme.electricBlue) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("MAIN QUEST", systemImage: "crown.fill")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(AscendTheme.metallicGold)
                        Spacer()
                        Text(planDraft.category.displayName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AscendTheme.cyberCyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(AscendTheme.cyberCyan.opacity(0.15)))
                    }
                    
                    Text(planDraft.goalTitle)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AscendTheme.textPrimary)
                    
                    if !planDraft.goalDescription.isEmpty {
                        Text(planDraft.goalDescription)
                            .font(.system(size: 13))
                            .foregroundColor(AscendTheme.textSecondary)
                    }
                    
                    // Priority Distribution
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DAILY FOCUS ALLOCATION")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(AscendTheme.textTertiary)
                        
                        HStack {
                            Text("Primary: \(Int(planDraft.priorityAllocation.careerWeight * 100))%")
                                .foregroundColor(AscendTheme.electricBlue)
                            Spacer()
                            Text("Fitness: \(Int(planDraft.priorityAllocation.fitnessWeight * 100))%")
                                .foregroundColor(AscendTheme.energeticCoral)
                            Spacer()
                            Text("Self-Care: \(Int(planDraft.priorityAllocation.selfCareWeight * 100))%")
                                .foregroundColor(AscendTheme.cyberCyan)
                        }
                        .font(.system(size: 11, weight: .medium))
                    }
                }
            }
            
            // Request Changes Box (Prominent User Control)
            GlassCard(cornerRadius: 16, borderColor: AscendTheme.metallicGold) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(AscendTheme.metallicGold)
                        Text("Want adjustments? Request changes:")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(AscendTheme.textPrimary)
                    }
                    
                    HStack(spacing: 8) {
                        TextField("e.g. 'Add morning workout', 'More beginner friendly'...", text: $refinementRequest)
                            .font(.system(size: 14))
                            .foregroundColor(AscendTheme.textPrimary)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(AscendTheme.backgroundDark))
                        
                        Button {
                            applyRefinement()
                        } label: {
                            Text("Refine")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(AscendTheme.metallicGold))
                        }
                        .disabled(refinementRequest.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    
                    if let msg = refinementMessage {
                        Text(msg)
                            .font(.system(size: 12))
                            .foregroundColor(AscendTheme.cyberCyan)
                    }
                }
            }
            
            // Sub Quests List
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionHeader(title: "Sub Quests & Milestones", icon: "flag.fill")
                    Spacer()
                    Button("+ Add") {
                        showingAddMilestone = true
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AscendTheme.electricBlue)
                }
                
                ForEach(planDraft.subQuests) { sq in
                    GlassCard(cornerRadius: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(AscendTheme.primaryGradient.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(Image(systemName: "flag.fill").font(.system(size: 12)).foregroundColor(AscendTheme.cyberCyan))
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(sq.title)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(AscendTheme.textPrimary)
                                Text(sq.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(AscendTheme.textSecondary)
                                Text("🎯 Criteria: \(sq.completionConditionDescription)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(AscendTheme.textTertiary)
                            }
                            
                            Spacer()
                            
                            Button {
                                planDraft.subQuests.removeAll(where: { $0.id == sq.id })
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AscendTheme.textTertiary)
                            }
                        }
                    }
                }
            }
            
            // Daily Starter Quests List
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionHeader(title: "Starter Daily Quests", icon: "checklist")
                    Spacer()
                    Button("+ Add") {
                        showingAddTask = true
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AscendTheme.electricBlue)
                }
                
                ForEach(planDraft.dailyQuests) { dq in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundColor(AscendTheme.electricBlue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dq.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AscendTheme.textPrimary)
                            Text("\(dq.estimatedDurationMinutes) mins • \(dq.priority.rawValue) Priority")
                                .font(.system(size: 11))
                                .foregroundColor(AscendTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            planDraft.dailyQuests.removeAll(where: { $0.id == dq.id })
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AscendTheme.textTertiary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AscendTheme.cardBackground))
                }
            }
            
            // Future Self Evolution Roadmap
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Future-Self Evolution Stages", subtitle: "Identity transformations unlocked via verified milestones", icon: "sparkles")
                
                ForEach(planDraft.futureSelfStages, id: \.id) { stage in
                    HStack(spacing: 12) {
                        Text("\(stage.stageIndex)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(AscendTheme.cyberCyan)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(AscendTheme.cardBorder))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stage.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AscendTheme.textPrimary)
                            Text(stage.tagline)
                                .font(.system(size: 11))
                                .foregroundColor(AscendTheme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AscendTheme.cardBackground.opacity(0.6)))
                }
            }
        }
    }
    
    // MARK: - Step 3: Daily Working Hours
    
    @ViewBuilder
    private func renderStep3AvailableHours() -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("READY FOR ASCENSION")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(AscendTheme.metallicGold)
                
                Text("Available Daily Focus")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AscendTheme.textPrimary)
                
                Text("How many hours can you realistically dedicate to focused effort each day?")
                    .font(.system(size: 13))
                    .foregroundColor(AscendTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            GlassCard(cornerRadius: 20) {
                VStack(spacing: 16) {
                    Text("\(Int(workingHours)) Hours / Day")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(AscendTheme.cyberCyan)
                    
                    Slider(value: $workingHours, in: 2.0...12.0, step: 0.5)
                        .tint(AscendTheme.electricBlue)
                    
                    Text("The deterministic daily planning engine will balance this time across your approved milestones, routines, and rest breaks.")
                        .font(.system(size: 13))
                        .foregroundColor(AscendTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleStep1Continue() {
        if inputMode == .smartGenerator {
            let prompt = userGoalPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            let effectivePrompt = prompt.isEmpty ? "Land a Software Engineering Job" : prompt
            
            Task {
                let generated = try? await LocalDeterministicAIService.shared.generateCustomPlan(
                    from: effectivePrompt,
                    timelineMonths: selectedTimelineMonths
                )
                await MainActor.run {
                    if let gen = generated {
                        self.planDraft = gen
                    }
                    withAnimation(.easeInOut) {
                        currentStep = 2
                    }
                    HapticService.shared.triggerImpact(.medium)
                }
            }
        } else {
            // Manual mode -> ensure title is set
            if planDraft.goalTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                planDraft.goalTitle = "My Custom Life Quest"
            }
            withAnimation(.easeInOut) {
                currentStep = 2
            }
            HapticService.shared.triggerImpact(.medium)
        }
    }
    
    private func applyRefinement() {
        let req = refinementRequest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !req.isEmpty else { return }
        
        Task {
            let updated = try? await LocalDeterministicAIService.shared.refinePlan(
                current: planDraft,
                request: req
            )
            await MainActor.run {
                if let up = updated {
                    self.planDraft = up
                    self.refinementMessage = up.explanation
                }
                self.refinementRequest = ""
                HapticService.shared.triggerNotification(.success)
            }
        }
    }
    
    private func finalizeAndEnterRealm() {
        let cleanName = playerName.trimmingCharacters(in: .whitespaces)
        store.state.avatar.name = cleanName.isEmpty ? "Traveler" : cleanName
        
        let mqId = UUID()
        let mainQuest = MainQuest(
            id: mqId,
            title: planDraft.goalTitle,
            description: planDraft.goalDescription,
            status: .active,
            priorityDistribution: planDraft.priorityAllocation
        )
        store.state.mainQuests = [mainQuest]
        
        // Convert SubQuest drafts to real SubQuests
        var realSubQuests: [SubQuest] = []
        for (idx, draft) in planDraft.subQuests.enumerated() {
            let prevId = idx > 0 ? realSubQuests[idx - 1].id : nil
            let sq = SubQuest(
                id: draft.id,
                mainQuestId: mqId,
                title: draft.title,
                description: draft.description,
                category: draft.category,
                prerequisiteSubQuestIds: (idx > 1 && prevId != nil) ? [prevId!] : [],
                completionCondition: .deliverableCompleted(deliverableName: draft.completionConditionDescription),
                orderIndex: idx,
                completionBonusXP: draft.completionBonusXP,
                linkedSkillIds: ["career_programming"]
            )
            realSubQuests.append(sq)
        }
        store.state.subQuests = realSubQuests
        
        // Convert DailyQuest drafts
        var realDailyQuests: [DailyQuest] = []
        for (idx, draft) in planDraft.dailyQuests.enumerated() {
            let linkedSqId = realSubQuests.indices.contains(idx) ? realSubQuests[idx].id : nil
            let dq = DailyQuest(
                name: draft.name,
                subQuestId: linkedSqId,
                category: draft.category,
                priority: draft.priority,
                estimatedDurationMinutes: draft.estimatedDurationMinutes
            )
            realDailyQuests.append(dq)
        }
        store.state.dailyQuests = realDailyQuests
        
        // Convert Side Habit drafts
        var realSideQuests: [SideQuest] = []
        for draft in planDraft.sideHabits {
            realSideQuests.append(SideQuest(
                title: draft.title,
                category: draft.category,
                xpPerCompletion: 30
            ))
        }
        store.state.sideQuests = realSideQuests
        
        // Create Future Self Roadmap
        var roadmapStages: [FutureSelfStage] = []
        for draft in planDraft.futureSelfStages {
            roadmapStages.append(FutureSelfStage(
                id: draft.id,
                stageIndex: draft.stageIndex,
                title: draft.title,
                tagline: draft.tagline,
                description: "Milestone: \(draft.milestoneRequirement)",
                requiredMilestones: [draft.milestoneRequirement],
                completedMilestones: draft.stageIndex == 1 ? [draft.milestoneRequirement] : [],
                isUnlocked: draft.stageIndex == 1,
                unlockedAt: draft.stageIndex == 1 ? Date() : nil
            ))
        }
        let roadmap = FutureSelfRoadmap(
            mainQuestId: mqId,
            finalVisionTitle: planDraft.goalTitle,
            finalVisionDescription: planDraft.goalDescription,
            stages: roadmapStages
        )
        store.state.futureSelfRoadmaps = [roadmap]
        
        // Generate initial Daily Plan
        let plan = PlanningEngine.shared.generateSuggestedPlan(
            availableHours: workingHours,
            in: store.state
        )
        store.state.dailyPlan = plan
        store.state.dailyPlan.isApprovedByUser = true
        
        store.state.isOnboarded = true
        store.saveImmediately()
        
        HapticService.shared.triggerNotification(.success)
    }
    
    // MARK: - Modals
    
    private var addMilestoneSheet: some View {
        NavigationStack {
            Form {
                TextField("Milestone Title (e.g. Deploy Live App)", text: $newMilestoneTitle)
                TextField("Description & Criteria", text: $newMilestoneDesc)
            }
            .navigationTitle("Add Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddMilestone = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let clean = newMilestoneTitle.trimmingCharacters(in: .whitespaces)
                        if !clean.isEmpty {
                            planDraft.subQuests.append(SubQuestDraft(
                                title: clean,
                                description: newMilestoneDesc,
                                completionConditionDescription: "Verified completion of \(clean)"
                            ))
                        }
                        newMilestoneTitle = ""
                        newMilestoneDesc = ""
                        showingAddMilestone = false
                    }
                    .disabled(newMilestoneTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private var addTaskSheet: some View {
        NavigationStack {
            Form {
                TextField("Task Name (e.g. Study 60 mins)", text: $newTaskName)
                Stepper("Duration: \(newTaskDuration) mins", value: $newTaskDuration, in: 15...180, step: 15)
            }
            .navigationTitle("Add Daily Starter Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddTask = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let clean = newTaskName.trimmingCharacters(in: .whitespaces)
                        if !clean.isEmpty {
                            planDraft.dailyQuests.append(DailyQuestDraft(
                                name: clean,
                                priority: .high,
                                estimatedDurationMinutes: newTaskDuration
                            ))
                        }
                        newTaskName = ""
                        showingAddTask = false
                    }
                    .disabled(newTaskName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
