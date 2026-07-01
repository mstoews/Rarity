import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var subscriptions: SubscriptionManager
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 10) {
                    Circle()
                        .strokeBorder(Theme.separator, lineWidth: 1)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 22, weight: .light))
                                .foregroundStyle(Theme.brand)
                        )

                    Text("Rarity+")
                        .font(.cormorant(size: 38))
                        .foregroundStyle(Theme.ink)

                    Text("Discover every detail of specialty beauty")
                        .font(.atelierBody)
                        .foregroundStyle(Theme.sub)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    featureRow("Full ingredients & product detail",    icon: "list.bullet.rectangle")
                    featureRow("Store locations & directions",         icon: "mappin.and.ellipse")
                    featureRow("Community reviews & photos",           icon: "star.bubble")
                    featureRow("Unlimited wishlist & saved items",     icon: "heart.text.square")
                }
                .padding(.horizontal, Metrics.page)

                // Plan tiles
                if subscriptions.isLoadingProducts {
                    ProgressView()
                } else {
                    VStack(spacing: 12) {
                        ForEach(subscriptions.products) { product in
                            PlanTileView(product: product, trialEligible: subscriptions.trialEligible) {
                                Task {
                                    if await subscriptions.purchase(product) { onDismiss() }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Metrics.page)
                }

                if let err = subscriptions.errorMessage {
                    Text(err)
                        .font(.atelierCaption)
                        .foregroundStyle(Theme.destructive)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button("Restore Purchases") {
                    Task { if await subscriptions.restore() { onDismiss() } }
                }
                .font(.atelierCaption)
                .foregroundStyle(Theme.hint)

                Spacer(minLength: 20)
            }
        }
        .background(Theme.page.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button { onDismiss() } label: {
                Circle()
                    .fill(Theme.card2)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.sub)
                    )
            }
            .padding([.top, .trailing], 16)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                guard let first = subscriptions.products.first else { return }
                Task { if await subscriptions.purchase(first) { onDismiss() } }
            } label: {
                Text(subscriptions.trialEligible ? "Start Free Trial" : "Subscribe")
                    .primaryButtonLabel()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusButton))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Metrics.page)
            .padding(.vertical, 14)
            .background(Theme.page.opacity(0.96))
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.separator).frame(height: 0.5)
            }
        }
        .task { await subscriptions.loadProducts() }
    }

    private func featureRow(_ text: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Theme.brand)
                .frame(width: 24)
            Text(text)
                .font(.atelierBody)
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}

private struct PlanTileView: View {
    let product: Product
    let trialEligible: Bool
    let onTap: () -> Void

    private var isAnnual: Bool { product.id.contains("annual") }

    private var badge: String? {
        guard isAnnual else { return nil }
        if trialEligible,
           let offer = product.subscription?.introductoryOffer,
           offer.paymentMode == .freeTrial {
            return "Best value · 7-day trial"
        }
        return "Best value"
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(product.displayName)
                            .font(.atelierCardName)
                            .foregroundStyle(Theme.ink)
                        if !product.description.isEmpty {
                            Text(product.description)
                                .font(.atelierCaption)
                                .foregroundStyle(Theme.sub)
                        }
                    }
                    Spacer()
                    Text(product.displayPrice)
                        .font(.cormorant(size: 22))
                        .foregroundStyle(isAnnual ? Theme.brand : Theme.ink)
                }
                .padding(16)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusTile))
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.radiusTile)
                        .stroke(
                            isAnnual ? Theme.brand : Theme.separator,
                            lineWidth: isAnnual ? 1.5 : 1
                        )
                )
                .padding(.top, badge != nil ? 9 : 0)

                if let label = badge {
                    Text(label)
                        .font(.jost(.semibold, size: 9))
                        .tracking(1.5)
                        .textCase(.uppercase)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(Theme.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .padding(.leading, 16)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
