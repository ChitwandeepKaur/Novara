import SwiftUI
import UserNotifications

public struct FocusTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let quest: DailyQuest?
    @ObservedObject var store: AppDataStore
    @State private var durationMinutes = 25
    @State private var manualMinutes = 25
    @State private var showManualLogging = false
    @State private var confirmingDiscard = false

    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                ParticleFieldView(particleCount: 20)
                ScrollView {
                    VStack(spacing: 24) {
                        Text("DEEP FOCUS CHAMBER")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(AscendTheme.cyberCyan)
                        Text(store.state.activeFocusSession?.questTitle ?? quest?.name ?? "Deliberate Practice")
                            .font(.system(size: 23, design: .serif)).multilineTextAlignment(.center)
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            let session = store.state.activeFocusSession
                            let total = session?.plannedSeconds ?? durationMinutes * 60
                            let remaining = session?.remainingSeconds(at: context.date) ?? total
                            let minutes = Int(session?.elapsed(at: context.date) ?? 0) / 60
                            ZStack {
                                StatRing(progress: Double(total - remaining) / Double(max(1, total)), lineWidth: 12)
                                    .frame(width: 230, height: 230)
                                VStack(spacing: 8) {
                                    Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                                        .font(.system(size: 48, weight: .medium, design: .monospaced))
                                    Text("\(minutes) minutes focused")
                                        .font(.caption).foregroundStyle(AscendTheme.textSecondary)
                                }
                            }
                        }
                        if let session = store.state.activeFocusSession {
                            HStack(spacing: 24) {
                                GlowingButton(title: session.runStartedAt == nil ? "Resume" : "Pause",
                                              icon: session.runStartedAt == nil ? "play.fill" : "pause.fill") {
                                    var updated = session
                                    if updated.runStartedAt == nil { updated.resume() } else { updated.pause() }
                                    store.state.activeFocusSession = updated
                                    store.saveImmediately()
                                }
                                GlowingButton(title: "Finish", icon: "checkmark") {
                                    FocusSessionEngine.finish(id: session.id, in: &store.state)
                                    store.saveImmediately()
                                    dismiss()
                                }
                            }
                            Text("You can close this sheet or lock your phone. Your session is saved and will resume when you reopen Novara. Completed minutes earn XP up to your daily limit.")
                                .font(.footnote).foregroundStyle(AscendTheme.textSecondary)
                            Button("Discard session", role: .destructive) { confirmingDiscard = true }
                        } else {
                            Stepper("Session: \(durationMinutes) minutes", value: $durationMinutes, in: 5...180, step: 5)
                            GlowingButton(title: "Start focus", icon: "play.fill") {
                                FocusSessionEngine.start(quest: quest, minutes: durationMinutes, in: &store.state)
                                store.saveImmediately()
                            }
                            Button(showManualLogging ? "Hide manual logging" : "Log focused time manually") {
                                showManualLogging.toggle()
                            }.foregroundStyle(AscendTheme.cyberCyan)
                            if showManualLogging {
                                Stepper("Time: \(manualMinutes) minutes", value: $manualMinutes, in: 5...240, step: 5)
                                GlowingButton(title: "Log \(manualMinutes) minutes", icon: "clock.badge.checkmark") {
                                    let xp = XPEngine.shared.awardEffortXP(minutes: manualMinutes, questId: quest?.id,
                                        title: quest?.name ?? "Manual Focus", in: &store.state)
                                    store.state.focusSessions.append(FocusSession(dailyQuestId: quest?.id,
                                        questTitle: quest?.name ?? "Manual Focus", startTime: Date().addingTimeInterval(Double(-manualMinutes * 60)),
                                        endTime: Date(), durationMinutes: manualMinutes, xpAwarded: xp))
                                    store.saveImmediately()
                                    dismiss()
                                }
                            }
                        }
                        if let error = store.storageError {
                            Text(error).font(.footnote).foregroundStyle(AscendTheme.energeticCoral)
                            Button("Retry save") { store.saveImmediately() }
                        }
                    }.padding(24)
                }
            }
            .foregroundStyle(AscendTheme.textPrimary)
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { store.saveImmediately(); dismiss() }
                }
            }
            .confirmationDialog("Discard this focus session? No time or XP will be logged.", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                Button("Discard session", role: .destructive) {
                    store.state.activeFocusSession = nil
                    store.saveImmediately()
                    dismiss()
                }
            }
            .onChange(of: store.state.activeFocusSession?.id) { old, new in
                if old != nil && new == nil { dismiss() }
            }
        }
    }
}

/// The system delivers the reminder even when Novara is suspended.
@MainActor
public enum FocusNotifications {
    private static let prefix = "novara.focus.complete."
    private static var revision = 0
    public static func update(for session: ActiveFocusSession?) async {
        revision += 1
        let current = revision
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        guard !Task.isCancelled, current == revision else { return }
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) })
        guard let session, let deadline = session.deadline, deadline > Date() else { return }
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
        guard !Task.isCancelled, current == revision, deadline > Date() else { return }
        let identifier = prefix + session.id.uuidString + "." + UUID().uuidString
        let content = UNMutableNotificationContent()
        content.title = "Focus complete"
        content.body = "Your focus session is complete. Open Novara to review your progress."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, deadline.timeIntervalSinceNow), repeats: false)
        do {
            try await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            if Task.isCancelled || current != revision {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
            }
        } catch { /* Focus timing still works if notifications are disabled or unavailable. */ }
    }
}
