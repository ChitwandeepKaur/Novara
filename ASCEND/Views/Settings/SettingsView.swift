import SwiftUI
import UniformTypeIdentifiers

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppDataStore
    
    @State private var showingOnlineServices = false
    @State private var showingExportSheet = false
    @State private var exportedJSONString = ""
    @State private var showingBackupFile = false
    @State private var showingBackupExport = false
    @State private var showingRestoreConfirmation = false
    @State private var showingImportAlert = false
    @State private var importInputString = ""
    @State private var showingResetConfirmation = false
    @State private var statusMessage: String?
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                
                Form {
                    Section {
                        FairyRealmBanner(name: store.state.avatar.name)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                        fairyProgress
                        ForEach(FairyPalette.allCases) { palette in
                            Button {
                                store.state.selectedFairy = palette
                                HapticService.shared.triggerImpact(.light)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: palette.symbol)
                                        .font(.system(size: 19, weight: .light))
                                        .foregroundColor(Color(hex: palette.accent))
                                        .frame(width: 38, height: 38)
                                        .background(Circle().fill(Color(hex: palette.accent).opacity(0.12)))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(palette.name).font(.system(.body, design: .serif))
                                            .foregroundColor(AscendTheme.textPrimary)
                                        Text(palette.element).font(.caption).foregroundColor(AscendTheme.textSecondary)
                                        Text(palette.designDetails)
                                            .font(.caption2).foregroundColor(AscendTheme.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text(palette.isUnlocked(totalXP: store.state.avatar.totalCumulativeXP)
                                             ? (palette == .flora ? "Starting fairy" : "Unlocked at \(palette.requiredXP.formatted()) XP")
                                             : "Unlock at \(palette.requiredXP.formatted()) XP")
                                            .font(.caption2).foregroundColor(AscendTheme.textSecondary)
                                    }
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Circle().fill(Color(hex: palette.accent)).frame(width: 9, height: 9)
                                        Circle().fill(Color(hex: palette.secondary)).frame(width: 9, height: 9)
                                    }
                                    Image(systemName: !palette.isUnlocked(totalXP: store.state.avatar.totalCumulativeXP) ? "lock.fill" : (store.state.selectedFairy == palette ? "checkmark.circle.fill" : "circle"))
                                        .foregroundColor(FairyAppearance.shared.selected == palette ? Color(hex: palette.accent) : AscendTheme.textTertiary)
                                }
                                .padding(.vertical, 3)
                                .contentShape(Rectangle())
                            }
                            .disabled(!palette.isUnlocked(totalXP: store.state.avatar.totalCumulativeXP))
                            .opacity(palette.isUnlocked(totalXP: store.state.avatar.totalCumulativeXP) ? 1 : 0.55)
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(palette.name), \(palette.element)")
                            .accessibilityAddTraits(FairyAppearance.shared.selected == palette ? [.isSelected] : [])
                        }
                    } header: {
                        Text("Your fairy journey")
                    } footer: {
                        Text("Start as Flora. Every 10,000 lifetime XP unlocks and equips the next fairy. You can switch back to any unlocked fairy. All XP sources contribute, including the 75 day challenge. Your choice is included in backups.")
                    }
                    .listRowBackground(AscendTheme.cardBackground)

                    Section("Connections") {
                        Button("Cloud sync and free planning", systemImage: "network") { showingOnlineServices = true }
                    }.listRowBackground(AscendTheme.cardBackground)

                    Section("Backups and saved progress") {
                        if let error = store.storageError {
                            Text(error).font(.footnote).foregroundStyle(AscendTheme.energeticCoral)
                            Button(store.recoveryRequired ? "Retry opening save" : "Retry save") {
                                if store.recoveryRequired { store.retryRecovery() } else { store.saveImmediately() }
                            }
                        }
                        if let date = store.lastSavedAt {
                            Text("Last saved: \(date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundStyle(AscendTheme.textSecondary)
                        }
                        Text("Novara keeps your progress and a previous good copy on this device. Export a JSON backup to Files for a separate copy. Configure optional cloud sync in Cloud sync.")
                            .font(.footnote).foregroundStyle(AscendTheme.textSecondary)
                        Button("Save JSON backup to Files", systemImage: "square.and.arrow.up") {
                            if let json = store.exportJSON() { exportedJSONString = json; showingBackupExport = true }
                        }.disabled(store.recoveryRequired)
                        Button("Restore JSON backup from Files", systemImage: "square.and.arrow.down") {
                            showingBackupFile = true
                        }
                        if let message = statusMessage {
                            Text(message).font(.footnote).foregroundStyle(AscendTheme.textSecondary)
                        }
                        Button {
                            exportData()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .foregroundColor(AscendTheme.electricBlue)
                                Text("Export All Data (JSON)")
                                    .foregroundColor(AscendTheme.textPrimary)
                            }
                        }.disabled(store.recoveryRequired)
                        
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
                    
                    Section("Focus reminders and feedback") {
                        Text("Allow notifications for a reminder when a focus session ends, including while your phone is locked. The timer still tracks time if reminders are off.")
                            .font(.footnote).foregroundStyle(AscendTheme.textSecondary)
                        Button("Open notification settings", systemImage: "bell.badge") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
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
                    
                    Section("About Novara") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0 (Native iOS 17+)")
                                .foregroundColor(AscendTheme.textSecondary)
                        }
                        
                        HStack {
                            Text("Storage")
                            Spacer()
                            Text("Local saves and JSON backups")
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
                    if store.resetAllData() { dismiss() }
                    else { statusMessage = store.storageError }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all local quests, XP, avatar unlocks, and world progress.")
            }
            .sheet(isPresented: $showingOnlineServices) { OnlineServicesSheet(store: store) }
            .fileExporter(isPresented: $showingBackupExport,
                          document: NovaraBackupDocument(text: exportedJSONString),
                          contentType: .json, defaultFilename: "Novara-Backup-\(Date().formatted(.iso8601.year().month().day()))") { result in
                switch result {
                case .success: statusMessage = "Backup exported. Keep this file somewhere separate from the app."
                case .failure(let error): statusMessage = "Backup export failed: \(error.localizedDescription)"
                }
            }
            .fileImporter(isPresented: $showingBackupFile, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 20_000_000 else {
                        statusMessage = "This backup is too large to open. Choose a Novara JSON backup under 20 MB."
                        return
                    }
                    importInputString = try String(contentsOf: url, encoding: .utf8)
                    showingRestoreConfirmation = true
                } catch { statusMessage = "Could not open backup: \(error.localizedDescription)" }
            }
            .alert("Restore this backup?", isPresented: $showingRestoreConfirmation) {
                Button("Restore backup", role: .destructive) { performImport() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This replaces your current progress with the selected backup. Novara will preserve the previous save separately.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(items: [exportedJSONString])
            }
        }
    }
    
    private var fairyProgress: some View {
        let totalXP = store.state.avatar.totalCumulativeXP
        let highest = FairyPalette.highestUnlocked(totalXP: totalXP)
        let next = FairyPalette.nextUnlock(totalXP: totalXP)
        return VStack(alignment: .leading, spacing: 8) {
            Text("\((store.state.selectedFairy ?? .flora).name) fairy")
                .font(.system(.title3, design: .serif))
            Text("\(totalXP.formatted()) lifetime XP")
                .font(.caption).foregroundColor(AscendTheme.textSecondary)
            if let next {
                ProgressView(value: Double(max(0, totalXP - highest.requiredXP)), total: 10_000)
                    .tint(AscendTheme.electricBlue)
                Text("\((next.requiredXP - totalXP).formatted()) XP to unlock \(next.name)")
                    .font(.caption).foregroundColor(AscendTheme.textSecondary)
            } else {
                Label("All six fairies unlocked", systemImage: "sparkles")
                    .font(.caption).foregroundColor(AscendTheme.metallicGold)
            }
        }.padding(.vertical, 8)
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
        case .failure(let error):
            statusMessage = "Restore failed: \(error.localizedDescription)"
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

public struct NovaraBackupDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.json] }
    public var text: String
    public init(text: String) { self.text = text }
    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = text
    }
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
