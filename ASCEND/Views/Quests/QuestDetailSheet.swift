import SwiftUI

public struct QuestDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let questId: UUID
    let isSubQuest: Bool
    @ObservedObject var store: AppDataStore
    
    @State private var showingAddEvidenceSheet = false
    @State private var evidenceTitle = ""
    @State private var evidenceContent = ""
    @State private var evidenceType: EvidenceType = .url
    
    private var subQuest: SubQuest? {
        store.state.subQuests.first(where: { $0.id == questId })
    }
    
    private var dailyQuest: DailyQuest? {
        store.state.dailyQuests.first(where: { $0.id == questId })
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                ParticleFieldView(particleCount: 15)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let sq = subQuest {
                            renderSubQuestDetail(sq)
                        } else if let dq = dailyQuest {
                            renderDailyQuestDetail(dq)
                        } else {
                            Text("Quest not found.")
                                .foregroundColor(AscendTheme.textSecondary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(isSubQuest ? "Sub Quest Details" : "Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AscendTheme.electricBlue)
                }
            }
            .sheet(isPresented: $showingAddEvidenceSheet) {
                addEvidenceSheet
            }
        }
    }
    
    @ViewBuilder
    private func renderSubQuestDetail(_ sq: SubQuest) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Card
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(sq.category.displayName.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(AscendTheme.cyberCyan)
                        Spacer()
                        Text(sq.status.rawValue)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(sq.status == .completed ? AscendTheme.emeraldRecovery : AscendTheme.metallicGold)
                    }
                    
                    Text(sq.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AscendTheme.textPrimary)
                    
                    if !sq.description.isEmpty {
                        Text(sq.description)
                            .font(.system(size: 14))
                            .foregroundColor(AscendTheme.textSecondary)
                    }
                    
                    HStack {
                        XPBadge(amount: sq.completionBonusXP, category: .completionBonus)
                        Spacer()
                        if sq.status != .completed {
                            Button("Mark Complete") {
                                completeSubQuest(sq)
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(AscendTheme.primaryGradient))
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            // Completion Condition Card
            SectionHeader(title: "Completion Criteria", icon: "checkmark.seal.fill")
            GlassCard {
                HStack(spacing: 12) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 20))
                        .foregroundColor(AscendTheme.metallicGold)
                    Text(sq.completionCondition.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AscendTheme.textPrimary)
                }
            }
            
            // Optional Evidence Vault
            HStack {
                SectionHeader(title: "Evidence & Artifacts", subtitle: "Verify your craft without stress", icon: "paperclip")
                Spacer()
                Button("+ Add Evidence") {
                    showingAddEvidenceSheet = true
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AscendTheme.electricBlue)
            }
            
            let attachments = store.state.evidenceAttachments.filter { $0.questId == sq.id }
            if attachments.isEmpty {
                GlassCard {
                    Text("No evidence attached yet. You may attach GitHub repos, live deployments, certificates, or written notes.")
                        .font(.system(size: 13))
                        .foregroundColor(AscendTheme.textSecondary)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(attachments) { item in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: item.type.iconName)
                                        .foregroundColor(AscendTheme.cyberCyan)
                                    Text(item.title)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AscendTheme.textPrimary)
                                    Spacer()
                                    Text(item.type.rawValue)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(AscendTheme.textTertiary)
                                }
                                Text(item.content)
                                    .font(.system(size: 13))
                                    .foregroundColor(AscendTheme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderDailyQuestDetail(_ dq: DailyQuest) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(dq.category.displayName.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(AscendTheme.cyberCyan)
                        Spacer()
                        Text(dq.priority.rawValue)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AscendTheme.energeticCoral)
                    }
                    
                    Text(dq.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AscendTheme.textPrimary)
                    
                    if !dq.description.isEmpty {
                        Text(dq.description)
                            .font(.system(size: 14))
                            .foregroundColor(AscendTheme.textSecondary)
                    }
                    
                    HStack {
                        XPBadge(amount: dq.xpReward, category: .effort)
                        Spacer()
                        Text("Est: \(dq.estimatedDurationMinutes) mins")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AscendTheme.textSecondary)
                    }
                }
            }
        }
    }
    
    private func completeSubQuest(_ sq: SubQuest) {
        if let idx = store.state.subQuests.firstIndex(where: { $0.id == sq.id }) {
            store.state.subQuests[idx].status = .completed
            store.state.subQuests[idx].completedAt = Date()
            
            // Award Completion Bonus XP
            XPEngine.shared.awardCompletionBonusXP(
                amount: sq.completionBonusXP,
                questId: sq.id,
                questTitle: sq.title,
                in: &store.state
            )
            
            // Upgrade matching world structures
            WorldEngine.shared.recordQuestProgress(category: sq.category, in: &store.state)
            
            // Attribute to skill trees
            SkillEngine.shared.attributeQuestCompletion(
                category: sq.category,
                linkedSkillIds: sq.linkedSkillIds,
                xpAmount: sq.completionBonusXP,
                in: &store.state
            )
            
            HapticService.shared.triggerNotification(.success)
        }
    }
    
    private var addEvidenceSheet: some View {
        NavigationStack {
            Form {
                Picker("Evidence Type", selection: $evidenceType) {
                    ForEach(EvidenceType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                TextField("Title (e.g. GitHub Repository, Certificate)", text: $evidenceTitle)
                TextField("URL or Reflection Notes", text: $evidenceContent, axis: .vertical)
                    .lineLimit(3...5)
            }
            .navigationTitle("Attach Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddEvidenceSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Attach") {
                        let newEvidence = EvidenceAttachment(
                            questId: questId,
                            type: evidenceType,
                            title: evidenceTitle.isEmpty ? "Evidence Artifact" : evidenceTitle,
                            content: evidenceContent
                        )
                        store.state.evidenceAttachments.append(newEvidence)
                        showingAddEvidenceSheet = false
                    }
                    .disabled(evidenceContent.isEmpty)
                }
            }
        }
    }
}
