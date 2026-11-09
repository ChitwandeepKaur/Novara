import SwiftUI

@main
struct ASCENDApp: App {
    @StateObject private var store = AppDataStore.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
