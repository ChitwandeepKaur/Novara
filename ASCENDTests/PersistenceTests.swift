import Foundation

public struct PersistenceTests {
    public static func runAll() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        results["testStateEncodingAndDecoding"] = testStateEncodingAndDecoding()
        results["testExportAndImportJSON"] = testExportAndImportJSON()
        results["testResetAllData"] = testResetAllData()
        
        results["damagedSaveRecoversPreviousGoodCopy"] = damagedSaveRecoversPreviousGoodCopy()
        results["unrecoverableSaveIsPreservedUntilRestore"] = unrecoverableSaveIsPreservedUntilRestore()
        results["diskFailureIsVisibleAndExportStillWorks"] = diskFailureIsVisibleAndExportStillWorks()
        results["invalidRestoreCannotReplaceProgress"] = invalidRestoreCannotReplaceProgress()
        results["resetReplacesRecoveryBackup"] = resetReplacesRecoveryBackup()
        results["activeFocusSurvivesDiskReload"] = activeFocusSurvivesDiskReload()
        return results
    }
    
    private static func withStore(_ test: (URL) throws -> Bool) -> Bool {
        let folder = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("novara-test-\(UUID())")
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: folder) }
            return try test(folder.appendingPathComponent("state.json"))
        } catch { print("Persistence check failed: \(error)"); return false }
    }
    private static func damagedSaveRecoversPreviousGoodCopy() -> Bool {
        withStore { url in
            let store = AppDataStore(customFileURL: url)
            store.state.avatar.name = "First copy"
            guard store.saveImmediately() else { return false }
            store.state.avatar.name = "Latest copy"
            guard store.saveImmediately() else { return false }
            try Data("damaged".utf8).write(to: url)
            let recovered = AppDataStore(customFileURL: url)
            let files = try FileManager.default.contentsOfDirectory(atPath: url.deletingLastPathComponent().path)
            guard recovered.state.avatar.name == "First copy", !recovered.recoveryRequired,
                  recovered.recoveryNotice != nil, files.contains(where: { $0.hasPrefix("novara-recovery-") }) else { return false }
            return recovered.saveImmediately() && AppDataStore(customFileURL: url).state.avatar.name == "First copy"
        }
    }
    private static func unrecoverableSaveIsPreservedUntilRestore() -> Bool {
        withStore { url in
            let damaged = Data("unreadable progress".utf8)
            try damaged.write(to: url)
            let store = AppDataStore(customFileURL: url)
            guard store.recoveryRequired, store.storageError != nil, !store.saveImmediately(),
                  store.exportJSON() == nil, try Data(contentsOf: url) == damaged else { return false }
            let fresh = AppDataStore(customFileURL: url.deletingLastPathComponent().appendingPathComponent("fresh.json"))
            fresh.state.avatar.name = "Restored hero"
            guard let json = fresh.exportJSON() else { return false }
            if case .failure = store.importJSON(json) { return false }
            return !store.recoveryRequired && store.state.avatar.name == "Restored hero"
                && AppDataStore(customFileURL: url).state.avatar.name == "Restored hero"
        }
    }
    private static func diskFailureIsVisibleAndExportStillWorks() -> Bool {
        withStore { url in
            try Data("not a folder".utf8).write(to: url)
            let store = AppDataStore(customFileURL: url.appendingPathComponent("state.json"))
            store.state.avatar.name = "Keep me"
            return !store.saveImmediately() && store.storageError != nil
                && store.exportJSON()?.contains("Keep me") == true
        }
    }
    private static func invalidRestoreCannotReplaceProgress() -> Bool {
        withStore { url in
            let store = AppDataStore(customFileURL: url)
            store.state.avatar.name = "Do not replace"
            guard store.saveImmediately() else { return false }
            let original = try Data(contentsOf: url)
            for text in ["{}", "not JSON", "{\"avatar\":{},\"schemaVersion\":99}"] {
                if case .success = store.importJSON(text) { return false }
            }
            let after = try Data(contentsOf: url)
            return store.state.avatar.name == "Do not replace" && after == original
        }
    }
    private static func resetReplacesRecoveryBackup() -> Bool {
        withStore { url in
            let store = AppDataStore(customFileURL: url)
            store.state.avatar.totalCumulativeXP = 12_000
            guard store.saveImmediately(), store.resetAllData() else { return false }
            try Data("damaged".utf8).write(to: url)
            let restored = AppDataStore(customFileURL: url)
            return !restored.recoveryRequired && restored.state.avatar.totalCumulativeXP == 0
                && restored.state.selectedFairy == .flora
        }
    }
    private static func activeFocusSurvivesDiskReload() -> Bool {
        withStore { url in
            let store = AppDataStore(customFileURL: url)
            FocusSessionEngine.start(quest: nil, in: &store.state)
            store.state.activeFocusSession?.pause()
            let id = store.state.activeFocusSession?.id
            guard store.saveImmediately() else { return false }
            let restored = AppDataStore(customFileURL: url)
            return restored.state.activeFocusSession?.id == id
                && restored.state.activeFocusSession?.runStartedAt == nil
        }
    }

    private static func testStateEncodingAndDecoding() -> Bool {
        var state = AppState()
        state.isOnboarded = true
        state.avatar.name = "Test Hero"
        state.avatar.totalCumulativeXP = 1500
        state.mainQuests = [MainQuest(title: "Land a Dream Job", status: .active)]
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(state)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(AppState.self, from: data)
            
            return decoded.isOnboarded &&
                decoded.avatar.name == "Test Hero" &&
                decoded.avatar.totalCumulativeXP == 1500 &&
                decoded.mainQuests.count == 1 &&
                decoded.mainQuests.first?.title == "Land a Dream Job"
        } catch {
            print("Encoding error: \(error)")
            return false
        }
    }
    
    private static func testExportAndImportJSON() -> Bool {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_store_\(UUID().uuidString).json")
        let store = AppDataStore(customFileURL: tempURL)
        
        store.state.avatar.name = "Archivist"
        store.state.avatar.totalCumulativeXP = 3400
        
        guard let jsonString = store.exportJSON(), !jsonString.isEmpty else { return false }
        
        // Wipe and restore
        store.resetAllData()
        let preRestoreName = store.state.avatar.name
        
        let importResult = store.importJSON(jsonString)
        let postRestoreName = store.state.avatar.name
        let postRestoreXP = store.state.avatar.totalCumulativeXP
        
        try? FileManager.default.removeItem(at: tempURL)
        
        if case .success = importResult {
            return preRestoreName == "Traveler" && postRestoreName == "Archivist" && postRestoreXP == 3400
        }
        return false
    }
    
    private static func testResetAllData() -> Bool {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_reset_\(UUID().uuidString).json")
        let store = AppDataStore(customFileURL: tempURL)
        
        store.state.isOnboarded = true
        store.state.avatar.totalCumulativeXP = 9000
        store.resetAllData()
        
        let isClean = !store.state.isOnboarded && store.state.avatar.totalCumulativeXP == 0
        try? FileManager.default.removeItem(at: tempURL)
        return isClean
    }
}

