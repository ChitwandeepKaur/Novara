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
        
        results["miniQuestIntegration"] = testMiniQuestIntegration()
        results["miniQuestValidationAndPersistence"] = testMiniQuestValidationAndPersistence()
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


extension PlanningEngineTests {
    private static func testMiniQuestIntegration() -> Bool {
        var state = AppState()
        let main = MainQuest(title: "Main journey")
        state.mainQuests = [main]
        let mainTask = DailyQuest(name: "Main work", estimatedDurationMinutes: 60)
        state.dailyQuests = [mainTask]
        let deadline = Date().addingTimeInterval(86400 * 30)
        let tasks = QuestEngine.shared.miniQuestBreakdown(outcomes: ["Christmas gifts", "Portfolio"], category: .career, minutes: 30)
        guard let id = try? QuestEngine.shared.addMiniQuest(title: "Christmas", outcomes: ["Christmas gifts", "Portfolio"], deadline: deadline, category: .career, tasks: tasks, in: &state) else { return false }
        guard state.mainQuests == [main], state.dailyQuests.contains(mainTask), state.subQuests.count == 2 else { return false }
        let plan = PlanningEngine.shared.generateSuggestedPlan(availableHours: 4, in: state)
        let miniIDs = Set(state.dailyQuests.filter { $0.miniQuestId == id }.map { $0.id })
        guard plan.slots.contains(where: { $0.dailyQuestId == mainTask.id }),
              plan.slots.filter({ $0.dailyQuestId.map { miniIDs.contains($0) } == true }).count == 1,
              plan.slots.reduce(0, { $0 + $1.durationMinutes }) <= 240 else { return false }
        state.dailyPlan = plan
        let before = state.dailyPlan.slots
        PlanningEngine.shared.appendMiniTasksToCurrentPlan(in: &state)
        guard state.dailyPlan.slots == before else { return false }
        for index in state.dailyQuests.indices where state.dailyQuests[index].miniQuestId == id {
            state.dailyQuests[index].status = .completed
            state.dailyQuests[index].completedAt = Date()
        }
        QuestEngine.shared.refreshMiniQuestProgress(in: &state)
        let xp = state.avatar.totalCumulativeXP
        QuestEngine.shared.refreshMiniQuestProgress(in: &state)
        guard state.miniMainQuests.first?.status == .completed, xp == 1400, state.avatar.totalCumulativeXP == xp else { return false }
        state.dailyQuests[1].status = .notStarted
        state.dailyQuests[1].completedAt = nil
        QuestEngine.shared.refreshMiniQuestProgress(in: &state)
        return state.miniMainQuests.first?.status == .active && state.avatar.totalCumulativeXP == xp
    }

    private static func testMiniQuestValidationAndPersistence() -> Bool {
        var state = AppState()
        let tasks = QuestEngine.shared.miniQuestBreakdown(outcomes: ["Gifts"], category: .selfCare, minutes: 30)
        do {
            try QuestEngine.shared.addMiniQuest(title: "Past", outcomes: ["Gifts"], deadline: Date().addingTimeInterval(-86400), category: .selfCare, tasks: tasks, in: &state)
            return false
        } catch { }
        guard state.dailyQuests.isEmpty, state.miniMainQuests.isEmpty else { return false }
        do {
            try QuestEngine.shared.addMiniQuest(title: "Holiday", outcomes: ["Gifts"], deadline: Date(), category: .selfCare, tasks: tasks, in: &state)
            let data = try JSONEncoder().encode(state)
            let restored = try JSONDecoder().decode(AppState.self, from: data)
            guard restored.miniMainQuests == state.miniMainQuests, restored.dailyQuests == state.dailyQuests else { return false }
            var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            object.removeValue(forKey: "miniMainQuests")
            let legacy = try JSONDecoder().decode(AppState.self, from: JSONSerialization.data(withJSONObject: object))
            return legacy.miniMainQuests.isEmpty
        } catch { return false }
    }
}
