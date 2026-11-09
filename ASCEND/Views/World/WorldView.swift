import SwiftUI

public struct WorldView: View {
    @ObservedObject var store: AppDataStore
    @State private var selectedRegion: WorldRegion?
    @State private var hoveredRegionId: String?
    
    private var activeMainQuest: MainQuest? {
        store.state.mainQuests.first(where: { $0.status == .active })
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.celestialSkybox.ignoresSafeArea()
                ParticleFieldView(particleCount: 40)
                
                VStack(spacing: 0) {
                    // World Status Header
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("THE ASCENDANT REALM")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(AscendTheme.electricBlue)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "globe.americas.fill")
                                    .foregroundColor(AscendTheme.metallicGold)
                                Text(activeMainQuest?.title ?? "No Active Quest")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(AscendTheme.textPrimary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // Total Realm Illumination Ring
                        HStack(spacing: 8) {
                            ZStack {
                                StatRing(
                                    progress: store.state.worldState.totalIllumination,
                                    lineWidth: 4,
                                    gradient: AscendTheme.primaryGradient
                                )
                                .frame(width: 34, height: 34)
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AscendTheme.cyberCyan)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(Int(store.state.worldState.totalIllumination * 100))%")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(AscendTheme.textPrimary)
                                Text("Aura")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(AscendTheme.textSecondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(AscendTheme.cardBackground))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    
                    // Main Interactive World Canvas
                    GeometryReader { geometry in
                        let w = geometry.size.width
                        let h = geometry.size.height
                        
                        ZStack {
                            // 1. Background Leyline Glow Bridges (Canvas)
                            Canvas { context, size in
                                let centerIsland = CGPoint(x: size.width * 0.5, y: size.height * 0.42)
                                let fitnessIsland = CGPoint(x: size.width * 0.22, y: size.height * 0.75)
                                let selfCareIsland = CGPoint(x: size.width * 0.78, y: size.height * 0.75)
                                
                                var path = Path()
                                path.move(to: centerIsland)
                                path.addLine(to: fitnessIsland)
                                path.move(to: centerIsland)
                                path.addLine(to: selfCareIsland)
                                
                                // Glowing Bridge Stroke
                                context.stroke(
                                    path,
                                    with: .linearGradient(
                                        Gradient(colors: [AscendTheme.electricBlue.opacity(0.8), AscendTheme.deepViolet.opacity(0.4)]),
                                        startPoint: centerIsland,
                                        endPoint: fitnessIsland
                                    ),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 6])
                                )
                            }
                            
                            // 2. Render World Regions
                            ForEach(store.state.worldState.regions) { region in
                                let posX = region.islandCenterX * w
                                let posY = region.islandCenterY * h
                                
                                Button {
                                    HapticService.shared.triggerImpact(.light)
                                    selectedRegion = region
                                } label: {
                                    ZStack {
                                        // Ambient Glow
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [Color(hex: region.themeColorHex).opacity(0.35 * region.illuminationLevel), Color.clear],
                                                    center: .center,
                                                    startRadius: 10,
                                                    endRadius: region.islandRadius
                                                )
                                            )
                                            .frame(width: region.islandRadius * 2, height: region.islandRadius * 2)
                                        
                                        // Floating Island Base
                                        Circle()
                                            .fill(AscendTheme.worldIslandGradient)
                                            .frame(width: region.islandRadius * 1.6, height: region.islandRadius * 1.6)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(
                                                        LinearGradient(
                                                            colors: [Color(hex: region.themeColorHex).opacity(0.6), Color.clear],
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        ),
                                                        lineWidth: 2
                                                    )
                                            )
                                            .shadow(color: Color.black.opacity(0.6), radius: 12, x: 0, y: 8)
                                        
                                        // Content within Island
                                        VStack(spacing: 4) {
                                            if region.regionType == .careerKingdom {
                                                // Center Island Avatar Indicator
                                                ZStack {
                                                    Circle()
                                                        .fill(AscendTheme.primaryGradient)
                                                        .frame(width: 38, height: 38)
                                                        .shadow(color: AscendTheme.electricBlue, radius: 8)
                                                    Image(systemName: "person.fill")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 18, weight: .bold))
                                                }
                                            }
                                            
                                            Text(region.name)
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .foregroundColor(AscendTheme.textPrimary)
                                                .multilineTextAlignment(.center)
                                                .shadow(color: .black, radius: 3)
                                            
                                            HStack(spacing: 4) {
                                                Image(systemName: "sun.max.fill")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.yellow)
                                                Text("\(Int(region.illuminationLevel * 100))%")
                                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                                    .foregroundColor(AscendTheme.textSecondary)
                                            }
                                        }
                                        .padding(8)
                                    }
                                }
                                .buttonStyle(.plain)
                                .position(x: posX, y: posY)
                            }
                        }
                    }
                    
                    // Bottom Realm Carousel
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SELECT REALM TO INSPECT")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(AscendTheme.textTertiary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(store.state.worldState.regions) { region in
                                    Button {
                                        HapticService.shared.triggerImpact(.light)
                                        selectedRegion = region
                                    } label: {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(Color(hex: region.themeColorHex).opacity(0.2))
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Image(systemName: region.regionType == .careerKingdom ? "sparkles" : (region.regionType == .fitnessGrounds ? "flame.fill" : "leaf.fill"))
                                                        .foregroundColor(Color(hex: region.themeColorHex))
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(region.name)
                                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                                    .foregroundColor(AscendTheme.textPrimary)
                                                Text("\(region.structures.filter { $0.isUnlocked }.count)/\(region.structures.count) Structures")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(AscendTheme.textSecondary)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AscendTheme.cardBackground)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color(hex: region.themeColorHex).opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedRegion) { region in
                RegionDetailSheet(region: region, store: store)
            }
        }
    }
}
