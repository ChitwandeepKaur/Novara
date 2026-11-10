import Foundation

public enum FocusSessionEngine {
    @discardableResult
    public static func start(quest: DailyQuest?, minutes: Int = 25, now: Date = Date(), in state: inout AppState) -> Bool {
        guard state.activeFocusSession == nil else { return false }
        state.activeFocusSession = ActiveFocusSession(dailyQuestId: quest?.id,
            questTitle: quest?.name ?? "Deliberate Practice", plannedSeconds: min(180, max(1, minutes)) * 60, now: now)
        return true
    }

    @discardableResult
    public static func finish(id: UUID, now: Date = Date(), in state: inout AppState) -> Bool {
        guard let active = state.activeFocusSession, active.id == id else { return false }
        state.activeFocusSession = nil
        guard !state.focusSessions.contains(where: { $0.id == id }) else { return false }
        let minutes = Int(active.elapsed(at: now) / 60)
        let xp = XPEngine.shared.awardEffortXP(minutes: minutes, questId: active.dailyQuestId,
            title: active.questTitle, in: &state)
        state.focusSessions.append(FocusSession(id: id, dailyQuestId: active.dailyQuestId,
            questTitle: active.questTitle, startTime: active.startedAt,
            endTime: min(now, active.deadline ?? now), durationMinutes: minutes, xpAwarded: xp))
        return true
    }

    @discardableResult
    public static func reconcileExpired(now: Date = Date(), in state: inout AppState) -> Bool {
        guard let active = state.activeFocusSession, active.remainingSeconds(at: now) == 0 else { return false }
        return finish(id: active.id, now: now, in: &state)
    }
}
