import CoreLocation
import Foundation
import MapKit

@MainActor
final class VibeMapViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published private(set) var searchResults: [PlaceCandidate] = []
    @Published private(set) var savedPlaceSearchResults: [VibePlace] = []
    @Published private(set) var nearbyPlaces: [VibePlace] = []
    @Published private(set) var mapCellClusters: [MapCellCluster] = []
    @Published private(set) var allowedVibes = VibeTag.allCases
    @Published private(set) var selectedVibeFilters: Set<VibeTag> = []
    @Published var selectedPlace: VibePlace?
    @Published var ratingDraft: RatingDraft?
    @Published var alert: AppAlert?
    @Published private(set) var contributedPlaceIDs: Set<String> = []
    @Published private(set) var mapTapMatches: [PlaceCandidateMatch] = []
    @Published private(set) var mapTapError: String?
    @Published private(set) var isSearching = false
    @Published private(set) var isLoadingNearby = false
    @Published private(set) var isSelectingPlace = false
    @Published private(set) var isResolvingMapTap = false
    @Published private(set) var nearbyError: String?
    @Published private(set) var searchError: String?
    @Published var accountSignupPrompt: AccountSignupPrompt?
    @Published private var accountSessionToken: String?
    @Published private var displayedAnnotationLayer: AnnotationLayer = .nearby

    let locationService: LocationService

    private let vibeService: any VibeServicing
    private let searchService: any PlaceSearching
    private let identityService: any DeviceIdentifying
    private let contributedPlaceIDsKey = "vibe-map.contributed-place-ids"
    private let accountPromptDismissedKey = "vibes-yall.account-prompt-dismissed"
    private let accountSessionTokenKey = "vibes-yall.account-session-token"
    private let pendingRatingSubmissionsKey = "vibes-yall.pending-rating-submissions"
    private var visibleCenter = AppConfig.initialMapCenter
    private var visibleRadius = AppConfig.nearbyRadiusMeters
    private var activeMapTapRequestID: UUID?
    private var activeSearchRequestID: UUID?
    private var activeNearbyRequestID: UUID?
    private var activeNearbyRequestKey: String?
    private var shouldCheckAccountAfterRating = false
    private var currentNearbyCacheKey: String?
    private var currentMapCellCacheKey: String?
    private var displayedNearbySignature = ""
    private var displayedMapCellSignature = ""
    private var lastAccountStatusRefresh: Date?
    private var nearbyCache: [String: NearbyCacheEntry] = [:]
    private var nearbyCacheOrder: [String] = []
    private var mapCellCache: [String: MapCellCacheEntry] = [:]
    private var mapCellCacheOrder: [String] = []
    private var hasRecordedAppOpen = false
    private var lastTrackedSearchQuery: String?
    private var pendingRatingSyncTask: Task<Void, Never>?

    private enum AnnotationLayer {
        case nearby
        case mapCells
    }

    private struct NearbyCacheEntry {
        var places: [VibePlace]
        var loadedAt: Date
    }

    private struct MapCellCacheEntry {
        var clusters: [MapCellCluster]
        var loadedAt: Date
    }

    private struct MapCellDisplayBucket: Hashable {
        var x: Int
        var y: Int
    }

    private struct PendingRatingSubmission: Codable, Identifiable, Equatable {
        var id: UUID
        var localPlaceID: String
        var candidate: PlaceCandidate
        var vibeTags: [VibeTag]
        var createdAt: Date
    }

    var showsMapTapChoices: Bool {
        isResolvingMapTap || !mapTapMatches.isEmpty || mapTapError != nil
    }

    var visibleNearbyPlaces: [VibePlace] {
        guard displayedAnnotationLayer == .nearby else {
            return []
        }

        guard !selectedVibeFilters.isEmpty else {
            return nearbyPlaces
        }

        return nearbyPlaces.filter { $0.matchesAnyVibe(in: selectedVibeFilters) }
    }

    var visibleNearbyPlaceCount: Int {
        if displayedAnnotationLayer == .mapCells {
            return filteredMapCellClusters.reduce(0) { $0 + $1.count }
        }

        return visibleNearbyPlaces.count + visibleMapCellClusters.reduce(0) { $0 + $1.count }
    }

    var isShowingMapCellClusters: Bool {
        displayedAnnotationLayer == .mapCells
    }

    var visibleMapCellClusters: [MapCellCluster] {
        let sortedClusters = sortedMapCellClusters(filteredMapCellClusters)

        switch displayedAnnotationLayer {
        case .mapCells:
            let limit = min(AppConfig.maximumRenderedMapCellClusters, AppConfig.mapCellDisplayLimit(for: visibleRadius))
            return geographicallyBalancedMapCellClusters(sortedClusters, limit: limit)
        case .nearby:
            guard AppConfig.shouldShowContinuityMapCells(for: visibleRadius) else {
                return []
            }

            return Array(
                sortedClusters
                    .filter { isMapCellClusterInVisibleArea($0) }
                    .filter { !isMapCellClusterRepresentedByNearbyPlaces($0) }
                    .prefix(AppConfig.maximumContinuityMapCellClusters)
            )
        }
    }

    private var filteredMapCellClusters: [MapCellCluster] {
        guard !selectedVibeFilters.isEmpty else {
            return mapCellClusters
        }

        return mapCellClusters.filter { cluster in
            guard let displayVibe = cluster.displayVibe else {
                return false
            }
            return selectedVibeFilters.contains(displayVibe)
        }
    }

    var filteredSearchResults: [PlaceSearchResult] {
        rankedSearchResults(applyingVibeFilters: true)
    }

    var primarySearchResults: [PlaceSearchResult] {
        let results = filteredSearchResults
        guard PlaceSearchQueryIntent.isSpecificNameSearch(searchQuery), results.count > 1 else {
            return results
        }
        return Array(results.prefix(1))
    }

    var relatedSearchResults: [PlaceSearchResult] {
        guard PlaceSearchQueryIntent.isSpecificNameSearch(searchQuery) else {
            return []
        }
        return Array(filteredSearchResults.dropFirst())
    }

    var hasActiveVibeFilters: Bool {
        !selectedVibeFilters.isEmpty
    }

    var didFilterSearchResultsToEmpty: Bool {
        hasActiveVibeFilters &&
            !rankedSearchResults(applyingVibeFilters: false).isEmpty &&
            filteredSearchResults.isEmpty
    }

    var selectedVibeFilterSummary: String {
        VibeTag.bestToWorst(Array(selectedVibeFilters))
            .map(\.mapLabel)
            .joined(separator: L10n.string(" or "))
    }

    init(
        vibeService: any VibeServicing,
        searchService: any PlaceSearching,
        locationService: LocationService,
        identityService: any DeviceIdentifying
    ) {
        self.vibeService = vibeService
        self.searchService = searchService
        self.locationService = locationService
        self.identityService = identityService
        self.contributedPlaceIDs = Set(UserDefaults.standard.stringArray(forKey: contributedPlaceIDsKey) ?? [])
        self.accountSessionToken = UserDefaults.standard.string(forKey: accountSessionTokenKey)
    }

    func start() async {
        locationService.requestAuthorizationAndLocation()
        recordAppOpenIfNeeded()
        await loadAllowedVibes()
        await refreshAccountStatus()
        schedulePendingRatingSync()
        await loadNearby(center: visibleCenter)
    }

    func updateVisibleCenter(_ coordinate: CLLocationCoordinate2D) {
        visibleCenter = coordinate
    }

    func updateVisibleRegion(_ region: MKCoordinateRegion) {
        visibleCenter = region.center
        visibleRadius = AppConfig.nearbyRadius(for: region)
    }

    func previewCachedAnnotations(center: CLLocationCoordinate2D, radius: CLLocationDistance) {
        let usesMapCells = AppConfig.shouldUseServerMapCells(for: radius)
        let cellSize = AppConfig.mapCellSize(for: radius)
        let deviceIDHash = radius <= AppConfig.personalizedNearbyRadiusMeters
            ? identityService.deviceIDHash()
            : nil
        let cacheKey = usesMapCells
            ? AppConfig.mapCellCacheKey(center: center, radius: radius, cellSize: cellSize)
            : AppConfig.nearbyCacheKey(
                center: center,
                radius: radius,
                includesDevice: deviceIDHash != nil
            )

        visibleCenter = center
        visibleRadius = radius

        if usesMapCells, let cachedMapCellEntry = mapCellCache[cacheKey] {
            applyMapCellClusters(cachedMapCellEntry.clusters, cacheKey: cacheKey)
        } else if !usesMapCells, let cachedNearbyEntry = nearbyCache[cacheKey] {
            applyNearbyPlaces(cachedNearbyEntry.places, cacheKey: cacheKey)
        }
    }

    func loadNearby(center: CLLocationCoordinate2D? = nil, radius: CLLocationDistance? = nil) async {
        let coordinate = center ?? visibleCenter
        let queryRadius = radius ?? visibleRadius
        let usesMapCells = AppConfig.shouldUseServerMapCells(for: queryRadius)
        let cellSize = AppConfig.mapCellSize(for: queryRadius)
        let deviceIDHash = queryRadius <= AppConfig.personalizedNearbyRadiusMeters
            ? identityService.deviceIDHash()
            : nil
        let cacheKey = usesMapCells
            ? AppConfig.mapCellCacheKey(center: coordinate, radius: queryRadius, cellSize: cellSize)
            : AppConfig.nearbyCacheKey(
                center: coordinate,
                radius: queryRadius,
                includesDevice: deviceIDHash != nil
            )
        let cachedNearbyEntry = usesMapCells ? nil : nearbyCache[cacheKey]
        let cachedMapCellEntry = usesMapCells ? mapCellCache[cacheKey] : nil
        let now = Date()
        let hasFreshNearbyCache = cachedNearbyEntry.map { now.timeIntervalSince($0.loadedAt) <= AppConfig.nearbyMemoryCacheTTL } ?? false
        let hasFreshMapCellCache = cachedMapCellEntry.map { now.timeIntervalSince($0.loadedAt) <= AppConfig.mapCellMemoryCacheTTL } ?? false
        visibleCenter = coordinate
        visibleRadius = queryRadius
        setNearbyError(nil)

        if usesMapCells,
           let cachedMapCellEntry,
           hasFreshMapCellCache,
           displayedAnnotationLayer == .mapCells,
           currentMapCellCacheKey == cacheKey,
           displayedMapCellSignature == Self.mapCellSignature(cachedMapCellEntry.clusters) {
            cancelActiveNearbyRequest()
            setIsLoadingNearby(false)
            return
        }

        if !usesMapCells,
           let cachedNearbyEntry,
           hasFreshNearbyCache,
           displayedAnnotationLayer == .nearby,
           currentNearbyCacheKey == cacheKey,
           displayedNearbySignature == Self.nearbySignature(cachedNearbyEntry.places) {
            cancelActiveNearbyRequest()
            setIsLoadingNearby(false)
            return
        }

        guard activeNearbyRequestKey != cacheKey else {
            return
        }

        let requestID = UUID()
        activeNearbyRequestID = requestID
        activeNearbyRequestKey = cacheKey
        setIsLoadingNearby(usesMapCells ? cachedMapCellEntry == nil : cachedNearbyEntry == nil)
        defer {
            if activeNearbyRequestID == requestID {
                setIsLoadingNearby(false)
                activeNearbyRequestID = nil
                activeNearbyRequestKey = nil
            }
        }

        if usesMapCells {
            if let cachedMapCellEntry {
                applyMapCellClusters(cachedMapCellEntry.clusters, cacheKey: cacheKey)
                guard !hasFreshMapCellCache else {
                    return
                }
            }

            do {
                let clusters = try await vibeService.fetchMapCells(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    radius: queryRadius,
                    cellSize: cellSize,
                    vibeFilter: nil
                )
                guard activeNearbyRequestID == requestID else { return }
                cacheMapCellClusters(clusters, for: cacheKey)
                applyMapCellClusters(clusters, cacheKey: cacheKey)
            } catch is CancellationError {
                return
            } catch {
                guard activeNearbyRequestID == requestID else { return }
                if cachedMapCellEntry == nil {
                    setNearbyError(error.localizedDescription)
                }
            }

            return
        }

        if let cachedNearbyEntry {
            applyNearbyPlaces(cachedNearbyEntry.places, cacheKey: cacheKey)
            guard !hasFreshNearbyCache else {
                return
            }
        }

        do {
            let places = try await vibeService.fetchNearby(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radius: queryRadius,
                vibeFilter: nil,
                deviceIdHash: deviceIDHash
            )
            guard activeNearbyRequestID == requestID else { return }
            cacheNearbyPlaces(places, for: cacheKey)
            applyNearbyPlaces(places, cacheKey: cacheKey)
        } catch is CancellationError {
            return
        } catch {
            guard activeNearbyRequestID == requestID else { return }
            if cachedNearbyEntry == nil {
                setNearbyError(error.localizedDescription)
            }
        }

    }

    func searchPlaces() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            searchResults = []
            savedPlaceSearchResults = []
            searchError = nil
            return
        }

        let requestID = UUID()
        activeSearchRequestID = requestID
        searchError = nil
        isSearching = true
        clearMapTapChoices()

        async let providerResults = try? searchService.search(query: query, near: visibleCenter)
        async let savedResults = try? vibeService.searchSavedPlaces(
            query: query,
            latitude: visibleCenter.latitude,
            longitude: visibleCenter.longitude,
            limit: 12,
            deviceIdHash: identityService.deviceIDHash()
        )
        let results = await providerResults ?? []
        let reviewedPlaces = await savedResults ?? []

        guard !Task.isCancelled else {
            return
        }
        guard activeSearchRequestID == requestID,
              searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) == query else {
            return
        }

        searchResults = results
        savedPlaceSearchResults = reviewedPlaces
        searchError = nil
        trackSearchIfNeeded(query: query, resultCount: filteredSearchResults.count)

        if activeSearchRequestID == requestID {
            isSearching = false
        }
    }

    func clearSearch() {
        activeSearchRequestID = nil
        searchQuery = ""
        searchResults = []
        savedPlaceSearchResults = []
        searchError = nil
        isSearching = false
    }

    func setVibeFilter(_ vibe: VibeTag?) {
        guard let vibe else {
            selectedVibeFilters = []
            return
        }

        var filters = selectedVibeFilters
        if filters.contains(vibe) {
            filters.remove(vibe)
        } else {
            filters.insert(vibe)
        }
        selectedVibeFilters = filters
    }

    func selectSearchResult(_ result: PlaceSearchResult) async {
        let rank = filteredSearchResults.firstIndex(of: result).map { String($0 + 1) }
        trackAnalytics(
            "place_selected",
            properties: analyticsPlaceProperties(
                candidate: result.candidate,
                place: result.vibedPlace,
                source: "search",
                extra: [
                    "result_rank": rank,
                    "has_community_vibes": result.hasCommunityVibes ? "true" : "false"
                ]
            )
        )
        await select(result.candidate, knownPlace: result.vibedPlace, opensRating: true)
    }

    func resolvePointOfInterestSelection(for selectedItem: MKMapItem) async {
        let requestID = UUID()
        activeMapTapRequestID = requestID
        selectedPlace = nil
        mapTapMatches = []
        mapTapError = nil
        isResolvingMapTap = true
        clearSearch()

        do {
            let matches = try await searchService.pointOfInterestChoices(for: selectedItem)
            guard activeMapTapRequestID == requestID else { return }

            if matches.count > 1 {
                mapTapMatches = matches
                mapTapError = nil
            } else if let match = matches.first {
                activeMapTapRequestID = nil
                await select(match.candidate, opensRating: true)
            } else {
                mapTapMatches = []
                mapTapError = L10n.string("No map places found here.")
            }
        } catch is CancellationError {
            return
        } catch {
            guard activeMapTapRequestID == requestID else { return }
            mapTapMatches = []
            mapTapError = L10n.string("Could not load that place. Try searching its name.")
        }

        isResolvingMapTap = false
    }

    func resolvePointOfInterestSelection(named title: String?, near coordinate: CLLocationCoordinate2D) async {
        let requestID = UUID()
        activeMapTapRequestID = requestID
        selectedPlace = nil
        mapTapMatches = []
        mapTapError = nil
        isResolvingMapTap = true
        clearSearch()

        do {
            let matches = try await searchService.pointOfInterestChoices(named: title, near: coordinate)
            guard activeMapTapRequestID == requestID else { return }

            if matches.count > 1 {
                mapTapMatches = matches
                mapTapError = nil
            } else if let match = matches.first {
                activeMapTapRequestID = nil
                await select(match.candidate, opensRating: true)
            } else {
                mapTapMatches = []
                mapTapError = L10n.string("Could not load that place. Try searching its name.")
            }
        } catch is CancellationError {
            return
        } catch {
            guard activeMapTapRequestID == requestID else { return }
            mapTapMatches = []
            mapTapError = L10n.string("Could not load that place. Try searching its name.")
        }

        isResolvingMapTap = false
    }

    func selectMapTapMatch(_ match: PlaceCandidateMatch) async {
        trackAnalytics(
            "place_selected",
            properties: analyticsPlaceProperties(candidate: match.candidate, place: nil, source: "map_tap")
        )
        await select(match.candidate, opensRating: true)
    }

    func selectNearbyPlace(_ place: VibePlace) {
        trackAnalytics(
            "place_selected",
            properties: analyticsPlaceProperties(candidate: place.placeCandidate, place: place, source: "nearby_list")
        )
        selectedPlace = place
        clearMapTapChoices()
        clearSearch()
        enrichAddressIfNeeded(for: place)
    }

    func openRating(for place: VibePlace) {
        trackAnalytics(
            "rating_started",
            properties: analyticsPlaceProperties(candidate: place.placeCandidate, place: place, source: "place_card")
        )
        selectedPlace = place
        clearMapTapChoices()
        clearSearch()
        ratingDraft = RatingDraft(place: place)
        enrichAddressIfNeeded(for: place)
    }

    func closeRatingFlow() {
        let shouldCheckAccount = shouldCheckAccountAfterRating
        shouldCheckAccountAfterRating = false
        ratingDraft = nil
        selectedPlace = nil

        guard shouldCheckAccount else {
            return
        }

        Task {
            await maybeOfferAccountSignup()
        }
    }

    func clearSelection() {
        selectedPlace = nil
        clearMapTapChoices()
    }

    func requestCurrentLocation() {
        locationService.requestAuthorizationAndLocation()
    }

    func clearMapTapChoices() {
        activeMapTapRequestID = nil
        mapTapMatches = []
        mapTapError = nil
        isResolvingMapTap = false
    }

    func openRating() {
        guard let selectedPlace else {
            return
        }
        trackAnalytics(
            "rating_started",
            properties: analyticsPlaceProperties(candidate: selectedPlace.placeCandidate, place: selectedPlace, source: "selected_place")
        )
        ratingDraft = RatingDraft(place: selectedPlace)
    }

    func canRevealCommunity(for place: VibePlace) -> Bool {
        place.myRating != nil || contributedPlaceIDs.contains(place.id)
    }

    func submitRating(vibeTags: [VibeTag]) async throws -> RatingSubmission {
        guard let selectedPlace else {
            throw APIError.server("Pick a spot first.")
        }

        let selectedTags = VibeTag.normalizedSelection(vibeTags)
        guard !selectedTags.isEmpty else {
            throw APIError.server("Pick a vibe first.")
        }

        let optimisticSubmission = optimisticRatingSubmission(
            for: selectedPlace,
            selectedTags: selectedTags
        )
        self.selectedPlace = optimisticSubmission.place
        if var draft = ratingDraft, draft.place.id == optimisticSubmission.rating.placeId {
            draft.place = optimisticSubmission.place
            ratingDraft = draft
        }
        markContribution(for: optimisticSubmission.place)
        invalidateAnnotationCaches()
        upsertNearbyPlace(optimisticSubmission.place)
        enqueuePendingRatingSubmission(
            place: optimisticSubmission.place,
            vibeTags: selectedTags
        )
        schedulePendingRatingSync()
        return optimisticSubmission
    }

    func deleteRating() async throws -> VibePlace {
        guard let selectedPlace, selectedPlace.myRating != nil else {
            throw APIError.server("There are no vibes to delete here.")
        }

        let activeSyncTask = pendingRatingSyncTask
        activeSyncTask?.cancel()
        await activeSyncTask?.value
        pendingRatingSyncTask = nil
        removePendingRatingSubmissions(for: selectedPlace.id)

        var deletedPlace = try await vibeService.deleteRating(
            placeId: selectedPlace.id,
            deviceIdHash: identityService.deviceIDHash()
        )
        if deletedPlace.distanceMeters == nil {
            deletedPlace.distanceMeters = selectedPlace.distanceMeters
        }

        contributedPlaceIDs.remove(selectedPlace.id)
        UserDefaults.standard.set(Array(contributedPlaceIDs), forKey: contributedPlaceIDsKey)
        invalidateAnnotationCaches()
        applyPlaceUpdate(deletedPlace, replacing: selectedPlace.id)
        upsertNearbyPlace(deletedPlace)
        return deletedPlace
    }

    private func optimisticRatingSubmission(
        for place: VibePlace,
        selectedTags: [VibeTag]
    ) -> RatingSubmission {
        let normalizedTags = VibeTag.normalizedSelection(selectedTags)
        let rating = VibeRating(
            id: "pending:\(UUID().uuidString)",
            placeId: place.id,
            score: VibeTag.score(for: normalizedTags),
            vibeTag: normalizedTags[0],
            vibeTags: normalizedTags,
            createdAt: nil,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        var optimisticPlace = place
        optimisticPlace.myRating = rating
        optimisticPlace.stats = optimisticStats(
            for: place,
            replacing: place.myRating,
            with: rating
        )

        return RatingSubmission(
            place: optimisticPlace,
            rating: rating,
            discovery: RatingDiscovery(wasFirstVibe: place.myRating == nil && place.vibeCount == 0)
        )
    }

    private func optimisticStats(
        for place: VibePlace,
        replacing previousRating: VibeRating?,
        with rating: VibeRating
    ) -> PlaceStats {
        let previousStats = place.stats ?? PlaceStats(ratingCount: 0, averageScore: 0, topVibeTag: nil, topVibes: nil)
        let ratingCount = max(1, previousStats.ratingCount + (previousRating == nil ? 1 : 0))
        let previousTotalScore = previousStats.averageScore * Double(max(previousStats.ratingCount, 0))
        let adjustedTotalScore: Double
        if let previousRating {
            adjustedTotalScore = previousTotalScore - previousRating.score + rating.score
        } else {
            adjustedTotalScore = previousTotalScore + rating.score
        }

        let previousOrder = Dictionary(
            uniqueKeysWithValues: VibeTag.bestToWorst(VibeTag.allCases).enumerated().map { ($0.element, $0.offset) }
        )
        var counts: [VibeTag: Int] = [:]
        for breakdown in previousStats.visibleTopVibes {
            counts[breakdown.vibeTag, default: 0] += breakdown.count
        }
        for tag in previousRating?.selectedVibeTags ?? [] {
            counts[tag, default: 0] -= 1
        }
        for tag in rating.selectedVibeTags {
            counts[tag, default: 0] += 1
        }

        let sortedTopVibes = counts
            .filter { $0.value > 0 }
            .sorted { lhs, rhs in
                if lhs.value != rhs.value {
                    return lhs.value > rhs.value
                }
                return (previousOrder[lhs.key] ?? Int.max) < (previousOrder[rhs.key] ?? Int.max)
            }
            .map { tag, count in
                VibeBreakdown(
                    vibeTag: tag,
                    count: count,
                    percentage: Int((Double(count) / Double(ratingCount) * 100).rounded())
                )
            }
        let topVibes = sortedTopVibes
            .filter { $0.vibeTag == rating.vibeTag } +
            sortedTopVibes.filter { $0.vibeTag != rating.vibeTag }

        return PlaceStats(
            ratingCount: ratingCount,
            averageScore: adjustedTotalScore / Double(ratingCount),
            topVibeTag: rating.vibeTag,
            topVibes: topVibes,
            recentVibeCount: previousStats.recentVibeCount,
            recentPositivePercentage: previousStats.recentPositivePercentage
        )
    }

    private func enqueuePendingRatingSubmission(place: VibePlace, vibeTags: [VibeTag]) {
        let pendingSubmission = PendingRatingSubmission(
            id: UUID(),
            localPlaceID: place.id,
            candidate: place.placeCandidate,
            vibeTags: vibeTags,
            createdAt: Date()
        )
        var pendingSubmissions = loadPendingRatingSubmissions()
        pendingSubmissions.removeAll {
            $0.localPlaceID == pendingSubmission.localPlaceID ||
                $0.candidate.id == pendingSubmission.candidate.id
        }
        pendingSubmissions.append(pendingSubmission)
        savePendingRatingSubmissions(pendingSubmissions)
    }

    private func schedulePendingRatingSync() {
        guard pendingRatingSyncTask == nil,
              !loadPendingRatingSubmissions().isEmpty else {
            return
        }

        pendingRatingSyncTask = Task { [weak self] in
            await self?.syncPendingRatingSubmissions()
        }
    }

    private func syncPendingRatingSubmissions() async {
        var shouldContinueSyncing = true
        defer {
            pendingRatingSyncTask = nil
            if shouldContinueSyncing, !loadPendingRatingSubmissions().isEmpty {
                schedulePendingRatingSync()
            }
        }

        while let pendingSubmission = loadPendingRatingSubmissions().first {
            guard !Task.isCancelled else {
                shouldContinueSyncing = false
                return
            }

            do {
                let syncedPlace = try await vibeService.upsertPlace(pendingSubmission.candidate)
                let submission = try await vibeService.submitRating(
                    placeId: syncedPlace.id,
                    deviceIdHash: identityService.deviceIDHash(),
                    vibeTags: pendingSubmission.vibeTags
                )
                removePendingRatingSubmission(id: pendingSubmission.id)
                await applySyncedRatingSubmission(
                    submission,
                    replacingLocalPlaceID: pendingSubmission.localPlaceID
                )
            } catch is CancellationError {
                shouldContinueSyncing = false
                return
            } catch {
                shouldContinueSyncing = false
                alert = AppAlert(
                    title: L10n.string("Still saving"),
                    message: L10n.string("Your vibe is saved on this device and will retry when the connection improves.")
                )
                return
            }
        }
    }

    private func applySyncedRatingSubmission(
        _ submission: RatingSubmission,
        replacingLocalPlaceID localPlaceID: String
    ) async {
        let localPlace = selectedPlace?.id == localPlaceID
            ? selectedPlace
            : nearbyPlaces.first { $0.id == localPlaceID }
        let syncedPlace = localPlace.map { submission.place.preservingInteraction(from: $0) } ?? submission.place

        if localPlaceID != syncedPlace.id {
            contributedPlaceIDs.remove(localPlaceID)
            UserDefaults.standard.set(Array(contributedPlaceIDs), forKey: contributedPlaceIDsKey)
        }

        invalidateAnnotationCaches()
        applyPlaceUpdate(syncedPlace, replacing: localPlaceID)
        if localPlaceID != syncedPlace.id {
            nearbyPlaces.removeAll { $0.id == localPlaceID }
            removeCachedPlace(id: localPlaceID)
        }
        markContribution(for: syncedPlace)
        upsertNearbyPlace(syncedPlace)
        shouldCheckAccountAfterRating = true

        if ratingDraft == nil {
            await maybeOfferAccountSignup()
        }
    }

    private func loadPendingRatingSubmissions() -> [PendingRatingSubmission] {
        guard let data = UserDefaults.standard.data(forKey: pendingRatingSubmissionsKey),
              let submissions = try? JSONDecoder().decode([PendingRatingSubmission].self, from: data) else {
            return []
        }

        return submissions.sorted { $0.createdAt < $1.createdAt }
    }

    private func savePendingRatingSubmissions(_ submissions: [PendingRatingSubmission]) {
        guard !submissions.isEmpty else {
            UserDefaults.standard.removeObject(forKey: pendingRatingSubmissionsKey)
            return
        }

        if let data = try? JSONEncoder().encode(submissions) {
            UserDefaults.standard.set(data, forKey: pendingRatingSubmissionsKey)
        }
    }

    private func removePendingRatingSubmission(id: UUID) {
        var submissions = loadPendingRatingSubmissions()
        submissions.removeAll { $0.id == id }
        savePendingRatingSubmissions(submissions)
    }

    private func removePendingRatingSubmissions(for placeID: String) {
        var submissions = loadPendingRatingSubmissions()
        submissions.removeAll { $0.localPlaceID == placeID }
        savePendingRatingSubmissions(submissions)
        if !submissions.isEmpty {
            schedulePendingRatingSync()
        }
    }

    private func invalidateAnnotationCaches() {
        nearbyCache.removeAll()
        nearbyCacheOrder.removeAll()
        mapCellCache.removeAll()
        mapCellCacheOrder.removeAll()
        currentNearbyCacheKey = nil
        currentMapCellCacheKey = nil
    }

    func dismissAccountSignupPrompt() {
        UserDefaults.standard.set(true, forKey: accountPromptDismissedKey)
        accountSignupPrompt = nil
    }

    var hasConfirmedAccount: Bool {
        accountSessionToken != nil
    }

    func refreshAccountStatusOnActivation() {
        schedulePendingRatingSync()

        guard accountSessionToken == nil else { return }
        let now = Date()
        if let lastAccountStatusRefresh, now.timeIntervalSince(lastAccountStatusRefresh) < 4 {
            return
        }

        lastAccountStatusRefresh = now
        Task {
            await refreshAccountStatus()
        }
    }

    func requestAccountSignup(email: String) async throws -> AccountSignupResponse {
        let response = try await vibeService.requestAccountSignup(
            email: email,
            deviceIdHash: identityService.deviceIDHash()
        )
        trackAnalytics(
            "account_signup_requested",
            properties: [
                "status": response.status,
                "eligible": response.account.eligible ? "true" : "false",
                "email_sent": response.emailSent ? "true" : "false"
            ]
        )
        if let sessionToken = response.sessionToken ?? response.account.sessionToken {
            saveAccountSessionToken(sessionToken)
        }
        return response
    }

    func requestAccountLogin(email: String) async throws -> AccountLoginResponse {
        let response = try await vibeService.requestAccountLogin(email: email)
        trackAnalytics(
            "account_login_requested",
            properties: [
                "status": response.status,
                "email_sent": response.emailSent ? "true" : "false"
            ]
        )
        return response
    }

    func requestAccountLogout() async {
        do {
            _ = try await vibeService.requestAccountLogout()
            alert = AppAlert(
                title: L10n.string("Logged out"),
                message: L10n.string("You can keep using VIBES Y'ALL anonymously on this device.")
            )
        } catch {
            alert = AppAlert(
                title: L10n.string("Logged out locally"),
                message: L10n.string("The server session could not be reached, but this device is no longer using the account session.")
            )
        }

        clearAccountSessionToken()
        trackAnalytics("account_logout")
        UserDefaults.standard.set(true, forKey: accountPromptDismissedKey)
        accountSignupPrompt = nil
    }

    func presentAccountSignupFromMenu() async {
        guard accountSignupPrompt == nil else { return }

        do {
            let eligibility = try await vibeService.fetchAccountEligibility(deviceIdHash: identityService.deviceIDHash())
            if let sessionToken = eligibility.sessionToken {
                saveAccountSessionToken(sessionToken)
                alert = AppAlert(
                    title: L10n.string("Account saved"),
                    message: L10n.string("Your confirmed account is active on this device.")
                )
                return
            }

            if eligibility.profile?.emailVerified == true {
                UserDefaults.standard.set(false, forKey: accountPromptDismissedKey)
                accountSignupPrompt = AccountSignupPrompt(eligibility: eligibility)
                return
            }

            if hasConfirmedAccount {
                alert = AppAlert(
                    title: L10n.string("Account saved"),
                    message: L10n.string("Your confirmed account is active on this device.")
                )
                return
            }

            guard eligibility.eligible else {
                alert = AppAlert(
                    title: L10n.string("Keep vibing"),
                    message: L10n.format(
                        "Account backup unlocks after %d vibed places. You have %d, so %d more to go.",
                        eligibility.threshold,
                        eligibility.vibedPlaceCount,
                        eligibility.remainingPlaces
                    )
                )
                return
            }

            UserDefaults.standard.set(false, forKey: accountPromptDismissedKey)
            accountSignupPrompt = AccountSignupPrompt(eligibility: eligibility)
        } catch {
            alert = AppAlert(title: L10n.string("Could not check account status"), message: error.localizedDescription)
        }
    }

    func requestAccountDeletion(email: String) async throws -> AccountDeletionResponse {
        let response = try await vibeService.requestAccountDeletion(
            email: email,
            deviceIdHash: identityService.deviceIDHash()
        )
        clearAccountSessionToken()
        UserDefaults.standard.set(false, forKey: accountPromptDismissedKey)
        accountSignupPrompt = nil
        trackAnalytics(
            "account_delete_requested",
            properties: [
                "status": response.status,
                "deleted": response.deleted ? "true" : "false"
            ]
        )
        alert = AppAlert(title: L10n.string("Account deleted"), message: L10n.serverMessage(response.message))
        return response
    }

    func handleAccountConfirmationURL(_ url: URL) {
        guard url.scheme == "vibesyall",
              url.host == "account",
              url.path == "/confirmed",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let session = components.queryItems?.first(where: { $0.name == "session" })?.value,
              !session.isEmpty else {
            return
        }

        saveAccountSessionToken(session)
        alert = AppAlert(
            title: L10n.string("Account confirmed"),
            message: L10n.string("Your past and future vibes can now stay tied to your account.")
        )
    }

    private func select(_ candidate: PlaceCandidate, knownPlace: VibePlace? = nil, opensRating: Bool = false) async {
        isSelectingPlace = true
        defer { isSelectingPlace = false }

        clearSearch()
        clearMapTapChoices()

        let place: VibePlace
        if let knownPlace = knownPlace ?? existingKnownPlace(for: candidate) {
            place = knownPlace.enriched(with: candidate)
        } else {
            do {
                place = try await vibeService.upsertPlace(candidate).enriched(with: candidate)
            } catch {
                place = VibePlace(candidate: candidate)
            }
        }
        selectedPlace = place
        if place.myRating != nil {
            markContribution(for: place)
        }

        if opensRating {
            ratingDraft = RatingDraft(place: place)
            trackAnalytics(
                "rating_started",
                properties: analyticsPlaceProperties(candidate: candidate, place: place, source: "selection")
            )
        }

        if knownPlace != nil {
            persistEnrichedPlaceIfUseful(place, sourceCandidate: candidate)
        }
    }

    private func recordAppOpenIfNeeded() {
        guard !hasRecordedAppOpen else { return }
        hasRecordedAppOpen = true
        trackAnalytics(
            "app_open",
            properties: [
                "has_account": accountSessionToken == nil ? "false" : "true"
            ]
        )
    }

    private func trackSearchIfNeeded(query: String, resultCount: Int) {
        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard normalizedQuery.count >= 2,
              normalizedQuery != lastTrackedSearchQuery else {
            return
        }

        lastTrackedSearchQuery = normalizedQuery
        trackAnalytics(
            "search_performed",
            properties: [
                "query_length": String(normalizedQuery.count),
                "result_count": String(resultCount),
                "visible_radius_meters": String(Int(visibleRadius.rounded())),
                "has_active_filter": hasActiveVibeFilters ? "true" : "false"
            ]
        )
    }

    private func trackAnalytics(_ name: String, properties: [String: String] = [:]) {
        let deviceIDHash = identityService.deviceIDHash()
        Task {
            await vibeService.recordAnalyticsEvent(
                name: name,
                deviceIdHash: deviceIDHash,
                properties: properties
            )
        }
    }

    private func analyticsPlaceProperties(
        candidate: PlaceCandidate,
        place: VibePlace?,
        source: String,
        extra: [String: String?] = [:]
    ) -> [String: String] {
        var properties: [String: String] = [
            "source": source,
            "provider": candidate.provider,
            "has_provider_place_id": candidate.providerPlaceId?.isEmpty == false ? "true" : "false",
            "has_community_vibes": (place?.vibeCount ?? 0) > 0 ? "true" : "false"
        ]

        if let place {
            properties["place_id"] = place.id
            properties["vibe_count"] = String(place.vibeCount)
            if let topVibe = place.stats?.visibleTopVibes.first?.vibeTag {
                properties["top_vibe"] = topVibe.rawValue
            }
        }

        if let category = (candidate.primaryCategory ?? candidate.category)?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
            properties["category"] = category
            properties["primary_category"] = category
        }

        if let providerCategory = candidate.providerCategory?.trimmingCharacters(in: .whitespacesAndNewlines), !providerCategory.isEmpty {
            properties["provider_category"] = providerCategory
        }

        for (key, value) in extra {
            if let value, !value.isEmpty {
                properties[key] = value
            }
        }

        return properties
    }

    private func loadAllowedVibes() async {
        do {
            let serverVibes = try await vibeService.fetchVibes()
            allowedVibes = VibeTag.allCases.filter {
                serverVibes.contains($0) || $0 == .bougie || $0 == .lowKey
            }
        } catch {
            allowedVibes = VibeTag.allCases
        }
    }

    private func maybeOfferAccountSignup() async {
        guard accountSignupPrompt == nil,
              accountSessionToken == nil,
              !UserDefaults.standard.bool(forKey: accountPromptDismissedKey) else {
            return
        }

        do {
            let eligibility = try await vibeService.fetchAccountEligibility(deviceIdHash: identityService.deviceIDHash())
            if let sessionToken = eligibility.sessionToken {
                saveAccountSessionToken(sessionToken)
                return
            }

            guard eligibility.eligible,
                  eligibility.profile?.emailVerified != true else {
                return
            }

            accountSignupPrompt = AccountSignupPrompt(eligibility: eligibility)
        } catch {
            return
        }
    }

    private func refreshAccountStatus() async {
        guard accountSessionToken == nil else { return }

        do {
            let eligibility = try await vibeService.fetchAccountEligibility(deviceIdHash: identityService.deviceIDHash())
            if let sessionToken = eligibility.sessionToken {
                saveAccountSessionToken(sessionToken)
            }
        } catch {
            return
        }
    }

    private func saveAccountSessionToken(_ sessionToken: String) {
        guard !sessionToken.isEmpty else { return }
        UserDefaults.standard.set(sessionToken, forKey: accountSessionTokenKey)
        UserDefaults.standard.set(false, forKey: accountPromptDismissedKey)
        accountSessionToken = sessionToken
        accountSignupPrompt = nil
    }

    private func clearAccountSessionToken() {
        UserDefaults.standard.removeObject(forKey: accountSessionTokenKey)
        accountSessionToken = nil
    }

    private func applyNearbyPlaces(_ places: [VibePlace], cacheKey: String? = nil) {
        let signature = Self.nearbySignature(places)
        guard displayedAnnotationLayer != .nearby || displayedNearbySignature != signature else {
            if let cacheKey {
                currentNearbyCacheKey = cacheKey
            }
            return
        }

        if displayedNearbySignature != signature {
            nearbyPlaces = places
            displayedNearbySignature = signature
        }
        if displayedAnnotationLayer != .nearby {
            displayedAnnotationLayer = .nearby
        }
        if let cacheKey {
            currentNearbyCacheKey = cacheKey
        }
        syncContributedPlaces(from: places)
        enrichNearbyAddressesIfNeeded(places)
    }

    private func applyMapCellClusters(_ clusters: [MapCellCluster], cacheKey: String? = nil) {
        let signature = Self.mapCellSignature(clusters)
        guard displayedAnnotationLayer != .mapCells || displayedMapCellSignature != signature else {
            if let cacheKey {
                currentMapCellCacheKey = cacheKey
            }
            return
        }

        if displayedMapCellSignature != signature {
            mapCellClusters = clusters
            displayedMapCellSignature = signature
        }
        if displayedAnnotationLayer != .mapCells {
            displayedAnnotationLayer = .mapCells
        }
        if let cacheKey {
            currentMapCellCacheKey = cacheKey
        }
        currentNearbyCacheKey = nil
    }

    private func cancelActiveNearbyRequest() {
        activeNearbyRequestID = nil
        activeNearbyRequestKey = nil
    }

    private func setIsLoadingNearby(_ value: Bool) {
        guard isLoadingNearby != value else { return }
        isLoadingNearby = value
    }

    private func setNearbyError(_ value: String?) {
        guard nearbyError != value else { return }
        nearbyError = value
    }

    private static func nearbySignature(_ places: [VibePlace]) -> String {
        places.map { place in
            let topVibes = place.stats?.visibleTopVibes.prefix(3).map {
                "\($0.vibeTag.rawValue):\($0.count):\($0.percentage)"
            }
            .joined(separator: ",") ?? ""
            let selectedVibes = place.myRating?.selectedVibeTags.map(\.rawValue).joined(separator: ",") ?? ""
            return "\(place.id):\(place.vibeCount):\(topVibes):\(selectedVibes)"
        }
        .joined(separator: "|")
    }

    private static func mapCellSignature(_ clusters: [MapCellCluster]) -> String {
        clusters.map { cluster in
            "\(cluster.id):\(cluster.count):\(cluster.totalVibes):\(cluster.displayVibe?.rawValue ?? ""):\(cluster.topVibePercent ?? 0)"
        }
        .joined(separator: "|")
    }

    private func cacheNearbyPlaces(_ places: [VibePlace], for key: String) {
        nearbyCache[key] = NearbyCacheEntry(places: places, loadedAt: Date())
        if !nearbyCacheOrder.contains(key) {
            nearbyCacheOrder.append(key)
        }

        while nearbyCacheOrder.count > AppConfig.nearbyMemoryCacheLimit {
            let expiredKey = nearbyCacheOrder.removeFirst()
            nearbyCache.removeValue(forKey: expiredKey)
        }
    }

    private func cacheMapCellClusters(_ clusters: [MapCellCluster], for key: String) {
        mapCellCache[key] = MapCellCacheEntry(clusters: clusters, loadedAt: Date())
        if !mapCellCacheOrder.contains(key) {
            mapCellCacheOrder.append(key)
        }

        while mapCellCacheOrder.count > AppConfig.mapCellMemoryCacheLimit {
            let expiredKey = mapCellCacheOrder.removeFirst()
            mapCellCache.removeValue(forKey: expiredKey)
        }
    }

    private func sortedMapCellClusters(_ clusters: [MapCellCluster]) -> [MapCellCluster] {
        clusters.sorted { lhs, rhs in
            isMapCellClusterHigherPriority(lhs, than: rhs)
        }
    }

    private func geographicallyBalancedMapCellClusters(_ sortedClusters: [MapCellCluster], limit: Int) -> [MapCellCluster] {
        guard limit > 0 else { return [] }
        guard sortedClusters.count > limit else { return sortedClusters }

        let representatives = mapCellBucketRepresentatives(from: sortedClusters)
        let coverageLimit = min(limit, max(12, limit / 2), representatives.count)
        var selected: [MapCellCluster] = []
        var selectedIDs = Set<String>()

        func appendCluster(_ cluster: MapCellCluster) {
            guard selected.count < limit, !selectedIDs.contains(cluster.id) else {
                return
            }

            selected.append(cluster)
            selectedIDs.insert(cluster.id)
        }

        if let firstRepresentative = representatives.first {
            appendCluster(firstRepresentative)
        }

        while selected.count < coverageLimit {
            let nextCluster = representatives
                .filter { !selectedIDs.contains($0.id) }
                .max { lhs, rhs in
                    let lhsDistance = minimumDistance(from: lhs, to: selected)
                    let rhsDistance = minimumDistance(from: rhs, to: selected)
                    if abs(lhsDistance - rhsDistance) > 1 {
                        return lhsDistance < rhsDistance
                    }
                    return isMapCellClusterHigherPriority(rhs, than: lhs)
                }

            guard let nextCluster else {
                break
            }

            appendCluster(nextCluster)
        }

        for cluster in sortedClusters {
            appendCluster(cluster)
            if selected.count >= limit {
                break
            }
        }

        return selected
    }

    private func mapCellBucketRepresentatives(from sortedClusters: [MapCellCluster]) -> [MapCellCluster] {
        let bucketSizeMeters = min(max(visibleRadius / 5, 110_000), 420_000)
        let latitudeStep = bucketSizeMeters / 111_320
        let longitudeStep = bucketSizeMeters / max(111_320 * cos((visibleCenter.latitude * .pi) / 180), 1)
        var representatives: [MapCellDisplayBucket: MapCellCluster] = [:]

        for cluster in sortedClusters {
            let bucket = MapCellDisplayBucket(
                x: Int(floor(cluster.longitude / longitudeStep)),
                y: Int(floor(cluster.latitude / latitudeStep))
            )

            if representatives[bucket] == nil {
                representatives[bucket] = cluster
            }
        }

        return representatives.values.sorted { lhs, rhs in
            isMapCellClusterHigherPriority(lhs, than: rhs)
        }
    }

    private func minimumDistance(from cluster: MapCellCluster, to selectedClusters: [MapCellCluster]) -> CLLocationDistance {
        guard !selectedClusters.isEmpty else {
            return .greatestFiniteMagnitude
        }

        let clusterLocation = CLLocation(latitude: cluster.latitude, longitude: cluster.longitude)
        return selectedClusters
            .map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: clusterLocation) }
            .min() ?? .greatestFiniteMagnitude
    }

    private func isMapCellClusterHigherPriority(_ lhs: MapCellCluster, than rhs: MapCellCluster) -> Bool {
        if lhs.count == rhs.count {
            if lhs.totalVibes == rhs.totalVibes {
                return lhs.id < rhs.id
            }
            return lhs.totalVibes > rhs.totalVibes
        }
        return lhs.count > rhs.count
    }

    private func isMapCellClusterInVisibleArea(_ cluster: MapCellCluster) -> Bool {
        let clusterLocation = CLLocation(latitude: cluster.latitude, longitude: cluster.longitude)
        let visibleLocation = CLLocation(latitude: visibleCenter.latitude, longitude: visibleCenter.longitude)
        return clusterLocation.distance(from: visibleLocation) <= visibleRadius * 1.08
    }

    private func isMapCellClusterRepresentedByNearbyPlaces(_ cluster: MapCellCluster) -> Bool {
        let clusterLocation = CLLocation(latitude: cluster.latitude, longitude: cluster.longitude)
        let matchDistance = AppConfig.mapCellContinuityMatchDistance(for: cluster)
        let clusterVibe = cluster.displayVibe

        return visibleNearbyPlaces.contains { place in
            let distance = CLLocation(latitude: place.latitude, longitude: place.longitude)
                .distance(from: clusterLocation)
            guard distance <= matchDistance else {
                return false
            }

            guard let clusterVibe else {
                return true
            }

            return place.matchesAnyVibe(in: [clusterVibe])
        }
    }

    private func updateCachedPlace(_ place: VibePlace, replacing placeID: String) {
        for key in nearbyCache.keys {
            guard var entry = nearbyCache[key],
                  let index = entry.places.firstIndex(where: { $0.id == placeID }) else {
                continue
            }
            entry.places[index] = place
            nearbyCache[key] = entry
        }
    }

    private func removeCachedPlace(id placeID: String) {
        for key in nearbyCache.keys {
            guard var entry = nearbyCache[key] else {
                continue
            }
            let countBefore = entry.places.count
            entry.places.removeAll { $0.id == placeID }
            if entry.places.count != countBefore {
                nearbyCache[key] = entry
            }
        }
    }

    private func upsertNearbyPlace(_ place: VibePlace) {
        guard place.hasRatings else {
            nearbyPlaces.removeAll { $0.id == place.id }
            displayedNearbySignature = Self.nearbySignature(nearbyPlaces)
            removeCachedPlace(id: place.id)
            return
        }

        if let index = nearbyPlaces.firstIndex(where: { $0.id == place.id }) {
            nearbyPlaces[index] = place
        } else {
            nearbyPlaces.insert(place, at: 0)
        }
        displayedNearbySignature = Self.nearbySignature(nearbyPlaces)
        updateCachedPlace(place, replacing: place.id)
        if let currentNearbyCacheKey {
            cacheNearbyPlaces(nearbyPlaces, for: currentNearbyCacheKey)
        }
    }

    private func markContribution(for place: VibePlace) {
        contributedPlaceIDs.insert(place.id)
        UserDefaults.standard.set(Array(contributedPlaceIDs), forKey: contributedPlaceIDsKey)
    }

    private func syncContributedPlaces(from places: [VibePlace]) {
        let ids = places.filter { $0.myRating != nil }.map(\.id)
        guard !ids.isEmpty else { return }
        contributedPlaceIDs.formUnion(ids)
        UserDefaults.standard.set(Array(contributedPlaceIDs), forKey: contributedPlaceIDsKey)
    }

    private func enrichNearbyAddressesIfNeeded(_ places: [VibePlace]) {
        guard visibleRadius <= AppConfig.addressEnrichmentMaximumRadiusMeters else {
            return
        }

        let placesMissingStreet = places
            .filter { !$0.hasStreetAddress }
            .prefix(3)

        guard !placesMissingStreet.isEmpty else {
            return
        }

        Task {
            for place in placesMissingStreet {
                await enrichAddress(for: place)
            }
        }
    }

    private func enrichAddressIfNeeded(for place: VibePlace) {
        guard !place.hasStreetAddress else {
            return
        }

        Task {
            await enrichAddress(for: place)
        }
    }

    private func enrichAddress(for place: VibePlace) async {
        guard !place.hasStreetAddress else {
            return
        }

        do {
            let matches = try await searchService.pointOfInterestChoices(named: place.name, near: place.coordinate)
            guard let candidate = matches.map(\.candidate).first(where: { $0.hasStreetAddress }) else {
                return
            }

            let enrichedPlace = place.enriched(with: candidate)
            applyPlaceUpdate(enrichedPlace, replacing: place.id)
            persistEnrichedPlaceIfUseful(enrichedPlace, sourceCandidate: candidate)
        } catch is CancellationError {
            return
        } catch {
            return
        }
    }

    private func persistEnrichedPlaceIfUseful(_ place: VibePlace, sourceCandidate candidate: PlaceCandidate) {
        guard candidate.hasStreetAddress, !place.id.hasPrefix("local:") else {
            return
        }

        Task {
            do {
                let savedPlace = try await vibeService.upsertPlace(place.placeCandidate)
                let displayPlace = savedPlace.preservingInteraction(from: place)
                applyPlaceUpdate(displayPlace, replacing: place.id)
            } catch {
                return
            }
        }
    }

    private func applyPlaceUpdate(_ place: VibePlace, replacing placeID: String) {
        if selectedPlace?.id == placeID {
            selectedPlace = place
        }

        if var draft = ratingDraft, draft.place.id == placeID {
            draft.place = place
            ratingDraft = draft
        }

        if let index = nearbyPlaces.firstIndex(where: { $0.id == placeID }) {
            nearbyPlaces[index] = place
            displayedNearbySignature = Self.nearbySignature(nearbyPlaces)
        }
        if let index = savedPlaceSearchResults.firstIndex(where: { $0.id == placeID }) {
            savedPlaceSearchResults[index] = place
        }
        updateCachedPlace(place, replacing: placeID)
    }

    private func rankedSearchResults(applyingVibeFilters: Bool) -> [PlaceSearchResult] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            return []
        }

        var results: [PlaceSearchResult] = []
        var seenPlaceIDs = Set<String>()
        var seenCandidateIDs = Set<String>()

        let localMatches = (savedPlaceSearchResults + nearbyPlaces)
            .uniquedByPlaceID()
            .filter { place in
                place.hasRatings &&
                    place.matchesSearchQuery(query, requireStrongNameMatch: PlaceSearchQueryIntent.isSpecificNameSearch(query)) &&
                    (!applyingVibeFilters || place.matchesAnyVibe(in: selectedVibeFilters))
            }
            .sorted {
                distanceFromVisibleCenter(to: $0.coordinate) < distanceFromVisibleCenter(to: $1.coordinate)
            }

        for place in localMatches {
            let displayPlace = placeWithVisibleDistance(place)
            results.append(PlaceSearchResult(candidate: displayPlace.placeCandidate, vibedPlace: displayPlace))
            seenPlaceIDs.insert(place.id)
            seenCandidateIDs.insert(place.placeCandidate.id)
        }

        var plainCandidates: [PlaceSearchResult] = []

        for candidate in searchResults {
            if PlaceSearchQueryIntent.isSpecificNameSearch(query),
               !PlaceNameSearchMatcher.matchTier(query: query, candidateName: candidate.name).isStrongMatch {
                continue
            }

            if let place = existingKnownPlace(for: candidate), place.hasRatings {
                guard !applyingVibeFilters || place.matchesAnyVibe(in: selectedVibeFilters) else {
                    continue
                }

                let enrichedPlace = place.enriched(with: candidate)
                if !seenPlaceIDs.contains(enrichedPlace.id) {
                    let displayPlace = placeWithVisibleDistance(enrichedPlace)
                    results.append(PlaceSearchResult(candidate: displayPlace.placeCandidate, vibedPlace: displayPlace))
                    seenPlaceIDs.insert(enrichedPlace.id)
                    seenCandidateIDs.insert(candidate.id)
                }
                continue
            }

            guard !applyingVibeFilters || selectedVibeFilters.isEmpty else {
                continue
            }

            guard !seenCandidateIDs.contains(candidate.id) else {
                continue
            }

            plainCandidates.append(PlaceSearchResult(candidate: candidateWithVisibleDistance(candidate), vibedPlace: nil))
            seenCandidateIDs.insert(candidate.id)
        }

        return sortedSearchResults(results + plainCandidates, query: query)
    }

    private func sortedSearchResults(_ results: [PlaceSearchResult], query: String) -> [PlaceSearchResult] {
        let preferDistance = Self.prefersDistanceRanking(for: query)

        return results.sorted { lhs, rhs in
            if preferDistance {
                let lhsDistance = distanceFromVisibleCenter(to: lhs)
                let rhsDistance = distanceFromVisibleCenter(to: rhs)
                if abs(lhsDistance - rhsDistance) > 250 {
                    return lhsDistance < rhsDistance
                }
            }

            let lhsRelevance = Self.searchRelevance(for: lhs, query: query)
            let rhsRelevance = Self.searchRelevance(for: rhs, query: query)
            if lhsRelevance != rhsRelevance {
                return lhsRelevance < rhsRelevance
            }

            if lhs.hasCommunityVibes != rhs.hasCommunityVibes {
                return lhs.hasCommunityVibes
            }

            let lhsDistance = distanceFromVisibleCenter(to: lhs)
            let rhsDistance = distanceFromVisibleCenter(to: rhs)
            if abs(lhsDistance - rhsDistance) > 25 {
                return lhsDistance < rhsDistance
            }

            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func distanceFromVisibleCenter(to result: PlaceSearchResult) -> CLLocationDistance {
        let coordinate = result.vibedPlace?.coordinate ?? result.candidate.coordinate
        return distanceFromVisibleCenter(to: coordinate)
    }

    private func distanceFromVisibleCenter(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            .distance(from: CLLocation(latitude: visibleCenter.latitude, longitude: visibleCenter.longitude))
    }

    private func placeWithVisibleDistance(_ place: VibePlace) -> VibePlace {
        var displayPlace = place
        displayPlace.distanceMeters = distanceFromVisibleCenter(to: place.coordinate)
        return displayPlace
    }

    private func candidateWithVisibleDistance(_ candidate: PlaceCandidate) -> PlaceCandidate {
        var displayCandidate = candidate
        displayCandidate.distanceMeters = distanceFromVisibleCenter(to: candidate.coordinate)
        return displayCandidate
    }

    private static func searchRelevance(for result: PlaceSearchResult, query: String) -> Int {
        if PlaceSearchQueryIntent.isSpecificNameSearch(query) {
            return PlaceNameSearchMatcher.matchTier(query: query, candidateName: result.name).rawValue
        }

        let normalizedQuery = query.normalizedForSearch()
        guard !normalizedQuery.isEmpty else {
            return 5
        }

        let queryTokens = normalizedQuery
            .split(separator: " ")
            .map(String.init)
        let normalizedName = result.name.normalizedForSearch()
        let searchableText = [
            result.name,
            result.locationLine,
            result.candidate.category,
            result.candidate.primaryCategory,
            result.candidate.providerCategory,
            result.topVibe?.vibeTag.rawValue
        ]
            .compactMap { $0 }
            .joined(separator: " ")
            .normalizedForSearch()

        if normalizedName == normalizedQuery {
            return 0
        }

        if normalizedName.hasPrefix(normalizedQuery) || normalizedName.contains(normalizedQuery) {
            return 1
        }

        if queryTokens.allSatisfy({ normalizedName.contains($0) }) {
            return 2
        }

        if queryTokens.allSatisfy({ searchableText.contains($0) }) {
            return 3
        }

        return 4
    }

    private static func prefersDistanceRanking(for query: String) -> Bool {
        let tokens = query.normalizedSearchTokens()
        guard !tokens.isEmpty else {
            return false
        }

        return tokens.allSatisfy { token in
            broadSearchIntentTokens.contains(token) ||
                (token.hasSuffix("s") && broadSearchIntentTokens.contains(String(token.dropLast())))
        }
    }

    private static let broadSearchIntentTokens: Set<String> = [
        "atm",
        "asian",
        "bakery",
        "bar",
        "bars",
        "bbq",
        "breakfast",
        "brewery",
        "burger",
        "burgers",
        "cafe",
        "cafes",
        "cajun",
        "chinese",
        "coffee",
        "dinner",
        "drink",
        "drinks",
        "entertainment",
        "food",
        "gas",
        "grocery",
        "groceries",
        "gym",
        "hotel",
        "hotels",
        "italian",
        "lunch",
        "mexican",
        "movie",
        "movies",
        "museum",
        "museums",
        "park",
        "parks",
        "pharmacy",
        "pizza",
        "restaurant",
        "restaurants",
        "shop",
        "shopping",
        "shops",
        "store",
        "stores",
        "taco",
        "tacos",
        "theater",
        "theatre"
    ]

    private func existingKnownPlace(for candidate: PlaceCandidate) -> VibePlace? {
        let knownPlaces = (savedPlaceSearchResults + nearbyPlaces).uniquedByPlaceID()

        if let providerPlaceId = candidate.providerPlaceId, !providerPlaceId.isEmpty {
            if let exactProviderMatch = knownPlaces.first(where: {
                $0.provider == candidate.provider && $0.providerPlaceId == providerPlaceId
            }) {
                return exactProviderMatch
            }

            if let providerMatch = knownPlaces.first(where: { $0.providerPlaceId == providerPlaceId }) {
                return providerMatch
            }
        }

        let candidateName = Self.normalizedPlaceName(candidate.name)
        let candidateLocation = CLLocation(latitude: candidate.latitude, longitude: candidate.longitude)
        let candidateStreet = Self.normalizedPlaceAddress(candidate.streetAddress)

        return knownPlaces
            .compactMap { place -> (place: VibePlace, distance: CLLocationDistance, score: Int)? in
                let placeName = Self.normalizedPlaceName(place.name)
                let exactNameMatch = placeName == candidateName
                let containedNameMatch = !placeName.isEmpty &&
                    !candidateName.isEmpty &&
                    (placeName.contains(candidateName) || candidateName.contains(placeName))

                guard exactNameMatch || containedNameMatch else { return nil }

                let distance = candidateLocation.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
                let placeStreet = Self.normalizedPlaceAddress(place.streetAddress)
                let addressMatch = !candidateStreet.isEmpty &&
                    !placeStreet.isEmpty &&
                    (candidateStreet == placeStreet || candidateStreet.contains(placeStreet) || placeStreet.contains(candidateStreet))

                let isReliableMatch =
                    addressMatch && distance <= 700 ||
                    exactNameMatch && distance <= 260 ||
                    containedNameMatch && distance <= 120

                guard isReliableMatch else { return nil }

                let score: Int
                if addressMatch {
                    score = exactNameMatch ? 0 : 1
                } else if exactNameMatch {
                    score = 2
                } else {
                    score = 3
                }

                return (place, distance, score)
            }
            .sorted {
                if $0.score != $1.score {
                    return $0.score < $1.score
                }
                return $0.distance < $1.distance
            }
            .first?
            .place
    }

    private static func normalizedPlaceName(_ name: String) -> String {
        name
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func normalizedPlaceAddress(_ address: String?) -> String {
        guard let address else { return "" }

        return address
            .lowercased()
            .replacingOccurrences(of: "street", with: "st")
            .replacingOccurrences(of: "avenue", with: "ave")
            .replacingOccurrences(of: "boulevard", with: "blvd")
            .replacingOccurrences(of: "road", with: "rd")
            .replacingOccurrences(of: "drive", with: "dr")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private extension Array where Element == VibePlace {
    func uniquedByPlaceID() -> [VibePlace] {
        var seen = Set<String>()
        return filter { seen.insert($0.id).inserted }
    }
}

private extension VibePlace {
    func matchesSearchQuery(_ query: String, requireStrongNameMatch: Bool) -> Bool {
        if requireStrongNameMatch {
            return PlaceNameSearchMatcher.matchTier(query: query, candidateName: name).isStrongMatch
        }

        let queryTokens = query.normalizedSearchTokens()
        guard !queryTokens.isEmpty else {
            return false
        }

        let searchableText = [
            name,
            category,
            primaryCategory,
            providerCategory,
            streetAddress,
            city,
            region,
            country,
            stats?.visibleTopVibes.map(\.vibeTag.rawValue).joined(separator: " ")
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .normalizedForSearch()

        return queryTokens.allSatisfy { token in
            searchableText.contains(token) ||
                (token.hasSuffix("s") && searchableText.contains(String(token.dropLast())))
        }
    }
}

private extension Array where Element == VibePlace {
    func sortedByDistance(from coordinate: CLLocationCoordinate2D) -> [VibePlace] {
        sorted { lhs, rhs in
            let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let lhsDistance = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude).distance(from: origin)
            let rhsDistance = CLLocation(latitude: rhs.latitude, longitude: rhs.longitude).distance(from: origin)
            return lhsDistance < rhsDistance
        }
    }
}

private extension String {
    func normalizedSearchTokens() -> [String] {
        normalizedForSearch()
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    func normalizedForSearch() -> String {
        PlaceNameSearchMatcher.normalized(self)
    }
}
