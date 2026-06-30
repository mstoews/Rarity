import MapKit
import SwiftUI

@MainActor
final class StoreDetailViewModel: ObservableObject {
    @Published private(set) var detail: StoreDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let api: APIClient
    let storeID: String

    init(storeID: String, api: APIClient) { self.storeID = storeID; self.api = api }

    func load() async {
        isLoading = true; error = nil; defer { isLoading = false }
        do { detail = try await api.storeDetail(id: storeID) }
        catch { self.error = (error as? APIError)?.errorDescription ?? error.localizedDescription }
    }
}

struct StoreDetailView: View {
    let storeID: String
    @StateObject private var vm: StoreDetailViewModel

    init(storeID: String) {
        self.storeID = storeID
        _vm = StateObject(wrappedValue: StoreDetailViewModel(storeID: storeID, api: APIClient()))
    }

    var body: some View {
        Group {
            if let detail = vm.detail {
                content(detail)
            } else if vm.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = vm.error {
                ContentUnavailableView(err, systemImage: "exclamationmark.triangle")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
    }

    private func content(_ d: StoreDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Map snippet
                if let lat = d.latitude, let lng = d.longitude {
                    Map(initialPosition: .region(
                        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                                          span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                    )) {
                        Marker(d.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                            .tint(Theme.brand)
                    }
                    .frame(maxWidth: .infinity).frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.radiusCard))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(d.name).font(.title2.bold()).foregroundStyle(Theme.ink)
                    if let address = d.address {
                        Label(address, systemImage: "mappin").font(.subheadline).foregroundStyle(Theme.sub)
                    }
                    if let hours = d.openingHours {
                        Label(hours, systemImage: "clock").font(.subheadline).foregroundStyle(Theme.sub)
                    }
                    if let site = d.website, let url = URL(string: site) {
                        Link(destination: url) {
                            Label(site, systemImage: "globe").font(.subheadline).foregroundStyle(Theme.brand)
                        }
                    }
                }

                if !d.cosmetics.isEmpty {
                    Divider().overlay(Theme.separator)
                    Text("Available here").font(.headline).foregroundStyle(Theme.ink)
                    ForEach(d.cosmetics) { cosmetic in
                        NavigationLink(destination: CosmeticDetailView(cosmeticID: cosmetic.id)) {
                            CosmeticCardView(cosmetic: cosmetic, isSubscribed: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Metrics.page)
        }
        .background(Theme.page.ignoresSafeArea())
        .navigationTitle(d.name)
    }
}
