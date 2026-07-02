import CoreLocation
import Foundation

final class MockVibeService: VibeServicing {
    private var places: [VibePlace]
    private var ratings: [String: VibeRating] = [:]

    init() {
        places = DemoScenario.austinPlaces
    }

    func fetchVibes() async throws -> [VibeTag] {
        VibeTag.allCases
    }

    func fetchNearby(latitude: Double, longitude: Double, radius: Double, vibeFilter: VibeTag?, deviceIdHash: String?) async throws -> [VibePlace] {
        let origin = CLLocation(latitude: latitude, longitude: longitude)
        return places
            .map { place in
                var nearbyPlace = place
                nearbyPlace.distanceMeters = origin.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude))
                if let deviceIdHash {
                    nearbyPlace.myRating = ratings["\(place.id):\(deviceIdHash)"]
                }
                return nearbyPlace
            }
            .filter { ($0.distanceMeters ?? .greatestFiniteMagnitude) <= radius }
            .filter { place in
                guard let vibeFilter else { return true }
                return place.stats?.includes(vibeFilter) == true
            }
            .sorted { ($0.distanceMeters ?? 0) < ($1.distanceMeters ?? 0) }
    }

    func fetchMapCells(latitude: Double, longitude: Double, radius: Double, cellSize: Double, vibeFilter: VibeTag?) async throws -> [MapCellCluster] {
        let nearby = try await fetchNearby(latitude: latitude, longitude: longitude, radius: radius, vibeFilter: vibeFilter, deviceIdHash: nil)
        guard !nearby.isEmpty else { return [] }

        let bucketSize = max(cellSize / 111_320, 0.01)
        let grouped = Dictionary(grouping: nearby) { place in
            "\(Int((place.latitude / bucketSize).rounded(.down))):\(Int((place.longitude / bucketSize).rounded(.down)))"
        }

        return grouped.map { key, places in
            let totalVibes = places.map(\.vibeCount).reduce(0, +)
            let topVibe = dominantVibe(in: places)
            return MapCellCluster(
                id: "mock-cell:\(key)",
                latitude: places.map(\.latitude).reduce(0, +) / Double(places.count),
                longitude: places.map(\.longitude).reduce(0, +) / Double(places.count),
                count: places.count,
                totalVibes: totalVibes,
                topVibeTag: topVibe,
                topVibeTagId: topVibe?.rawValue,
                topVibePercent: nil,
                cellSizeMeters: cellSize
            )
        }
        .sorted { lhs, rhs in
            if lhs.count == rhs.count {
                return lhs.id < rhs.id
            }
            return lhs.count > rhs.count
        }
    }

    func fetchPlace(id: String, deviceIdHash: String?) async throws -> VibePlace {
        guard var place = places.first(where: { $0.id == id }) else {
            throw APIError.server("That spot is not in the mock map.")
        }
        if let deviceIdHash {
            place.myRating = ratings["\(id):\(deviceIdHash)"]
        }
        return place
    }

    func upsertPlace(_ candidate: PlaceCandidate) async throws -> VibePlace {
        if let providerPlaceId = candidate.providerPlaceId, !providerPlaceId.isEmpty {
            if let existing = places.first(where: { $0.providerPlaceId == providerPlaceId }) {
                return existing
            }
        }

        let candidateLocation = CLLocation(latitude: candidate.latitude, longitude: candidate.longitude)
        if let existing = places.first(where: { place in
            normalizedPlaceName(place.name) == normalizedPlaceName(candidate.name) &&
                candidateLocation.distance(from: CLLocation(latitude: place.latitude, longitude: place.longitude)) <= 35
        }) {
            return existing
        }

        let place = VibePlace(
            id: "mock-\(UUID().uuidString)",
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
        places.append(place)
        return place
    }

    func submitRating(placeId: String, deviceIdHash: String, vibeTags: [VibeTag]) async throws -> RatingSubmission {
        guard let index = places.firstIndex(where: { $0.id == placeId }) else {
            throw APIError.server("That spot wandered off.")
        }

        let selectedTags = VibeTag.normalizedSelection(vibeTags)
        guard let primaryTag = selectedTags.first else {
            throw APIError.server("Pick a vibe first.")
        }

        let key = "\(placeId):\(deviceIdHash)"
        let previousRating = ratings[key]
        let previousStats = places[index].stats
        let wasFirstVibe = previousRating == nil && (previousStats?.ratingCount ?? 0) == 0
        let rating = VibeRating(
            id: previousRating?.id ?? UUID().uuidString,
            placeId: placeId,
            score: VibeTag.score(for: selectedTags),
            vibeTag: primaryTag,
            vibeTags: selectedTags,
            createdAt: previousRating?.createdAt,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        ratings[key] = rating

        let placeRatings = ratings.values.filter { $0.placeId == placeId }
        let storedRatingCount = previousStats?.ratingCount ?? 0
        let ratingCount = previousRating == nil ? storedRatingCount + 1 : storedRatingCount
        let average = placeRatings.map(\.score).reduce(0, +) / Double(max(placeRatings.count, 1))
        let topVibes = topBreakdowns(
            from: previousStats?.visibleTopVibes ?? [],
            adding: placeRatings,
            replacing: previousRating,
            ratingCount: ratingCount
        )
        let topTag = topVibes.first?.vibeTag

        places[index].stats = PlaceStats(
            ratingCount: max(placeRatings.count, ratingCount),
            averageScore: average,
            topVibeTag: topTag ?? primaryTag,
            topVibes: topVibes
        )

        return RatingSubmission(
            place: places[index],
            rating: rating,
            discovery: RatingDiscovery(wasFirstVibe: wasFirstVibe)
        )
    }

    func fetchAccountEligibility(deviceIdHash: String) async throws -> AccountEligibility {
        let vibedPlaceCount = Set(ratings.keys.compactMap { key in
            key.hasSuffix(":\(deviceIdHash)") ? key.components(separatedBy: ":").first : nil
        }).count
        let threshold = 10

        return AccountEligibility(
            eligible: vibedPlaceCount >= threshold,
            threshold: threshold,
            vibedPlaceCount: vibedPlaceCount,
            remainingPlaces: max(0, threshold - vibedPlaceCount),
            benefits: AccountBenefit.defaultBenefits,
            profile: nil
        )
    }

    func requestAccountSignup(email: String, deviceIdHash: String) async throws -> AccountSignupResponse {
        AccountSignupResponse(
            status: "confirmation_sent",
            emailSent: false,
            account: try await fetchAccountEligibility(deviceIdHash: deviceIdHash),
            message: "Check your email to confirm your VIBES Y'ALL account."
        )
    }

    private func topBreakdowns(
        from existingBreakdowns: [VibeBreakdown],
        adding ratings: [VibeRating],
        replacing previousRating: VibeRating?,
        ratingCount: Int
    ) -> [VibeBreakdown] {
        guard ratingCount > 0 else { return [] }

        var counts = Dictionary(uniqueKeysWithValues: existingBreakdowns.map { ($0.vibeTag, $0.count) })

        if let previousRating {
            for tag in previousRating.selectedVibeTags {
                counts[tag, default: 0] = max(0, counts[tag, default: 0] - 1)
            }
        }

        for tag in ratings.flatMap(\.selectedVibeTags) {
            counts[tag, default: 0] += 1
        }

        return counts
            .filter { $0.value > 0 }
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key.rawValue < rhs.key.rawValue
                }
                return lhs.value > rhs.value
            }
            .prefix(3)
            .map { tag, count in
                VibeBreakdown(
                    vibeTag: tag,
                    count: count,
                    percentage: Int((Double(count) / Double(ratingCount) * 100).rounded())
                )
            }
    }

    private func dominantVibe(in places: [VibePlace]) -> VibeTag? {
        var counts: [VibeTag: Int] = [:]
        for place in places {
            if let topVibe = place.stats?.visibleTopVibes.first {
                counts[topVibe.vibeTag, default: 0] += max(topVibe.count, 1)
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

    private func normalizedPlaceName(_ name: String) -> String {
        name
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
