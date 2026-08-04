import Foundation

final class ResilientVibeService: VibeServicing {
    private let primary: any VibeServicing
    private let fallback: any VibeServicing

    init(primary: any VibeServicing, fallback: any VibeServicing = MockVibeService()) {
        self.primary = primary
        self.fallback = fallback
    }

    func fetchVibes() async throws -> [VibeTag] {
        try await runWithConnectivityFallback {
            try await primary.fetchVibes()
        } fallback: {
            try await fallback.fetchVibes()
        }
    }

    func fetchNearby(latitude: Double, longitude: Double, radius: Double, vibeFilter: VibeTag?, deviceIdHash: String?) async throws -> [VibePlace] {
        try await runWithConnectivityFallback {
            try await primary.fetchNearby(latitude: latitude, longitude: longitude, radius: radius, vibeFilter: vibeFilter, deviceIdHash: deviceIdHash)
        } fallback: {
            try await fallback.fetchNearby(latitude: latitude, longitude: longitude, radius: radius, vibeFilter: vibeFilter, deviceIdHash: deviceIdHash)
        }
    }

    func searchSavedPlaces(
        query: String,
        latitude: Double?,
        longitude: Double?,
        limit: Int,
        deviceIdHash: String?
    ) async throws -> [VibePlace] {
        try await runWithConnectivityFallback {
            try await primary.searchSavedPlaces(
                query: query,
                latitude: latitude,
                longitude: longitude,
                limit: limit,
                deviceIdHash: deviceIdHash
            )
        } fallback: {
            try await fallback.searchSavedPlaces(
                query: query,
                latitude: latitude,
                longitude: longitude,
                limit: limit,
                deviceIdHash: deviceIdHash
            )
        }
    }

    func fetchMapCells(latitude: Double, longitude: Double, radius: Double, cellSize: Double, vibeFilter: VibeTag?) async throws -> [MapCellCluster] {
        try await runWithConnectivityFallback {
            try await primary.fetchMapCells(latitude: latitude, longitude: longitude, radius: radius, cellSize: cellSize, vibeFilter: vibeFilter)
        } fallback: {
            try await fallback.fetchMapCells(latitude: latitude, longitude: longitude, radius: radius, cellSize: cellSize, vibeFilter: vibeFilter)
        }
    }

    func searchProviderPlaces(query: String, latitude: Double?, longitude: Double?, limit: Int) async throws -> [PlaceCandidate] {
        try await runWithConnectivityFallback {
            try await primary.searchProviderPlaces(query: query, latitude: latitude, longitude: longitude, limit: limit)
        } fallback: {
            try await fallback.searchProviderPlaces(query: query, latitude: latitude, longitude: longitude, limit: limit)
        }
    }

    func fetchPlace(id: String, deviceIdHash: String?) async throws -> VibePlace {
        try await runWithConnectivityFallback {
            try await primary.fetchPlace(id: id, deviceIdHash: deviceIdHash)
        } fallback: {
            try await fallback.fetchPlace(id: id, deviceIdHash: deviceIdHash)
        }
    }

    func upsertPlace(_ candidate: PlaceCandidate) async throws -> VibePlace {
        try await primary.upsertPlace(candidate)
    }

    func submitRating(placeId: String, deviceIdHash: String, vibeTags: [VibeTag]) async throws -> RatingSubmission {
        try await primary.submitRating(placeId: placeId, deviceIdHash: deviceIdHash, vibeTags: vibeTags)
    }

    func deleteRating(placeId: String, deviceIdHash: String) async throws -> VibePlace {
        try await primary.deleteRating(placeId: placeId, deviceIdHash: deviceIdHash)
    }

    func fetchAccountEligibility(deviceIdHash: String) async throws -> AccountEligibility {
        try await runWithConnectivityFallback {
            try await primary.fetchAccountEligibility(deviceIdHash: deviceIdHash)
        } fallback: {
            try await fallback.fetchAccountEligibility(deviceIdHash: deviceIdHash)
        }
    }

    func requestAccountSignup(email: String, deviceIdHash: String) async throws -> AccountSignupResponse {
        try await primary.requestAccountSignup(email: email, deviceIdHash: deviceIdHash)
    }

    func requestAccountLogin(email: String) async throws -> AccountLoginResponse {
        try await primary.requestAccountLogin(email: email)
    }

    func requestAccountLogout() async throws -> AccountLogoutResponse {
        try await primary.requestAccountLogout()
    }

    func requestAccountDeletion(email: String, deviceIdHash: String) async throws -> AccountDeletionResponse {
        try await primary.requestAccountDeletion(email: email, deviceIdHash: deviceIdHash)
    }

    func recordAnalyticsEvent(name: String, deviceIdHash: String, properties: [String: String]) async {
        await primary.recordAnalyticsEvent(name: name, deviceIdHash: deviceIdHash, properties: properties)
    }

    private func runWithConnectivityFallback<Result>(
        _ primaryCall: () async throws -> Result,
        fallback fallbackCall: () async throws -> Result
    ) async throws -> Result {
        do {
            return try await primaryCall()
        } catch {
            guard error.isConnectivityFailure else {
                throw error
            }
            return try await fallbackCall()
        }
    }
}

private extension Error {
    var isConnectivityFailure: Bool {
        if self is URLError {
            return true
        }

        return (self as NSError).domain == NSURLErrorDomain
    }
}
