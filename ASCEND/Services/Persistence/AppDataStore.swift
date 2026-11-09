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
        cosmeticCatalogue: [CosmeticItem] = CosmeticCatalogue.allItems
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
    }
}

public final class AppDataStore: ObservableObject, @unchecked Sendable {
    public static let shared = AppDataStore()
    
    @Published public var state: AppState {
        didSet {
            scheduleAutoSave()
        }
    }
    
    private let fileURL: URL
    private let saveQueue = DispatchQueue(label: "com.ascend.appdatastore.save", qos: .utility)
    private var saveWorkItem: DispatchWorkItem?
    
    public init(customFileURL: URL? = nil) {
        if let customFileURL = customFileURL {
            self.fileURL = customFileURL
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let dir = paths.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.fileURL = dir.appendingPathComponent("ascend_state_v1.json")
        }
        
        self.state = AppDataStore.loadState(from: self.fileURL)
    }
    
    // MARK: - Persistence
    
    private static func loadState(from url: URL) -> AppState {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return AppState()
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(AppState.self, from: data)
            return decoded
        } catch {
            print("[AppDataStore] Failed to load data from \(url): \(error). Falling back to fresh state.")
            return AppState()
        }
    }
    
    public func saveImmediately() {
        saveQueue.sync {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(self.state)
                try data.write(to: self.fileURL, options: [.atomicWrite, .completeFileProtection])
            } catch {
                print("[AppDataStore] Save failed: \(error)")
            }
        }
    }
    
    private func scheduleAutoSave() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.saveImmediately()
        }
        saveWorkItem = item
        saveQueue.asyncAfter(deadline: .now() + 0.5, execute: item)
    }
    
    // MARK: - Export & Import
    
    public func exportJSON() -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(self.state)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    public func importJSON(_ jsonString: String) -> Result<Void, Error> {
        guard let data = jsonString.data(using: .utf8) else {
            return .failure(NSError(domain: "AppDataStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid text encoding"]))
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let newState = try decoder.decode(AppState.self, from: data)
            self.state = newState
            self.saveImmediately()
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    public func resetAllData() {
        self.state = AppState()
        saveImmediately()
    }
}
