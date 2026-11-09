import Foundation

public struct FutureSelfStage: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var stageIndex: Int
    public var title: String
    public var tagline: String
    public var description: String
    public var requiredMilestones: [String]
    public var completedMilestones: [String]
    public var isUnlocked: Bool
    public var unlockedAt: Date?
    public var visualAuraName: String
    public var rewardedCosmeticTitleId: String?
    
    public init(
        id: String,
        stageIndex: Int,
        title: String,
        tagline: String,
        description: String,
        requiredMilestones: [String],
        completedMilestones: [String] = [],
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        visualAuraName: String = "aura_whisper",
        rewardedCosmeticTitleId: String? = nil
    ) {
        self.id = id
        self.stageIndex = stageIndex
        self.title = title
        self.tagline = tagline
        self.description = description
        self.requiredMilestones = requiredMilestones
        self.completedMilestones = completedMilestones
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.visualAuraName = visualAuraName
        self.rewardedCosmeticTitleId = rewardedCosmeticTitleId
    }
    
    public var progressRatio: Double {
        guard !requiredMilestones.isEmpty else { return isUnlocked ? 1.0 : 0.0 }
        let completedCount = completedMilestones.filter { requiredMilestones.contains($0) }.count
        return Double(completedCount) / Double(requiredMilestones.count)
    }
    
    public var isEligibleForUnlock: Bool {
        guard !requiredMilestones.isEmpty else { return true }
        let completedSet = Set(completedMilestones)
        return requiredMilestones.allSatisfy { completedSet.contains($0) }
    }
}

public struct FutureSelfRoadmap: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var mainQuestId: UUID
    public var finalVisionTitle: String
    public var finalVisionDescription: String
    public var stages: [FutureSelfStage]
    
    public init(
        id: UUID = UUID(),
        mainQuestId: UUID,
        finalVisionTitle: String,
        finalVisionDescription: String,
        stages: [FutureSelfStage]
    ) {
        self.id = id
        self.mainQuestId = mainQuestId
        self.finalVisionTitle = finalVisionTitle
        self.finalVisionDescription = finalVisionDescription
        self.stages = stages
    }
    
    public var currentStage: FutureSelfStage {
        stages.last(where: { $0.isUnlocked }) ?? stages.first ?? FutureSelfStage(
            id: "default",
            stageIndex: 1,
            title: "The Initiate",
            tagline: "The First Step",
            description: "Embarking on the journey.",
            requiredMilestones: [],
            isUnlocked: true
        )
    }
    
    public var nextStage: FutureSelfStage? {
        stages.first(where: { !$0.isUnlocked })
    }
}

public struct FutureSelfPresets {
    public static func careerEngineeringRoadmap(mainQuestId: UUID) -> FutureSelfRoadmap {
        return FutureSelfRoadmap(
            mainQuestId: mainQuestId,
            finalVisionTitle: "Senior Software Engineer / Tech Pioneer",
            finalVisionDescription: "A confident, articulate software engineer who commands deep architectural knowledge, solves complex technical problems with poise, and lands their dream role.",
            stages: [
                FutureSelfStage(
                    id: "career_stage_1",
                    stageIndex: 1,
                    title: "The Initiate",
                    tagline: "Stepping onto the Path",
                    description: "You have embraced the commitment to transform your professional life. Your daily habits begin taking shape.",
                    requiredMilestones: ["setup_workspace_and_goals"],
                    completedMilestones: ["setup_workspace_and_goals"],
                    isUnlocked: true,
                    unlockedAt: Date(),
                    visualAuraName: "aura_whisper",
                    rewardedCosmeticTitleId: "title_initiate"
                ),
                FutureSelfStage(
                    id: "career_stage_2",
                    stageIndex: 2,
                    title: "The Artisan Builder",
                    tagline: "From Concepts to Production",
                    description: "You have shipped real software, mastered foundational data structures, and turned theory into deployed code.",
                    requiredMilestones: [
                        "milestone_portfolio_deployed",
                        "milestone_25_dsa_solved"
                    ],
                    completedMilestones: [],
                    isUnlocked: false,
                    visualAuraName: "aura_celestial_flame",
                    rewardedCosmeticTitleId: "title_builder"
                ),
                FutureSelfStage(
                    id: "career_stage_3",
                    stageIndex: 3,
                    title: "The Resolute Contender",
                    tagline: "Battle-Tested and Interview Ready",
                    description: "You speak fluent architecture, tackle technical challenges with composure, and command the attention of hiring teams.",
                    requiredMilestones: [
                        "milestone_system_design_mastered",
                        "milestone_50_dsa_solved",
                        "milestone_resume_polished",
                        "milestone_mock_interviews_done"
                    ],
                    completedMilestones: [],
                    isUnlocked: false,
                    visualAuraName: "aura_singularity",
                    rewardedCosmeticTitleId: "title_contender"
                ),
                FutureSelfStage(
                    id: "career_stage_4",
                    stageIndex: 4,
                    title: "The Breakthrough Self",
                    tagline: "The Offer Landed — The New Reality",
                    description: "You have achieved your prime real-life objective: the software engineering offer is secured, cementing your permanent transition.",
                    requiredMilestones: [
                        "milestone_job_offer_secured"
                    ],
                    completedMilestones: [],
                    isUnlocked: false,
                    visualAuraName: "aura_singularity",
                    rewardedCosmeticTitleId: "title_breakthrough"
                )
            ]
        )
    }
}

