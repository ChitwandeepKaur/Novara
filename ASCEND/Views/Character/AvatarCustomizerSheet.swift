import SwiftUI

public struct AvatarCustomizerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppDataStore
    
    let skinTones = ["#FFDFBF", "#F3B28A", "#D18659", "#945633", "#4A2A18"]
    let hairColors = ["#1A1A1A", "#8B4513", "#D4AF37", "#9B51E0", "#00D2FF"]
    let hairStyles = ["Short Sleek", "Wavy Mane", "Top Knot", "Cyber Buzz", "Long Flow"]
    let outfits = ["Apprentice Robes", "Cyber-Monk Vestments", "Grand Architect Coat"]
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Avatar Live Preview
                    FairyAvatar(profile: store.state.avatar)
                        .frame(width: 140, height: 145)
                    .padding(.top, 10)
                    
                    Form {
                        Section("Skin Tone") {
                            HStack(spacing: 12) {
                                ForEach(skinTones.indices, id: \.self) { idx in
                                    Circle()
                                        .fill(Color(hex: skinTones[idx]))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle().stroke(Color.white, lineWidth: store.state.avatar.skinToneIndex == idx ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            store.state.avatar.skinToneIndex = idx
                                            HapticService.shared.triggerImpact(.light)
                                        }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(AscendTheme.cardBackground)
                        
                        Section("Hairstyle") {
                            Picker("Hairstyle", selection: $store.state.avatar.hairStyleIndex) {
                                ForEach(hairStyles.indices, id: \.self) { idx in
                                    Text(hairStyles[idx]).tag(idx)
                                }
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(hairColors.indices, id: \.self) { idx in
                                    Circle()
                                        .fill(Color(hex: hairColors[idx]))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle().stroke(Color.white, lineWidth: store.state.avatar.hairColorIndex == idx ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            store.state.avatar.hairColorIndex = idx
                                            HapticService.shared.triggerImpact(.light)
                                        }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(AscendTheme.cardBackground)
                        
                        Section("Apparel & Robes") {
                            Picker("Outfit", selection: $store.state.avatar.outfitIndex) {
                                ForEach(outfits.indices, id: \.self) { idx in
                                    Text(outfits[idx]).tag(idx)
                                }
                            }
                        }
                        .listRowBackground(AscendTheme.cardBackground)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Customize Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AscendTheme.electricBlue)
                }
            }
        }
    }
}
