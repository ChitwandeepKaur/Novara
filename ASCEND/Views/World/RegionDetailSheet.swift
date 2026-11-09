import SwiftUI

public struct RegionDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let region: WorldRegion
    @ObservedObject var store: AppDataStore
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                ParticleFieldView(particleCount: 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Region Header Banner
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(region.title.uppercased())
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: region.themeColorHex))
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "sun.max.fill")
                                        .foregroundColor(.yellow)
                                    Text("\(Int(region.illuminationLevel * 100))% Illuminated")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(AscendTheme.textPrimary)
                                }
                            }
                            
                            Text(region.name)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(AscendTheme.textPrimary)
                            
                            Text(region.description)
                                .font(.system(size: 14))
                                .foregroundColor(AscendTheme.textSecondary)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AscendTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: region.themeColorHex).opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        // Regional Structures
                        SectionHeader(
                            title: "Realm Structures & Monuments",
                            subtitle: "Evolves with your real-life mastery",
                            icon: "building.columns.fill"
                        )
                        
                        VStack(spacing: 12) {
                            ForEach(region.structures) { structure in
                                GlassCard {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: region.themeColorHex).opacity(structure.isUnlocked ? 0.2 : 0.05))
                                                .frame(width: 48, height: 48)
                                            Image(systemName: structure.iconName)
                                                .font(.system(size: 22))
                                                .foregroundColor(structure.isUnlocked ? Color(hex: region.themeColorHex) : AscendTheme.textTertiary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(structure.name)
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundColor(structure.isUnlocked ? AscendTheme.textPrimary : AscendTheme.textTertiary)
                                                Spacer()
                                                Text("Tier \(structure.tier)/\(structure.maxTier)")
                                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                                    .foregroundColor(Color(hex: region.themeColorHex))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 2)
                                                    .background(Capsule().fill(Color(hex: region.themeColorHex).opacity(0.15)))
                                            }
                                            
                                            Text(structure.subtitle)
                                                .font(.system(size: 12))
                                                .foregroundColor(AscendTheme.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Active Quests Contributing to this Region
                        SectionHeader(
                            title: "Active Regional Quests",
                            subtitle: "Work on these quests to increase realm illumination",
                            icon: "target"
                        )
                        
                        let relevantQuests = store.state.dailyQuests.filter { quest in
                            switch region.regionType {
                            case .careerKingdom: return quest.category == .career
                            case .fitnessGrounds: return quest.category == .fitness
                            case .selfCareSanctuary, .custom: return quest.category == .selfCare
                            }
                        }
                        
                        if relevantQuests.isEmpty {
                            GlassCard {
                                Text("No pending daily quests for this realm today. Add one from the Quests screen!")
                                    .font(.system(size: 14))
                                    .foregroundColor(AscendTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 8)
                            }
                        } else {
                            VStack(spacing: 10) {
                                ForEach(relevantQuests) { quest in
                                    HStack {
                                        Image(systemName: quest.status == .completed ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(quest.status == .completed ? AscendTheme.emeraldRecovery : AscendTheme.textTertiary)
                                        Text(quest.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(quest.status == .completed ? AscendTheme.textSecondary : AscendTheme.textPrimary)
                                            .strikethrough(quest.status == .completed)
                                        Spacer()
                                        XPBadge(amount: quest.xpReward, category: .effort)
                                    }
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 12).fill(AscendTheme.cardBackground))
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Realm Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AscendTheme.electricBlue)
                }
            }
        }
    }
}
