import CoreLocation
import Foundation
import MapKit

protocol PlaceSearching {
    func search(query: String, near coordinate: CLLocationCoordinate2D?) async throws -> [PlaceCandidate]
    func pointOfInterestChoices(for selectedItem: MKMapItem) async throws -> [PlaceCandidateMatch]
    func pointOfInterestChoices(named title: String?, near coordinate: CLLocationCoordinate2D) async throws -> [PlaceCandidateMatch]
}

struct MapKitPlaceSearchService: PlaceSearching {
    private static let overlappingPOISearchRadiusMeters: CLLocationDistance = 24
    private static let overlappingPOIDistanceMeters: CLLocationDistance = 8
    private static let fallbackNamedPOISearchRadiusMeters: CLLocationDistance = 160
    private static let mapTapResultLimit = 4

    func search(query: String, near coordinate: CLLocationCoordinate2D?) async throws -> [PlaceCandidate] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest

        if let coordinate {
            request.region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 30_000,
                longitudinalMeters: 30_000
            )
        }

        let response = try await MKLocalSearch(request: request).start()
        let candidates = response.mapItems
            .map { candidate(for: $0, origin: coordinate) }
            .sortedByDistance()

        return Array(candidates.prefix(8))
    }

    func pointOfInterestChoices(for selectedItem: MKMapItem) async throws -> [PlaceCandidateMatch] {
        let selectedCoordinate = selectedItem.placemark.coordinate
        let selectedCandidate = candidate(for: selectedItem)
        let selectedMatch = PlaceCandidateMatch(
            candidate: selectedCandidate,
            distanceMeters: 0
        )
        let nearbyMatches = try await pointOfInterestMatches(near: selectedCoordinate)
            .filter { match in
                match.distanceMeters <= Self.overlappingPOIDistanceMeters &&
                    match.candidate.id != selectedCandidate.id
            }
            .sorted { $0.distanceMeters < $1.distanceMeters }

        return ([selectedMatch] + nearbyMatches)
            .uniquedByCandidateName()
            .prefix(Self.mapTapResultLimit)
            .map { $0 }
    }

    func pointOfInterestChoices(named title: String?, near coordinate: CLLocationCoordinate2D) async throws -> [PlaceCandidateMatch] {
        var matches: [PlaceCandidateMatch] = []

        if let title = title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            matches.append(contentsOf: (try? await namedPointOfInterestMatches(title, near: coordinate)) ?? [])
        }

        matches.append(contentsOf: (try? await pointOfInterestMatches(near: coordinate)) ?? [])

        if matches.isEmpty,
           let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
           !title.isEmpty {
            matches.append(
                PlaceCandidateMatch(
                    candidate: PlaceCandidate(
                        provider: "mapkit",
                        providerPlaceId: [
                            title,
                            String(format: "%.5f", coordinate.latitude),
                            String(format: "%.5f", coordinate.longitude)
                        ].joined(separator: "|"),
                        name: title,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        streetAddress: nil,
                        category: categoryLabel(forName: title),
                        city: nil,
                        region: nil,
                        country: nil,
                        distanceMeters: 0
                    ),
                    distanceMeters: 0
                )
            )
        }

        return matches
            .filter { $0.distanceMeters <= Self.fallbackNamedPOISearchRadiusMeters }
            .sorted { $0.distanceMeters < $1.distanceMeters }
            .uniquedByCandidateName()
            .prefix(Self.mapTapResultLimit)
            .map { $0 }
    }

    private func namedPointOfInterestMatches(_ title: String, near coordinate: CLLocationCoordinate2D) async throws -> [PlaceCandidateMatch] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = title
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: Self.fallbackNamedPOISearchRadiusMeters,
            longitudinalMeters: Self.fallbackNamedPOISearchRadiusMeters
        )

        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems
            .map { item in
                PlaceCandidateMatch(
                    candidate: candidate(for: item, origin: coordinate),
                    distanceMeters: distance(from: item, to: coordinate)
                )
            }
    }

    private func pointOfInterestMatches(near coordinate: CLLocationCoordinate2D) async throws -> [PlaceCandidateMatch] {
        let request = MKLocalPointsOfInterestRequest(
            center: coordinate,
            radius: Self.overlappingPOISearchRadiusMeters
        )
        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems
            .map { item in
                PlaceCandidateMatch(
                    candidate: candidate(for: item, origin: coordinate),
                    distanceMeters: distance(from: item, to: coordinate)
                )
            }
    }

    private func candidate(for item: MKMapItem, origin: CLLocationCoordinate2D? = nil) -> PlaceCandidate {
        let placemark = item.placemark
        let coordinate = placemark.coordinate
        return PlaceCandidate(
            provider: "mapkit",
            providerPlaceId: providerPlaceID(for: item),
            name: item.name ?? placemark.name ?? "Unnamed spot",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            streetAddress: streetAddress(for: placemark),
            category: categoryLabel(for: item),
            city: placemark.locality,
            region: placemark.administrativeArea,
            country: placemark.countryCode,
            distanceMeters: origin.map { distance(from: item, to: $0) }
        )
    }

    private func categoryLabel(for item: MKMapItem) -> String? {
        let name = item.name ?? item.placemark.name

        guard let category = item.pointOfInterestCategory else {
            return categoryLabel(forName: name)
        }

        let normalized = category.rawValue
            .lowercased()
            .replacingOccurrences(of: "mkpoicategory", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")

        switch normalized {
        case "restaurant", "cafe", "bakery", "foodmarket":
            return "Restaurant"
        case "brewery", "winery":
            return "Brewery"
        case "nightlife":
            return "Bar"
        case "park", "nationalpark", "beach", "campground":
            return "Park"
        case "theater", "movietheater":
            return "Music Venue"
        case "stadium":
            return "Stadium"
        case "museum", "aquarium", "zoo":
            return "Museum"
        case "hotel":
            return "Hotel"
        case "school", "university":
            return "School"
        case "hospital", "pharmacy":
            return "Health"
        case "fitnesscenter":
            return "Fitness"
        case "store":
            return "Shop"
        case "gasstation", "evcharger":
            return "Gas"
        case "airport", "marina", "publictransport":
            return "Transit"
        case "parking":
            return "Parking"
        case "bank", "atm":
            return "Bank"
        case "library":
            return "Library"
        case "police", "firestation", "postoffice", "restroom":
            return "Public Service"
        default:
            return prettifiedCategory(from: normalized) ?? categoryLabel(forName: name)
        }
    }

    private func categoryLabel(forName name: String?) -> String? {
        guard let name = name?.lowercased() else {
            return nil
        }

        if name.contains("stadium") || name.contains("arena") || name.contains("ballpark") {
            return "Stadium"
        }

        if name.contains("music") || name.contains("concert") || name.contains("venue") || name.contains("the masonic") {
            return "Music Venue"
        }

        if name.contains("park") || name.contains("trail") {
            return "Park"
        }

        if name.contains("bbq") ||
            name.contains("barbecue") ||
            name.contains("smokehouse") ||
            name.contains("taco") ||
            name.contains("diner") ||
            name.contains("restaurant") ||
            name.contains("cafe") ||
            name.contains("coffee") ||
            name.contains("pizza") ||
            name.contains("burger") ||
            name.contains("bakery") ||
            name.contains("grill") ||
            name.contains("kitchen") ||
            name.contains("eatery") {
            return "Restaurant"
        }

        if name.contains("bar") || name.contains("saloon") || name.contains("pub") {
            return "Bar"
        }

        return nil
    }

    private func prettifiedCategory(from normalized: String) -> String? {
        guard !normalized.isEmpty else {
            return nil
        }

        let spaced = normalized.reduce(into: "") { result, character in
            if character.isUppercase, !result.isEmpty {
                result.append(" ")
            }
            result.append(character)
        }

        return spaced.prefix(1).uppercased() + String(spaced.dropFirst())
    }

    private func streetAddress(for placemark: MKPlacemark) -> String? {
        let pieces = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { value -> String? in
                let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed?.isEmpty == false ? trimmed : nil
            }

        if !pieces.isEmpty {
            return pieces.joined(separator: " ")
        }

        return streetAddressFromTitle(placemark.title, excludingName: placemark.name)
    }

    private func streetAddressFromTitle(_ title: String?, excludingName name: String?) -> String? {
        guard let title else {
            return nil
        }

        let normalizedName = Self.normalized(title: name)
        let segments = title
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        return segments.first { segment in
            guard !segment.isEmpty,
                  Self.normalized(title: segment) != normalizedName else {
                return false
            }

            return looksLikeStreetAddress(segment)
        }
    }

    private func looksLikeStreetAddress(_ value: String) -> Bool {
        guard value.rangeOfCharacter(from: .decimalDigits) != nil else {
            return false
        }

        let normalized = " \(value.lowercased()) "
        let streetTokens = [
            " st ", " street ", " ave ", " avenue ", " rd ", " road ",
            " blvd ", " boulevard ", " dr ", " drive ", " ln ", " lane ",
            " ct ", " court ", " hwy ", " highway ", " fwy ", " freeway ",
            " pkwy ", " parkway ", " way ", " pl ", " place ", " loop "
        ]

        return streetTokens.contains { normalized.contains($0) }
    }

    private func distance(from item: MKMapItem, to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
            .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }

    private func providerPlaceID(for item: MKMapItem) -> String {
        let coordinate = item.placemark.coordinate
        return [
            item.name ?? item.placemark.name ?? "place",
            String(format: "%.5f", coordinate.latitude),
            String(format: "%.5f", coordinate.longitude)
        ].joined(separator: "|")
    }

    private static func normalized(title: String?) -> String {
        title?
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ") ?? ""
    }
}

private extension Array where Element == PlaceCandidate {
    func sortedByDistance() -> [PlaceCandidate] {
        sorted { lhs, rhs in
            switch (lhs.distanceMeters, rhs.distanceMeters) {
            case let (lhsDistance?, rhsDistance?):
                return lhsDistance < rhsDistance
            case (.some, nil):
                return true
            case (nil, .some):
                return false
            case (nil, nil):
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }
}

private extension Array where Element == PlaceCandidateMatch {
    func uniquedByCandidateName() -> [PlaceCandidateMatch] {
        var seenNames = Set<String>()
        return filter { match in
            let name = match.candidate.name
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            return seenNames.insert(name).inserted
        }
    }
}
