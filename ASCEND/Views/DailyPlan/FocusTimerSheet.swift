import SwiftUI

public struct FocusTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let quest: DailyQuest?
    @ObservedObject var store: AppDataStore
    
    @State private var timeRemainingSeconds: Int = 25 * 60
    @State private var totalTimerSeconds: Int = 25 * 60
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var manualMinutes: Int = 25
    @State private var showManualLogging = false
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AscendTheme.backgroundDark.ignoresSafeArea()
                ParticleFieldView(particleCount: 20)
                
                VStack(spacing: 28) {
                    // Task Header
                    VStack(spacing: 6) {
                        Text("DEEP FOCUS CHAMBER")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(AscendTheme.cyberCyan)
                        Text(quest?.name ?? "Deliberate Practice")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AscendTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Circular Focus Timer Display
                    ZStack {
                        let progress = totalTimerSeconds > 0 ? Double(totalTimerSeconds - timeRemainingSeconds) / Double(totalTimerSeconds) : 0.0
                        
                        StatRing(
                            progress: progress,
                            lineWidth: 12,
                            gradient: AscendTheme.primaryGradient
                        )
                        .frame(width: 240, height: 240)
                        
                        VStack(spacing: 8) {
                            Text(formatTime(timeRemainingSeconds))
                                .font(.system(size: 52, weight: .bold, design: .monospaced))
                                .foregroundColor(AscendTheme.textPrimary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(AscendTheme.electricBlue)
                                Text("+\(max(1, (totalTimerSeconds - timeRemainingSeconds) / 60)) Effort XP")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AscendTheme.textSecondary)
                            }
                        }
                    }
                    
                    // Control Buttons
                    HStack(spacing: 24) {
                        Button {
                            toggleTimer()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(isRunning ? AscendTheme.energeticCoral : AscendTheme.electricBlue)
                                    .frame(width: 68, height: 68)
                                    .shadow(color: (isRunning ? AscendTheme.energeticCoral : AscendTheme.electricBlue).opacity(0.4), radius: 10)
                                
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Button {
                            finishSession()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(AscendTheme.emeraldRecovery)
                                    .frame(width: 68, height: 68)
                                    .shadow(color: AscendTheme.emeraldRecovery.opacity(0.4), radius: 10)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Manual Adjust Option
                    Button {
                        showManualLogging.toggle()
                    } label: {
                        Text(showManualLogging ? "Hide Manual Logging" : "Log Effort Time Manually")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AscendTheme.textSecondary)
                    }
                    
                    if showManualLogging {
                        VStack(spacing: 8) {
                            Stepper("Time: \(manualMinutes) minutes", value: $manualMinutes, in: 5...240, step: 5)
                                .foregroundColor(AscendTheme.textPrimary)
                                .padding(.horizontal, 40)
                            
                            GlowingButton(title: "Log \(manualMinutes) Minutes Effort", icon: "clock.badge.checkmark") {
                                logManualTime()
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Dismiss") {
                        stopTimer()
                        dismiss()
                    }
                    .foregroundColor(AscendTheme.textSecondary)
                }
            }
        }
    }
    
    private func toggleTimer() {
        if isRunning {
            timer?.invalidate()
            timer = nil
            isRunning = false
        } else {
            isRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timeRemainingSeconds > 0 {
                    timeRemainingSeconds -= 1
                } else {
                    finishSession()
                }
            }
        }
        HapticService.shared.triggerImpact(.medium)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    private func finishSession() {
        stopTimer()
        let minutesCompleted = max(1, (totalTimerSeconds - timeRemainingSeconds) / 60)
        
        let awardedXP = XPEngine.shared.awardEffortXP(
            minutes: minutesCompleted,
            questId: quest?.id,
            title: quest?.name ?? "Focus Session",
            in: &store.state
        )
        
        let session = FocusSession(
            dailyQuestId: quest?.id,
            questTitle: quest?.name ?? "Focused Effort",
            durationMinutes: minutesCompleted,
            xpAwarded: awardedXP
        )
        store.state.focusSessions.append(session)
        
        HapticService.shared.triggerNotification(.success)
        dismiss()
    }
    
    private func logManualTime() {
        let awardedXP = XPEngine.shared.awardEffortXP(
            minutes: manualMinutes,
            questId: quest?.id,
            title: quest?.name ?? "Manual Effort Logging",
            in: &store.state
        )
        
        let session = FocusSession(
            dailyQuestId: quest?.id,
            questTitle: quest?.name ?? "Manual Log",
            durationMinutes: manualMinutes,
            xpAwarded: awardedXP
        )
        store.state.focusSessions.append(session)
        
        HapticService.shared.triggerNotification(.success)
        dismiss()
    }
    
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
