import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var subscriptions: SubscriptionManager
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 56)).foregroundStyle(Theme.brand)
                    Text("Rarity+").font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                    Text("Discover every detail about specialty beauty")
                        .font(.subheadline).foregroundStyle(Theme.sub)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // Features
                VStack(spacing: 14) {
                    featureRow("Full product details & ingredients", icon: "list.bullet.rectangle")
                    featureRow("Store locations with directions",     icon: "mappin.and.ellipse")
                    featureRow("Community reviews & photos",          icon: "star.bubble")
                    featureRow("Wishlist & saved items",              icon: "heart.text.square")
                }
                .padding(.horizontal, Metrics.page)

                // Products
                if subscriptions.isLoadingProducts {
                    ProgressView()
                } else {
                    VStack(spacing: 12) {
                        ForEach(subscriptions.products) { product in
                            ProductTileView(product: product,
                                           trialEligible: subscriptions.trialEligible) {
                                Task {
                                    if await subscriptions.purchase(product) { onDismiss() }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Metrics.page)
                }

                if let err = subscriptions.errorMessage {
                    Text(err).font(.footnote).foregroundStyle(Theme.systemRed)
                        .multilineTextAlignment(.center).padding(.horizontal)
                }

                Button("Restore Purchases") {
                    Task { if await subscriptions.restore() { onDismiss() } }
                }
                .font(.footnote).foregroundStyle(Theme.hint)

                Spacer(minLength: 20)
            }
        }
        .background(Theme.page.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28)).foregroundStyle(Theme.hint)
            }
            .padding([.top, .trailing], 16)
        }
        .task { await subscriptions.loadProducts() }
    }

    private func featureRow(_ text: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20)).foregroundStyle(Theme.brand)
                .frame(width: 32)
            Text(text).font(.subheadline).foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}

private struct ProductTileView: View {
    let product: Product
    let trialEligible: Bool
    let onTap: () -> Void

    private var isAnnual: Bool { product.id.contains("annual") }
    private var trialBadge: String? {
        guard isAnnual, trialEligible,
              let offer = product.subscription?.introductoryOffer else { return nil }
        if offer.paymentMode == .freeTrial { return "Free trial" }
        return nil
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(product.displayName).font(.subheadline.bold()).foregroundStyle(Theme.ink)
                            if let badge = trialBadge {
                                Text(badge).font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Theme.brand).clipShape(Capsule())
                            }
                        }
                        if !product.description.isEmpty {
                            Text(product.description).font(.footnote).foregroundStyle(Theme.sub)
                        }
                    }
                    Spacer()
                    Text(product.displayPrice)
                        .font(.headline).foregroundStyle(Theme.brand)
                }
            }
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusCard))
            .overlay(isAnnual
                ? RoundedRectangle(cornerRadius: Metrics.radiusCard).stroke(Theme.brand, lineWidth: 2)
                : RoundedRectangle(cornerRadius: Metrics.radiusCard).stroke(Theme.separator, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
