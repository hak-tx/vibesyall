import SwiftUI

@main
struct VibeMapApp: App {
    @StateObject private var viewModel: VibeMapViewModel
    @StateObject private var languageStore = AppLanguageStore()

    init() {
        let apiService = VibeAPIClient(baseURL: AppConfig.backendBaseURL)
        let vibeService: any VibeServicing = AppConfig.useMockBackend
            ? MockVibeService()
            : ResilientVibeService(primary: apiService)

        _viewModel = StateObject(
            wrappedValue: VibeMapViewModel(
                vibeService: vibeService,
                searchService: HybridPlaceSearchService(
                    mapKitSearch: MapKitPlaceSearchService(),
                    providerSearch: vibeService
                ),
                locationService: LocationService(),
                identityService: DeviceIdentityService()
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            VibeMapView(viewModel: viewModel)
                .environmentObject(languageStore)
                .environment(\.locale, languageStore.language.locale)
                .tint(VibeDesign.primary)
                .preferredColorScheme(.light)
                .environment(\.colorScheme, .light)
        }
    }
}
