import SwiftUI

public struct OnboardingFlowView: View {
    @ObservedObject var store: AppDataStore
    
    @State private var currentStep = 0
    @State private var playerName = ""
    @State private var selectedGoalIndex = 0 // 0: Career Software Engineering Preset, 1: Fitness, 2: Custom
    @State private var customGoalTitle = ""
    @State private var workingHours: Double = 6.0
    
    let goalPresets = [
        "Land a Software Engineering Job (80% Career, 10% Fitness, 10% Self-Care)",
        "Reach Peak Physical Fitness & Athleticism",
        "Master a Creative Discipline / Learn a New Instrument",
        "Custom Vision / Build a Startup"
    ]
    
    public var body: some View {
        ZStack {
            AscendTheme.celestialSkybox.ignoresSafeArea()
            ParticleFieldView(particleCount: 35)
            
            VStack {
                // Header Step Indicator
                HStack(spacing: 8) {
                    ForEach(0..<4) { idx in
                        Rectangle()
                            .fill(idx <= currentStep ? AscendTheme.electricBlue : AscendTheme.cardBorder)
                            .frame(height: 4)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                Spacer()
                
                // Step Content
                switch currentStep {
                case 0:
                    renderStep0Welcome()
                case 1:
                    renderStep1Goal()
                case 2:
                    renderStep2QuestsPreview()
                case 3:
                    renderStep3Finalize()
                default:
                    EmptyView()
                }
                
                Spacer()
                
                // Navigation Button
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button {
                            currentStep -= 1
                            HapticService.shared.triggerImpact(.light)
                        } label: {
                            Text("Back")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AscendTheme.textSecondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                        }
                    }
                    
                    Spacer()
                    
                    GlowingButton(
                        title: currentStep == 3 ? "Enter the Realm" : "Continue",
                        icon: currentStep == 3 ? "sparkles" : "arrow.right"
                    ) {
                        advanceStep()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    @ViewBuilder
    private func renderStep0Welcome() -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AscendTheme.primaryGradient.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(Circle().stroke(AscendTheme.electricBlue.opacity(0.6), lineWidth: 2))
                
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 46))
                    .foregroundColor(AscendTheme.cyberCyan)
            }
            
            VStack(spacing: 8) {
                Text("WELCOME TO ASCEND")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(AscendTheme.electricBlue)
                
                Text("A Real-Life RPG")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(AscendTheme.textPrimary)
                
                Text("Your avatar represents who you are becoming.\nYour world represents the life you are building.")
                    .font(.system(size: 14))
                    .foregroundColor(AscendTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal)
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
            .padding(.horizontal, 24)
            .padding(.top, 10)
        }
    }
    
    @ViewBuilder
    private func renderStep1Goal() -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("DEFINE YOUR PRIME OBJECTIVE")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(AscendTheme.electricBlue)
                
                Text("Choose Your Main Quest")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AscendTheme.textPrimary)
                
                Text("Only one Main Quest is active at a time, keeping your daily focus sharp and unambiguous.")
                    .font(.system(size: 13))
                    .foregroundColor(AscendTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            VStack(spacing: 10) {
                ForEach(goalPresets.indices, id: \.self) { idx in
                    Button {
                        selectedGoalIndex = idx
                        HapticService.shared.triggerImpact(.light)
                    } label: {
                        GlassCard(
                            cornerRadius: 14,
                            borderColor: selectedGoalIndex == idx ? AscendTheme.electricBlue : AscendTheme.cardBorder
                        ) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(selectedGoalIndex == idx ? AscendTheme.electricBlue : AscendTheme.cardBorder.opacity(0.3))
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Circle().stroke(Color.white, lineWidth: selectedGoalIndex == idx ? 4 : 0)
                                    )
                                
                                Text(goalPresets[idx])
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(AscendTheme.textPrimary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func renderStep2QuestsPreview() -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("BLUEPRINT DECOMPOSITION")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(AscendTheme.electricBlue)
                
                Text("Generated Sub Quests")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AscendTheme.textPrimary)
                
                Text("We've broken down your chosen journey into verifiable milestones.")
                    .font(.system(size: 13))
                    .foregroundColor(AscendTheme.textSecondary)
            }
            .padding(.horizontal)
            
            VStack(spacing: 10) {
                GlassCard {
                    HStack(spacing: 12) {
                        Image(systemName: "hammer.fill").foregroundColor(AscendTheme.cyberCyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Build & Deploy Signature Portfolio").font(.system(size: 14, weight: .bold)).foregroundColor(AscendTheme.textPrimary)
                            Text("Full-stack deployed app with live authentication").font(.system(size: 11)).foregroundColor(AscendTheme.textSecondary)
                        }
                    }
                }
                
                GlassCard {
                    HStack(spacing: 12) {
                        Image(systemName: "network").foregroundColor(AscendTheme.electricBlue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Master 50 Core DSA Patterns").font(.system(size: 14, weight: .bold)).foregroundColor(AscendTheme.textPrimary)
                            Text("Array, Two Pointers, Trees, Graphs, DP").font(.system(size: 11)).foregroundColor(AscendTheme.textSecondary)
                        }
                    }
                }
                
                GlassCard {
                    HStack(spacing: 12) {
                        Image(systemName: "server.rack").foregroundColor(AscendTheme.deepViolet)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("System Design & Distributed Systems").font(.system(size: 14, weight: .bold)).foregroundColor(AscendTheme.textPrimary)
                            Text("Scalability, Caching, Databases, Microservices").font(.system(size: 11)).foregroundColor(AscendTheme.textSecondary)
                        }
                    }
                }
                
                GlassCard {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark").foregroundColor(AscendTheme.emeraldRecovery)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Resume Refinement & 30 Target Apps").font(.system(size: 14, weight: .bold)).foregroundColor(AscendTheme.textPrimary)
                            Text("STAR metrics, recruiter outreach, and mock interviews").font(.system(size: 11)).foregroundColor(AscendTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func renderStep3Finalize() -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("READY FOR ASCENSION")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(AscendTheme.metallicGold)
                
                Text("Available Daily Focus")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AscendTheme.textPrimary)
                
                Text("How many hours can you realistically dedicate to focused effort each day?")
                    .font(.system(size: 13))
                    .foregroundColor(AscendTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            GlassCard(cornerRadius: 18) {
                VStack(spacing: 12) {
                    Text("\(Int(workingHours)) Hours / Day")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AscendTheme.cyberCyan)
                    
                    Slider(value: $workingHours, in: 2.0...12.0, step: 0.5)
                        .tint(AscendTheme.electricBlue)
                    
                    Text("The deterministic planning engine will balance this time across your priority domains.")
                        .font(.system(size: 12))
                        .foregroundColor(AscendTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .padding(.horizontal)
        }
    }
    
    private func advanceStep() {
        if currentStep < 3 {
            currentStep += 1
            HapticService.shared.triggerImpact(.medium)
        } else {
            finalizeOnboarding()
        }
    }
    
    private func finalizeOnboarding() {
        let cleanName = playerName.trimmingCharacters(in: .whitespaces)
        store.state.avatar.name = cleanName.isEmpty ? "Traveler" : cleanName
        
        let mqId = UUID()
        let mqTitle = selectedGoalIndex == 0 ? "Land a Software Engineering Job" : (selectedGoalIndex == 1 ? "Reach Peak Physical Fitness" : "Master a Creative Discipline")
        
        let mainQuest = MainQuest(
            id: mqId,
            title: mqTitle,
            description: "Primary real-life transformation objective.",
            status: .active,
            priorityDistribution: PriorityAllocation(careerWeight: 0.8, fitnessWeight: 0.1, selfCareWeight: 0.1)
        )
        store.state.mainQuests = [mainQuest]
        
        // Add default Sub Quests
        let sub1 = SubQuest(
            mainQuestId: mqId,
            title: "Build & Deploy Signature Portfolio Project",
            description: "Production-grade deployed application with live DB and auth.",
            category: .career,
            completionCondition: .deliverableCompleted(deliverableName: "Deployed URL"),
            orderIndex: 0,
            completionBonusXP: 300,
            linkedSkillIds: ["career_programming"]
        )
        let sub2 = SubQuest(
            mainQuestId: mqId,
            title: "Master 50 Core DSA Patterns",
            description: "Array, sliding window, graphs, trees, and DP.",
            category: .career,
            prerequisiteSubQuestIds: [],
            completionCondition: .numericalTarget(target: 50, current: 0, unit: "problems"),
            orderIndex: 1,
            completionBonusXP: 350,
            linkedSkillIds: ["career_dsa"]
        )
        let sub3 = SubQuest(
            mainQuestId: mqId,
            title: "System Design & Distributed Architecture",
            description: "Scalability, caching, message queues, and mock architecture.",
            category: .career,
            prerequisiteSubQuestIds: [sub1.id],
            completionCondition: .milestoneReached(description: "5 Mock Designs"),
            orderIndex: 2,
            completionBonusXP: 300,
            linkedSkillIds: ["career_system_design"]
        )
        let sub4 = SubQuest(
            mainQuestId: mqId,
            title: "Resume Polish & 30 Targeted Applications",
            description: "STAR bullet points and high-fit outreach.",
            category: .career,
            prerequisiteSubQuestIds: [sub2.id],
            completionCondition: .numericalTarget(target: 30, current: 0, unit: "applications"),
            orderIndex: 3,
            completionBonusXP: 250,
            linkedSkillIds: ["career_interview_comm"]
        )
        store.state.subQuests = [sub1, sub2, sub3, sub4]
        
        // Add initial Daily Tasks
        store.state.dailyQuests = [
            DailyQuest(name: "Study System Design (Caching & Sharding)", category: .career, priority: .high, estimatedDurationMinutes: 90, subQuestId: sub3.id),
            DailyQuest(name: "Solve 3 Medium DSA Problems", category: .career, priority: .critical, estimatedDurationMinutes: 60, subQuestId: sub2.id),
            DailyQuest(name: "Implement Project Auth & API Routes", category: .career, priority: .high, estimatedDurationMinutes: 90, subQuestId: sub1.id),
            DailyQuest(name: "Full Body Resistance Workout", category: .fitness, priority: .medium, estimatedDurationMinutes: 45),
            DailyQuest(name: "Nighttime Skincare & Reading", category: .selfCare, priority: .low, estimatedDurationMinutes: 20)
        ]
        
        // Add Side Quests / Habits
        store.state.sideQuests = [
            SideQuest(title: "Hydration & Electrolytes (3L)", category: .selfCare, xpPerCompletion: 20),
            SideQuest(title: "Daily 30-Minute Movement / Walk", category: .fitness, xpPerCompletion: 30)
        ]
        
        // Setup Career Roadmap
        let roadmap = FutureSelfPresets.careerEngineeringRoadmap(mainQuestId: mqId)
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
}
