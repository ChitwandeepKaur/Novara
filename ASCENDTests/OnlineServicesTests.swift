import Foundation

public enum OnlineServicesTests {
    public static func runAll() -> [String: Bool] {
        ["legacyPaidPreferenceCannotEnableOnlinePlanning": freePlanning(),
         "cloudConflictsNeverSilentlyOverwriteDivergentCopies": syncDecisions(),
         "cloudConfigurationRejectsSecretsAndUnsafeHosts": cloudConfiguration(),
         "cloudUpdatesUseVersionChecks": versionedRequest()]
    }
    private static func freePlanning() -> Bool {
        let key = "novara.onlinePlanning.enabled"
        let old = UserDefaults.standard.object(forKey: key)
        defer {
            if let old { UserDefaults.standard.set(old, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        UserDefaults.standard.set(true, forKey: key)
        return !PlanningProvider.isOnline
    }
    private static func syncDecisions() -> Bool {
        CloudSyncDecision.decide(local: "A", remote: nil, base: nil, localIsEmpty: false) == .upload
            && CloudSyncDecision.decide(local: "A", remote: "A", base: nil, localIsEmpty: false) == .unchanged
            && CloudSyncDecision.decide(local: "A", remote: "B", base: "A", localIsEmpty: false) == .download
            && CloudSyncDecision.decide(local: "B", remote: "A", base: "A", localIsEmpty: false) == .upload
            && CloudSyncDecision.decide(local: "B", remote: "C", base: "A", localIsEmpty: false) == .conflict
            && CloudSyncDecision.decide(local: "B", remote: "C", base: nil, localIsEmpty: false) == .conflict
            && CloudSyncDecision.decide(local: "empty", remote: "C", base: nil, localIsEmpty: true) == .download
    }
    private static let publicKey = "sb_publishable_test_fixture_only"
    private static func cloudConfiguration() -> Bool {
        do {
            _ = try CloudConfiguration(url: "https://example.supabase.co", publicKey: publicKey)
            for url in ["http://example.supabase.co", "https://example.supabase.co.evil.test", "https://user:password@example.supabase.co", "https://example.supabase.co/path"] {
                do { _ = try CloudConfiguration(url: url, publicKey: publicKey); return false } catch { }
            }
            for key in ["sb_secret_do_not_accept", "not-a-public-key"] {
                do { _ = try CloudConfiguration(url: "https://example.supabase.co", publicKey: key); return false } catch { }
            }
            return true
        } catch { return false }
    }
    private static func versionedRequest() -> Bool {
        do {
            let config = try CloudConfiguration(url: "https://example.supabase.co", publicKey: publicKey)
            let request = try config.request(path: "/rest/v1/novara_saves?user_id=eq.test&version=eq.old-version", method: "PATCH", token: "test-token", body: ["version": "new-version"])
            return request.httpMethod == "PATCH" && request.url?.query?.contains("version=eq.old-version") == true
                && request.value(forHTTPHeaderField: "apikey") == publicKey
                && request.value(forHTTPHeaderField: "Prefer") == "return=representation"
        } catch { return false }
    }
}
