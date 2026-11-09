import SwiftUI

public struct SkillNodeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let node: SkillNode
    @ObservedObject var store: AppDataStore
    
    private var currentNode: SkillNode {
        store.state.skillNodes.first(where: { $0.id == node.id }) ?? node
    }
    
    private var nodeState: SkillNodeState {
        SkillEngine.shared.state(for: currentNode, allNodes: store.state.skillNodes)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                ParticleFieldView(particleCount: 20)
                
                VStack(alignment: .leading, spacing: 20) {
                    // Header Node Badge
                    GlassCard(cornerRadius: 18, borderColor: AscendTheme.electricBlue) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AscendTheme.primaryGradient.opacity(0.2))
                                    .frame(width: 56, height: 56)
                                Image(systemName: currentNode.iconName)
                                    .font(.system(size: 26))
                                    .foregroundColor(AscendTheme.cyberCyan)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(currentNode.name)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(AscendTheme.textPrimary)
                                    Spacer()
                                    Text(nodeState.rawValue)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(stateColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(stateColor.opacity(0.15)))
                                }
                                
                                Text("Tier \(currentNode.tier) • \(currentNode.category.displayName)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AscendTheme.textSecondary)
                            }
                        }
                    }
                    
                    // Description
                    SectionHeader(title: "Mastery Description", icon: "book.fill")
                    GlassCard {
                        Text(currentNode.description)
                            .font(.system(size: 14))
                            .foregroundColor(AscendTheme.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    // Progress & Level Up
                    SectionHeader(title: "Level Progression", icon: "chart.bar.fill")
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Level \(currentNode.currentLevel) / \(currentNode.maxLevel)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(AscendTheme.textPrimary)
                                Spacer()
                                Text("\(currentNode.xpContributed) XP Contributed")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(AscendTheme.cyberCyan)
                            }
                            
                            ProgressView(value: currentNode.progressRatio)
                                .tint(AscendTheme.electricBlue)
                            
                            if !currentNode.isMastered && nodeState != .locked {
                                Button {
                                    SkillEngine.shared.addXP(amount: 50, to: currentNode.id, in: &store.state)
                                    HapticService.shared.triggerNotification(.success)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                        Text("Practice Skill (+50 XP)")
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(AscendTheme.primaryGradient))
                                }
                                .padding(.top, 6)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Skill Node")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(AscendTheme.electricBlue)
                }
            }
        }
    }
    
    private var stateColor: Color {
        switch nodeState {
        case .locked: return AscendTheme.textTertiary
        case .available: return AscendTheme.metallicGold
        case .inProgress: return AscendTheme.electricBlue
        case .mastered: return AscendTheme.emeraldRecovery
        }
    }
}
