import Foundation

public enum PlanningConnectionError: LocalizedError {
    case message(String)
    public var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
}

// All planning stays on device. Legacy online preferences cannot enable paid requests.
public enum PlanningProvider {
    public static var isOnline: Bool { false }
    public static func generateCustomPlan(from prompt: String, timelineMonths: Int) async throws -> CustomPlanDraft {
        try await LocalDeterministicAIService.shared.generateCustomPlan(from: prompt, timelineMonths: timelineMonths)
    }
    public static func refinePlan(current: CustomPlanDraft, request: String) async throws -> CustomPlanDraft {
        try await LocalDeterministicAIService.shared.refinePlan(current: current, request: request)
    }
}
