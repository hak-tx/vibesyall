import MapKit
import SwiftUI

struct VibeMapView: View {
    @ObservedObject var viewModel: VibeMapViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedMapFeature: MapFeature?
    @State private var nearbyLoadTask: Task<Void, Never>?
    @State private var shouldCenterOnNextLocation = false
    @State private var hasCenteredOnInitialUserLocation = false
    @State private var isSearchFocused = false
    @State private var isNearbyPanelMinimized = false
    @State private var isAppMenuPresented = false
    @State private var isAccountDeletionPresented = false
    @AppStorage("vibes-yall.map-display-style") private var mapDisplayStyleRawValue = VibeMapDisplayStyle.dark.rawValue
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
        let renderedMapContent = mapContent
        let renderedMapCellClusters = viewModel.visibleMapCellClusters

        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                Map(position: $position, selection: $selectedMapFeature) {
                    UserAnnotation(anchor: .center) {
                        UserLocationMarker()
                    }

                    ForEach(renderedMapContent.places) { place in
                        Annotation(place.name, coordinate: place.coordinate) {
                            PlaceMapMarker(
                                place: place,
                                isSelected: viewModel.selectedPlace?.id == place.id
                            )
                            .stableMapAnnotation()
                            .mapAnnotationTapTarget {
                                viewModel.openRating(for: place)
                            }
                        }
                    }

                    ForEach(renderedMapContent.clusters) { cluster in
                        Annotation("", coordinate: cluster.coordinate) {
                            PlaceClusterMarker(cluster: cluster)
                                .stableMapAnnotation()
                                .mapAnnotationTapTarget {
                                    centerMap(
                                        on: cluster.coordinate,
                                        distance: AppConfig.clusterFocusDistance(for: visibleRegion)
                                    )
                                }
                        }
                    }

                    ForEach(renderedMapCellClusters) { cluster in
                        Annotation("", coordinate: cluster.coordinate) {
                            MapCellClusterMarker(cluster: cluster)
                                .stableMapAnnotation()
                                .mapAnnotationTapTarget {
                                    centerMap(
                                        on: cluster.coordinate,
                                        distance: AppConfig.mapCellClusterFocusDistance(for: cluster, region: visibleRegion)
                                    )
                                }
                        }
                    }

                    if let selectedPlace = viewModel.selectedPlace {
                        Annotation(selectedPlace.name, coordinate: selectedPlace.coordinate) {
                            PlaceMapMarker(place: selectedPlace, isSelected: true)
                                .stableMapAnnotation()
                                .mapAnnotationTapTarget {
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
                    updateVisibleRegion(context.region)
                    viewModel.previewCachedAnnotations(
                        center: context.region.center,
                        radius: AppConfig.nearbyRadius(for: context.region)
                    )
                    scheduleNearbyLoad(for: context.region)
                }
                .ignoresSafeArea()

                SearchOverlayView(viewModel: viewModel, isSearchFocused: $isSearchFocused) {
                    isSearchFocused = false
                    isAppMenuPresented = true
                }
            }

            if !isSearchFocused {
                GeometryReader { geometry in
                    if usesTabletBottomPanelLayout(containerWidth: geometry.size.width) {
                        ZStack(alignment: .bottom) {
                            bottomPanel(availableHeight: geometry.size.height)
                                .frame(width: bottomPanelWidth(for: geometry.size.width), alignment: .bottomLeading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, bottomPanelHorizontalPadding(for: geometry.size.width))
                                .zIndex(0)

                            HStack {
                                Spacer()
                                mapControlButtons
                            }
                            .padding(.trailing, tabletMapControlTrailingPadding(for: geometry.size.width))
                            .padding(.bottom, tabletMapControlBottomPadding(for: geometry.size.height))
                            .zIndex(1)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    } else {
                        VStack(spacing: 12) {
                            HStack {
                                Spacer()
                                mapControlButtons
                            }
                            .padding(.horizontal, 18)
                            .zIndex(1)

                            bottomPanel(availableHeight: geometry.size.height)
                                .frame(width: bottomPanelWidth(for: geometry.size.width), alignment: .bottomLeading)
                                .frame(maxWidth: .infinity, alignment: bottomPanelAlignment(for: geometry.size.width))
                                .padding(.horizontal, bottomPanelHorizontalPadding(for: geometry.size.width))
                                .zIndex(0)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
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
        .sheet(isPresented: $isAppMenuPresented) {
            AppMenuSheet(
                hasConfirmedAccount: viewModel.hasConfirmedAccount,
                onSignUp: {
                    isAppMenuPresented = false
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(220))
                        await viewModel.presentAccountSignupFromMenu()
                    }
                },
                onLogout: {
                    isAppMenuPresented = false
                    Task { @MainActor in
                        await viewModel.requestAccountLogout()
                    }
                },
                onDeleteAccount: {
                    isAppMenuPresented = false
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(220))
                        isAccountDeletionPresented = true
                    }
                }
            )
            .presentationDetents([.height(500)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .preferredColorScheme(.light)
            .environment(\.colorScheme, .light)
        }
        .sheet(isPresented: $isAccountDeletionPresented) {
            AccountDeletionSheet(viewModel: viewModel)
                .presentationDetents([.height(390)])
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
            viewModel.refreshAccountStatusOnActivation()
        }
        .onOpenURL { url in
            viewModel.handleAccountConfirmationURL(url)
        }
        .onDisappear {
            nearbyLoadTask?.cancel()
        }
    }

    @ViewBuilder
    private func bottomPanel(availableHeight: CGFloat) -> some View {
        if viewModel.ratingDraft != nil {
            EmptyView()
        } else if viewModel.showsMapTapChoices {
            MapTapChoicesPanel(viewModel: viewModel)
        } else if viewModel.selectedPlace != nil {
            SelectedPlacePanel(viewModel: viewModel)
        } else {
            NearbyVibesPanel(
                viewModel: viewModel,
                isMinimized: $isNearbyPanelMinimized,
                availableHeight: availableHeight
            )
        }
    }

    private var mapControlButtons: some View {
        VStack(spacing: 10) {
            MapStyleFloatingButton(selection: mapDisplayStyleBinding)

            CurrentLocationButton {
                centerOnCurrentLocation()
            }
        }
    }

    private func bottomPanelWidth(for containerWidth: CGFloat) -> CGFloat {
        guard usesTabletBottomPanelLayout(containerWidth: containerWidth) else {
            return containerWidth
        }

        let proportionalWidth = containerWidth * 0.46
        return min(max(proportionalWidth, 460), 580)
    }

    private func bottomPanelAlignment(for containerWidth: CGFloat) -> Alignment {
        usesTabletBottomPanelLayout(containerWidth: containerWidth) ? .leading : .center
    }

    private func bottomPanelHorizontalPadding(for containerWidth: CGFloat) -> CGFloat {
        guard usesTabletBottomPanelLayout(containerWidth: containerWidth) else {
            return 0
        }

        return min(max(containerWidth * 0.035, 24), 44)
    }

    private func usesTabletBottomPanelLayout(containerWidth: CGFloat) -> Bool {
        horizontalSizeClass == .regular && containerWidth >= 700
    }

    private func tabletMapControlTrailingPadding(for containerWidth: CGFloat) -> CGFloat {
        min(max(containerWidth * 0.025, 22), 34)
    }

    private func tabletMapControlBottomPadding(for containerHeight: CGFloat) -> CGFloat {
        min(max(containerHeight * 0.035, 20), 32)
    }

    private var mapContent: ClusteredMapContent {
        MapPlaceClusterer.content(
            for: viewModel.visibleNearbyPlaces,
            selectedPlace: viewModel.selectedPlace,
            region: visibleRegion,
            maxPlaces: AppConfig.maximumRenderedMapPlaces(for: visibleRegion)
        )
    }

    private var mapDisplayStyle: VibeMapDisplayStyle {
        VibeMapDisplayStyle(rawValue: mapDisplayStyleRawValue) ?? .dark
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
        guard !AppConfig.shouldSkipInitialUserLocationAutocenter,
              !hasCenteredOnInitialUserLocation,
              viewModel.ratingDraft == nil,
              viewModel.selectedPlace == nil,
              !viewModel.showsMapTapChoices,
              viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        hasCenteredOnInitialUserLocation = true
        centerMap(on: coordinate, distance: AppConfig.initialUserMapDistanceMeters)
    }

    private func updateVisibleRegion(_ region: MKCoordinateRegion) {
        visibleRegion = region
        viewModel.updateVisibleRegion(region)
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

private extension View {
    func stableMapAnnotation() -> some View {
        transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
    }

    func mapAnnotationTapTarget(_ action: @escaping () -> Void) -> some View {
        contentShape(Circle())
            .simultaneousGesture(
                TapGesture().onEnded { _ in action() }
            )
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
                .frame(width: isSelected ? 30 : 24, height: isSelected ? 30 : 24)

            Circle()
                .fill(markerFillColor)
                .frame(width: isSelected ? 24 : 20, height: isSelected ? 24 : 20)

            Image(systemName: markerSymbol)
                .font(.system(size: isSelected ? 12 : 10, weight: .black))
                .foregroundStyle(markerIconColor)

            if isSelected {
                Circle()
                    .stroke(markerAccentColor, lineWidth: 2)
                    .frame(width: 30, height: 30)
            }
        }
        .shadow(color: .black.opacity(0.16), radius: 5, y: 2)
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
        VibeClusterIconMarker(vibe: cluster.topVibe, count: cluster.count, scale: .nearby)
    }
}

private struct MapCellClusterMarker: View {
    let cluster: MapCellCluster

    var body: some View {
        VibeClusterIconMarker(vibe: cluster.displayVibe, count: cluster.count, scale: .regional)
    }
}

private struct VibeClusterIconMarker: View {
    enum Scale {
        case nearby
        case regional
    }

    let vibe: VibeTag?
    let count: Int
    let scale: Scale

    var body: some View {
        let color = vibe?.visualStyle.color ?? VibeDesign.primary
        let symbolName = vibe?.visualStyle.symbolName ?? "circle.grid.2x2.fill"

        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(color.opacity(densityHaloOpacity))
                    .frame(width: haloSize, height: haloSize)

                Circle()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: outerSize, height: outerSize)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.75), lineWidth: 1)
                    }

                Circle()
                    .fill(color.opacity(0.96))
                    .frame(width: innerSize, height: innerSize)

                Image(systemName: symbolName)
                    .font(.system(size: iconSize, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: markerFrameSize, height: markerFrameSize)

            if showsCountBadge {
                countBadge
                    .offset(x: countBadgeOffset, y: countBadgeOffset)
            }
        }
        .frame(width: markerFrameSize + countBadgeWidthOffset, height: markerFrameSize + countBadgeWidthOffset)
        .shadow(color: color.opacity(0.20), radius: 5, y: 2)
        .accessibilityLabel(accessibilityLabel)
    }

    private var countBadge: some View {
        Text(formattedCount)
            .font(.system(size: countBadgeFontSize, weight: .black, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, countBadgeHorizontalPadding)
            .frame(minWidth: countBadgeMinWidth)
            .frame(height: countBadgeHeight)
            .background(VibeDesign.primary, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.96), lineWidth: 1.5)
            }
    }

    private var outerSize: CGFloat {
        switch scale {
        case .nearby:
            return count >= 10 ? 32 : 30
        case .regional:
            if count <= 1 {
                return 25
            }
            return count >= 25 ? 30 : 28
        }
    }

    private var innerSize: CGFloat {
        outerSize - 8
    }

    private var haloSize: CGFloat {
        outerSize + min(max(CGFloat(count) / 6, 4), 10)
    }

    private var iconSize: CGFloat {
        switch scale {
        case .nearby:
            return 11.5
        case .regional:
            if count <= 1 {
                return 9.5
            }
            return 10.5
        }
    }

    private var densityHaloOpacity: Double {
        guard count > 1 else {
            return 0.10
        }
        return min(0.28, 0.10 + Double(min(max(count, 2), 24)) / 160)
    }

    private var markerFrameSize: CGFloat {
        haloSize + countBadgeHeight * 0.5
    }

    private var countBadgeHeight: CGFloat {
        switch scale {
        case .nearby:
            return 16
        case .regional:
            return 15
        }
    }

    private var countBadgeMinWidth: CGFloat {
        let base: CGFloat
        switch formattedCount.count {
        case 0...1:
            base = 16
        case 2:
            base = 20
        default:
            base = 26
        }

        return scale == .nearby ? base : max(15, base - 2)
    }

    private var countBadgeFontSize: CGFloat {
        switch scale {
        case .nearby:
            return formattedCount.count > 2 ? 8 : 9
        case .regional:
            return formattedCount.count > 2 ? 7.5 : 8.5
        }
    }

    private var countBadgeHorizontalPadding: CGFloat {
        formattedCount.count > 1 ? 3.5 : 0
    }

    private var countBadgeOffset: CGFloat {
        switch scale {
        case .nearby:
            return 1
        case .regional:
            return 0.5
        }
    }

    private var countBadgeWidthOffset: CGFloat {
        guard showsCountBadge else {
            return 0
        }
        return max(countBadgeHeight * 0.45, 7)
    }

    private var showsCountBadge: Bool {
        scale == .nearby || count > 1
    }

    private var formattedCount: String {
        switch count {
        case 1_000...:
            let thousands = Double(count) / 1_000
            if thousands >= 10 {
                return "\(Int(thousands.rounded()))K"
            }
            return String(format: "%.1fK", thousands).replacingOccurrences(of: ".0K", with: "K")
        default:
            return "\(count)"
        }
    }

    private var accessibilityLabel: String {
        let placeLabel = count == 1 ? "1 nearby place" : "\(count) nearby places"
        if let vibe {
            return "\(placeLabel), mostly \(vibe.rawValue)"
        }
        return placeLabel
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
        region: MKCoordinateRegion,
        maxPlaces: Int
    ) -> ClusteredMapContent {
        guard maxPlaces > 0 else {
            return ClusteredMapContent(places: [], clusters: [])
        }

        let selectedPlaceID = selectedPlace?.id
        let clusterablePlaces = Array(
            places
                .filter { $0.id != selectedPlaceID }
                .prefix(maxPlaces)
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
