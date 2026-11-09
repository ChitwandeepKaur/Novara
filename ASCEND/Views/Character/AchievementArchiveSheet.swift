import SwiftUI

public struct AchievementArchiveSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppDataStore
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                ParticleFieldView(particleCount: 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "Hall of Accomplishments",
                            subtitle: "Milestones recorded across all your life quests",
                            icon: "trophy.fill"
                        )
                        
                        let achievements = store.state.achievements
                        ForEach(achievements) { ach in
                            GlassCard(cornerRadius: 14) {
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(ach.isUnlocked ? AscendTheme.metallicGold.opacity(0.2) : AscendTheme.cardBorder.opacity(0.3))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Image(systemName: ach.iconName)
                                                .font(.system(size: 22))
                                                .foregroundColor(ach.isUnlocked ? AscendTheme.metallicGold : AscendTheme.textTertiary)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(ach.title)
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundColor(ach.isUnlocked ? AscendTheme.textPrimary : AscendTheme.textTertiary)
                                            Spacer()
                                            if ach.isUnlocked {
                                                Image(systemName: "checkmark.seal.fill")
                                                    .foregroundColor(AscendTheme.metallicGold)
                                            }
                                        }
                                        
                                        Text(ach.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(AscendTheme.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievement Archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(AscendTheme.electricBlue)
                }
            }
        }
    }
}
