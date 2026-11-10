import Foundation
import CryptoKit
import Combine
import Security

public enum CloudSyncDecision: Equatable {
    case unchanged, upload, download, conflict
    public static func decide(local: String, remote: String?, base: String?, localIsEmpty: Bool) -> Self {
        guard let remote else { return .upload }
        if local == remote { return .unchanged }
        if localIsEmpty && base == nil { return .download }
        if let base, local == base { return .download }
        if let base, remote == base { return .upload }
        return .conflict
    }
}

public struct CloudConfiguration: Sendable {
    public static var savedProjectURL: String {
        UserDefaults.standard.string(forKey: "novara.cloud.url")
            ?? Bundle.main.object(forInfoDictionaryKey: "NovaraSupabaseURL") as? String ?? ""
    }
    public static var savedPublicKey: String {
        UserDefaults.standard.string(forKey: "novara.cloud.publicKey")
            ?? Bundle.main.object(forInfoDictionaryKey: "NovaraSupabasePublishableKey") as? String ?? ""
    }
    public var url: URL
    public var publicKey: String
    public init(url: String, publicKey: String) throws {
        guard let parsed = URL(string: url.trimmingCharacters(in: .whitespacesAndNewlines)),
              parsed.scheme == "https", let host = parsed.host, host.hasSuffix(".supabase.co"),
              parsed.user == nil, parsed.password == nil, parsed.port == nil,
              parsed.query == nil, parsed.fragment == nil, parsed.path.isEmpty || parsed.path == "/" else {
            throw PlanningConnectionError.message("Enter your Supabase project URL, such as https://your-project.supabase.co.")
        }
        let key = publicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        var isAnon = false
        let parts = key.split(separator: ".")
        if parts.count == 3 {
            var payload = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
            if let data = Data(base64Encoded: payload), let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                isAnon = object["role"] as? String == "anon"
            }
        }
        guard (key.hasPrefix("sb_publishable_") && key.count > 20) || isAnon else {
            throw PlanningConnectionError.message("Use a publishable or anon key. Secret and service-role keys must never be stored in the app.")
        }
        self.url = parsed
        self.publicKey = key
    }
    public func request(path: String, method: String = "GET", token: String? = nil, body: [String: Any]? = nil) throws -> URLRequest {
        var request = URLRequest(url: URL(string: path, relativeTo: url)!.absoluteURL)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue(publicKey, forHTTPHeaderField: "apikey")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        return request
    }
    public func send(path: String, method: String = "GET", token: String? = nil, body: [String: Any]? = nil) async throws -> Data {
        let request = try request(path: path, method: method, token: token, body: body)
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw PlanningConnectionError.message("Cloud request failed (HTTP \(code)). Check your account, project setup, and network. Your local progress has not been removed.")
        }
        guard data.count <= 25_000_000 else { throw PlanningConnectionError.message("The cloud response is too large.") }
        return data
    }
}

private struct CloudAuthSession: Codable {
    struct User: Codable { var id: UUID; var email: String? }
    var access_token: String
    var refresh_token: String
    var expires_at: TimeInterval?
    var user: User
}

private enum CloudCredential {
    static func read(project: String) -> Data? {
        var result: CFTypeRef?
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.ascend.cloud",
            kSecAttrAccount as String: project, kSecReturnData as String: true]
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }
    static func save(_ data: Data, project: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.ascend.cloud", kSecAttrAccount as String: project]
        let attributes: [String: Any] = [kSecValueData as String: data, kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            attributes.forEach { item[$0.key] = $0.value }
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw PlanningConnectionError.message("Could not save your cloud session to Keychain.") }
        } else if status != errSecSuccess { throw PlanningConnectionError.message("Could not update your cloud session in Keychain.") }
    }
    static func remove(project: String) throws {
        let status = SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.ascend.cloud", kSecAttrAccount as String: project] as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw PlanningConnectionError.message("Could not remove your cloud session from Keychain. Unlock and try again.") }
    }
}

@MainActor
public final class CloudSyncService: ObservableObject {
    public static let shared = CloudSyncService()
    @Published public var enabled: Bool = UserDefaults.standard.bool(forKey: "novara.cloud.enabled") {
        didSet { UserDefaults.standard.set(enabled, forKey: "novara.cloud.enabled") }
    }
    @Published public private(set) var status = "Cloud sync is off. Progress is saved on this device."
    @Published public private(set) var hasConflict = false
    @Published public private(set) var isSyncing = false
    @Published public private(set) var accountEmail: String?
    private var syncAgain = false
    private var remoteConflict: CloudRow?
    private var auth: CloudAuthSession?
    private var baseKey: String?
    private struct CloudRow: Decodable { var user_id: UUID; var state_json: String; var fingerprint: String; var version: UUID }
    public var isConfigured: Bool { configuration != nil }
    public var isSignedIn: Bool { auth != nil }
    public var conflictXPDescription: String {
        guard let row = remoteConflict, let data = row.state_json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let avatar = object["avatar"] as? [String: Any], let xp = avatar["totalCumulativeXP"] as? Int else { return "progress available" }
        return "\(xp.formatted()) lifetime XP"
    }
    private var configuration: CloudConfiguration? {
        try? CloudConfiguration(url: CloudConfiguration.savedProjectURL,
            publicKey: CloudConfiguration.savedPublicKey)
    }
    private init() {
        if let config = configuration, let data = CloudCredential.read(project: config.url.host!),
           let session = try? JSONDecoder().decode(CloudAuthSession.self, from: data) {
            auth = session
            accountEmail = session.user.email
        }
    }
    public func configure(url: String, publicKey: String) throws {
        guard !isSignedIn && !isSyncing else { throw PlanningConnectionError.message("Sign out before changing cloud projects.") }
        let config = try CloudConfiguration(url: url, publicKey: publicKey)
        UserDefaults.standard.set(config.url.absoluteString, forKey: "novara.cloud.url")
        UserDefaults.standard.set(config.publicKey, forKey: "novara.cloud.publicKey")
        status = "Project configured. Sign in to your Novara cloud account."
    }
    public func authenticate(email: String, password: String, createAccount: Bool) async throws {
        guard let config = configuration else { throw PlanningConnectionError.message("Save your Supabase project settings first.") }
        guard !isSyncing, email.contains("@"), password.count >= 6 else { throw PlanningConnectionError.message("Enter your email and password (at least 6 characters).") }
        isSyncing = true
        defer { isSyncing = false }
        let data = try await config.send(path: createAccount ? "/auth/v1/signup" : "/auth/v1/token?grant_type=password", method: "POST",
            body: ["email": email.trimmingCharacters(in: .whitespacesAndNewlines), "password": password])
        if let session = try? JSONDecoder().decode(CloudAuthSession.self, from: data) {
            try remember(session, config: config)
            status = "Signed in. Enable cloud sync to upload and download your progress."
        } else if createAccount {
            status = "Check your email to confirm the account, then sign in here."
        } else { throw PlanningConnectionError.message("Sign-in did not return a session. Confirm your email and try again.") }
    }
    public func signOut() throws {
        guard !isSyncing else { return }
        if let config = configuration { try CloudCredential.remove(project: config.url.host!) }
        enabled = false
        auth = nil
        accountEmail = nil
        remoteConflict = nil
        hasConflict = false
        status = "Signed out on this device. Your local progress and cloud copy were kept."
    }
    private func remember(_ session: CloudAuthSession, config: CloudConfiguration) throws {
        try CloudCredential.save(JSONEncoder().encode(session), project: config.url.host!)
        auth = session
        accountEmail = session.user.email
    }
    nonisolated public static func fingerprint(_ json: String) -> String {
        SHA256.hash(data: Data(json.utf8)).map { String(format: "%02x", $0) }.joined()
    }
    private func validSession(config: CloudConfiguration) async throws -> CloudAuthSession {
        guard var session = auth else { throw PlanningConnectionError.message("Sign in to cloud sync first.") }
        if (session.expires_at ?? 0) < Date().timeIntervalSince1970 + 60 {
            let data = try await config.send(path: "/auth/v1/token?grant_type=refresh_token", method: "POST", body: ["refresh_token": session.refresh_token])
            session = try JSONDecoder().decode(CloudAuthSession.self, from: data)
            try remember(session, config: config)
        }
        return session
    }
    public func sync(store: AppDataStore) async {
        guard enabled else { return }
        guard let config = configuration, isSignedIn else { status = "Configure and sign in to your cloud project first."; return }
        guard !store.recoveryRequired, !hasConflict else { return }
        guard !isSyncing else { syncAgain = true; return }
        isSyncing = true
        defer {
            isSyncing = false
            if syncAgain { syncAgain = false; Task { await self.sync(store: store) } }
        }
        do {
            status = "Syncing..."
            let session = try await validSession(config: config)
            let user = session.user.id.uuidString
            let key = "novara.cloud.base.\(config.url.host!).\(user)"
            baseKey = key
            guard enabled, store.storageError == nil, let json = store.exportJSON() else { return }
            let local = Self.fingerprint(json)
            let data = try await config.send(path: "/rest/v1/novara_saves?user_id=eq.\(user)&select=user_id,state_json,fingerprint,version", token: session.access_token)
            let rows = try JSONDecoder().decode([CloudRow].self, from: data)
            let remote = rows.first
            if let remote { try validate(remote) }
            guard enabled else { return }
            guard store.exportJSON().map(Self.fingerprint) == local else { syncAgain = true; return }
            let empty = !store.state.isOnboarded && store.state.mainQuests.isEmpty && store.state.dailyQuests.isEmpty
                && store.state.avatar.totalCumulativeXP == 0 && store.state.challenge75 == nil && store.state.activeFocusSession == nil
            switch CloudSyncDecision.decide(local: local, remote: remote?.fingerprint,
                base: UserDefaults.standard.string(forKey: key), localIsEmpty: empty) {
            case .unchanged: UserDefaults.standard.set(local, forKey: key)
            case .upload:
                try await upload(json: json, replacing: remote, config: config, session: session)
                UserDefaults.standard.set(local, forKey: key)
            case .download:
                if let remote {
                    try store.importJSON(remote.state_json).get()
                    UserDefaults.standard.set(remote.fingerprint, forKey: key)
                }
            case .conflict:
                remoteConflict = remote
                hasConflict = true
                status = "This device and the cloud have different progress. Choose a copy in Online Services. Neither has been overwritten."
                return
            }
            status = "Synced at \(Date().formatted(date: .omitted, time: .shortened))."
        } catch {
            status = "Cloud sync could not finish: \(error.localizedDescription) Local progress is kept. Sync retries on your next save or when you reopen Novara."
        }
    }
    private func validate(_ row: CloudRow) throws {
        guard row.user_id == auth?.user.id, row.state_json.utf8.count <= 20_000_000,
              Self.fingerprint(row.state_json) == row.fingerprint else {
            throw PlanningConnectionError.message("The cloud copy did not pass its integrity check.")
        }
    }
    private func upload(json: String, replacing row: CloudRow?, config: CloudConfiguration, session: CloudAuthSession) async throws {
        let user = session.user.id.uuidString
        let path = row.map { "/rest/v1/novara_saves?user_id=eq.\(user)&version=eq.\($0.version.uuidString)" } ?? "/rest/v1/novara_saves"
        let data = try await config.send(path: path, method: row == nil ? "POST" : "PATCH", token: session.access_token,
            body: ["user_id": user, "state_json": json, "fingerprint": Self.fingerprint(json), "version": UUID().uuidString])
        let saved = try JSONDecoder().decode([CloudRow].self, from: data)
        guard saved.count == 1 else { throw PlanningConnectionError.message("The cloud copy changed during sync. Sync again to resolve the newer versions.") }
    }
    public func restoreFromCloud(store: AppDataStore) async {
        guard !isSyncing, let config = configuration, isSignedIn else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let session = try await validSession(config: config)
            let user = session.user.id.uuidString
            let data = try await config.send(path: "/rest/v1/novara_saves?user_id=eq.\(user)&select=user_id,state_json,fingerprint,version", token: session.access_token)
            guard let row = try JSONDecoder().decode([CloudRow].self, from: data).first else {
                throw PlanningConnectionError.message("There is no saved cloud copy for this account yet.")
            }
            try validate(row)
            try store.importJSON(row.state_json).get()
            UserDefaults.standard.set(row.fingerprint, forKey: "novara.cloud.base.\(config.url.host!).\(user)")
            remoteConflict = nil
            hasConflict = false
            status = "Your cloud progress was restored. The previous local save was preserved."
        } catch { status = "Cloud restore failed: \(error.localizedDescription) Your existing files were kept." }
    }
    public func resolveConflict(useCloud: Bool, store: AppDataStore) async {
        guard enabled, !isSyncing, let config = configuration, let remote = remoteConflict, let key = baseKey else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            if useCloud {
                try store.importJSON(remote.state_json).get()
                UserDefaults.standard.set(remote.fingerprint, forKey: key)
            } else {
                let session = try await validSession(config: config)
                guard let json = store.exportJSON(), store.saveImmediately() else { return }
                let preserved = store.backupURL.deletingLastPathComponent().appendingPathComponent("novara-cloud-conflict-\(UUID()).json")
                try Data(remote.state_json.utf8).write(to: preserved, options: [.atomicWrite, .completeFileProtectionUntilFirstUserAuthentication])
                try await upload(json: json, replacing: remote, config: config, session: session)
                UserDefaults.standard.set(Self.fingerprint(json), forKey: key)
            }
            hasConflict = false
            remoteConflict = nil
            status = "Your chosen copy is saved. The other version was preserved on this device."
        } catch {
            hasConflict = false
            remoteConflict = nil
            status = "Could not resolve the conflict: \(error.localizedDescription) Sync again to check the latest copies."
        }
    }
}
