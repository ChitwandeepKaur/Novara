import Foundation

public struct PlanningEngineTests {
    public static func runAll() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        results["testGenerateSuggestedPlanBudgeting"] = testGenerateSuggestedPlanBudgeting()
        results["testPrerequisiteFilteringInPlanning"] = testPrerequisiteFilteringInPlanning()
        results["testReplanDetectionAndApproval"] = testReplanDetectionAndApproval()
        results["testDismissReplanPreservesSchedule"] = testDismissReplanPreservesSchedule()
        results["testCustomPlanGeneration"] = testCustomPlanGeneration()
        results["testPlanRefinement"] = testPlanRefinement()
        
        return results
    }
    
    private static func testGenerateSuggestedPlanBudgeting() -> Bool {
        var state = AppState()
        let mq = MainQuest(
            title: "Software Engineer",
            priorityDistribution: PriorityAllocation(careerWeight: 0.8, fitnessWeight: 0.1, selfCareWeight: 0.1)
        )
        state.mainQuests = [mq]
        
        state.dailyQuests = [
            DailyQuest(name: "Study Architecture", category: .career, priority: .high, estimatedDurationMinutes: 60),
            DailyQuest(name: "Gym Workout", category: .fitness, priority: .medium, estimatedDurationMinutes: 45),
            DailyQuest(name: "Mindful Meditation", category: .selfCare, priority: .low, estimatedDurationMinutes: 15)
        ]
        
        let plan = PlanningEngine.shared.generateSuggestedPlan(availableHours: 4.0, in: state)
        
        let hasCareer = plan.slots.contains { $0.category == .career }
        let hasFitness = plan.slots.contains { $0.category == .fitness }
        
        return !plan.slots.isEmpty && hasCareer && hasFitness && !plan.isApprovedByUser
    }
    
    private static func testPrerequisiteFilteringInPlanning() -> Bool {
        var state = AppState()
        let mq = MainQuest(title: "Land Job", status: .active)
        state.mainQuests = [mq]
        
        let sqPrereq = SubQuest(mainQuestId: mq.id, title: "Prereq SubQuest", status: .inProgress)
        let sqBlocked = SubQuest(mainQuestId: mq.id, title: "Blocked SubQuest", prerequisiteSubQuestIds: [sqPrereq.id], status: .notStarted)
        state.subQuests = [sqPrereq, sqBlocked]
        
        let taskEligible = DailyQuest(name: "Do Prereq Work", subQuestId: sqPrereq.id)
        let taskBlocked = DailyQuest(name: "Do Advanced Blocked Work", subQuestId: sqBlocked.id)
        state.dailyQuests = [taskEligible, taskBlocked]
        
        let plan = PlanningEngine.shared.generateSuggestedPlan(availableHours: 4.0, in: state)
        
        let scheduledTaskIds = Set(plan.slots.compactMap { $0.dailyQuestId })
        let containsEligible = scheduledTaskIds.contains(taskEligible.id)
        let excludesBlocked = !scheduledTaskIds.contains(taskBlocked.id)
        
        return containsEligible && excludesBlocked
    }
    
    private static func testReplanDetectionAndApproval() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let pastStart = calendar.date(byAdding: .minute, value: -90, to: now)!
        let pastEnd = calendar.date(byAdding: .minute, value: -30, to: now)!
        
        let lapsedSlot = TimeSlot(
            startTime: pastStart,
            endTime: pastEnd,
            title: "Overdue Study Block",
            category: .career,
            isCompleted: false
        )
        
        var plan = DailyPlan(date: now, slots: [lapsedSlot], isApprovedByUser: true)
        
        // Detect replan
        let proposal = PlanningEngine.shared.detectAndProposeReplan(for: plan, currentTime: now, calendar: calendar)
        guard let validProposal = proposal else { return false }
        
        // Apply replan
        PlanningEngine.shared.applyReplanProposal(validProposal, to: &plan)
        
        let updatedSlot = plan.slots.first
        return plan.pendingReplanProposal == nil && updatedSlot != nil && updatedSlot!.startTime >= now
    }
    
    private static func testDismissReplanPreservesSchedule() -> Bool {
        var plan = DailyPlan()
        plan.pendingReplanProposal = ReplanProposal(rationale: "Test")
        
        PlanningEngine.shared.dismissReplanProposal(in: &plan)
        return plan.pendingReplanProposal == nil
    }
    
    private static func testCustomPlanGeneration() -> Bool {
        var passed = false
        let sema = DispatchSemaphore(value: 0)
        Task {
            if let plan = try? await LocalDeterministicAIService.shared.generateCustomPlan(from: "Train for a marathon in 6 months", timelineMonths: 6) {
                if plan.category == .fitness && !plan.subQuests.isEmpty && !plan.dailyQuests.isEmpty && plan.subQuests.count >= 2 {
                    passed = true
                }
            }
            sema.signal()
        }
        sema.wait()
        return passed
    }
    
    private static func testPlanRefinement() -> Bool {
        var passed = false
        let sema = DispatchSemaphore(value: 0)
        Task {
            if let initial = try? await LocalDeterministicAIService.shared.generateCustomPlan(from: "Learn backend engineering", timelineMonths: 3),
               let refined = try? await LocalDeterministicAIService.shared.refinePlan(current: initial, request: "Add fitness workout routine") {
                if refined.subQuests.contains(where: { $0.category == .fitness }) && refined.priorityAllocation.fitnessWeight > initial.priorityAllocation.fitnessWeight {
                    passed = true
                }
            }
            sema.signal()
        }
        sema.wait()
        return passed
    }
}

