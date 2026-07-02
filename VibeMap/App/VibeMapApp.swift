import SwiftUI

@main
struct VibeMapApp: App {
    @StateObject private var viewModel: VibeMapViewModel

    init() {
        let apiService = VibeAPIClient(baseURL: AppConfig.backendBaseURL)
        let vibeService: any VibeServicing = AppConfig.useMockBackend
            ? MockVibeService()
            : ResilientVibeService(primary: apiService)

        _viewModel = StateObject(
            wrappedValue: VibeMapViewModel(
                vibeService: vibeService,
                searchService: MapKitPlaceSearchService(),
                locationService: LocationService(),
                identityService: DeviceIdentityService()
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            VibeMapView(viewModel: viewModel)
                .tint(VibeDesign.primary)
                .preferredColorScheme(.light)
                .environment(\.colorScheme, .light)
        }
    }
}
