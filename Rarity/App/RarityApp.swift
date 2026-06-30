import SwiftUI

@main
struct RarityApp: App {
    @StateObject private var session = SessionStore()
    @StateObject private var subscriptions: SubscriptionManager

    init() {
        let s = SessionStore()
        _session = StateObject(wrappedValue: s)
        _subscriptions = StateObject(wrappedValue: SubscriptionManager(session: s))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(subscriptions)
        }
    }
}
