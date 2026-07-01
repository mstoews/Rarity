import SwiftUI

struct AccountView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var subscriptions: SubscriptionManager
    @State private var showPaywall = false
    @State private var showConfirmLogout = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile header
                    profileHeader
                        .padding(.horizontal, Metrics.page)
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                    // Subscription card
                    subscriptionCard
                        .padding(.horizontal, Metrics.page)
                        .padding(.bottom, 24)

                    // Preferences
                    preferencesSection
                        .padding(.horizontal, Metrics.page)
                        .padding(.bottom, 24)

                    // Sign out
                    Button(role: .destructive) { showConfirmLogout = true } label: {
                        Text("Sign Out")
                            .font(.jost(size: 14))
                            .foregroundStyle(Theme.destructive)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusTile))
                            .overlay(
                                RoundedRectangle(cornerRadius: Metrics.radiusTile)
                                    .stroke(Theme.separator, lineWidth: 0.5)
                            )
                    }
                    .padding(.horizontal, Metrics.page)
                }
                .padding(.bottom, 32)
            }
            .background(Theme.page.ignoresSafeArea())
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                PaywallView { showPaywall = false }
            }
            .confirmationDialog("Sign out?", isPresented: $showConfirmLogout, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { session.logout() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 14) {
            // Gradient avatar circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xE8C9D1), Color(hex: 0xCAA6B2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Text(initials)
                        .font(.cormorant(size: 24))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(session.user?.username ?? "—")
                    .font(.cormorant(size: 22))
                    .foregroundStyle(Theme.ink)
                if let email = session.user?.email {
                    Text(email)
                        .font(.atelierCaption)
                        .foregroundStyle(Theme.sub)
                }
            }
        }
    }

    private var subscriptionCard: some View {
        Group {
            if session.isSubscribed {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.brand)
                        Text("Rarity+ · Active")
                            .font(.cormorant(size: 18))
                            .foregroundStyle(Theme.brand)
                    }
                    Spacer()
                    if let exp = session.subscription?.subExpiresAt {
                        Text(exp, style: .date)
                            .font(.atelierCaption)
                            .foregroundStyle(Theme.hint)
                    }
                }
                .padding(16)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusTile))
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.radiusTile)
                        .stroke(Theme.separator, lineWidth: 0.5)
                )
            } else {
                Button { showPaywall = true } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .light))
                        Text("Upgrade to Rarity+")
                            .font(.cormorant(size: 18))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Theme.brand)
                    .padding(16)
                    .background(Theme.brandSoft)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusTile))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Preferences")
                .font(.jost(.semibold, size: 11))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(Theme.sub)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                preferenceRow("Notifications", destination: notificationsPlaceholder)
                Rectangle().fill(Theme.separator).frame(height: 0.5).padding(.leading, 16)
                preferenceRow("Restore Purchases", destination: restorePlaceholder)
                Rectangle().fill(Theme.separator).frame(height: 0.5).padding(.leading, 16)
                preferenceRow("Help & Support", destination: helpPlaceholder)
            }
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusTile))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.radiusTile)
                    .stroke(Theme.separator, lineWidth: 0.5)
            )
        }
    }

    @ViewBuilder
    private func preferenceRow<D: View>(_ title: String, destination: D) -> some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title)
                    .font(.jost(size: 14))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.hint)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var notificationsPlaceholder: some View {
        Text("Notification preferences coming soon.")
            .font(.atelierBody).foregroundStyle(Theme.sub).padding()
    }

    private var restorePlaceholder: some View {
        Group {
            EmptyView()
                .task { await subscriptions.restore() }
        }
    }

    private var helpPlaceholder: some View {
        Text("Help & support coming soon.")
            .font(.atelierBody).foregroundStyle(Theme.sub).padding()
    }

    private var initials: String {
        guard let name = session.user?.username, let first = name.first else { return "?" }
        return String(first).uppercased()
    }
}
