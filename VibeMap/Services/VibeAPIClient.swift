import Foundation

protocol VibeServicing {
    func fetchVibes() async throws -> [VibeTag]
    func fetchNearby(latitude: Double, longitude: Double, radius: Double, vibeFilter: VibeTag?, deviceIdHash: String?) async throws -> [VibePlace]
    func fetchMapCells(latitude: Double, longitude: Double, radius: Double, cellSize: Double, vibeFilter: VibeTag?) async throws -> [MapCellCluster]
    func fetchPlace(id: String, deviceIdHash: String?) async throws -> VibePlace
    func upsertPlace(_ candidate: PlaceCandidate) async throws -> VibePlace
    func submitRating(placeId: String, deviceIdHash: String, vibeTags: [VibeTag]) async throws -> RatingSubmission
    func fetchAccountEligibility(deviceIdHash: String) async throws -> AccountEligibility
    func requestAccountSignup(email: String, deviceIdHash: String) async throws -> AccountSignupResponse
}

struct VibeAPIClient: VibeServicing {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    func fetchVibes() async throws -> [VibeTag] {
        let response: VibesResponse = try await get(path: "vibes")
        return response.vibes
    }

    func fetchNearby(latitude: Double, longitude: Double, radius: Double, vibeFilter: VibeTag?, deviceIdHash: String?) async throws -> [VibePlace] {
        var components = URLComponents(url: baseURL.appendingPathComponent("places/nearby"), resolvingAgainstBaseURL: false)
        let normalizedLatitude = AppConfig.roundedNearbyCoordinate(latitude)
        let normalizedLongitude = AppConfig.roundedNearbyCoordinate(longitude)
        let normalizedRadius = AppConfig.roundedNearbyRadius(radius)
        var queryItems = [
            URLQueryItem(name: "lat", value: String(normalizedLatitude)),
            URLQueryItem(name: "lng", value: String(normalizedLongitude)),
            URLQueryItem(name: "radius", value: String(normalizedRadius))
        ]
        if let vibeFilter {
            queryItems.append(URLQueryItem(name: "vibe_tag", value: vibeFilter.rawValue))
        }
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        let response: NearbyPlacesResponse = try await get(url: url, deviceIdHash: deviceIdHash)
        return response.places
    }

    func fetchMapCells(latitude: Double, longitude: Double, radius: Double, cellSize: Double, vibeFilter: VibeTag?) async throws -> [MapCellCluster] {
        var components = URLComponents(url: baseURL.appendingPathComponent("places/map-cells"), resolvingAgainstBaseURL: false)
        let normalizedCellSize = AppConfig.roundedMapCellSize(cellSize)
        var queryItems = [
            URLQueryItem(name: "lat", value: String(AppConfig.roundedMapCellCoordinate(latitude, cellSize: normalizedCellSize))),
            URLQueryItem(name: "lng", value: String(AppConfig.roundedMapCellCoordinate(longitude, cellSize: normalizedCellSize))),
            URLQueryItem(name: "radius", value: String(AppConfig.roundedMapCellRadius(radius))),
            URLQueryItem(name: "cell_size", value: String(normalizedCellSize))
        ]
        if let vibeFilter {
            queryItems.append(URLQueryItem(name: "vibe_tag", value: vibeFilter.rawValue))
        }
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        let response: MapCellsResponse = try await get(url: url)
        return response.cells
    }

    func fetchPlace(id: String, deviceIdHash: String?) async throws -> VibePlace {
        let response: PlaceResponse = try await get(path: "places/\(id)", deviceIdHash: deviceIdHash)
        return response.place
    }

    func upsertPlace(_ candidate: PlaceCandidate) async throws -> VibePlace {
        let response: PlaceResponse = try await send(path: "places", method: "POST", body: candidate)
        return response.place
    }

    func submitRating(placeId: String, deviceIdHash: String, vibeTags: [VibeTag]) async throws -> RatingSubmission {
        let selectedTags = VibeTag.normalizedSelection(vibeTags)
        guard let primaryTag = selectedTags.first else {
            throw APIError.server("Pick a vibe first.")
        }

        let request = RatingRequest(
            placeId: placeId,
            deviceIdHash: deviceIdHash,
            score: VibeTag.score(for: selectedTags),
            vibeTag: primaryTag,
            vibeTags: selectedTags
        )
        let response: RatingResponse = try await send(path: "ratings", method: "POST", body: request)
        return RatingSubmission(place: response.place, rating: response.rating, discovery: response.discovery)
    }

    func fetchAccountEligibility(deviceIdHash: String) async throws -> AccountEligibility {
        let response: AccountEligibilityResponse = try await get(path: "account/eligibility", deviceIdHash: deviceIdHash)
        return response.account
    }

    func requestAccountSignup(email: String, deviceIdHash: String) async throws -> AccountSignupResponse {
        let request = AccountSignupRequest(email: email, deviceIdHash: deviceIdHash)
        return try await send(path: "account/signup", method: "POST", body: request)
    }

    private func get<Response: Decodable>(path: String, deviceIdHash: String? = nil) async throws -> Response {
        try await get(url: baseURL.appendingPathComponent(path), deviceIdHash: deviceIdHash)
    }

    private func get<Response: Decodable>(url: URL, deviceIdHash: String? = nil) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyStandardHeaders(to: &request, deviceIdHash: deviceIdHash)
        return try await perform(request)
    }

    private func send<Body: Encodable, Response: Decodable>(path: String, method: String, body: Body) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        applyStandardHeaders(to: &request)
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }

    private func applyStandardHeaders(to request: inout URLRequest, deviceIdHash: String? = nil) {
        if let deviceIdHash, !deviceIdHash.isEmpty {
            request.addValue(deviceIdHash, forHTTPHeaderField: "X-Vibe-Device-ID-Hash")
        }

        if let betaAccessToken = AppConfig.betaAccessToken {
            request.addValue(betaAccessToken, forHTTPHeaderField: "X-Vibe-Beta-Token")
        }

        if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            request.addValue("\(appVersion) (\(buildNumber))", forHTTPHeaderField: "X-Vibe-App-Version")
        }

        request.addValue("ios", forHTTPHeaderField: "X-Vibe-Source")
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.server(errorResponse.error)
            }
            throw APIError.server("The vibe wires got crossed.")
        }

        return try decoder.decode(Response.self, from: data)
    }
}

private struct VibesResponse: Decodable {
    var vibes: [VibeTag]
}

private struct NearbyPlacesResponse: Decodable {
    var places: [VibePlace]
}

private struct MapCellsResponse: Decodable {
    var cells: [MapCellCluster]
}

private struct PlaceResponse: Decodable {
    var place: VibePlace
}

private struct RatingRequest: Encodable {
    var placeId: String
    var deviceIdHash: String
    var score: Double
    var vibeTag: VibeTag
    var vibeTags: [VibeTag]
}

private struct RatingResponse: Decodable {
    var place: VibePlace
    var rating: VibeRating
    var discovery: RatingDiscovery?
}

private struct ErrorResponse: Decodable {
    var error: String
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The backend URL is not valid."
        case .invalidResponse:
            "The backend did not return a usable response."
        case .server(let message):
            message
        }
    }
}
