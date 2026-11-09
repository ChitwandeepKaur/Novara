import SwiftUI

public struct SkillTreesView: View {
    @ObservedObject var store: AppDataStore
    
    @State private var selectedCategory: QuestCategory = .career
    @State private var selectedNode: SkillNode?
    
    private var filteredNodes: [SkillNode] {
        store.state.skillNodes.filter { $0.category == selectedCategory }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                ParticleFieldView(particleCount: 25)
                
                VStack(spacing: 0) {
                    // Category Picker Tabs
                    HStack(spacing: 8) {
                        categoryTabButton(title: "Career", category: .career, icon: "briefcase.fill")
                        categoryTabButton(title: "Fitness", category: .fitness, icon: "dumbbell.fill")
                        categoryTabButton(title: "Self-Care", category: .selfCare, icon: "sparkles")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Tree Overview Banner
                            GlassCard {
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(AscendTheme.primaryGradient.opacity(0.2))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: selectedCategory.iconName)
                                                .foregroundColor(AscendTheme.cyberCyan)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(selectedCategory.displayName) Skill Tree")
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                            .foregroundColor(AscendTheme.textPrimary)
                                        
                                        let masteredCount = filteredNodes.filter { $0.isMastered }.count
                                        Text("\(masteredCount) of \(filteredNodes.count) Nodes Mastered")
                                            .font(.system(size: 12))
                                            .foregroundColor(AscendTheme.textSecondary)
                                    }
                                }
                            }
                            
                            // Visual Node List / Graph
                            SectionHeader(
                                title: "Skill Matrix & Progression",
                                subtitle: "Complete tasks to unlock higher tiers",
                                icon: "network"
                            )
                            
                            VStack(spacing: 12) {
                                ForEach(filteredNodes) { node in
                                    let nodeState = SkillEngine.shared.state(for: node, allNodes: store.state.skillNodes)
                                    
                                    Button {
                                        selectedNode = node
                                        HapticService.shared.triggerImpact(.light)
                                    } label: {
                                        GlassCard(cornerRadius: 14) {
                                            HStack(spacing: 14) {
                                                // Icon with Tier and State Styling
                                                ZStack {
                                                    Circle()
                                                        .fill(nodeColor(for: nodeState).opacity(0.18))
                                                        .frame(width: 44, height: 44)
                                                    
                                                    Image(systemName: node.iconName)
                                                        .font(.system(size: 20))
                                                        .foregroundColor(nodeColor(for: nodeState))
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack {
                                                        Text(node.name)
                                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                                            .foregroundColor(nodeState == .locked ? AscendTheme.textTertiary : AscendTheme.textPrimary)
                                                        Spacer()
                                                        Text("Tier \(node.tier)")
                                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                            .foregroundColor(AscendTheme.textTertiary)
                                                    }
                                                    
                                                    Text(node.description)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(AscendTheme.textSecondary)
                                                        .lineLimit(2)
                                                    
                                                    // Progress bar
                                                    HStack(spacing: 8) {
                                                        ProgressView(value: node.progressRatio)
                                                            .tint(nodeColor(for: nodeState))
                                                        Text("Lvl \(node.currentLevel)/\(node.maxLevel)")
                                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                                            .foregroundColor(AscendTheme.textSecondary)
                                                    }
                                                    .padding(.top, 2)
                                                }
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Skill Trees")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedNode) { node in
                SkillNodeDetailSheet(node: node, store: store)
            }
        }
    }
    
    @ViewBuilder
    private func categoryTabButton(title: String, category: QuestCategory, icon: String) -> some View {
        let isSelected = selectedCategory == category
        Button {
            selectedCategory = category
            HapticService.shared.triggerImpact(.light)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : AscendTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? AscendTheme.electricBlue : AscendTheme.cardBackground)
            )
        }
    }
    
    private func nodeColor(for state: SkillNodeState) -> Color {
        switch state {
        case .locked: return AscendTheme.textTertiary
        case .available: return AscendTheme.metallicGold
        case .inProgress: return AscendTheme.electricBlue
        case .mastered: return AscendTheme.emeraldRecovery
        }
    }
}
