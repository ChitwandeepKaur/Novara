import Foundation

public final class PlanningEngine: Sendable {
    public static let shared = PlanningEngine()
    
    public init() {}
    
    // MARK: - Daily Plan Generation
    
    /// Generates a deterministic, explainable daily schedule based on active quests and priority weighting.
    public func generateSuggestedPlan(
        for date: Date = Date(),
        availableHours: Double = 6.0,
        startHour: Int = 9,
        in state: AppState
    ) -> DailyPlan {
        let calendar = Calendar.current
        var baseDate = calendar.startOfDay(for: date)
        baseDate = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: baseDate) ?? date
        
        let activeMQ = state.mainQuests.first(where: { $0.status == .active })
        let weights = activeMQ?.priorityDistribution ?? PriorityAllocation(careerWeight: 0.8, fitnessWeight: 0.1, selfCareWeight: 0.1)
        
        let fullBudget = max(60, Int(availableHours * 60))
        // Reserve at most a quarter of focus time for temporary goals. Earliest deadline first.
        let miniTasks = suggestedMiniTasks(for: date, budget: fullBudget / 4, in: state)
        let miniMinutes = miniTasks.reduce(0) { $0 + $1.estimatedDurationMinutes }
        let totalAvailableMinutes = fullBudget - miniMinutes
        let careerMinutesBudget = Int(Double(totalAvailableMinutes) * weights.careerWeight)
        let fitnessMinutesBudget = Int(Double(totalAvailableMinutes) * weights.fitnessWeight)
        let selfCareMinutesBudget = max(15, totalAvailableMinutes - careerMinutesBudget - fitnessMinutesBudget)
        
        var slots: [TimeSlot] = []
        var currentTime = baseDate
        
        // 1. Filter eligible daily tasks whose SubQuest prerequisites are satisfied
        let completedSubQuestIds = Set(state.subQuests.filter { $0.status == .completed }.map { $0.id })
        
        let eligibleTasks = WeeklyPlanEngine.tasks(on: date, in: state).filter { quest in
            guard quest.isExternalCommitment != true, quest.isOptional != true, quest.miniQuestId == nil, quest.status != .completed && quest.status != .archived else { return false }
            if let sqId = quest.subQuestId, let sq = state.subQuests.first(where: { $0.id == sqId }) {
                // If the SubQuest has prerequisites, check if they are all met
                if !sq.prerequisiteSubQuestIds.isEmpty {
                    return sq.prerequisiteSubQuestIds.allSatisfy { completedSubQuestIds.contains($0) }
                }
            }
            return true
        }
        
        // Sort by Priority (Critical > High > Medium > Low), then by deadline
        let sortedTasks = eligibleTasks.sorted { q1, q2 in
            if q1.priority != q2.priority {
                return q1.priority > q2.priority
            }
            if let d1 = q1.deadline, let d2 = q2.deadline {
                return d1 < d2
            }
            return (q1.deadline != nil) && (q2.deadline == nil)
        }
        
        var careerMinutesUsed = 0
        var fitnessMinutesUsed = 0
        var selfCareMinutesUsed = 0
        
        for task in sortedTasks {
            let taskDuration = task.weeklyPlanID == nil ? min(120, max(15, task.estimatedDurationMinutes)) : task.estimatedDurationMinutes
            
            let workUsed = careerMinutesUsed + fitnessMinutesUsed + selfCareMinutesUsed
            guard workUsed + taskDuration <= totalAvailableMinutes else { continue }

            // Check budget allocation
            switch task.category {
            case .career:
                if task.weeklyPlanID == nil && careerMinutesUsed + taskDuration > careerMinutesBudget + 30 && careerMinutesUsed > 0 { continue }
                careerMinutesUsed += taskDuration
            case .fitness:
                if fitnessMinutesUsed + taskDuration > fitnessMinutesBudget + 30 && fitnessMinutesUsed > 0 { continue }
                fitnessMinutesUsed += taskDuration
            case .selfCare, .custom:
                if selfCareMinutesUsed + taskDuration > selfCareMinutesBudget + 30 && selfCareMinutesUsed > 0 { continue }
                selfCareMinutesUsed += taskDuration
            }
            
            let endTime = calendar.date(byAdding: .minute, value: taskDuration, to: currentTime) ?? currentTime
            let slot = TimeSlot(
                startTime: currentTime,
                endTime: endTime,
                dailyQuestId: task.id,
                title: task.name,
                category: task.category,
                isFixedCommitment: false,
                isBreak: false,
                isCompleted: task.status == .completed,
                notes: "Suggested based on \(task.priority.rawValue) priority and \(task.category.displayName) allocation."
            )
            slots.append(slot)
            
            // Add a short 10-minute break after intense blocks (>= 60 mins)
            if taskDuration >= 60 {
                let breakEnd = calendar.date(byAdding: .minute, value: 10, to: endTime) ?? endTime
                slots.append(TimeSlot(
                    startTime: endTime,
                    endTime: breakEnd,
                    title: "Restorative Break & Hydration",
                    category: .selfCare,
                    isFixedCommitment: false,
                    isBreak: true,
                    isCompleted: false
                ))
                currentTime = breakEnd
            } else {
                currentTime = endTime
            }
        }
        
        // 2. Include side quests / habits if not already represented
        for sideQuest in state.sideQuests where sideQuest.status == .inProgress {
            let duration = 20
            guard careerMinutesUsed + fitnessMinutesUsed + selfCareMinutesUsed + duration <= totalAvailableMinutes else { continue }
            selfCareMinutesUsed += duration
            let endTime = calendar.date(byAdding: .minute, value: duration, to: currentTime) ?? currentTime
            slots.append(TimeSlot(
                startTime: currentTime,
                endTime: endTime,
                dailyQuestId: nil,
                title: sideQuest.title,
                category: sideQuest.category,
                isFixedCommitment: false,
                isBreak: false,
                isCompleted: false,
                notes: "Daily side quest habit."
            ))
            currentTime = endTime
        }
        
        for task in miniTasks {
            let end = calendar.date(byAdding: .minute, value: task.estimatedDurationMinutes, to: currentTime) ?? currentTime
            slots.append(TimeSlot(startTime: currentTime, endTime: end, dailyQuestId: task.id,
                                  title: task.name, category: task.category,
                                  notes: "Mini Main Quest • Due \(task.deadline?.formatted(date: .abbreviated, time: .omitted) ?? "soon")"))
            currentTime = end
        }

        let externalTasks = WeeklyPlanEngine.tasks(on: date, in: state).filter {
            $0.isExternalCommitment == true && $0.isOptional != true && !$0.status.isTerminal
        }
        for task in externalTasks {
            let end = calendar.date(byAdding: .minute, value: task.estimatedDurationMinutes, to: currentTime) ?? currentTime
            slots.append(TimeSlot(startTime: currentTime, endTime: end, dailyQuestId: task.id,
                                  title: task.name, category: task.category, notes: "Outside core focus budget"))
            currentTime = end
        }

        return DailyPlan(
            date: date,
            slots: slots,
            isApprovedByUser: false,
            availableWorkingHours: availableHours
        )
    }
    
    // MARK: - Smart Replanning When Behind
    
    /// Detects if scheduled slots have elapsed without completion and proposes an adjusted schedule.
    public func detectAndProposeReplan(
        for plan: DailyPlan,
        currentTime: Date = Date(),
        calendar: Calendar = .current
    ) -> ReplanProposal? {
        var uncompletedLapsedSlots: [TimeSlot] = []
        var upcomingSlots: [TimeSlot] = []
        
        for slot in plan.slots {
            if !slot.isCompleted && !slot.isBreak && slot.endTime < currentTime {
                uncompletedLapsedSlots.append(slot)
            } else if slot.endTime >= currentTime {
                upcomingSlots.append(slot)
            }
        }
        
        guard !uncompletedLapsedSlots.isEmpty else { return nil }
        
        var shortened: [String] = []
        var moved: [String] = []
        var deferred: [String] = []
        var newSlots: [TimeSlot] = []
        
        var runningTime = currentTime
        
        // Carry forward lapsed tasks
        for slot in uncompletedLapsedSlots {
            if slot.isFixedCommitment {
                // Fixed commitments cannot be deferred
                let newEnd = calendar.date(byAdding: .minute, value: slot.durationMinutes, to: runningTime) ?? runningTime
                var adjusted = slot
                adjusted.startTime = runningTime
                adjusted.endTime = newEnd
                newSlots.append(adjusted)
                moved.append(slot.title)
                runningTime = newEnd
            } else if slot.durationMinutes > 45 {
                // Shorten long tasks
                let compressedDuration = max(30, slot.durationMinutes - 20)
                let newEnd = calendar.date(byAdding: .minute, value: compressedDuration, to: runningTime) ?? runningTime
                var adjusted = slot
                adjusted.startTime = runningTime
                adjusted.endTime = newEnd
                newSlots.append(adjusted)
                shortened.append("\(slot.title) (compressed to \(compressedDuration)m)")
                runningTime = newEnd
            } else {
                // Move or defer
                if newSlots.count < 4 {
                    let newEnd = calendar.date(byAdding: .minute, value: slot.durationMinutes, to: runningTime) ?? runningTime
                    var adjusted = slot
                    adjusted.startTime = runningTime
                    adjusted.endTime = newEnd
                    newSlots.append(adjusted)
                    moved.append(slot.title)
                    runningTime = newEnd
                } else {
                    deferred.append(slot.title)
                }
            }
        }
        
        // Append remaining upcoming slots
        for slot in upcomingSlots {
            if runningTime > slot.startTime {
                var adjusted = slot
                adjusted.startTime = runningTime
                adjusted.endTime = calendar.date(byAdding: .minute, value: slot.durationMinutes, to: runningTime) ?? runningTime
                newSlots.append(adjusted)
                runningTime = adjusted.endTime
            } else {
                newSlots.append(slot)
                runningTime = slot.endTime
            }
        }
        
        let rationale = "Detected \(uncompletedLapsedSlots.count) tasks behind schedule. We've compressed flexible sessions and shifted the schedule forward while protecting your fixed goals."
        
        return ReplanProposal(
            rationale: rationale,
            shortenedTasks: shortened,
            movedTasks: moved,
            deferredTasks: deferred,
            proposedSlots: newSlots
        )
    }
    
    /// Applies a proposed replan upon user approval.
    public func applyReplanProposal(_ proposal: ReplanProposal, to plan: inout DailyPlan) {
        plan.slots = proposal.proposedSlots
        plan.pendingReplanProposal = nil
        plan.isApprovedByUser = true
    }
    
    /// Dismisses a proposed replan without modifying the schedule.
    public func dismissReplanProposal(in plan: inout DailyPlan) {
        plan.pendingReplanProposal = nil
    }
}


extension PlanningEngine {
    /// One next unfinished session per active mini quest, bounded by the shared daily budget.
    public func suggestedMiniTasks(for date: Date, budget: Int, in state: AppState) -> [DailyQuest] {
        var remaining = budget
        var result: [DailyQuest] = []
        let active = state.miniMainQuests.filter { $0.status == .active }.sorted { $0.targetDeadline < $1.targetDeadline }
        for mini in active {
            // Completed sessions today already used this quest's daily allocation.
            if state.dailyQuests.contains(where: { $0.miniQuestId == mini.id && $0.status == .completed && $0.completedAt.map { Calendar.current.isDate($0, inSameDayAs: date) } == true }) { continue }
            guard let task = state.dailyQuests.first(where: { $0.miniQuestId == mini.id && !$0.status.isTerminal }),
                  task.estimatedDurationMinutes <= remaining else { continue }
            result.append(task)
            remaining -= task.estimatedDurationMinutes
        }
        return result
    }

    /// Add today's mini sessions without moving or deleting any existing appointments.
    public func appendMiniTasksToCurrentPlan(now: Date = Date(), in state: inout AppState) {
        guard Calendar.current.isDate(state.dailyPlan.date, inSameDayAs: now) else { return }
        let used = state.dailyPlan.slots.reduce(0) { $0 + $1.durationMinutes }
        let budget = max(0, Int(state.dailyPlan.availableWorkingHours * 60) - used)
        let tasks = suggestedMiniTasks(for: now, budget: min(budget, Int(state.dailyPlan.availableWorkingHours * 15)), in: state)
        var start = max(now, state.dailyPlan.slots.map { $0.endTime }.max() ?? now)
        for task in tasks where !state.dailyPlan.slots.contains(where: { $0.dailyQuestId == task.id }) {
            let end = start.addingTimeInterval(Double(task.estimatedDurationMinutes * 60))
            state.dailyPlan.slots.append(TimeSlot(startTime: start, endTime: end, dailyQuestId: task.id, title: task.name, category: task.category, notes: "Mini Main Quest"))
            start = end
        }
    }
}
