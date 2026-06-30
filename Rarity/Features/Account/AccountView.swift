import SwiftUI

struct AccountView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var subscriptions: SubscriptionManager
    @State private var showPaywall = false
    @State private var showConfirmLogout = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 46)).foregroundStyle(Theme.brand)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.user?.username ?? "—")
                                .font(.headline).foregroundStyle(Theme.ink)
                            Text(session.user?.email ?? "")
                                .font(.footnote).foregroundStyle(Theme.sub)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Subscription") {
                    if session.isSubscribed {
                        HStack {
                            Label("Rarity+ Active", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.brand)
                            Spacer()
                            if let exp = session.subscription?.subExpiresAt {
                                Text(exp, style: .date).font(.footnote).foregroundStyle(Theme.hint)
                            }
                        }
                    } else {
                        Button { showPaywall = true } label: {
                            Label("Upgrade to Rarity+", systemImage: "sparkles")
                                .foregroundStyle(Theme.brand)
                        }
                    }
                    Button("Restore Purchases") {
                        Task { await subscriptions.restore() }
                    }
                    .foregroundStyle(Theme.sub)
                }

                Section("Preferences") {
                    NavigationLink("Manage Notifications") {
                        Text("Notification preferences coming soon.")
                            .font(.subheadline).foregroundStyle(Theme.sub)
                            .padding()
                    }
                }

                Section {
                    Button(role: .destructive) { showConfirmLogout = true } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Account")
            .sheet(isPresented: $showPaywall) {
                PaywallView { showPaywall = false }
            }
            .confirmationDialog("Sign out?", isPresented: $showConfirmLogout, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { session.logout() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
