import SwiftUI

public struct OnlineServicesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: AppDataStore
    @ObservedObject private var cloud = CloudSyncService.shared
    @State private var projectURL = CloudConfiguration.savedProjectURL
    @State private var publicKey = CloudConfiguration.savedPublicKey
    @State private var email = ""
    @State private var password = ""
    @State private var message: String?
    @State private var busy = false
    @State private var conflictChoice: Bool?
    @State private var confirmingConflict = false
    @State private var confirmingCloudRestore = false

    public var body: some View {
        NavigationStack {
            Form {
                Section("Cloud sync") {
                    Text("Syncs your full progress, including quests, challenge logs, XP, and fairy choice, to your own Supabase project. Local use works without signing in.")
                        .font(.footnote)
                    if !cloud.isSignedIn {
                        TextField("Supabase project URL", text: $projectURL)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                        TextField("Publishable or anon key", text: $publicKey, axis: .vertical)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        Button("Save project settings") {
                            do { try cloud.configure(url: projectURL, publicKey: publicKey); message = nil }
                            catch { message = error.localizedDescription }
                        }.disabled(busy)
                        TextField("Cloud account email", text: $email)
                            .textContentType(.emailAddress).keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        SecureField("Cloud account password", text: $password).textContentType(.password)
                        HStack {
                            Button("Sign in") { authenticate(createAccount: false) }
                            Spacer()
                            Button("Create cloud account") { authenticate(createAccount: true) }
                        }.disabled(!cloud.isConfigured || busy || cloud.isSyncing)
                        Text("The password is sent only to your configured Supabase project. Novara saves the session in Keychain, never your password. Confirm your email before signing in if the project requires it.")
                            .font(.caption)
                    } else {
                        Text("Signed in: \(cloud.accountEmail ?? "Cloud account")")
                        Toggle("Automatically sync progress", isOn: $cloud.enabled).disabled(store.recoveryRequired)
                        if store.recoveryRequired {
                            Button("Restore my saved cloud copy") { confirmingCloudRestore = true }
                                .disabled(cloud.isSyncing)
                        }
                        Text("Sync checks after saves and while the app is open. Changes made offline sync later. If both copies change, Novara asks which to keep.")
                            .font(.caption)
                        Button("Sync now") { Task { await cloud.sync(store: store) } }
                            .disabled(!cloud.enabled || cloud.isSyncing)
                        Button("Sign out on this device") {
                            do { try cloud.signOut() } catch { message = error.localizedDescription }
                        }.disabled(cloud.isSyncing)
                    }
                    Text(cloud.status).font(.footnote)
                    if cloud.hasConflict {
                        Text("Cloud copy: \(cloud.conflictXPDescription). This device: \(store.state.avatar.totalCumulativeXP.formatted()) lifetime XP. A separate local copy is kept before either version is replaced.")
                            .font(.footnote)
                        Button("Keep this device's progress") { conflictChoice = false; confirmingConflict = true }
                        Button("Use the cloud copy") { conflictChoice = true; confirmingConflict = true }
                    }
                    Link("Supabase project dashboard", destination: URL(string: "https://supabase.com/dashboard")!)
                }
                Section("Free planning") {
                    Text("Goal plans and mini quest breakdowns use editable templates on this device. No paid AI service, API key, or subscription is required.")
                    Text("Optional cloud sync uses your Supabase Free project. Free-tier limits or inactivity can interrupt sync; local progress and Files backups remain available. Novara cannot purchase upgrades.")
                        .font(.footnote)
                }
                if busy || cloud.isSyncing { ProgressView("Connecting...") }
                if let message { Section { Text(message).font(.footnote) } }
            }
            .navigationTitle("Cloud sync")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .confirmationDialog("Restore your cloud progress? The current local file will be preserved separately.", isPresented: $confirmingCloudRestore, titleVisibility: .visible) {
                Button("Restore cloud copy") { Task { await cloud.restoreFromCloud(store: store) } }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Use the selected progress copy? The other version will be preserved on this device.", isPresented: $confirmingConflict, titleVisibility: .visible) {
                Button("Use selected copy") {
                    if let useCloud = conflictChoice { Task { await cloud.resolveConflict(useCloud: useCloud, store: store) } }
                }
                Button("Cancel", role: .cancel) {}
            }
        }.preferredColorScheme(.dark)
    }
    private func authenticate(createAccount: Bool) {
        busy = true
        Task {
            defer { busy = false; password = "" }
            do { try await cloud.authenticate(email: email, password: password, createAccount: createAccount); message = nil }
            catch { message = error.localizedDescription }
        }
    }
}
