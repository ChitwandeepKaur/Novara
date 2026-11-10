import SwiftUI
import UIKit

public struct ContentView: View {
    @ObservedObject var store: AppDataStore = AppDataStore.shared
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var cloud = CloudSyncService.shared
    @State private var showingRecoverySettings = false

    public init(store: AppDataStore = AppDataStore.shared) { self.store = store }

    public var body: some View {
        Group {
            if store.recoveryRequired {
                ContentUnavailableView {
                    Label("Your progress needs attention", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text(store.storageError ?? "Novara has preserved your files. Restore a backup to continue.")
                } actions: {
                    Button("Retry opening save") { store.retryRecovery() }
                    Button("Open backup settings") { showingRecoverySettings = true }
                }
                .background(AscendTheme.backgroundDark)
            } else if store.state.isOnboarded {
                MainTabView(store: store)
            } else {
                OnboardingFlowView(store: store)
            }
        }
        .preferredColorScheme(.dark)
        .safeAreaInset(edge: .top, spacing: 0) {
            if !store.recoveryRequired, let message = store.storageError ?? store.recoveryNotice {
                VStack(alignment: .leading, spacing: 6) {
                    Label(message, systemImage: store.storageError == nil ? "arrow.counterclockwise.circle" : "exclamationmark.triangle")
                        .font(.footnote)
                    HStack {
                        if store.storageError != nil {
                            Button("Retry save") { store.saveImmediately() }
                            Button("Backup settings") { showingRecoverySettings = true }
                        } else {
                            Button("Got it") { store.dismissRecoveryNotice() }
                        }
                    }.font(.footnote.bold())
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(AscendTheme.textPrimary)
                .background(AscendTheme.cardBackground)
            }
        }
        .sheet(isPresented: $showingRecoverySettings) { SettingsView(store: store) }
        .onChange(of: store.state.selectedFairy, initial: true) { _, fairy in
            FairyAppearance.shared.apply(fairy ?? .flora)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                if store.recoveryRequired { store.retryRecovery() }
                finishExpiredFocus()
                Task { await cloud.sync(store: store) }
            } else {
                store.saveImmediately()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification)) { _ in
            if store.recoveryRequired { store.retryRecovery() }
        }
        .task(id: store.lastSavedAt) {
            guard cloud.enabled else { return }
            do {
                try await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                await cloud.sync(store: store)
            } catch { }
        }
        .task(id: cloud.enabled) {
            while cloud.enabled && !Task.isCancelled {
                if scenePhase == .active { await cloud.sync(store: store) }
                do { try await Task.sleep(for: .seconds(60)) } catch { return }
            }
        }
        .task(id: store.state.activeFocusSession) {
            guard !store.recoveryRequired else { return }
            if finishExpiredFocus() { return }
            let session = store.state.activeFocusSession
            await FocusNotifications.update(for: session)
            guard let deadline = session?.deadline else { return }
            do {
                try await Task.sleep(for: .seconds(max(0, deadline.timeIntervalSinceNow)))
                guard !Task.isCancelled else { return }
                finishExpiredFocus()
            } catch { /* Paused or replaced sessions cancel their old deadline. */ }
        }
    }

    @discardableResult
    private func finishExpiredFocus() -> Bool {
        guard !store.recoveryRequired,
              let session = store.state.activeFocusSession,
              session.remainingSeconds() == 0 else { return false }
        let completed = FocusSessionEngine.reconcileExpired(in: &store.state)
        if completed { store.saveImmediately() }
        return completed
    }
}
