import Foundation

public protocol PlanningAIServiceProtocol: Sendable {
    func suggestSubQuests(for goalTitle: String, category: QuestCategory) async throws -> [SubQuest]
    func decomposeTasks(for subQuest: SubQuest) async throws -> [DailyQuest]
    func suggestReplanAdvice(behindTasks: [String], availableMinutes: Int) async throws -> String
    func generateCustomPlan(from prompt: String, timelineMonths: Int) async throws -> CustomPlanDraft
    func refinePlan(current: CustomPlanDraft, request: String) async throws -> CustomPlanDraft
}

/// Robust deterministic AI & Planning engine.
/// Works 100% offline with zero network or external key requirements,
/// while providing intelligent semantic decomposition of user goals.
public final class LocalDeterministicAIService: PlanningAIServiceProtocol {
    public static let shared = LocalDeterministicAIService()
    
    public init() {}
    
    // MARK: - Smart Custom Plan Generation from Natural Language
    
    public func generateCustomPlan(from prompt: String, timelineMonths: Int = 3) async throws -> CustomPlanDraft {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()
        
        if lower.contains("job") || lower.contains("software") || lower.contains("engineer") || lower.contains("code") || lower.contains("developer") || lower.contains("programming") || lower.contains("ios") || lower.contains("web") || lower.contains("full stack") || lower.contains("backend") || lower.contains("frontend") {
            return generateSoftwareEngineeringPlan(prompt: trimmed, months: timelineMonths)
        } else if lower.contains("fit") || lower.contains("muscle") || lower.contains("run") || lower.contains("marathon") || lower.contains("gym") || lower.contains("weight") || lower.contains("strength") || lower.contains("health") || lower.contains("athletic") {
            return generateFitnessPlan(prompt: trimmed, months: timelineMonths)
        } else if lower.contains("startup") || lower.contains("business") || lower.contains("indie") || lower.contains("saas") || lower.contains("launch") || lower.contains("product") || lower.contains("company") || lower.contains("app") {
            return generateStartupPlan(prompt: trimmed, months: timelineMonths)
        } else if lower.contains("music") || lower.contains("guitar") || lower.contains("piano") || lower.contains("write") || lower.contains("book") || lower.contains("art") || lower.contains("creative") || lower.contains("draw") {
            return generateCreativePlan(prompt: trimmed, months: timelineMonths)
        } else if lower.contains("study") || lower.contains("exam") || lower.contains("degree") || lower.contains("bar") || lower.contains("mcat") || lower.contains("cert") || lower.contains("learn") || lower.contains("language") || lower.contains("spanish") || lower.contains("japanese") {
            return generateLearningPlan(prompt: trimmed, months: timelineMonths)
        } else {
            return generateGeneralCustomPlan(prompt: trimmed, months: timelineMonths)
        }
    }
    
    // MARK: - Plan Refinement
    
    public func refinePlan(current: CustomPlanDraft, request: String) async throws -> CustomPlanDraft {
        var updated = current
        let lowerReq = request.lowercased()
        
        if lowerReq.contains("fitness") || lowerReq.contains("workout") || lowerReq.contains("gym") || lowerReq.contains("run") {
            if !updated.subQuests.contains(where: { $0.category == .fitness }) {
                updated.subQuests.append(SubQuestDraft(
                    title: "Physical Conditioning & Energy Foundation",
                    description: "Consistent 4-day workout cadence to sustain deep focus mana.",
                    completionConditionDescription: "Log 20 completed sessions",
                    category: .fitness,
                    completionBonusXP: 250,
                    linkedSkillName: "Physical Resilience"
                ))
            }
            if !updated.dailyQuests.contains(where: { $0.category == .fitness }) {
                updated.dailyQuests.append(DailyQuestDraft(
                    name: "45-Minute Movement or Strength Session",
                    category: .fitness,
                    priority: .medium,
                    estimatedDurationMinutes: 45
                ))
            }
            updated.priorityAllocation = PriorityAllocation(careerWeight: 0.65, fitnessWeight: 0.25, selfCareWeight: 0.10)
            updated.explanation = "Added a dedicated physical conditioning track and adjusted daily priority allocation."
            return updated
        }
        
        if lowerReq.contains("beginner") || lowerReq.contains("slower") || lowerReq.contains("easier") || lowerReq.contains("gradual") {
            for i in updated.dailyQuests.indices {
                updated.dailyQuests[i].estimatedDurationMinutes = max(20, updated.dailyQuests[i].estimatedDurationMinutes - 20)
            }
            updated.explanation = "Calibrated task durations to be more approachable and sustainable for beginners."
            return updated
        }
        
        if lowerReq.contains("intensive") || lowerReq.contains("harder") || lowerReq.contains("fast") || lowerReq.contains("accelerate") {
            for i in updated.dailyQuests.indices {
                updated.dailyQuests[i].estimatedDurationMinutes = min(120, updated.dailyQuests[i].estimatedDurationMinutes + 20)
            }
            updated.explanation = "Accelerated timeline and amplified daily focus targets for high-tempo execution."
            return updated
        }
        
        // Generic addition based on user words
        let cleanReq = request.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.subQuests.append(SubQuestDraft(
            title: cleanReq,
            description: "Custom objective added based on your revision request: \(cleanReq)",
            completionConditionDescription: "Verified completion of \(cleanReq)",
            category: updated.category,
            completionBonusXP: 250,
            linkedSkillName: "Focused Mastery"
        ))
        updated.dailyQuests.append(DailyQuestDraft(
            name: "Work on: \(cleanReq)",
            category: updated.category,
            priority: .high,
            estimatedDurationMinutes: 60
        ))
        updated.explanation = "Successfully incorporated: '\(cleanReq)' into your custom roadmap."
        return updated
    }
    
    // MARK: - Specialized Plan Generators
    
    private func generateSoftwareEngineeringPlan(prompt: String, months: Int) -> CustomPlanDraft {
        let title = prompt.count > 5 ? prompt : "Land a Software Engineering Role"
        return CustomPlanDraft(
            goalTitle: title,
            goalDescription: "Structured technical transformation to build standout production software, solve algorithm challenges with poise, and land high-fit engineering offers.",
            category: .career,
            priorityAllocation: PriorityAllocation(careerWeight: 0.80, fitnessWeight: 0.10, selfCareWeight: 0.10),
            subQuests: [
                SubQuestDraft(
                    title: "Ship Production-Grade Signature Application",
                    description: "Architect and deploy a full-stack, distributed, or native app with database persistence and live authentication.",
                    completionConditionDescription: "Live Production URL & public GitHub Repository",
                    category: .career,
                    completionBonusXP: 350,
                    linkedSkillName: "Software Architecture"
                ),
                SubQuestDraft(
                    title: "Master 50 Core Data Structures & Algorithm Patterns",
                    description: "Target top technical interview patterns: Sliding Window, Trees, Graphs, BFS/DFS, and Dynamic Programming.",
                    completionConditionDescription: "50 problems solved and cataloged",
                    category: .career,
                    completionBonusXP: 350,
                    linkedSkillName: "Algorithms & Logic"
                ),
                SubQuestDraft(
                    title: "System Design & Distributed Infrastructure",
                    description: "Master caching, database sharding, rate limiters, message queues, and high-availability patterns.",
                    completionConditionDescription: "Complete 5 mock architecture blueprints",
                    category: .career,
                    completionBonusXP: 300,
                    linkedSkillName: "System Architecture"
                ),
                SubQuestDraft(
                    title: "Resume Polish & 30 High-Fit Job Applications",
                    description: "Tailor STAR metric bullet points, optimize LinkedIn profile, and submit 30 focused applications with warm intros.",
                    completionConditionDescription: "30 submitted applications tracked",
                    category: .career,
                    completionBonusXP: 250,
                    linkedSkillName: "Interview Communication"
                )
            ],
            dailyQuests: [
                DailyQuestDraft(name: "Study System Design Patterns (Caching & Queues)", category: .career, priority: .high, estimatedDurationMinutes: 75),
                DailyQuestDraft(name: "Solve 2 Medium DSA Pattern Problems", category: .career, priority: .critical, estimatedDurationMinutes: 60),
                DailyQuestDraft(name: "Develop Project Core Architecture & APIs", category: .career, priority: .high, estimatedDurationMinutes: 90),
                DailyQuestDraft(name: "Physical Re-energizing Workout", category: .fitness, priority: .medium, estimatedDurationMinutes: 45),
                DailyQuestDraft(name: "Evening Reading & Sleep Ritual", category: .selfCare, priority: .low, estimatedDurationMinutes: 20)
            ],
            sideHabits: [
                SideHabitDraft(title: "Hydration & Electrolytes (3L)", category: .selfCare),
                SideHabitDraft(title: "30-Minute Daily Walk & Posture Reset", category: .fitness)
            ],
            futureSelfStages: [
                FutureSelfStageDraft(id: "s1", stageIndex: 1, title: "The Initiate", tagline: "Stepping onto the Path", milestoneRequirement: "Define technical roadmap & schedule"),
                FutureSelfStageDraft(id: "s2", stageIndex: 2, title: "The Artisan Builder", tagline: "From Concept to Deployed Software", milestoneRequirement: "Live portfolio deployed & 25 DSA solved"),
                FutureSelfStageDraft(id: "s3", stageIndex: 3, title: "The Resolute Contender", tagline: "Battle-Tested and Interview Ready", milestoneRequirement: "50 DSA solved & mock interviews finished"),
                FutureSelfStageDraft(id: "s4", stageIndex: 4, title: "The Breakthrough Self", tagline: "The Offer Landed — The New Reality", milestoneRequirement: "Software Engineering Offer Secured")
            ],
            explanation: "Optimized 80/10/10 blueprint balancing deep coding hours with physical stamina and cognitive recovery."
        )
    }
    
    private func generateFitnessPlan(prompt: String, months: Int) -> CustomPlanDraft {
        let title = prompt.count > 5 ? prompt : "Reach Peak Physical Fitness & Athleticism"
        return CustomPlanDraft(
            goalTitle: title,
            goalDescription: "A comprehensive physical transformation building athletic strength, cardiovascular engine, and sustainable nutrition habits.",
            category: .fitness,
            priorityAllocation: PriorityAllocation(careerWeight: 0.15, fitnessWeight: 0.70, selfCareWeight: 0.15),
            subQuests: [
                SubQuestDraft(
                    title: "Progressive Overload Strength Foundation",
                    description: "Complete 16 focused compound resistance sessions tracking volume and intensity.",
                    completionConditionDescription: "16 logged gym workouts",
                    category: .fitness,
                    completionBonusXP: 300,
                    linkedSkillName: "Strength & Power"
                ),
                SubQuestDraft(
                    title: "Cardiovascular Engine: 100km Aerobic Milestone",
                    description: "Build Zone-2 aerobic base through weekly steady-state runs or rowing.",
                    completionConditionDescription: "100 cumulative kilometers logged",
                    category: .fitness,
                    completionBonusXP: 350,
                    linkedSkillName: "Aerobic Capacity"
                ),
                SubQuestDraft(
                    title: "Nutritional Discipline & Micronutrient Tracking",
                    description: "Hit target protein and caloric boundaries for 28 consecutive days.",
                    completionConditionDescription: "28 tracked nutrition days",
                    category: .selfCare,
                    completionBonusXP: 250,
                    linkedSkillName: "Nutrition Consistency"
                )
            ],
            dailyQuests: [
                DailyQuestDraft(name: "Structured Workout (Strength / Cardio)", category: .fitness, priority: .critical, estimatedDurationMinutes: 60),
                DailyQuestDraft(name: "Pre-workout Mobility & Joint Prep", category: .fitness, priority: .medium, estimatedDurationMinutes: 15),
                DailyQuestDraft(name: "Nutrient-Dense Meal Prep & Hydration", category: .selfCare, priority: .high, estimatedDurationMinutes: 30),
                DailyQuestDraft(name: "Focused Intellectual Project Work", category: .career, priority: .medium, estimatedDurationMinutes: 60),
                DailyQuestDraft(name: "Static Stretching & 8-Hour Sleep Prep", category: .selfCare, priority: .low, estimatedDurationMinutes: 20)
            ],
            sideHabits: [
                SideHabitDraft(title: "Hydration (1 Gallon Daily)", category: .selfCare),
                SideHabitDraft(title: "10,000 Daily Steps", category: .fitness)
            ],
            futureSelfStages: [
                FutureSelfStageDraft(id: "s1", stageIndex: 1, title: "The Novice Mover", tagline: "Igniting the Physical Spark", milestoneRequirement: "Establish 7-day movement streak"),
                FutureSelfStageDraft(id: "s2", stageIndex: 2, title: "The Dedicated Athlete", tagline: "Consistent Volume & Form", milestoneRequirement: "Log 16 workouts & 50km cardio"),
                FutureSelfStageDraft(id: "s3", stageIndex: 3, title: "The Conditioning Master", tagline: "Peak Stamina and Strength", milestoneRequirement: "100km completed & PR achieved"),
                FutureSelfStageDraft(id: "s4", stageIndex: 4, title: "The Ascended Athlete", tagline: "Unbreakable Mind-Body Harmony", milestoneRequirement: "Final fitness target achieved")
            ],
            explanation: "Fitness-dominant plan emphasizing progressive overload, cardiovascular conditioning, and restorative nutrition."
        )
    }
    
    private func generateStartupPlan(prompt: String, months: Int) -> CustomPlanDraft {
        let title = prompt.count > 5 ? prompt : "Launch a Profitable Startup / Indie App"
        return CustomPlanDraft(
            goalTitle: title,
            goalDescription: "From user problem validation to shipping an MVP, acquiring the first 100 users, and building a profitable software business.",
            category: .career,
            priorityAllocation: PriorityAllocation(careerWeight: 0.75, fitnessWeight: 0.15, selfCareWeight: 0.10),
            subQuests: [
                SubQuestDraft(
                    title: "Problem Validation & 20 Customer Discovery Calls",
                    description: "Interview target users to identify critical pain points and willingness to pay.",
                    completionConditionDescription: "20 interview summaries completed",
                    category: .career,
                    completionBonusXP: 300,
                    linkedSkillName: "Market Discovery"
                ),
                SubQuestDraft(
                    title: "Ship Functional Minimum Viable Product (MVP)",
                    description: "Build and deploy the core feature set that solves the primary problem with payment integration.",
                    completionConditionDescription: "Live public URL with Stripe checkout",
                    category: .career,
                    completionBonusXP: 400,
                    linkedSkillName: "Product Delivery"
                ),
                SubQuestDraft(
                    title: "Acquire First 100 Active Users & Initial Revenue",
                    description: "Execute distribution via cold outreach, content marketing, and communities.",
                    completionConditionDescription: "100 registered accounts or $1k MRR",
                    category: .career,
                    completionBonusXP: 350,
                    linkedSkillName: "Growth & Distribution"
                )
            ],
            dailyQuests: [
                DailyQuestDraft(name: "MVP Feature Development (Coding)", category: .career, priority: .critical, estimatedDurationMinutes: 90),
                DailyQuestDraft(name: "User Outreach & Distribution Outreach", category: .career, priority: .high, estimatedDurationMinutes: 60),
                DailyQuestDraft(name: "Customer Feedback Review & Iteration", category: .career, priority: .medium, estimatedDurationMinutes: 30),
                DailyQuestDraft(name: "Fitness Reset Workout", category: .fitness, priority: .medium, estimatedDurationMinutes: 45)
            ],
            sideHabits: [
                SideHabitDraft(title: "Post 1 Build-in-Public Update", category: .career),
                SideHabitDraft(title: "Daily 30-min Brain Walk", category: .fitness)
            ],
            futureSelfStages: [
                FutureSelfStageDraft(id: "s1", stageIndex: 1, title: "The Ideator", tagline: "Validating the Problem", milestoneRequirement: "10 user interviews logged"),
                FutureSelfStageDraft(id: "s2", stageIndex: 2, title: "The Indie Builder", tagline: "Shipping the MVP", milestoneRequirement: "MVP deployed with live payments"),
                FutureSelfStageDraft(id: "s3", stageIndex: 3, title: "The Growth Operator", tagline: "Gaining Market Traction", milestoneRequirement: "First 100 active users secured"),
                FutureSelfStageDraft(id: "s4", stageIndex: 4, title: "The Sustainable Founder", tagline: "Profitable & Self-Sustaining", milestoneRequirement: "Initial recurring revenue milestone")
            ],
            explanation: "Fast-iteration startup roadmap prioritizing customer validation, rapid MVP shipment, and distribution."
        )
    }
    
    private func generateCreativePlan(prompt: String, months: Int) -> CustomPlanDraft {
        let title = prompt.count > 5 ? prompt : "Master a Creative Craft"
        return CustomPlanDraft(
            goalTitle: title,
            goalDescription: "Dedicated deliberate practice to develop creative voice, technique, and a completed public portfolio piece.",
            category: .career,
            priorityAllocation: PriorityAllocation(careerWeight: 0.70, fitnessWeight: 0.15, selfCareWeight: 0.15),
            subQuests: [
                SubQuestDraft(
                    title: "Foundational Technique & Deliberate Drills",
                    description: "Log 30 hours of structured fundamental exercises and theory.",
                    completionConditionDescription: "30 practice hours logged",
                    category: .career,
                    completionBonusXP: 300,
                    linkedSkillName: "Artistic Technique"
                ),
                SubQuestDraft(
                    title: "Draft & Iterate Intermediate Studies",
                    description: "Complete 5 intermediate studies or pieces testing composition and style.",
                    completionConditionDescription: "5 completed studies archived",
                    category: .career,
                    completionBonusXP: 300,
                    linkedSkillName: "Composition"
                ),
                SubQuestDraft(
                    title: "Deliver Signature Capstone Masterpiece",
                    description: "Polish, finalize, and publicly showcase your complete creative work.",
                    completionConditionDescription: "Public performance or published work",
                    category: .career,
                    completionBonusXP: 400,
                    linkedSkillName: "Creative Expression"
                )
            ],
            dailyQuests: [
                DailyQuestDraft(name: "Deep Creative Practice Session", category: .career, priority: .critical, estimatedDurationMinutes: 75),
                DailyQuestDraft(name: "Theory, Study & Critical Review", category: .career, priority: .medium, estimatedDurationMinutes: 30),
                DailyQuestDraft(name: "Physical Movement & Hand/Posture Mobility", category: .fitness, priority: .medium, estimatedDurationMinutes: 30),
                DailyQuestDraft(name: "Mindful Reflection & Journaling", category: .selfCare, priority: .low, estimatedDurationMinutes: 15)
            ],
            sideHabits: [
                SideHabitDraft(title: "15-Minute Daily Sketching/Drill", category: .career),
                SideHabitDraft(title: "Hydration & Eye Rest Breaks", category: .selfCare)
            ],
            futureSelfStages: [
                FutureSelfStageDraft(id: "s1", stageIndex: 1, title: "The Apprentice", tagline: "Learning the Fundamentals", milestoneRequirement: "Log 10 hours deliberate drills"),
                FutureSelfStageDraft(id: "s2", stageIndex: 2, title: "The Practicing Artisan", tagline: "Developing Style and Technique", milestoneRequirement: "Complete 5 intermediate studies"),
                FutureSelfStageDraft(id: "s3", stageIndex: 3, title: "The Skilled Creator", tagline: "Refining the Capstone", milestoneRequirement: "Complete rough draft of masterpiece"),
                FutureSelfStageDraft(id: "s4", stageIndex: 4, title: "The Master Craftsman", tagline: "Public Showcase & Mastery", milestoneRequirement: "Publish/Perform final work")
            ],
            explanation: "Deliberate practice roadmap balancing daily creation with artistic theory and wellness."
        )
    }
    
    private func generateLearningPlan(prompt: String, months: Int) -> CustomPlanDraft {
        let title = prompt.count > 5 ? prompt : "Master Examination / Specialized Discipline"
        return CustomPlanDraft(
            goalTitle: title,
            goalDescription: "Spaced repetition, comprehensive curriculum coverage, and high-intensity practice tests to achieve top-tier mastery.",
            category: .career,
            priorityAllocation: PriorityAllocation(careerWeight: 0.75, fitnessWeight: 0.15, selfCareWeight: 0.10),
            subQuests: [
                SubQuestDraft(
                    title: "Curriculum & Foundational Syllabus Mastery",
                    description: "Complete all primary textbook chapters, lectures, and note consolidation.",
                    completionConditionDescription: "100% syllabus modules finished",
                    category: .career,
                    completionBonusXP: 300,
                    linkedSkillName: "Deep Knowledge"
                ),
                SubQuestDraft(
                    title: "Active Recall & Spaced Repetition Problem Bank",
                    description: "Solve 500 practice problems or flashcards across all sub-disciplines.",
                    completionConditionDescription: "500 practice questions logged",
                    category: .career,
                    completionBonusXP: 350,
                    linkedSkillName: "Analytical Problem Solving"
                ),
                SubQuestDraft(
                    title: "Full-Length Timed Mock Assessments",
                    description: "Complete 4 full-length simulated exams under real test conditions.",
                    completionConditionDescription: "4 full-length exams completed",
                    category: .career,
                    completionBonusXP: 350,
                    linkedSkillName: "Testing Composure"
                )
            ],
            dailyQuests: [
                DailyQuestDraft(name: "Focused Study & Note Synthesis", category: .career, priority: .critical, estimatedDurationMinutes: 90),
                DailyQuestDraft(name: "Spaced Repetition & Practice Questions", category: .career, priority: .high, estimatedDurationMinutes: 45),
                DailyQuestDraft(name: "Aerobic Exercise / Jog for Brain Health", category: .fitness, priority: .medium, estimatedDurationMinutes: 40),
                DailyQuestDraft(name: "Evening Mind Decompression", category: .selfCare, priority: .low, estimatedDurationMinutes: 20)
            ],
            sideHabits: [
                SideHabitDraft(title: "50 Flashcards / Anki Review", category: .career),
                SideHabitDraft(title: "Dark Bedroom Sleep Routine", category: .selfCare)
            ],
            futureSelfStages: [
                FutureSelfStageDraft(id: "s1", stageIndex: 1, title: "The Scholar", tagline: "Building the Foundation", milestoneRequirement: "Cover first 25% of curriculum"),
                FutureSelfStageDraft(id: "s2", stageIndex: 2, title: "The Analyst", tagline: "Mastering Problem Patterns", milestoneRequirement: "Finish syllabus & 200 questions"),
                FutureSelfStageDraft(id: "s3", stageIndex: 3, title: "The High Scorer", tagline: "Exam Simulation Readiness", milestoneRequirement: "Complete 2 timed mock exams"),
                FutureSelfStageDraft(id: "s4", stageIndex: 4, title: "The Ascended Scholar", tagline: "Flawless Performance", milestoneRequirement: "Target score achieved on final trial")
            ],
            explanation: "Rigorous study blueprint utilizing spaced repetition and timed simulation drills."
        )
    }
    
    private func generateGeneralCustomPlan(prompt: String, months: Int) -> CustomPlanDraft {
        let title = prompt.isEmpty ? "My Real-Life Quest" : prompt
        return CustomPlanDraft(
            goalTitle: title,
            goalDescription: "Tailored life quest structured to turn your vision into actionable milestones, daily habits, and visible world progression.",
            category: .career,
            priorityAllocation: PriorityAllocation(careerWeight: 0.70, fitnessWeight: 0.15, selfCareWeight: 0.15),
            subQuests: [
                SubQuestDraft(
                    title: "Phase 1: Foundations & Systematic Setup",
                    description: "Establish resources, environment, and foundational habits for: \(title).",
                    completionConditionDescription: "Setup checklist confirmed",
                    category: .career,
                    completionBonusXP: 250,
                    linkedSkillName: "Strategic Planning"
                ),
                SubQuestDraft(
                    title: "Phase 2: Core Deliberate Execution",
                    description: "Complete primary heavy lifting and skill acquisition for: \(title).",
                    completionConditionDescription: "Core deliverable milestones verified",
                    category: .career,
                    completionBonusXP: 350,
                    linkedSkillName: "Execution & Craft"
                ),
                SubQuestDraft(
                    title: "Phase 3: Culmination & Final Victory",
                    description: "Achieve the defining outcome: \(title).",
                    completionConditionDescription: "Final outcome confirmed & verified",
                    category: .career,
                    completionBonusXP: 400,
                    linkedSkillName: "Goal Ascension"
                )
            ],
            dailyQuests: [
                DailyQuestDraft(name: "Dedicated Focus Session: \(title)", category: .career, priority: .critical, estimatedDurationMinutes: 75),
                DailyQuestDraft(name: "Review & Refine Implementation", category: .career, priority: .medium, estimatedDurationMinutes: 30),
                DailyQuestDraft(name: "Physical Re-energizing Activity", category: .fitness, priority: .medium, estimatedDurationMinutes: 40),
                DailyQuestDraft(name: "Evening Reflection & Recharge", category: .selfCare, priority: .low, estimatedDurationMinutes: 20)
            ],
            sideHabits: [
                SideHabitDraft(title: "Hydration & Focus Reset", category: .selfCare),
                SideHabitDraft(title: "Daily Movement / Walk", category: .fitness)
            ],
            futureSelfStages: [
                FutureSelfStageDraft(id: "s1", stageIndex: 1, title: "The Initiate", tagline: "Committing to the Vision", milestoneRequirement: "Launch phase 1 setup"),
                FutureSelfStageDraft(id: "s2", stageIndex: 2, title: "The Practitioner", tagline: "Deep in the Work", milestoneRequirement: "Phase 1 completed"),
                FutureSelfStageDraft(id: "s3", stageIndex: 3, title: "The Contender", tagline: "Approaching the Summit", milestoneRequirement: "Phase 2 completed"),
                FutureSelfStageDraft(id: "s4", stageIndex: 4, title: "The Realized Self", tagline: "Vision Fulfilled", milestoneRequirement: "Final quest objective completed")
            ],
            explanation: "Personalized roadmap decomposed into 3 progressive phases, daily actionable blocks, and identity transformations."
        )
    }
    
    // MARK: - Legacy Protocol Conformances
    
    public func suggestSubQuests(for goalTitle: String, category: QuestCategory) async throws -> [SubQuest] {
        let plan = try await generateCustomPlan(from: goalTitle)
        let dummyId = UUID()
        return plan.subQuests.enumerated().map { index, draft in
            SubQuest(
                mainQuestId: dummyId,
                title: draft.title,
                description: draft.description,
                category: draft.category,
                completionCondition: .deliverableCompleted(deliverableName: draft.completionConditionDescription),
                orderIndex: index,
                completionBonusXP: draft.completionBonusXP,
                linkedSkillIds: ["career_programming"]
            )
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
