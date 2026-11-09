import Foundation

public struct PersistenceTests {
    public static func runAll() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        results["testStateEncodingAndDecoding"] = testStateEncodingAndDecoding()
        results["testExportAndImportJSON"] = testExportAndImportJSON()
        results["testResetAllData"] = testResetAllData()
        
        return results
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
