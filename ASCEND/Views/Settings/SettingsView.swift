import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppDataStore
    
    @State private var showingExportSheet = false
    @State private var exportedJSONString = ""
    @State private var showingImportAlert = false
    @State private var importInputString = ""
    @State private var showingResetConfirmation = false
    @State private var statusMessage: String?
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                
                Form {
                    Section("Privacy & Data Autonomy") {
                        Button {
                            exportData()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .foregroundColor(AscendTheme.electricBlue)
                                Text("Export All Data (JSON)")
                                    .foregroundColor(AscendTheme.textPrimary)
                            }
                        }
                        
                        Button {
                            showingImportAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .foregroundColor(AscendTheme.cyberCyan)
                                Text("Import / Restore Data")
                                    .foregroundColor(AscendTheme.textPrimary)
                            }
                        }
                        
                        Button(role: .destructive) {
                            showingResetConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                Text("Reset All Progress")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .listRowBackground(AscendTheme.cardBackground)
                    
                    Section("Sensory Feedback") {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(AscendTheme.cyberCyan)
                            Text("Haptic Feedback")
                                .foregroundColor(AscendTheme.textPrimary)
                            Spacer()
                            Text("Enabled")
                                .font(.system(size: 13))
                                .foregroundColor(AscendTheme.textSecondary)
                        }
                    }
                    .listRowBackground(AscendTheme.cardBackground)
                    
                    Section("About ASCEND") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0 (Native iOS 17+)")
                                .foregroundColor(AscendTheme.textSecondary)
                        }
                        
                        HStack {
                            Text("Architecture")
                            Spacer()
                            Text("SwiftUI • SwiftData / JSON Core")
                                .foregroundColor(AscendTheme.textSecondary)
                        }
                        
                        HStack {
                            Text("Philosophy")
                            Spacer()
                            Text("Offline-First • Anti-Guilt")
                                .foregroundColor(AscendTheme.textSecondary)
                        }
                    }
                    .listRowBackground(AscendTheme.cardBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AscendTheme.electricBlue)
                }
            }
            .alert("Import Data", isPresented: $showingImportAlert) {
                TextField("Paste JSON backup here", text: $importInputString)
                Button("Restore", role: .none) {
                    performImport()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Restoring from backup will replace your current local state.")
            }
            .alert("Confirm Reset", isPresented: $showingResetConfirmation) {
                Button("Wipe Everything", role: .destructive) {
                    store.resetAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all local quests, XP, avatar unlocks, and world progress.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(items: [exportedJSONString])
            }
        }
    }
    
    private func exportData() {
        if let json = store.exportJSON() {
            exportedJSONString = json
            showingExportSheet = true
            HapticService.shared.triggerNotification(.success)
        }
    }
    
    private func performImport() {
        let result = store.importJSON(importInputString)
        switch result {
        case .success:
            HapticService.shared.triggerNotification(.success)
            dismiss()
        case .failure:
            HapticService.shared.triggerNotification(.error)
        }
    }
}

public struct ShareSheet: UIViewControllerRepresentable {
    public let items: [Any]
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
