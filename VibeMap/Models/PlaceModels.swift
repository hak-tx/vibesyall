import CoreLocation
import Foundation

struct VibeBreakdown: Codable, Hashable, Identifiable {
    var vibeTag: VibeTag
    var count: Int
    var percentage: Int

    var id: VibeTag { vibeTag }
}

struct PlaceStats: Codable, Hashable {
    var ratingCount: Int
    var averageScore: Double
    var topVibeTag: VibeTag?
    var topVibes: [VibeBreakdown]?
    var recentVibeCount: Int? = nil
    var recentPositivePercentage: Int? = nil

    var visibleTopVibes: [VibeBreakdown] {
        guard let topVibes, !topVibes.isEmpty else {
            guard let topVibeTag, ratingCount > 0 else {
                return []
            }
            return [VibeBreakdown(vibeTag: topVibeTag, count: ratingCount, percentage: 100)]
        }
        return topVibes
    }

    func includes(_ vibe: VibeTag) -> Bool {
        visibleTopVibes.contains { $0.vibeTag == vibe && $0.count > 0 }
    }
}

enum DiscoverySignal: String, CaseIterable, Identifiable, Hashable {
    case firstToVibe = "First to Vibe"
    case needsMoreVibes = "Needs More Vibes"
    case hotTake = "Hot Take"
    case hiddenGem = "Hidden Gem"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .firstToVibe:
            "Be first"
        case .needsMoreVibes:
            "Needs vibes"
        case .hotTake:
            "Hot take"
        case .hiddenGem:
            "Hidden gem"
        }
    }

    var message: String {
        switch self {
        case .firstToVibe:
            "No one has vibed this place yet."
        case .needsMoreVibes:
            "This place needs more vibes."
        case .hotTake:
            "Hot take: people are split."
        case .hiddenGem:
            "Hidden gem."
        }
    }
}

struct VibePlace: Identifiable, Codable, Hashable {
    var id: String
    var provider: String?
    var providerPlaceId: String?
    var name: String
    var latitude: Double
    var longitude: Double
    var streetAddress: String?
    var category: String?
    var city: String?
    var region: String?
    var country: String?
    var stats: PlaceStats?
    var distanceMeters: Double?
    var myRating: VibeRating? = nil

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var hasRatings: Bool {
        (stats?.ratingCount ?? 0) > 0
    }

    var vibeCount: Int {
        stats?.ratingCount ?? 0
    }

    var isHotTake: Bool {
        guard vibeCount >= 10,
              let topVibes = stats?.visibleTopVibes,
              topVibes.count >= 2 else {
            return false
        }

        return abs(topVibes[0].percentage - topVibes[1].percentage) <= 10
    }

    var isHiddenGem: Bool {
        guard let stats,
              (stats.recentVibeCount ?? 0) >= 5,
              (stats.recentPositivePercentage ?? 0) >= 70 else {
            return false
        }

        return true
    }

    var needsMoreVibes: Bool {
        (1...2).contains(vibeCount)
    }

    var primaryDiscoverySignal: DiscoverySignal? {
        if vibeCount == 0 {
            return .firstToVibe
        }

        if isHotTake {
            return .hotTake
        }

        if isHiddenGem {
            return .hiddenGem
        }

        if needsMoreVibes {
            return .needsMoreVibes
        }

        return nil
    }

    var needsOpinion: Bool {
        vibeCount == 0 || needsMoreVibes || isHotTake
    }

    func matchesAnyVibe(in filters: Set<VibeTag>) -> Bool {
        guard !filters.isEmpty else {
            return true
        }

        if myRating?.selectedVibeTags.contains(where: { filters.contains($0) }) == true {
            return true
        }

        return stats?.visibleTopVibes.contains { breakdown in
            filters.contains(breakdown.vibeTag) && breakdown.count > 0
        } == true
    }

    var locationLine: String {
        [streetAddress, localityLine].compactMap { $0 }.joined(separator: ", ")
    }

    var addressStreetLine: String? {
        cleanAddressField(streetAddress)
    }

    var addressLocalityLine: String? {
        cleanAddressField(localityLine)
    }

    var hasStreetAddress: Bool {
        cleanAddressField(streetAddress) != nil
    }

    var localityLine: String {
        [city, region].compactMap { $0 }.joined(separator: ", ")
    }

    var displayCategory: String? {
        if let category = category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
            return Self.normalizedCategory(category)
        }

        return Self.inferredCategory(from: name)
    }

    private static func normalizedCategory(_ category: String) -> String {
        let cleaned = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let compact = cleaned
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)

        switch compact {
        case "musicvenue":
            return "Music Venue"
        case "movietheater", "cinema":
            return "Movie Theater"
        case "amusementpark":
            return "Amusement Park"
        case "nationalpark":
            return "National Park"
        case "publictransport", "transitstation":
            return "Transit"
        case "gasstation":
            return "Gas Station"
        case "conventioncenter":
            return "Convention Center"
        case "performingarts":
            return "Performing Arts"
        default:
            return cleaned
        }
    }

    private static func inferredCategory(from name: String) -> String? {
        let normalized = name.lowercased()

        if normalized.contains("stadium") || normalized.contains("arena") || normalized.contains("ballpark") {
            return "Stadium"
        }

        if normalized.contains("music") || normalized.contains("concert") || normalized.contains("venue") || normalized.contains("masonic") {
            return "Music Venue"
        }

        if normalized.contains("park") || normalized.contains("trail") || normalized.contains("garden") {
            return "Park"
        }

        if normalized.contains("bbq") ||
            normalized.contains("barbecue") ||
            normalized.contains("smokehouse") ||
            normalized.contains("taco") ||
            normalized.contains("diner") ||
            normalized.contains("restaurant") ||
            normalized.contains("cafe") ||
            normalized.contains("coffee") ||
            normalized.contains("pizza") ||
            normalized.contains("burger") ||
            normalized.contains("bakery") ||
            normalized.contains("grill") ||
            normalized.contains("kitchen") ||
            normalized.contains("eatery") {
            return "Restaurant"
        }

        if normalized.contains("bar") || normalized.contains("saloon") || normalized.contains("pub") {
            return "Bar"
        }

        if normalized.contains("hotel") || normalized.contains("inn") {
            return "Hotel"
        }

        if normalized.contains("museum") || normalized.contains("gallery") {
            return "Museum"
        }

        return nil
    }
}

struct MapCellCluster: Identifiable, Codable, Hashable {
    var id: String
    var latitude: Double
    var longitude: Double
    var count: Int
    var totalVibes: Int
    var topVibeTag: VibeTag?
    var topVibeTagId: String?
    var topVibePercent: Int?
    var cellSizeMeters: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var displayVibe: VibeTag? {
        topVibeTag ?? topVibeTagId.flatMap(VibeTag.fromServerValue)
    }
}

struct PlaceCandidate: Codable, Hashable, Identifiable {
    var provider: String
    var providerPlaceId: String?
    var name: String
    var latitude: Double
    var longitude: Double
    var streetAddress: String?
    var category: String?
    var city: String?
    var region: String?
    var country: String?
    var distanceMeters: Double? = nil

    var id: String {
        [
            provider,
            providerPlaceId ?? name,
            String(format: "%.5f", latitude),
            String(format: "%.5f", longitude)
        ].joined(separator: ":")
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var locationLine: String {
        [streetAddress, localityLine].compactMap { $0 }.joined(separator: ", ")
    }

    var hasStreetAddress: Bool {
        cleanAddressField(streetAddress) != nil
    }

    var localityLine: String {
        [city, region].compactMap { $0 }.joined(separator: ", ")
    }

    var distanceText: String? {
        guard let distanceMeters else {
            return nil
        }

        return Self.formattedDistance(distanceMeters)
    }

    static func formattedDistance(_ meters: Double) -> String {
        let miles = meters / 1_609.344

        if miles < 0.1 {
            return "<0.1 mi"
        }

        if miles < 10 {
            return String(format: "%.1f mi", miles)
        }

        return "\(Int(miles.rounded())) mi"
    }
}

struct PlaceCandidateMatch: Identifiable, Hashable {
    var candidate: PlaceCandidate
    var distanceMeters: CLLocationDistance

    var id: String {
        candidate.id
    }

    var distanceText: String {
        PlaceCandidate.formattedDistance(distanceMeters)
    }
}

struct PlaceSearchResult: Identifiable, Hashable {
    var candidate: PlaceCandidate
    var vibedPlace: VibePlace?

    var id: String {
        vibedPlace?.id ?? candidate.id
    }

    var name: String {
        vibedPlace?.name ?? candidate.name
    }

    var locationLine: String {
        let placeLocation = vibedPlace?.locationLine ?? ""
        return placeLocation.isEmpty ? candidate.locationLine : placeLocation
    }

    var distanceText: String? {
        if let distanceMeters = vibedPlace?.distanceMeters ?? candidate.distanceMeters {
            return PlaceCandidate.formattedDistance(distanceMeters)
        }

        return nil
    }

    var vibeCount: Int {
        vibedPlace?.vibeCount ?? 0
    }

    var topVibe: VibeBreakdown? {
        vibedPlace?.stats?.visibleTopVibes.first
    }

    var hasCommunityVibes: Bool {
        vibeCount > 0
    }
}

struct VibeRating: Identifiable, Codable, Hashable {
    var id: String
    var placeId: String
    var score: Double
    var vibeTag: VibeTag
    var vibeTags: [VibeTag]?
    var createdAt: String?
    var updatedAt: String?

    var selectedVibeTags: [VibeTag] {
        guard let vibeTags, !vibeTags.isEmpty else {
            return [vibeTag]
        }
        return VibeTag.normalizedSelection(vibeTags)
    }

    var vibeSummary: String {
        selectedVibeTags.map(\.rawValue).joined(separator: " + ")
    }
}

struct RatingDraft: Identifiable, Hashable {
    let id = UUID()
    var place: VibePlace
}

struct RatingSubmission: Hashable {
    var place: VibePlace
    var rating: VibeRating
    var discovery: RatingDiscovery?
}

struct RatingDiscovery: Codable, Hashable {
    var wasFirstVibe: Bool?
}

struct AppAlert: Identifiable {
    let id = UUID()
    var title: String
    var message: String
}

extension PlaceCandidate {
    var localPlaceID: String {
        "local:\(id)"
    }
}

extension VibePlace {
    init(candidate: PlaceCandidate) {
        self.init(
            id: candidate.localPlaceID,
            provider: candidate.provider,
            providerPlaceId: candidate.providerPlaceId,
            name: candidate.name,
            latitude: candidate.latitude,
            longitude: candidate.longitude,
            streetAddress: candidate.streetAddress,
            category: candidate.category,
            city: candidate.city,
            region: candidate.region,
            country: candidate.country,
            stats: PlaceStats(ratingCount: 0, averageScore: 0, topVibeTag: nil, topVibes: nil),
            distanceMeters: nil
        )
    }

    func enriched(with candidate: PlaceCandidate) -> VibePlace {
        var place = self

        if !place.hasStreetAddress, let streetAddress = cleanAddressField(candidate.streetAddress) {
            place.streetAddress = streetAddress
        }

        if cleanAddressField(place.city) == nil {
            place.city = cleanAddressField(candidate.city)
        }

        if cleanAddressField(place.region) == nil {
            place.region = cleanAddressField(candidate.region)
        }

        if cleanAddressField(place.country) == nil {
            place.country = cleanAddressField(candidate.country)
        }

        if cleanAddressField(place.category) == nil {
            place.category = cleanAddressField(candidate.category)
        }

        if cleanAddressField(place.providerPlaceId) == nil {
            place.providerPlaceId = cleanAddressField(candidate.providerPlaceId)
        }

        if cleanAddressField(place.provider) == nil {
            place.provider = cleanAddressField(candidate.provider)
        }

        return place
    }

    func preservingInteraction(from original: VibePlace) -> VibePlace {
        var place = self

        if place.stats == nil {
            place.stats = original.stats
        }

        if place.myRating == nil {
            place.myRating = original.myRating
        }

        if place.distanceMeters == nil {
            place.distanceMeters = original.distanceMeters
        }

        if !place.hasStreetAddress, let streetAddress = cleanAddressField(original.streetAddress) {
            place.streetAddress = streetAddress
        }

        return place
    }

    var placeCandidate: PlaceCandidate {
        PlaceCandidate(
            provider: provider ?? "mapkit",
            providerPlaceId: providerPlaceId,
            name: name,
            latitude: latitude,
            longitude: longitude,
            streetAddress: streetAddress,
            category: category,
            city: city,
            region: region,
            country: country,
            distanceMeters: distanceMeters
        )
    }
}

private func cleanAddressField(_ value: String?) -> String? {
    let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed?.isEmpty == false ? trimmed : nil
}
