import SwiftUI

public enum NavigationTab: Int, CaseIterable, Identifiable {
    case world = 0
    case quests = 1
    case dailyPlan = 2
    case skills = 3
    case character = 4
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .world: return "World"
        case .quests: return "Quests"
        case .dailyPlan: return "Daily Plan"
        case .skills: return "Skills"
        case .character: return "Character"
        }
    }
    
    public var iconName: String {
        switch self {
        case .world: return "globe.americas.fill"
        case .quests: return "scroll.fill"
        case .dailyPlan: return "calendar.badge.clock"
        case .skills: return "network"
        case .character: return "person.crop.circle.fill"
        }
    }
}

public struct MainTabView: View {
    @ObservedObject var store: AppDataStore
    @State private var selectedTab: NavigationTab = .dailyPlan
    @State private var showingSettings = false
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                WorldView(store: store)
                    .tag(NavigationTab.world)
                
                QuestsView(store: store)
                    .tag(NavigationTab.quests)
                
                DailyPlanView(store: store)
                    .tag(NavigationTab.dailyPlan)
                
                SkillTreesView(store: store)
                    .tag(NavigationTab.skills)
                
                CharacterView(store: store)
                    .tag(NavigationTab.character)
            }
            .tint(AscendTheme.electricBlue)
            
            // Custom High-Tech Tab Bar Overlay
            HStack {
                ForEach(NavigationTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Spacer()
                    Button {
                        selectedTab = tab
                        HapticService.shared.triggerImpact(.light)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: isSelected ? 22 : 18, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? AscendTheme.electricBlue : AscendTheme.textTertiary)
                                .shadow(color: isSelected ? AscendTheme.electricBlue.opacity(0.5) : .clear, radius: 6)
                            
                            Text(tab.title)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundColor(isSelected ? AscendTheme.textPrimary : AscendTheme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AscendTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(AscendTheme.cardBorder.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.7), radius: 16, x: 0, y: 8)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay(alignment: .topTrailing) {
            Button {
                showingSettings = true
                HapticService.shared.triggerImpact(.light)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AscendTheme.textSecondary)
                    .padding(10)
                    .background(Circle().fill(AscendTheme.cardBackground))
                    .shadow(color: Color.black.opacity(0.4), radius: 4)
            }
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(store: store)
        }
    }
}
