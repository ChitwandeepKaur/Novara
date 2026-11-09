import Foundation

@main
struct TestRunnerMain {
    static func main() {
        print("========================================")
        print("   ASCEND iOS Automated Test Suite")
        print("========================================")
        
        var totalPassed = 0
        var totalFailed = 0
        
        func report(suiteName: String, results: [String: Bool]) {
            print("\n[\(suiteName)]")
            for (testName, passed) in results.sorted(by: { $0.key < $1.key }) {
                if passed {
                    print("  ✅ \(testName)")
                    totalPassed += 1
                } else {
                    print("  ❌ \(testName) FAILED")
                    totalFailed += 1
                }
            }
        }
        
        report(suiteName: "QuestEngineTests", results: QuestEngineTests.runAll())
        report(suiteName: "XPEngineTests", results: XPEngineTests.runAll())
        report(suiteName: "PlanningEngineTests", results: PlanningEngineTests.runAll())
        report(suiteName: "SkillEngineTests", results: SkillEngineTests.runAll())
        report(suiteName: "FutureSelfEngineTests", results: FutureSelfEngineTests.runAll())
        report(suiteName: "PersistenceTests", results: PersistenceTests.runAll())
        
        print("\n========================================")
        print("Results: \(totalPassed) passed, \(totalFailed) failed.")
        print("========================================")
        
        if totalFailed > 0 {
            exit(1)
        }
    }
}

