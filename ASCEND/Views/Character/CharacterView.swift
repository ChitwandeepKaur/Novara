import SwiftUI

public struct CharacterView: View {
    @ObservedObject var store: AppDataStore
    
    @State private var showingCustomizer = false
    @State private var showingAchievements = false
    @State private var selectedCosmeticSlot: CosmeticSlot = .outfit
    
    private var progressInfo: XPProgressInfo {
        XPEngine.shared.progressInfo(totalCumulativeXP: store.state.avatar.totalCumulativeXP)
    }
    
    private var activeRoadmap: FutureSelfRoadmap? {
        if let mq = store.state.mainQuests.first(where: { $0.status == .active }) {
            return store.state.futureSelfRoadmaps.first(where: { $0.mainQuestId == mq.id })
        }
        return store.state.futureSelfRoadmaps.first
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                ParticleFieldView(particleCount: 30)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Avatar Presentation Card
                        renderAvatarHeroCard()
                        
                        // Future-Self Roadmap
                        renderFutureSelfSection()
                        
                        // Cosmetic Equipment & Wardrobe
                        renderCosmeticsWardrobe()
                    }
                    .padding()
                }
            }
            .navigationTitle("Character Evolution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingAchievements = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                            Text("Vault")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(AscendTheme.metallicGold)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCustomizer = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Style")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(AscendTheme.cyberCyan)
                    }
                }
            }
            .sheet(isPresented: $showingCustomizer) {
                AvatarCustomizerSheet(store: store)
            }
            .sheet(isPresented: $showingAchievements) {
                AchievementArchiveSheet(store: store)
            }
        }
    }
    
    @ViewBuilder
    private func renderAvatarHeroCard() -> some View {
        GlassCard(cornerRadius: 20, borderColor: AscendTheme.electricBlue) {
            VStack(spacing: 16) {
                HStack(alignment: .center, spacing: 20) {
                    // Avatar Visualization with Ambient Aura
                    ZStack {
                        // Pulsing Aura Ring
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [AscendTheme.electricBlue.opacity(0.4), Color.clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 55
                                )
                            )
                            .frame(width: 90, height: 90)
                        
                        Circle()
                            .fill(AscendTheme.cardBackground)
                            .frame(width: 76, height: 76)
                            .overlay(Circle().stroke(AscendTheme.primaryGradient, lineWidth: 2))
                        
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 68, height: 68)
                            .foregroundColor(AscendTheme.cyberCyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.state.avatar.title.uppercased())
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(AscendTheme.metallicGold)
                        
                        Text(store.state.avatar.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AscendTheme.textPrimary)
                        
                        HStack(spacing: 8) {
                            Text("Level \(progressInfo.level)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(AscendTheme.electricBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(AscendTheme.electricBlue.opacity(0.15)))
                            
                            Text("\(store.state.avatar.totalCumulativeXP) Total XP")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(AscendTheme.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Level Progress Bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Next Level Progress")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AscendTheme.textTertiary)
                        Spacer()
                        Text("\(progressInfo.currentXP) / \(progressInfo.xpForNextLevel - progressInfo.xpForCurrentLevel) XP")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(AscendTheme.textSecondary)
                    }
                    
                    ProgressView(value: progressInfo.progressToNextLevel)
                        .tint(AscendTheme.electricBlue)
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderFutureSelfSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Future-Self Roadmap",
                subtitle: "Identity milestones required to evolve (distinct from XP)",
                icon: "sparkles"
            )
            
            if let roadmap = activeRoadmap {
                VStack(spacing: 12) {
                    ForEach(roadmap.stages) { stage in
                        GlassCard(cornerRadius: 14) {
                            HStack(alignment: .top, spacing: 14) {
                                Circle()
                                    .fill(stage.isUnlocked ? AscendTheme.metallicGold.opacity(0.2) : AscendTheme.cardBorder.opacity(0.4))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: stage.isUnlocked ? "crown.fill" : "lock.fill")
                                            .foregroundColor(stage.isUnlocked ? AscendTheme.metallicGold : AscendTheme.textTertiary)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Stage \(stage.stageIndex): \(stage.title)")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(stage.isUnlocked ? AscendTheme.textPrimary : AscendTheme.textSecondary)
                                        Spacer()
                                        if stage.isUnlocked {
                                            Text("Unlocked")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(AscendTheme.metallicGold)
                                        }
                                    }
                                    
                                    Text(stage.tagline)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AscendTheme.cyberCyan)
                                    
                                    Text(stage.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(AscendTheme.textSecondary)
                                        .lineSpacing(2)
                                    
                                    // Milestone Validation Button
                                    if !stage.isUnlocked {
                                        Button {
                                            for mId in stage.requiredMilestones {
                                                FutureSelfEngine.shared.recordMilestone(milestoneId: mId, roadmapId: roadmap.id, in: &store.state)
                                            }
                                            HapticService.shared.triggerNotification(.success)
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "sparkles")
                                                Text("Validate Milestones & Transform")
                                            }
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(AscendTheme.primaryGradient))
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                GlassCard {
                    Text("No Future-Self roadmap active. Assign one during Main Quest creation.")
                        .font(.system(size: 13))
                        .foregroundColor(AscendTheme.textSecondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func renderCosmeticsWardrobe() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Cosmetic Wardrobe & Artifacts",
                subtitle: "Unlockable through level milestones and achievements",
                icon: "shield.lefthalf.filled"
            )
            
            // Slot Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CosmeticSlot.allCases, id: \.self) { slot in
                        Button {
                            selectedCosmeticSlot = slot
                            HapticService.shared.triggerImpact(.light)
                        } label: {
                            Text(slot.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(selectedCosmeticSlot == slot ? .white : AscendTheme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(selectedCosmeticSlot == slot ? AscendTheme.electricBlue : AscendTheme.cardBackground)
                                )
                        }
                    }
                }
            }
            
            let itemsForSlot = store.state.cosmeticCatalogue.filter { $0.slot == selectedCosmeticSlot }
            VStack(spacing: 10) {
                ForEach(itemsForSlot) { item in
                    let isUnlocked = store.state.avatar.unlockedCosmeticIds.contains(item.id)
                    let isEquipped = store.state.avatar.equippedCosmeticIds[item.slot.rawValue] == item.id
                    
                    GlassCard(cornerRadius: 12) {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(isUnlocked ? Color(hex: item.rarity.glowColorHex).opacity(0.2) : AscendTheme.cardBorder.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: item.iconName)
                                        .foregroundColor(isUnlocked ? Color(hex: item.rarity.glowColorHex) : AscendTheme.textTertiary)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(item.name)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(isUnlocked ? AscendTheme.textPrimary : AscendTheme.textTertiary)
                                    Spacer()
                                    Text(item.rarity.rawValue)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(hex: item.rarity.glowColorHex))
                                }
                                
                                Text(item.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(AscendTheme.textSecondary)
                                    .lineLimit(2)
                            }
                            
                            if isUnlocked {
                                Button {
                                    store.state.avatar.equippedCosmeticIds[item.slot.rawValue] = item.id
                                    if item.slot == .title {
                                        store.state.avatar.title = item.name
                                    }
                                    HapticService.shared.triggerImpact(.medium)
                                } label: {
                                    Text(isEquipped ? "Equipped" : "Equip")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(isEquipped ? AscendTheme.emeraldRecovery : AscendTheme.electricBlue)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Capsule().stroke(isEquipped ? AscendTheme.emeraldRecovery : AscendTheme.electricBlue, lineWidth: 1))
                                }
                            } else {
                                Text("Lvl \(item.requiredLevel)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AscendTheme.textTertiary)
                            }
                        }
                    }
                }
            }
        }
    }
}
