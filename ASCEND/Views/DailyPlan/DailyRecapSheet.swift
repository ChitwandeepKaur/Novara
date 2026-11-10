import SwiftUI

public struct DailyRecapSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppDataStore
    
    private var todayEffortXP: Int {
        XPEngine.shared.effortXPEarnedToday(in: store.state)
    }
    
    private var completedTasksCount: Int {
        store.state.dailyQuests.filter { $0.status == .completed }.count
    }
    
    private var pendingTasksCount: Int {
        store.state.dailyQuests.filter { $0.status != .completed && $0.status != .archived }.count
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                ParticleFieldView(particleCount: 25)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Hero Celebration Card
                        GlassCard(cornerRadius: 18, borderColor: AscendTheme.metallicGold) {
                            VStack(spacing: 12) {
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(AscendTheme.metallicGold)
                                
                                Text("Evening Reflection")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(AscendTheme.textPrimary)
                                
                                Text("Every focused minute moves your life realm forward. Celebrate the steps you took today. Tomorrow will build upon them.")
                                    .font(.system(size: 13))
                                    .foregroundColor(AscendTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Summary Metrics
                        HStack(spacing: 12) {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Effort XP Today")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AscendTheme.textTertiary)
                                    Text("+\(todayEffortXP)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(AscendTheme.cyberCyan)
                                }
                            }
                            
                            GlassCard {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tasks Shipped")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AscendTheme.textTertiary)
                                    Text("\(completedTasksCount)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(AscendTheme.emeraldRecovery)
                                }
                            }
                            
                            GlassCard {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("In Flight")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AscendTheme.textTertiary)
                                    Text("\(pendingTasksCount)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(AscendTheme.electricBlue)
                                }
                            }
                        }
                        
                        // Completed Quests
                        SectionHeader(title: "Accomplished Today", icon: "checkmark.circle.fill")
                        let completedTasks = store.state.dailyQuests.filter { $0.status == .completed }
                        if completedTasks.isEmpty {
                            GlassCard {
                                Text("No tasks marked complete today yet. Deep effort still counts toward your progression!")
                                    .font(.system(size: 13))
                                    .foregroundColor(AscendTheme.textSecondary)
                            }
                        } else {
                            VStack(spacing: 8) {
                                ForEach(completedTasks) { task in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AscendTheme.emeraldRecovery)
                                        Text(task.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AscendTheme.textPrimary)
                                        Spacer()
                                        XPBadge(amount: task.xpReward, category: .effort)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(AscendTheme.cardBackground))
                                }
                            }
                        }
                        
                        // Non-punitive Tomorrow Prep
                        SectionHeader(title: "Prepared for Tomorrow", subtitle: "Carrying your momentum forward with zero guilt", icon: "sunrise.fill")
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your active quest roadmap and skills remain preserved. Get a good night's rest to replenish your focus mana.")
                                    .font(.system(size: 13))
                                    .foregroundColor(AscendTheme.textSecondary)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Daily Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Rest & Close") { dismiss() }
                        .foregroundColor(AscendTheme.electricBlue)
                }
            }
        }
    }
}
