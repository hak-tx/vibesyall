import CoreLocation
import Foundation
import MapKit

@MainActor
final class VibeMapViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published private(set) var searchResults: [PlaceCandidate] = []
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
    @Published private var displayedAnnotationLayer: AnnotationLayer = .nearby

    let locationService: LocationService

    private let vibeService: any VibeServicing
    private let searchService: any PlaceSearching
    private let identityService: any DeviceIdentifying
    private let contributedPlaceIDsKey = "vibe-map.contributed-place-ids"
    private let accountPromptDismissedKey = "vibes-yall.account-prompt-dismissed"
    private let accountSessionTokenKey = "vibes-yall.account-session-token"
    private var visibleCenter = AppConfig.initialMapCenter
    private var visibleRadius = AppConfig.nearbyRadiusMeters
    private var activeMapTapRequestID: UUID?
    private var activeNearbyRequestID: UUID?
    private var activeNearbyRequestKey: String?
    private var shouldCheckAccountAfterRating = false
    private var currentNearbyCacheKey: String?
    private var currentMapCellCacheKey: String?
    private var displayedNearbySignature = ""
    private var displayedMapCellSignature = ""
    private var nearbyCache: [String: NearbyCacheEntry] = [:]
    private var nearbyCacheOrder: [String] = []
    private var mapCellCache: [String: MapCellCacheEntry] = [:]
    private var mapCellCacheOrder: [String] = []

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
            return visibleMapCellClusters.reduce(0) { $0 + $1.count }
        }

        return visibleNearbyPlaces.count
    }

    var isShowingMapCellClusters: Bool {
        displayedAnnotationLayer == .mapCells
    }

    var visibleMapCellClusters: [MapCellCluster] {
        guard displayedAnnotationLayer == .mapCells else {
            return []
        }

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

    var hasActiveVibeFilters: Bool {
        !selectedVibeFilters.isEmpty
    }

    var didFilterSearchResultsToEmpty: Bool {
        hasActiveVibeFilters &&
            !rankedSearchResults(applyingVibeFilters: false).isEmpty &&
            filteredSearchResults.isEmpty
    }

    var selectedVibeFilterSummary: String {
        VibeTag.bestToWorst(Array(selectedVibeFilters)).map(\.mapLabel).joined(separator: " or ")
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
    }

    func start() async {
        locationService.requestAuthorizationAndLocation()
        await loadAllowedVibes()
        await loadNearby(center: visibleCenter)
    }

    func updateVisibleCenter(_ coordinate: CLLocationCoordinate2D) {
        visibleCenter = coordinate
    }

    func updateVisibleRegion(_ region: MKCoordinateRegion) {
        visibleCenter = region.center
        visibleRadius = AppConfig.nearbyRadius(for: region)
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
            searchError = nil
            return
        }

        searchError = nil
        isSearching = true
        clearMapTapChoices()

        do {
            searchResults = try await searchService.search(query: query, near: visibleCenter)
        } catch is CancellationError {
            return
        } catch {
            searchResults = []
            searchError = error.localizedDescription
        }

        isSearching = false
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        searchError = nil
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
        await select(result.candidate, opensRating: true)
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
                mapTapError = "No map places found here."
            }
        } catch is CancellationError {
            return
        } catch {
            guard activeMapTapRequestID == requestID else { return }
            mapTapMatches = []
            mapTapError = error.localizedDescription
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
                mapTapError = "Could not load that place. Try searching its name."
            }
        } catch is CancellationError {
            return
        } catch {
            guard activeMapTapRequestID == requestID else { return }
            mapTapMatches = []
            mapTapError = "Could not load that place. Try searching its name."
        }

        isResolvingMapTap = false
    }

    func selectMapTapMatch(_ match: PlaceCandidateMatch) async {
        await select(match.candidate, opensRating: true)
    }

    func selectNearbyPlace(_ place: VibePlace) {
        selectedPlace = place
        clearMapTapChoices()
        clearSearch()
        enrichAddressIfNeeded(for: place)
    }

    func openRating(for place: VibePlace) {
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

        let syncedPlace = try await vibeService.upsertPlace(selectedPlace.placeCandidate)
        if let refreshedPlace = try? await vibeService.fetchPlace(id: syncedPlace.id, deviceIdHash: identityService.deviceIDHash()) {
            self.selectedPlace = refreshedPlace
        } else {
            self.selectedPlace = syncedPlace
        }

        let submission = try await vibeService.submitRating(
            placeId: syncedPlace.id,
            deviceIdHash: identityService.deviceIDHash(),
            vibeTags: selectedTags
        )

        self.selectedPlace = submission.place
        markContribution(for: submission.place)
        upsertNearbyPlace(submission.place)
        shouldCheckAccountAfterRating = true
        return submission
    }

    func dismissAccountSignupPrompt() {
        UserDefaults.standard.set(true, forKey: accountPromptDismissedKey)
        accountSignupPrompt = nil
    }

    var hasConfirmedAccount: Bool {
        UserDefaults.standard.string(forKey: accountSessionTokenKey) != nil
    }

    func requestAccountSignup(email: String) async throws -> AccountSignupResponse {
        let response = try await vibeService.requestAccountSignup(
            email: email,
            deviceIdHash: identityService.deviceIDHash()
        )
        return response
    }

    func presentAccountSignupFromMenu() async {
        guard accountSignupPrompt == nil else { return }

        do {
            let eligibility = try await vibeService.fetchAccountEligibility(deviceIdHash: identityService.deviceIDHash())
            if eligibility.profile?.emailVerified == true || hasConfirmedAccount {
                alert = AppAlert(
                    title: "Account saved",
                    message: "Your confirmed account is active on this device."
                )
                return
            }

            guard eligibility.eligible else {
                alert = AppAlert(
                    title: "Keep vibing",
                    message: "Account backup unlocks after \(eligibility.threshold) vibed places. You have \(eligibility.vibedPlaceCount), so \(eligibility.remainingPlaces) more to go."
                )
                return
            }

            UserDefaults.standard.set(false, forKey: accountPromptDismissedKey)
            accountSignupPrompt = AccountSignupPrompt(eligibility: eligibility)
        } catch {
            alert = AppAlert(title: "Could not check account status", message: error.localizedDescription)
        }
    }

    func requestAccountDeletion(email: String) async throws -> AccountDeletionResponse {
        let response = try await vibeService.requestAccountDeletion(
            email: email,
            deviceIdHash: identityService.deviceIDHash()
        )
        UserDefaults.standard.removeObject(forKey: accountSessionTokenKey)
        UserDefaults.standard.set(false, forKey: accountPromptDismissedKey)
        accountSignupPrompt = nil
        alert = AppAlert(title: "Account deleted", message: response.message)
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

        UserDefaults.standard.set(session, forKey: accountSessionTokenKey)
        UserDefaults.standard.set(false, forKey: accountPromptDismissedKey)
        accountSignupPrompt = nil
        alert = AppAlert(
            title: "Account confirmed",
            message: "Your past and future vibes can now stay tied to your account."
        )
    }

    private func select(_ candidate: PlaceCandidate, opensRating: Bool = false) async {
        isSelectingPlace = true
        defer { isSelectingPlace = false }

        clearSearch()
        clearMapTapChoices()

        let place = (existingNearbyPlace(for: candidate)?.enriched(with: candidate)) ?? VibePlace(candidate: candidate)
        selectedPlace = place
        if place.myRating != nil {
            markContribution(for: place)
        }

        if opensRating {
            ratingDraft = RatingDraft(place: place)
        }

        persistEnrichedPlaceIfUseful(place, sourceCandidate: candidate)
    }

    private func loadAllowedVibes() async {
        do {
            allowedVibes = try await vibeService.fetchVibes()
        } catch {
            allowedVibes = VibeTag.allCases
        }
    }

    private func maybeOfferAccountSignup() async {
        guard accountSignupPrompt == nil,
              UserDefaults.standard.string(forKey: accountSessionTokenKey) == nil,
              !UserDefaults.standard.bool(forKey: accountPromptDismissedKey) else {
            return
        }

        do {
            let eligibility = try await vibeService.fetchAccountEligibility(deviceIdHash: identityService.deviceIDHash())
            guard eligibility.eligible,
                  eligibility.profile?.emailVerified != true else {
                return
            }

            accountSignupPrompt = AccountSignupPrompt(eligibility: eligibility)
        } catch {
            return
        }
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
        if !mapCellClusters.isEmpty {
            mapCellClusters = []
        }
        displayedMapCellSignature = ""
        if let cacheKey {
            currentNearbyCacheKey = cacheKey
        }
        currentMapCellCacheKey = nil
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

        let localMatches = nearbyPlaces
            .filter { place in
                place.hasRatings &&
                    place.matchesSearchQuery(query) &&
                    (!applyingVibeFilters || place.matchesAnyVibe(in: selectedVibeFilters))
            }
            .sortedByDistance(from: visibleCenter)

        for place in localMatches {
            results.append(PlaceSearchResult(candidate: place.placeCandidate, vibedPlace: place))
            seenPlaceIDs.insert(place.id)
            seenCandidateIDs.insert(place.placeCandidate.id)
        }

        var plainCandidates: [PlaceSearchResult] = []

        for candidate in searchResults {
            if let place = existingNearbyPlace(for: candidate), place.hasRatings {
                guard !applyingVibeFilters || place.matchesAnyVibe(in: selectedVibeFilters) else {
                    continue
                }

                let enrichedPlace = place.enriched(with: candidate)
                if !seenPlaceIDs.contains(enrichedPlace.id) {
                    results.append(PlaceSearchResult(candidate: enrichedPlace.placeCandidate, vibedPlace: enrichedPlace))
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

            plainCandidates.append(PlaceSearchResult(candidate: candidate, vibedPlace: nil))
            seenCandidateIDs.insert(candidate.id)
        }

        return results + plainCandidates
    }

    private func existingNearbyPlace(for candidate: PlaceCandidate) -> VibePlace? {
        if let providerPlaceId = candidate.providerPlaceId, !providerPlaceId.isEmpty {
            if let exactProviderMatch = nearbyPlaces.first(where: {
                $0.provider == candidate.provider && $0.providerPlaceId == providerPlaceId
            }) {
                return exactProviderMatch
            }

            if let providerMatch = nearbyPlaces.first(where: { $0.providerPlaceId == providerPlaceId }) {
                return providerMatch
            }
        }

        let candidateName = Self.normalizedPlaceName(candidate.name)
        let candidateLocation = CLLocation(latitude: candidate.latitude, longitude: candidate.longitude)

        return nearbyPlaces
            .compactMap { place -> (place: VibePlace, distance: CLLocationDistance)? in
                guard Self.normalizedPlaceName(place.name) == candidateName else { return nil }
                let distance = candidateLocation.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
                guard distance <= 35 else { return nil }
                return (place, distance)
            }
            .sorted { $0.distance < $1.distance }
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
}

private extension VibePlace {
    func matchesSearchQuery(_ query: String) -> Bool {
        let queryTokens = query.normalizedSearchTokens()
        guard !queryTokens.isEmpty else {
            return false
        }

        let searchableText = [
            name,
            category,
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
            switch (lhs.distanceMeters, rhs.distanceMeters) {
            case let (lhsDistance?, rhsDistance?):
                return lhsDistance < rhsDistance
            case (.some, nil):
                return true
            case (nil, .some):
                return false
            case (nil, nil):
                let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let lhsDistance = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude).distance(from: origin)
                let rhsDistance = CLLocation(latitude: rhs.latitude, longitude: rhs.longitude).distance(from: origin)
                return lhsDistance < rhsDistance
            }
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
        lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
