import Foundation

public protocol PlanningAIServiceProtocol: Sendable {
    func suggestSubQuests(for goalTitle: String, category: QuestCategory) async throws -> [SubQuest]
    func decomposeTasks(for subQuest: SubQuest) async throws -> [DailyQuest]
    func suggestReplanAdvice(behindTasks: [String], availableMinutes: Int) async throws -> String
}

/// Robust deterministic default fallback implementation.
/// Works 100% offline with zero network or external key requirements.
public final class LocalDeterministicAIService: PlanningAIServiceProtocol {
    public static let shared = LocalDeterministicAIService()
    
    public init() {}
    
    public func suggestSubQuests(for goalTitle: String, category: QuestCategory) async throws -> [SubQuest] {
        let dummyMainQuestId = UUID()
        let lower = goalTitle.lowercased()
        
        if lower.contains("job") || lower.contains("software") || lower.contains("engineer") || lower.contains("career") {
            return [
                SubQuest(
                    mainQuestId: dummyMainQuestId,
                    title: "Build & Deploy Signature Portfolio Project",
                    description: "Architect, build, and deploy a production-grade full-stack application with live authentication and database persistence.",
                    category: .career,
                    completionCondition: .deliverableCompleted(deliverableName: "Live Production URL & GitHub Repository"),
                    orderIndex: 0,
                    completionBonusXP: 300,
                    linkedSkillIds: ["career_programming"]
                ),
                SubQuest(
                    mainQuestId: dummyMainQuestId,
                    title: "Master 50 Core Data Structures & Algorithm Patterns",
                    description: "Target top interview patterns: Sliding Window, Two Pointers, Trees, Graphs, BFS/DFS, and Dynamic Programming.",
                    category: .career,
                    completionCondition: .numericalTarget(target: 50, current: 0, unit: "problems solved"),
                    orderIndex: 1,
                    completionBonusXP: 350,
                    linkedSkillIds: ["career_dsa"]
                ),
                SubQuest(
                    mainQuestId: dummyMainQuestId,
                    title: "System Design & Distributed Architecture Deep-Dive",
                    description: "Master caching, sharding, message queues, rate limiters, and high-availability patterns.",
                    category: .career,
                    completionCondition: .milestoneReached(description: "Complete 5 mock system design architectural designs"),
                    orderIndex: 2,
                    completionBonusXP: 300,
                    linkedSkillIds: ["career_system_design"]
                ),
                SubQuest(
                    mainQuestId: dummyMainQuestId,
                    title: "Resume Refinement & Targeted Job Applications",
                    description: "Tailor STAR bullet points, optimize LinkedIn profile, and submit 30 high-fit applications with warm intros.",
                    category: .career,
                    completionCondition: .numericalTarget(target: 30, current: 0, unit: "applications"),
                    orderIndex: 3,
                    completionBonusXP: 250,
                    linkedSkillIds: ["career_interview_comm"]
                )
            ]
        } else if lower.contains("fit") || lower.contains("muscle") || lower.contains("run") || lower.contains("health") {
            return [
                SubQuest(
                    mainQuestId: dummyMainQuestId,
                    title: "Establish 4-Day Progressive Overload Training Routine",
                    description: "Track compound lifts and progressive volume across 4 weekly resistance sessions.",
                    category: .fitness,
                    completionCondition: .numericalTarget(target: 16, current: 0, unit: "gym sessions"),
                    orderIndex: 0,
                    completionBonusXP: 300,
                    linkedSkillIds: ["fitness_strength"]
                ),
                SubQuest(
                    mainQuestId: dummyMainQuestId,
                    title: "Cardiovascular Engine: 100km Aerobic Milestone",
                    description: "Build Zone-2 aerobic base through weekly steady-state runs or rowing.",
                    category: .fitness,
                    completionCondition: .numericalTarget(target: 100, current: 0, unit: "kilometers"),
                    orderIndex: 1,
                    completionBonusXP: 350,
                    linkedSkillIds: ["fitness_endurance"]
                )
            ]
        } else {
            return [
                SubQuest(
                    mainQuestId: dummyMainQuestId,
                    title: "Foundation & Setup Phase",
                    description: "Define study schedule, gather essential learning resources, and complete initial setup.",
                    category: category,
                    completionCondition: .manualConfirmation,
                    orderIndex: 0,
                    completionBonusXP: 200
                ),
                SubQuest(
                    mainQuestId: dummyMainQuestId,
                    title: "Core Deliberate Practice",
                    description: "Log 30 hours of focused deliberate practice.",
                    category: category,
                    completionCondition: .numericalTarget(target: 30, current: 0, unit: "hours"),
                    orderIndex: 1,
                    completionBonusXP: 300
                ),
                SubQuest(
                    mainQuestId: dummyMainQuestId,
                    title: "Capstone Milestone Project",
                    description: "Complete and share your final deliverable or performance demonstrating mastery.",
                    category: category,
                    completionCondition: .milestoneReached(description: "Final Capstone Completed"),
                    orderIndex: 2,
                    completionBonusXP: 400
                )
            ]
        }
    }
    
    public func decomposeTasks(for subQuest: SubQuest) async throws -> [DailyQuest] {
        return [
            DailyQuest(
                name: "Deep Focus Session: \(subQuest.title)",
                description: "Dedicated 60-minute focused effort on \(subQuest.title).",
                subQuestId: subQuest.id,
                category: subQuest.category,
                priority: .high,
                estimatedDurationMinutes: 60,
                difficulty: .medium,
                xpReward: 60
            ),
            DailyQuest(
                name: "Review & Refine Implementation",
                description: "Test edge cases, clean up documentation, and record progress.",
                subQuestId: subQuest.id,
                category: subQuest.category,
                priority: .medium,
                estimatedDurationMinutes: 30,
                difficulty: .easy,
                xpReward: 30
            )
        ]
    }
    
    public func suggestReplanAdvice(behindTasks: [String], availableMinutes: Int) async throws -> String {
        return "You have \(behindTasks.count) uncompleted sessions today. Prioritize the highest-leverage deep work task and defer administrative tasks to tomorrow morning."
    }
}

