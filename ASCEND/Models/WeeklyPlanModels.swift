import Foundation

public enum AscendText {
    public static func clean(_ text: String) -> String {
        text.replacingOccurrences(of: "[ \t]*\u{2014}[ \t]*", with: ": ", options: .regularExpression)
    }
}

public struct WeeklyPlanItem: Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var weekday: Int // Monday = 0
    public var title: String
    public var minutes: Int
    public var optional: Bool = false
    public var external: Bool = false
    public var included = true
    public var notes = ""
}

public struct WeeklyPlanImport: Sendable {
    public var items: [WeeklyPlanItem] = []
    public var warnings: [String] = []
}

public struct ImportedWeeklyPlan: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var weekStart: Date
    public var sourceName: String
    public var taskIDs: [UUID]
    public var importedAt: Date
}

public enum DailyNonNegotiable: String, CaseIterable {
    case dsa, phcQA, sahota, portfolio
    public var title: String {
        switch self {
        case .dsa: return "DSA Practice"
        case .phcQA: return "PHC QA"
        case .sahota: return "Sahota Services"
        case .portfolio: return "Portfolio Work"
        }
    }
    public var minutes: Int {
        switch self {
        case .dsa, .phcQA: return 120
        case .sahota: return 60
        case .portfolio: return 90
        }
    }
    public var outsideCore: Bool { self == .phcQA || self == .sahota }
    public static func matching(_ title: String) -> Self? {
        let text = AscendText.clean(title).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if text == "dsa practice" || text.hasPrefix("dsa:") { return .dsa }
        if text == "portfolio work" || text.hasPrefix("portfolio:") || text.hasPrefix("cli:") || text.hasPrefix("advanced python cli:") { return .portfolio }
        if text == "phc qa" || text == "phc qa internship" { return .phcQA }
        if text == "sahota services" { return .sahota }
        return nil
    }
}
