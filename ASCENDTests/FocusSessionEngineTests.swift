import Foundation

public enum FocusSessionEngineTests {
    public static func runAll() -> [String: Bool] {
        ["clockSurvivesSuspensionAndRelaunch": clockSurvivesSuspensionAndRelaunch(),
         "pausedTimeIsNotCounted": pausedTimeIsNotCounted(),
         "completionIsCappedAndDeduplicated": completionIsCappedAndDeduplicated(),
         "zeroMinuteFinishDoesNotEarnXP": zeroMinuteFinishDoesNotEarnXP(),
         "existingSessionCannotBeOverwritten": existingSessionCannotBeOverwritten()]
    }
    private static let start = Date(timeIntervalSince1970: 1_790_000_000)
    private static func clockSurvivesSuspensionAndRelaunch() -> Bool {
        var state = AppState()
        FocusSessionEngine.start(quest: nil, minutes: 25, now: start, in: &state)
        do {
            let restored = try JSONDecoder().decode(AppState.self, from: JSONEncoder().encode(state))
            return restored.activeFocusSession?.remainingSeconds(at: start.addingTimeInterval(600)) == 900
                && restored.activeFocusSession?.remainingSeconds(at: start.addingTimeInterval(86_400)) == 0
        } catch { return false }
    }
    private static func pausedTimeIsNotCounted() -> Bool {
        var session = ActiveFocusSession(questTitle: "Practice", now: start)
        session.pause(at: start.addingTimeInterval(120))
        guard session.remainingSeconds(at: start.addingTimeInterval(600)) == 1380 else { return false }
        session.resume(at: start.addingTimeInterval(600))
        return session.remainingSeconds(at: start.addingTimeInterval(660)) == 1320
            && session.deadline == start.addingTimeInterval(1980)
    }
    private static func completionIsCappedAndDeduplicated() -> Bool {
        var state = AppState()
        FocusSessionEngine.start(quest: nil, minutes: 25, now: start, in: &state)
        let active = state.activeFocusSession!
        guard FocusSessionEngine.reconcileExpired(now: start.addingTimeInterval(86_400), in: &state) else { return false }
        let once = state.avatar.totalCumulativeXP
        state.activeFocusSession = active
        let twice = FocusSessionEngine.finish(id: active.id, now: start.addingTimeInterval(86_400), in: &state)
        return !twice && state.activeFocusSession == nil && state.focusSessions.count == 1
            && once == 25 && state.avatar.totalCumulativeXP == 25
            && state.focusSessions.first?.durationMinutes == 25
            && state.focusSessions.first?.endTime == start.addingTimeInterval(1500)
    }
    private static func zeroMinuteFinishDoesNotEarnXP() -> Bool {
        var state = AppState()
        FocusSessionEngine.start(quest: nil, now: start, in: &state)
        let id = state.activeFocusSession!.id
        FocusSessionEngine.finish(id: id, now: start.addingTimeInterval(5), in: &state)
        return state.avatar.totalCumulativeXP == 0 && state.focusSessions.first?.durationMinutes == 0
    }
    private static func existingSessionCannotBeOverwritten() -> Bool {
        var state = AppState()
        FocusSessionEngine.start(quest: nil, now: start, in: &state)
        let id = state.activeFocusSession!.id
        let overwritten = FocusSessionEngine.start(quest: DailyQuest(name: "Other task"), in: &state)
        let wrongFinish = FocusSessionEngine.finish(id: UUID(), in: &state)
        return !overwritten && !wrongFinish && state.activeFocusSession?.id == id
    }
}
