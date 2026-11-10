import SwiftUI

@main
struct NovaraApp: App {
    @StateObject private var store = AppDataStore.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
