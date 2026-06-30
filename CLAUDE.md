# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Generate .xcodeproj from project.yml (required after adding/removing files)
xcodegen generate

# Build for simulator from CLI
xcodebuild -project Rarity.xcodeproj -scheme Rarity \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  ARCHS=x86_64 build

# List available simulators
xcrun simctl list devices available | grep iPhone

# Install and launch on a booted simulator
xcrun simctl install booted DerivedData/.../Rarity.app
xcrun simctl launch  booted com.mapleon.rarity
```

Open `Rarity.xcodeproj` in Xcode (not a workspace — no CocoaPods). Deployment target is **iOS 17.0**. No third-party dependencies; everything is native Swift.

The Go backend must be running for any API calls to succeed. See `rarity-go-server` (sibling repo) — `make server` starts it on port 8092. Override the base URL via the `RARITY_API_BASE_URL` env var in the scheme's Run environment.

## Architecture

SwiftUI + MVVM. iOS 17.0 minimum — `ContentUnavailableView`, `onChange(of:)` two-arg form, and `NavigationStack` are used freely.

**Entry point:** `App/RarityApp.swift` — creates `SessionStore` and `SubscriptionManager`, injects both as `@EnvironmentObject` into the root. The two objects share the same `SessionStore` instance (passed explicitly in `init()` to wire `SubscriptionManager.session`).

**Navigation:** `App/RootView.swift` switches between `AuthView` and `MainTabView` based on `SessionStore.isAuthenticated`. `App/MainTabView.swift` is a 4-tab `TabView`: Discover, Stores, Saved, Account.

**Source layout:**
- `App/` — app entry, root view, tab bar
- `Auth/` — `SessionStore` (auth state + subscription), `KeychainStore` (Security framework token persistence)
- `Networking/` — `APIClient` (shared singleton), `APIError`
- `Models/` — all `Codable` DTOs
- `StoreKit/` — `SubscriptionManager` (StoreKit 2 purchase/restore/transaction listener)
- `Config/` — `AppConfig` (base URL, StoreKit product IDs)
- `DesignSystem/` — `Theme` (color tokens), `Metrics` (spacing/radius constants), `Color+Hex`
- `Components/` — `CosmeticCardView`, `StarRatingView`/`StarPickerView`, `CategoryChips`
- `Features/` — one folder per screen (Auth, Browse, CosmeticDetail, Stores, Wishlist, Paywall, Account)

## APIClient

**`APIClient.shared` is the only instance in use.** `SessionStore.init()` configures it with the token provider and refresh hook. Every ViewModel receives `APIClient.shared` — never construct `APIClient()` directly, as it would have no auth token and all requests would 401.

The client handles 401 automatically: it calls `tokenRefresher` (which POSTs `/auth/refresh`), then retries the original request once. If the refresh also fails, it throws `APIError.unauthorized`, which `SessionStore.loadSubscription()` catches to trigger logout.

## Auth & Session

`SessionStore` is `@MainActor`. Key properties:
- `isAuthenticated` — drives `RootView` gate; set by `tokens.didSet`
- `isSubscribed` — `subscription?.isActive ?? false`; controls paywall visibility

Tokens are stored in Keychain via `KeychainStore` (Security framework, `kSecClassGenericPassword`). `AuthUser` is cached in `UserDefaults` for display before the first API round-trip.

After login, `apply()` sets tokens and fires `loadSubscription()`. `bootstrap()` is called from `RootView.task` on first app launch; it's a no-op if not authenticated (handles the cold-start case where stored tokens are restored from Keychain).

## Subscription & Paywall

`SubscriptionManager` wraps StoreKit 2. Call `loadProducts()` before showing `PaywallView`. The `purchase(_:)` and `restore()` methods call `session.verifySubscription(signedTransaction:)` which POSTs the JWS transaction to the backend for server-side verification.

The paywall is triggered two ways:
1. **402 from backend** — `CosmeticDetailViewModel.load()` catches `APIError.paymentRequired` and sets `showPaywall = true`
2. **`session.isSubscribed == false`** — `BrowseView` and `WishlistView` gate UI locally without a network call

Free tier receives cosmetic `name`, `brand`, and `image_url` from `GET /cosmetics`. `GET /cosmetics/{id}` returns 402 for non-subscribers; the paid tier gets full detail including stores, ingredients, and reviews.

## Design System

All colors come from `Theme` and all spacing/radius from `Metrics` — never use raw `Color` literals or magic numbers in views.

Brand palette: deep rose `#9B4F6E` (light) / `#BD6F90` (dark). Accent colors: `Theme.wishlist` (#E05080) for heart/save actions, `Theme.star` (#E8A830) for ratings, `Theme.systemRed` for errors.

`Color.adaptive(light:dark:)` (defined in `Color+Hex.swift`) is the standard way to create adaptive colors.

## Adding a New Screen

1. Create `Features/<Name>/<Name>View.swift` and optionally `<Name>ViewModel.swift`
2. Add any new model types to `Models/Models.swift`
3. Add any new API calls to `APIClient.swift`
4. Wire the new view into `MainTabView` or as a `NavigationLink` destination
5. Run `xcodegen generate` only if you added new files outside Xcode (xcodegen uses `path: Rarity` with recursive source discovery)
