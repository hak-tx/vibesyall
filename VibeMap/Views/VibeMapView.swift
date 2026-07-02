import MapKit
import SwiftUI

struct VibeMapView: View {
    @ObservedObject var viewModel: VibeMapViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedMapFeature: MapFeature?
    @State private var nearbyLoadTask: Task<Void, Never>?
    @State private var shouldCenterOnNextLocation = false
    @State private var hasCenteredOnInitialUserLocation = false
    @State private var isSearchFocused = false
    @State private var isNearbyPanelMinimized = false
    @AppStorage("vibes-yall.map-display-style") private var mapDisplayStyleRawValue = VibeMapDisplayStyle.standard.rawValue
    @State private var visibleRegion = MKCoordinateRegion(
        center: AppConfig.initialMapCenter,
        latitudinalMeters: AppConfig.defaultMapDistanceMeters,
        longitudinalMeters: AppConfig.defaultMapDistanceMeters
    )
    @State private var position: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: AppConfig.initialMapCenter,
            distance: AppConfig.defaultMapDistanceMeters
        )
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                Map(position: $position, selection: $selectedMapFeature) {
                    UserAnnotation(anchor: .center) {
                        UserLocationMarker()
                    }

                    ForEach(mapContent.places) { place in
                        Annotation(place.name, coordinate: place.coordinate) {
                            PlaceMapMarker(
                                place: place,
                                isSelected: viewModel.selectedPlace?.id == place.id
                            )
                            .onTapGesture {
                                viewModel.openRating(for: place)
                            }
                        }
                    }

                    ForEach(mapContent.clusters) { cluster in
                        Annotation("Cluster of \(cluster.count) places", coordinate: cluster.coordinate) {
                            Button {
                                centerMap(
                                    on: cluster.coordinate,
                                    distance: AppConfig.clusterFocusDistance(for: visibleRegion)
                                )
                            } label: {
                                PlaceClusterMarker(cluster: cluster)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    ForEach(viewModel.visibleMapCellClusters) { cluster in
                        Annotation("Cluster of \(cluster.count) places", coordinate: cluster.coordinate) {
                            Button {
                                centerMap(
                                    on: cluster.coordinate,
                                    distance: AppConfig.mapCellClusterFocusDistance(for: cluster, region: visibleRegion)
                                )
                            } label: {
                                MapCellClusterMarker(cluster: cluster)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let selectedPlace = viewModel.selectedPlace {
                        Annotation(selectedPlace.name, coordinate: selectedPlace.coordinate) {
                            PlaceMapMarker(place: selectedPlace, isSelected: true)
                                .onTapGesture {
                                    viewModel.openRating(for: selectedPlace)
                                }
                        }
                    }
                }
                .mapStyle(mapDisplayStyle.style)
                .mapControls {
                    MapScaleView()
                }
                .environment(\.colorScheme, mapDisplayStyle.mapColorScheme)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        handleMapBackgroundTap()
                    }
                )
                .mapFeatureSelectionDisabled { feature in
                    feature.kind != .pointOfInterest
                }
                .onChange(of: selectedMapFeature) { _, feature in
                    guard let feature else { return }
                    Task {
                        await resolveMapFeatureSelection(feature)
                        selectedMapFeature = nil
                    }
                }
                .onMapCameraChange(frequency: .onEnd) { context in
                    visibleRegion = context.region
                    viewModel.updateVisibleRegion(context.region)
                    scheduleNearbyLoad(for: context.region)
                }
                .ignoresSafeArea()

                SearchOverlayView(viewModel: viewModel, isSearchFocused: $isSearchFocused)
            }

            if !isSearchFocused {
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            MapStyleFloatingButton(selection: mapDisplayStyleBinding)

                            CurrentLocationButton {
                                centerOnCurrentLocation()
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .zIndex(1)

                    bottomPanel
                        .zIndex(0)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.easeInOut(duration: 0.18), value: isSearchFocused)
        .onReceive(viewModel.locationService.$lastKnownCoordinate.compactMap { $0 }) { coordinate in
            if shouldCenterOnNextLocation {
                shouldCenterOnNextLocation = false
                hasCenteredOnInitialUserLocation = true
                centerMap(on: coordinate, distance: AppConfig.currentLocationMapDistanceMeters)
                return
            }

            centerOnInitialUserLocationIfNeeded(coordinate)
        }
        .sheet(item: $viewModel.ratingDraft, onDismiss: {
            viewModel.closeRatingFlow()
        }) { draft in
            RatingSheetView(viewModel: viewModel, draft: draft)
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(30)
                .preferredColorScheme(.light)
                .environment(\.colorScheme, .light)
        }
        .sheet(item: $viewModel.accountSignupPrompt) { prompt in
            AccountSignupSheet(viewModel: viewModel, prompt: prompt)
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .preferredColorScheme(.light)
                .environment(\.colorScheme, .light)
        }
        .tint(VibeDesign.primary)
        .preferredColorScheme(.light)
        .environment(\.colorScheme, .light)
        .onChange(of: viewModel.ratingDraft) { _, draft in
            guard let draft else { return }
            centerMapForRating(on: draft.place.coordinate)
        }
        .alert(item: $viewModel.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .task {
            viewModel.updateVisibleRegion(visibleRegion)
            await viewModel.start()
            if let debugSearchQuery = AppConfig.debugInitialSearchQuery {
                viewModel.searchQuery = debugSearchQuery
                isSearchFocused = true
                await viewModel.searchPlaces()
            }
            if let coordinate = viewModel.locationService.lastKnownCoordinate {
                centerOnInitialUserLocationIfNeeded(coordinate)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            isSearchFocused = false
        }
        .onOpenURL { url in
            viewModel.handleAccountConfirmationURL(url)
        }
        .onDisappear {
            nearbyLoadTask?.cancel()
        }
    }

    @ViewBuilder
    private var bottomPanel: some View {
        if viewModel.ratingDraft != nil {
            EmptyView()
        } else if viewModel.showsMapTapChoices {
            MapTapChoicesPanel(viewModel: viewModel)
        } else if viewModel.selectedPlace != nil {
            SelectedPlacePanel(viewModel: viewModel)
        } else {
            NearbyVibesPanel(viewModel: viewModel, isMinimized: $isNearbyPanelMinimized)
        }
    }

    private var mapContent: ClusteredMapContent {
        MapPlaceClusterer.content(
            for: viewModel.visibleNearbyPlaces,
            selectedPlace: viewModel.selectedPlace,
            region: visibleRegion
        )
    }

    private var mapDisplayStyle: VibeMapDisplayStyle {
        VibeMapDisplayStyle(rawValue: mapDisplayStyleRawValue) ?? .standard
    }

    private var mapDisplayStyleBinding: Binding<VibeMapDisplayStyle> {
        Binding {
            mapDisplayStyle
        } set: { newValue in
            mapDisplayStyleRawValue = newValue.rawValue
        }
    }

    private func centerMapForRating(on coordinate: CLLocationCoordinate2D) {
        let visualCenter = offset(coordinate, latitudeMeters: -450)
        let region = MKCoordinateRegion(
            center: visualCenter,
            latitudinalMeters: 3_200,
            longitudinalMeters: 3_200
        )

        withAnimation(.easeInOut(duration: 0.25)) {
            position = .camera(
                MapCamera(
                    centerCoordinate: visualCenter,
                    distance: 3_200
                )
            )
        }
        visibleRegion = region
        viewModel.updateVisibleRegion(region)
    }

    private func offset(_ coordinate: CLLocationCoordinate2D, latitudeMeters: CLLocationDistance) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coordinate.latitude + latitudeMeters / 111_000,
            longitude: coordinate.longitude
        )
    }

    private func centerOnCurrentLocation() {
        shouldCenterOnNextLocation = true
        viewModel.requestCurrentLocation()
    }

    private func handleMapBackgroundTap() {
        isSearchFocused = false

        guard viewModel.ratingDraft == nil else {
            return
        }

        if viewModel.selectedPlace == nil,
           !viewModel.showsMapTapChoices,
           !isNearbyPanelMinimized {
            withAnimation(.easeInOut(duration: 0.18)) {
                isNearbyPanelMinimized = true
            }
        }

        viewModel.clearSelection()
    }

    private func centerOnInitialUserLocationIfNeeded(_ coordinate: CLLocationCoordinate2D) {
        guard !hasCenteredOnInitialUserLocation,
              viewModel.ratingDraft == nil,
              viewModel.selectedPlace == nil,
              !viewModel.showsMapTapChoices,
              viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        hasCenteredOnInitialUserLocation = true
        centerMap(on: coordinate, distance: AppConfig.initialUserMapDistanceMeters)
    }

    private func centerMap(on coordinate: CLLocationCoordinate2D, distance: CLLocationDistance) {
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: distance,
            longitudinalMeters: distance
        )

        withAnimation(.easeInOut(duration: 0.25)) {
            position = .camera(
                MapCamera(
                    centerCoordinate: coordinate,
                    distance: distance
                )
            )
        }
        visibleRegion = region
        viewModel.updateVisibleRegion(region)
        loadNearbyNow(for: region)
    }

    private func scheduleNearbyLoad(for region: MKCoordinateRegion) {
        nearbyLoadTask?.cancel()
        nearbyLoadTask = Task {
            try? await Task.sleep(for: AppConfig.nearbyReloadDebounce)
            guard !Task.isCancelled else { return }
            await viewModel.loadNearby(
                center: region.center,
                radius: AppConfig.nearbyRadius(for: region)
            )
        }
    }

    private func loadNearbyNow(for region: MKCoordinateRegion) {
        nearbyLoadTask?.cancel()
        nearbyLoadTask = Task {
            await viewModel.loadNearby(
                center: region.center,
                radius: AppConfig.nearbyRadius(for: region)
            )
        }
    }

    private func resolveMapFeatureSelection(_ feature: MapFeature) async {
        guard feature.kind == .pointOfInterest else {
            return
        }

        do {
            let selectedItem = try await MKMapItemRequest(feature: feature).mapItem
            await viewModel.resolvePointOfInterestSelection(for: selectedItem)
        } catch {
            await viewModel.resolvePointOfInterestSelection(
                named: feature.title,
                near: feature.coordinate
            )
        }
    }
}

private struct MapStyleFloatingButton: View {
    @Binding var selection: VibeMapDisplayStyle

    var body: some View {
        Menu {
            ForEach(VibeMapDisplayStyle.allCases) { style in
                Button {
                    selection = style
                } label: {
                    Label(style.label, systemImage: style.symbolName)
                }
            }
        } label: {
            Image(systemName: selection.symbolName)
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(VibeDesign.primary)
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.94), in: Circle())
                .overlay {
                    Circle()
                        .stroke(VibeDesign.hairline, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.16), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Map style")
    }
}

private struct UserLocationMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.0, green: 0.45, blue: 1.0).opacity(0.18))
                .frame(width: 34, height: 34)

            Circle()
                .fill(Color(red: 0.0, green: 0.45, blue: 1.0))
                .frame(width: 16, height: 16)
                .overlay {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                }
                .shadow(color: .black.opacity(0.22), radius: 5, y: 2)
        }
        .accessibilityLabel("My location")
    }
}

private struct PlaceMapMarker: View {
    let place: VibePlace
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: isSelected ? 34 : 28, height: isSelected ? 34 : 28)

            Circle()
                .fill(markerFillColor)
                .frame(width: isSelected ? 28 : 23, height: isSelected ? 28 : 23)

            Image(systemName: markerSymbol)
                .font(.system(size: isSelected ? 13 : 11, weight: .black))
                .foregroundStyle(markerIconColor)

            if isSelected {
                Circle()
                    .stroke(markerAccentColor, lineWidth: 2)
                    .frame(width: 34, height: 34)
            }
        }
        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        .accessibilityLabel(place.name)
    }

    private var markerSymbol: String {
        guard let topVibeTag = place.stats?.topVibeTag, place.hasRatings else {
            return "mappin.circle.fill"
        }
        return topVibeTag.visualStyle.symbolName
    }

    private var markerColor: Color {
        guard let topVibeTag = place.stats?.topVibeTag, place.hasRatings else {
            return VibeDesign.primary
        }
        return topVibeTag.visualStyle.color
    }

    private var markerFillColor: Color {
        isSelected ? markerColor : Color.white.opacity(0.86)
    }

    private var markerIconColor: Color {
        isSelected ? .white : markerColor
    }

    private var markerAccentColor: Color {
        isSelected ? markerColor : Color.clear
    }
}

private struct PlaceClusterMarker: View {
    let cluster: MapPlaceCluster

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 48, height: 48)

                Circle()
                    .fill(VibeDesign.primary)
                    .frame(width: 38, height: 38)

                Text("\(cluster.count)")
                    .font(.system(size: cluster.count > 99 ? 12 : 15, weight: .black))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.72)
            }

            if let topVibe = cluster.topVibe {
                ZStack {
                    Circle()
                        .fill(topVibe.visualStyle.color)
                        .frame(width: 18, height: 18)

                    Image(systemName: topVibe.visualStyle.symbolName)
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                }
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                }
                .offset(x: 2, y: -2)
            }
        }
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        .accessibilityLabel("\(cluster.count) nearby places")
    }
}

private struct MapCellClusterMarker: View {
    let cluster: MapCellCluster

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 50, height: 50)

                Circle()
                    .fill(VibeDesign.primary)
                    .frame(width: 40, height: 40)

                Text("\(cluster.count)")
                    .font(.system(size: cluster.count > 99 ? 12 : 16, weight: .black))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.72)
            }

            if let topVibe = cluster.displayVibe {
                ZStack {
                    Circle()
                        .fill(topVibe.visualStyle.color)
                        .frame(width: 19, height: 19)

                    Image(systemName: topVibe.visualStyle.symbolName)
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                }
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                }
                .offset(x: 2, y: -2)
            }
        }
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        .accessibilityLabel("\(cluster.count) nearby places")
    }
}

private struct ClusteredMapContent {
    var places: [VibePlace]
    var clusters: [MapPlaceCluster]
}

private struct MapPlaceCluster: Identifiable {
    let id: String
    let places: [VibePlace]
    let coordinate: CLLocationCoordinate2D
    let topVibe: VibeTag?

    var count: Int {
        places.count
    }
}

private struct MapClusterBucket: Hashable {
    let x: Int
    let y: Int
}

private enum MapPlaceClusterer {
    static func content(
        for places: [VibePlace],
        selectedPlace: VibePlace?,
        region: MKCoordinateRegion
    ) -> ClusteredMapContent {
        let selectedPlaceID = selectedPlace?.id
        let clusterablePlaces = Array(
            places
                .filter { $0.id != selectedPlaceID }
                .prefix(AppConfig.maximumRenderedMapPlaces)
        )
            .sorted(by: placeSort)
        let radius = AppConfig.clusterRadius(for: region)

        guard radius > 0, clusterablePlaces.count > 1 else {
            return ClusteredMapContent(places: clusterablePlaces, clusters: [])
        }

        var loosePlaces: [VibePlace] = []
        var clusters: [MapPlaceCluster] = []
        let metersPerMapPoint = max(MKMetersPerMapPointAtLatitude(region.center.latitude), 0.0001)
        let bucketSize = max(radius / metersPerMapPoint, 1)
        var buckets: [MapClusterBucket: [VibePlace]] = [:]

        for place in clusterablePlaces {
            let point = MKMapPoint(place.coordinate)
            let bucket = MapClusterBucket(
                x: Int((point.x / bucketSize).rounded(.down)),
                y: Int((point.y / bucketSize).rounded(.down))
            )
            buckets[bucket, default: []].append(place)
        }

        for bucket in buckets.keys.sorted(by: bucketSort) {
            let bucketPlaces = (buckets[bucket] ?? []).sorted(by: placeSort)
            if bucketPlaces.count > 1 {
                clusters.append(
                    MapPlaceCluster(
                        id: bucketPlaces.map(\.id).joined(separator: "|"),
                        places: bucketPlaces,
                        coordinate: averageCoordinate(for: bucketPlaces),
                        topVibe: dominantVibe(in: bucketPlaces)
                    )
                )
            } else {
                loosePlaces.append(contentsOf: bucketPlaces)
            }
        }

        return ClusteredMapContent(
            places: loosePlaces.sorted(by: placeSort),
            clusters: clusters.sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.id < rhs.id
                }
                return lhs.count > rhs.count
            }
        )
    }

    private static func bucketSort(_ lhs: MapClusterBucket, _ rhs: MapClusterBucket) -> Bool {
        if lhs.y == rhs.y {
            return lhs.x < rhs.x
        }
        return lhs.y < rhs.y
    }

    private static func placeSort(_ lhs: VibePlace, _ rhs: VibePlace) -> Bool {
        if lhs.latitude == rhs.latitude {
            if lhs.longitude == rhs.longitude {
                return lhs.id < rhs.id
            }
            return lhs.longitude < rhs.longitude
        }
        return lhs.latitude < rhs.latitude
    }

    private static func averageCoordinate(for places: [VibePlace]) -> CLLocationCoordinate2D {
        let latitude = places.map(\.latitude).reduce(0, +) / Double(places.count)
        let longitude = places.map(\.longitude).reduce(0, +) / Double(places.count)
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private static func dominantVibe(in places: [VibePlace]) -> VibeTag? {
        var counts: [VibeTag: Int] = [:]

        for place in places {
            if let breakdown = place.stats?.visibleTopVibes.first {
                counts[breakdown.vibeTag, default: 0] += max(breakdown.count, 1)
            }
        }

        return counts.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.rankingScore > rhs.key.rankingScore
            }
            return lhs.value > rhs.value
        }
        .first?
        .key
    }
}

private struct CurrentLocationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "location.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(red: 0.0, green: 0.45, blue: 1.0))
                .frame(width: 52, height: 52)
                .background(Color.white.opacity(0.94), in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Near me")
    }
}

#Preview {
    VibeMapView(
        viewModel: VibeMapViewModel(
            vibeService: MockVibeService(),
            searchService: MapKitPlaceSearchService(),
            locationService: LocationService(),
            identityService: DeviceIdentityService()
        )
    )
}
