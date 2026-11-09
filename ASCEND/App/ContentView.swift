import SwiftUI

public struct ContentView: View {
    @ObservedObject var store: AppDataStore = AppDataStore.shared
    
    public init(store: AppDataStore = AppDataStore.shared) {
        self.store = store
    }
    
    public var body: some View {
        Group {
            if store.state.isOnboarded {
                MainTabView(store: store)
            } else {
                OnboardingFlowView(store: store)
            }
        }
        .preferredColorScheme(.dark)
    }
}
