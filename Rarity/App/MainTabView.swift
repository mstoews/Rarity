import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            BrowseView()
                .tabItem { Label("Discover", systemImage: "sparkles") }

            StoresView()
                .tabItem { Label("Stores", systemImage: "mappin.and.ellipse") }

            WishlistView()
                .tabItem { Label("Saved", systemImage: "heart") }

            AccountView()
                .tabItem { Label("Account", systemImage: "person") }
        }
        .accentColor(Theme.brand)
    }
}
