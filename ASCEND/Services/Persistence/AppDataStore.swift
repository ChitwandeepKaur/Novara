import Foundation
import SwiftUI
import Combine

public struct AppState: Codable, Sendable {
    public var schemaVersion: Int
    public var isOnboarded: Bool
    public var avatar: AvatarProfile
    public var mainQuests: [MainQuest]
    public var subQuests: [SubQuest]
    public var dailyQuests: [DailyQuest]
    public var sideQuests: [SideQuest]
    public var skillNodes: [SkillNode]
    public var futureSelfRoadmaps: [FutureSelfRoadmap]
    public var worldState: WorldState
    public var dailyPlan: DailyPlan
    public var focusSessions: [FocusSession]
    public var xpTransactions: [XPTransaction]
    public var achievements: [Achievement]
    public var evidenceAttachments: [EvidenceAttachment]
    public var cosmeticCatalogue: [CosmeticItem]
    public var miniMainQuests: [MiniMainQuest]
    public var challenge75: Challenge75?
    public var weeklyPlans: [ImportedWeeklyPlan]
    public var selectedFairy: FairyPalette?
    public var activeFocusSession: ActiveFocusSession?
    
    public init(
        schemaVersion: Int = 1,
        isOnboarded: Bool = false,
        avatar: AvatarProfile = AvatarProfile(),
        mainQuests: [MainQuest] = [],
        subQuests: [SubQuest] = [],
        dailyQuests: [DailyQuest] = [],
        sideQuests: [SideQuest] = [],
        skillNodes: [SkillNode] = SkillTreePresets.defaultSkills(),
        futureSelfRoadmaps: [FutureSelfRoadmap] = [],
        worldState: WorldState = WorldState(),
        dailyPlan: DailyPlan = DailyPlan(),
        focusSessions: [FocusSession] = [],
        xpTransactions: [XPTransaction] = [],
        achievements: [Achievement] = AchievementCatalogue.defaultAchievements(),
        evidenceAttachments: [EvidenceAttachment] = [],
        cosmeticCatalogue: [CosmeticItem] = CosmeticCatalogue.allItems,
        miniMainQuests: [MiniMainQuest] = [],
        challenge75: Challenge75? = nil,
        weeklyPlans: [ImportedWeeklyPlan] = [],
        selectedFairy: FairyPalette? = .flora,
        activeFocusSession: ActiveFocusSession? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.isOnboarded = isOnboarded
        self.avatar = avatar
        self.mainQuests = mainQuests
        self.subQuests = subQuests
        self.dailyQuests = dailyQuests
        self.sideQuests = sideQuests
        self.skillNodes = skillNodes
        self.futureSelfRoadmaps = futureSelfRoadmaps
        self.worldState = worldState
        self.dailyPlan = dailyPlan
        self.focusSessions = focusSessions
        self.xpTransactions = xpTransactions
        self.achievements = achievements
        self.evidenceAttachments = evidenceAttachments
        self.cosmeticCatalogue = cosmeticCatalogue
        self.miniMainQuests = miniMainQuests
        self.challenge75 = challenge75
        self.weeklyPlans = weeklyPlans
        self.activeFocusSession = activeFocusSession
        self.selectedFairy = selectedFairy
        updateFairyProgress()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        self.isOnboarded = try container.decodeIfPresent(Bool.self, forKey: .isOnboarded) ?? false
        self.avatar = try container.decodeIfPresent(AvatarProfile.self, forKey: .avatar) ?? AvatarProfile()
        self.mainQuests = try container.decodeIfPresent([MainQuest].self, forKey: .mainQuests) ?? []
        self.subQuests = try container.decodeIfPresent([SubQuest].self, forKey: .subQuests) ?? []
        self.dailyQuests = try container.decodeIfPresent([DailyQuest].self, forKey: .dailyQuests) ?? []
        self.sideQuests = try container.decodeIfPresent([SideQuest].self, forKey: .sideQuests) ?? []
        self.skillNodes = try container.decodeIfPresent([SkillNode].self, forKey: .skillNodes) ?? SkillTreePresets.defaultSkills()
        self.futureSelfRoadmaps = try container.decodeIfPresent([FutureSelfRoadmap].self, forKey: .futureSelfRoadmaps) ?? []
        self.worldState = try container.decodeIfPresent(WorldState.self, forKey: .worldState) ?? WorldState()
        self.dailyPlan = try container.decodeIfPresent(DailyPlan.self, forKey: .dailyPlan) ?? DailyPlan()
        self.focusSessions = try container.decodeIfPresent([FocusSession].self, forKey: .focusSessions) ?? []
        self.xpTransactions = try container.decodeIfPresent([XPTransaction].self, forKey: .xpTransactions) ?? []
        self.achievements = try container.decodeIfPresent([Achievement].self, forKey: .achievements) ?? AchievementCatalogue.defaultAchievements()
        self.evidenceAttachments = try container.decodeIfPresent([EvidenceAttachment].self, forKey: .evidenceAttachments) ?? []
        self.cosmeticCatalogue = try container.decodeIfPresent([CosmeticItem].self, forKey: .cosmeticCatalogue) ?? CosmeticCatalogue.allItems
        self.miniMainQuests = try container.decodeIfPresent([MiniMainQuest].self, forKey: .miniMainQuests) ?? []
        self.challenge75 = try container.decodeIfPresent(Challenge75.self, forKey: .challenge75)
        self.weeklyPlans = try container.decodeIfPresent([ImportedWeeklyPlan].self, forKey: .weeklyPlans) ?? []
        self.activeFocusSession = try container.decodeIfPresent(ActiveFocusSession.self, forKey: .activeFocusSession)
        self.selectedFairy = try container.decodeIfPresent(FairyPalette.self, forKey: .selectedFairy)
        updateFairyProgress()
        cleanDisplayText()
    }
}

public final class AppDataStore: ObservableObject, @unchecked Sendable {
    public static let shared = AppDataStore()
    
    @Published public var state: AppState {
        didSet {
            guard !isNormalizingState else { return }
            isNormalizingState = true
            state.updateFairyProgress(previousXP: oldValue.avatar.totalCumulativeXP)
            state.cleanDisplayText()
            isNormalizingState = false
            if !suppressAutoSave { scheduleAutoSave() }
        }
    }
    
    @Published public private(set) var storageError: String?
    @Published public private(set) var recoveryNotice: String?
    @Published public private(set) var recoveryRequired = false
    @Published public private(set) var lastSavedAt: Date?
    private var isNormalizingState = false
    private var suppressAutoSave = false
    private var saveRevision = 0
    private let fileURL: URL
    private let saveQueue = DispatchQueue(label: "com.ascend.appdatastore.save", qos: .utility)
    private var saveWorkItem: DispatchWorkItem?
    public var backupURL: URL { fileURL.appendingPathExtension("backup.json") }

    public init(customFileURL: URL? = nil) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        fileURL = customFileURL ?? directory.appendingPathComponent("ascend_state_v1.json")
        let loaded = Self.loadState(from: fileURL)
        state = loaded.state
        recoveryRequired = loaded.blocked
        recoveryNotice = loaded.notice
        storageError = loaded.error
    }

    private struct LoadResult {
        var state: AppState
        var blocked = false
        var notice: String?
        var error: String?
    }

    private static func decode(_ data: Data) throws -> AppState {
        // An empty object must never replace a real save as if it were a complete backup.
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard object?["avatar"] != nil else { throw storageFailure("This file is not a Novara backup.") }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let state = try decoder.decode(AppState.self, from: data)
        guard state.schemaVersion <= 1 else {
            throw NSError(domain: "Novara.Storage", code: 2, userInfo: [NSLocalizedDescriptionKey: "This backup needs a newer version of Novara."])
        }
        if let focus = state.activeFocusSession {
            guard (60...10_800).contains(focus.plannedSeconds), focus.elapsedBeforeRun.isFinite,
                  focus.elapsedBeforeRun >= 0, focus.elapsedBeforeRun <= Double(focus.plannedSeconds) else {
                throw storageFailure("This backup contains an invalid focus session.")
            }
        }
        return state
    }

    private static func encode(_ state: AppState) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(state)
    }

    private static func storageFailure(_ message: String) -> NSError {
        NSError(domain: "Novara.Storage", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private static func preserveOriginal(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let preserved = url.deletingLastPathComponent()
            .appendingPathComponent("novara-recovery-\(UUID().uuidString).json")
        try FileManager.default.copyItem(at: url, to: preserved)
    }

    private static func loadState(from url: URL) -> LoadResult {
        let backup = url.appendingPathExtension("backup.json")
        let manager = FileManager.default
        if !manager.fileExists(atPath: url.path) && !manager.fileExists(atPath: backup.path) {
            return LoadResult(state: AppState())
        }
        do {
            return LoadResult(state: try decode(Data(contentsOf: url)))
        } catch {
            let failure = error as NSError
            if failure.domain == "Novara.Storage", failure.code == 2 {
                return LoadResult(state: AppState(), blocked: true, error: failure.localizedDescription + " Your files have been preserved.")
            }
            do {
                let restored = try decode(Data(contentsOf: backup))
                // Preserve the damaged original before allowing subsequent autosaves.
                try preserveOriginal(at: url)
                return LoadResult(state: restored, notice: "Recovered your progress from the last good local backup. Your original save was preserved. Recent changes may need checking.")
            } catch {
                return LoadResult(state: AppState(), blocked: true,
                    error: "Your saved progress could not be opened. It may be damaged or temporarily unavailable. Novara has kept the files and stopped automatic saving. Retry after unlocking, or restore a JSON backup in Settings.")
            }
        }
    }

    /// Retry reading without replacing existing files with an empty state.
    public func retryRecovery() {
        saveWorkItem?.cancel()
        saveQueue.sync {}
        let loaded = Self.loadState(from: fileURL)
        recoveryRequired = loaded.blocked
        recoveryNotice = loaded.notice
        storageError = loaded.error
        if !loaded.blocked {
            suppressAutoSave = true
            state = loaded.state
            suppressAutoSave = false
        }
    }

    public func dismissRecoveryNotice() { recoveryNotice = nil }

    @discardableResult
    public func saveImmediately() -> Bool {
        saveWorkItem?.cancel()
        saveRevision += 1
        guard !recoveryRequired else { return false }
        let snapshot = state
        let result = saveQueue.sync { write(snapshot) }
        applySaveResult(result)
        return result == nil
    }

    /// Returns an error instead of discarding it. Both files use atomic replacement.
    private func write(_ snapshot: AppState, replaceBackup: Bool = false) -> String? {
        do {
            let data = try Self.encode(snapshot)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            var backupData = data
            if !replaceBackup, let previous = try? Data(contentsOf: fileURL),
               (try? Self.decode(previous)) != nil {
                backupData = previous
            }
            // Available after the first unlock, including subsequent screen locks.
            let options: Data.WritingOptions = [.atomicWrite, .completeFileProtectionUntilFirstUserAuthentication]
            try backupData.write(to: backupURL, options: options)
            try data.write(to: fileURL, options: options)
            return nil
        } catch {
            return "Your latest changes are still in memory but could not be saved: \(error.localizedDescription) Retry saving or export a JSON backup before closing Novara."
        }
    }

    private func applySaveResult(_ error: String?) {
        storageError = error
        if error == nil { lastSavedAt = Date() }
    }

    private func scheduleAutoSave() {
        saveWorkItem?.cancel()
        saveRevision += 1
        guard !recoveryRequired else { return }
        let revision = saveRevision
        let snapshot = state
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let error = self.write(snapshot)
            DispatchQueue.main.async { [weak self] in
                guard let self, self.saveRevision == revision else { return }
                self.applySaveResult(error)
            }
        }
        saveWorkItem = item
        saveQueue.asyncAfter(deadline: .now() + 0.5, execute: item)
    }

    public func exportJSON() -> String? {
        guard !recoveryRequired, let data = try? Self.encode(state) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func importJSON(_ jsonString: String) -> Result<Void, Error> {
        do {
            guard let data = jsonString.data(using: .utf8) else {
                throw Self.storageFailure("Invalid text encoding.")
            }
            let restored = try Self.decode(data)
            saveWorkItem?.cancel()
            saveRevision += 1
            let error = saveQueue.sync { () -> String? in
                do { try Self.preserveOriginal(at: fileURL) }
                catch { return "The current save could not be preserved: \(error.localizedDescription)" }
                return write(restored, replaceBackup: true)
            }
            if let error { storageError = error; throw Self.storageFailure(error) }
            suppressAutoSave = true
            state = restored
            suppressAutoSave = false
            recoveryRequired = false
            recoveryNotice = "Your JSON backup was restored. The previous save was preserved separately."
            applySaveResult(nil)
            return .success(())
        } catch { return .failure(error) }
    }

    @discardableResult
    public func resetAllData() -> Bool {
        saveWorkItem?.cancel()
        saveRevision += 1
        let fresh = AppState()
        let error = saveQueue.sync { () -> String? in
            if recoveryRequired {
                do { try Self.preserveOriginal(at: fileURL) }
                catch { return "The original save could not be preserved: \(error.localizedDescription)" }
            }
            return write(fresh, replaceBackup: true)
        }
        applySaveResult(error)
        guard error == nil else { return false }
        suppressAutoSave = true
        state = fresh
        suppressAutoSave = false
        recoveryRequired = false
        recoveryNotice = nil
        return true
    }

}

extension AppState {
    /// Equip a newly earned affinity; preserve a chosen unlocked fairy between milestones.
    public mutating func updateFairyProgress(previousXP: Int? = nil) {
        let totalXP = avatar.totalCumulativeXP
        let highest = FairyPalette.highestUnlocked(totalXP: totalXP)
        let crossedMilestone = previousXP.map {
            highest != FairyPalette.highestUnlocked(totalXP: $0)
        } ?? false
        if selectedFairy == nil || !(selectedFairy?.isUnlocked(totalXP: totalXP) ?? false) || crossedMilestone {
            selectedFairy = highest
        }
    }

    /// Normalize display copy without altering URL evidence or stable reward keys.
    public mutating func cleanDisplayText() {
        avatar.name = AscendText.clean(avatar.name)
        avatar.title = AscendText.clean(avatar.title)
        if activeFocusSession != nil { activeFocusSession!.questTitle = AscendText.clean(activeFocusSession!.questTitle) }
        for i in mainQuests.indices {
            mainQuests[i].title = AscendText.clean(mainQuests[i].title)
            mainQuests[i].description = AscendText.clean(mainQuests[i].description)
        }
        for i in subQuests.indices {
            subQuests[i].title = AscendText.clean(subQuests[i].title)
            subQuests[i].description = AscendText.clean(subQuests[i].description)
            switch subQuests[i].completionCondition {
            case .milestoneReached(let text): subQuests[i].completionCondition = .milestoneReached(description: AscendText.clean(text))
            case .deliverableCompleted(let text): subQuests[i].completionCondition = .deliverableCompleted(deliverableName: AscendText.clean(text))
            default: break
            }
        }
        for i in dailyQuests.indices {
            dailyQuests[i].name = AscendText.clean(dailyQuests[i].name)
            dailyQuests[i].description = AscendText.clean(dailyQuests[i].description)
            dailyQuests[i].notes = AscendText.clean(dailyQuests[i].notes)
        }
        for i in sideQuests.indices {
            sideQuests[i].title = AscendText.clean(sideQuests[i].title)
            sideQuests[i].description = AscendText.clean(sideQuests[i].description)
        }
        for i in miniMainQuests.indices {
            miniMainQuests[i].title = AscendText.clean(miniMainQuests[i].title)
            miniMainQuests[i].visionDescription = AscendText.clean(miniMainQuests[i].visionDescription)
        }
        for i in futureSelfRoadmaps.indices {
            futureSelfRoadmaps[i].finalVisionTitle = AscendText.clean(futureSelfRoadmaps[i].finalVisionTitle)
            futureSelfRoadmaps[i].finalVisionDescription = AscendText.clean(futureSelfRoadmaps[i].finalVisionDescription)
            for j in futureSelfRoadmaps[i].stages.indices {
                futureSelfRoadmaps[i].stages[j].title = AscendText.clean(futureSelfRoadmaps[i].stages[j].title)
                futureSelfRoadmaps[i].stages[j].tagline = AscendText.clean(futureSelfRoadmaps[i].stages[j].tagline)
                futureSelfRoadmaps[i].stages[j].description = AscendText.clean(futureSelfRoadmaps[i].stages[j].description)
            }
        }
        for i in dailyPlan.slots.indices {
            dailyPlan.slots[i].title = AscendText.clean(dailyPlan.slots[i].title)
            dailyPlan.slots[i].notes = AscendText.clean(dailyPlan.slots[i].notes)
        }
        for i in xpTransactions.indices {
            xpTransactions[i].title = AscendText.clean(xpTransactions[i].title)
            xpTransactions[i].details = AscendText.clean(xpTransactions[i].details)
        }
        for i in focusSessions.indices {
            focusSessions[i].questTitle = AscendText.clean(focusSessions[i].questTitle)
            focusSessions[i].notes = AscendText.clean(focusSessions[i].notes)
        }
        for i in skillNodes.indices {
            skillNodes[i].name = AscendText.clean(skillNodes[i].name)
            skillNodes[i].description = AscendText.clean(skillNodes[i].description)
        }
        for i in achievements.indices {
            achievements[i].title = AscendText.clean(achievements[i].title)
            achievements[i].description = AscendText.clean(achievements[i].description)
            if achievements[i].id == "ach_first_blood",
               achievements[i].description == "Completed your very first quest in ASCEND." {
                achievements[i].description = "Completed your very first quest in Novara."
            }
        }
        for i in evidenceAttachments.indices {
            evidenceAttachments[i].title = AscendText.clean(evidenceAttachments[i].title)
            if evidenceAttachments[i].type == .note { evidenceAttachments[i].content = AscendText.clean(evidenceAttachments[i].content) }
        }
        if var proposal = dailyPlan.pendingReplanProposal {
            proposal.rationale = AscendText.clean(proposal.rationale)
            proposal.shortenedTasks = proposal.shortenedTasks.map(AscendText.clean)
            proposal.movedTasks = proposal.movedTasks.map(AscendText.clean)
            proposal.deferredTasks = proposal.deferredTasks.map(AscendText.clean)
            for i in proposal.proposedSlots.indices {
                proposal.proposedSlots[i].title = AscendText.clean(proposal.proposedSlots[i].title)
                proposal.proposedSlots[i].notes = AscendText.clean(proposal.proposedSlots[i].notes)
            }
            dailyPlan.pendingReplanProposal = proposal
        }
        if challenge75 != nil {
            for i in challenge75!.days.indices { challenge75!.days[i].notes = AscendText.clean(challenge75!.days[i].notes) }
            for i in challenge75!.weeks.indices {
                challenge75!.weeks[i].gymProgress = AscendText.clean(challenge75!.weeks[i].gymProgress)
                challenge75!.weeks[i].reflection = AscendText.clean(challenge75!.weeks[i].reflection)
                challenge75!.weeks[i].wentWell = AscendText.clean(challenge75!.weeks[i].wentWell)
                challenge75!.weeks[i].improve = AscendText.clean(challenge75!.weeks[i].improve)
            }
        }
    }
}
