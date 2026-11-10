import Foundation

public struct ChallengeDay: Identifiable, Codable, Equatable, Sendable {
    public var id: Int
    public var learningHours: Double?
    public var steps: Double?
    public var movement: Bool?
    public var calories: Double?
    public var nutrition = ""
    public var treatMeal: Bool?
    public var water: Double?
    public var sleep: Double?
    public var rating = ""
    public var notes = ""
    public init(id: Int) { self.id = id }
    public var goalsCompleted: Int? {
        guard learningHours != nil || steps != nil || movement != nil || water != nil || sleep != nil else { return nil }
        return [(learningHours ?? -1) >= 8, (steps ?? -1) >= 7000, movement == true,
                (water ?? -1) >= 2, (sleep ?? -1) >= 7].filter { $0 }.count
    }
    public var completion: Double? { goalsCompleted.map { Double($0) / 5 } }
}

public struct ChallengeWeek: Identifiable, Codable, Equatable, Sendable {
    public var id: Int
    public var weight: Double?
    public var waist: Double?
    public var chest: Double?
    public var arm: Double?
    public var leg: Double?
    public var gymProgress = ""
    public var reflection = ""
    public var wentWell = ""
    public var improve = ""
    public init(id: Int) { self.id = id }
}

public struct Challenge75: Codable, Equatable, Sendable {
    public static let sourceURL = "https://docs.google.com/spreadsheets/d/1BVxgXNfHQ8Df8WbR9VStG6ucLBfQ-qrhFWeElWWlA-o/edit"
    public var rewardID: UUID? = UUID()
    public var startDate: Date
    public var days: [ChallengeDay] = []
    public var weeks: [ChallengeWeek] = []
    public init(startDate: Date = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 9))!) {
        self.startDate = Calendar.current.startOfDay(for: startDate)
    }
    public func date(for day: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: day - 1, to: calendar.startOfDay(for: startDate))!
    }
    public func dayNumber(on date: Date = Date(), calendar: Calendar = .current) -> Int {
        (calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: date)).day ?? 0) + 1
    }
    public func entry(_ day: Int) -> ChallengeDay { days.first { $0.id == day } ?? ChallengeDay(id: day) }
    public func week(_ week: Int) -> ChallengeWeek { weeks.first { $0.id == week } ?? ChallengeWeek(id: week) }
}

public enum ChallengeMetric: String, CaseIterable, Identifiable {
    case learning, steps, movement, water, sleep, green
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .learning: return "Learning 8+ hrs"
        case .steps: return "7,000+ steps"
        case .movement: return "30+ min movement"
        case .water: return "Water 2+ L"
        case .sleep: return "Sleep 7+ hrs"
        case .green: return "Green days"
        }
    }
    public var target: Double {
        switch self {
        case .learning: return 8
        case .steps: return 7000
        case .water: return 2
        case .sleep: return 7
        case .movement, .green: return 1
        }
    }
    public func value(_ day: ChallengeDay) -> Double? {
        switch self {
        case .learning: return day.learningHours
        case .steps: return day.steps
        case .water: return day.water
        case .sleep: return day.sleep
        case .movement: return day.movement.map { $0 ? 1 : 0 }
        case .green: return day.rating.isEmpty ? nil : (day.rating == "Green" ? 1 : 0)
        }
    }
}
