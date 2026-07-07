import CoreLocation
import Foundation
import MapKit

enum MapRenderingTier {
    case detail
    case local
    case metro
    case regional
}

enum AppConfig {
    static var backendBaseURL: URL {
        if let configuredURL = Bundle.main.object(forInfoDictionaryKey: "VIBE_MAP_BACKEND_BASE_URL") as? String,
           !configuredURL.hasPrefix("$("),
           let url = URL(string: configuredURL) {
            return url
        }

        return URL(string: "http://127.0.0.1:8787")!
    }

    static var betaAccessToken: String? {
        var candidates = [
            Bundle.main.object(forInfoDictionaryKey: "VIBE_BETA_ACCESS_TOKEN") as? String
        ]

        #if DEBUG
        candidates.append(ProcessInfo.processInfo.environment["VIBE_BETA_ACCESS_TOKEN"])
        candidates.append(UserDefaults.standard.string(forKey: "vibes-yall.debug-beta-access-token"))
        #endif

        for candidate in candidates {
            let trimmedToken = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmedToken.isEmpty, !trimmedToken.hasPrefix("$(") {
                return trimmedToken
            }
        }

        return nil
    }

    static let privacyPolicyURL = URL(string: "https://vibesyall.com/privacy")!
    static let termsURL = URL(string: "https://vibesyall.com/terms")!
    static let supportURL = URL(string: "https://vibesyall.com/support")!
    static let appStoreURL = URL(string: "https://apps.apple.com/us/app/vibes-yall/id6783989332")!
    static let supportEmail = "vibesyall@gmail.com"

    static let forceMockBackend = false
    static var useMockBackend: Bool {
        forceMockBackend || isDemoMode
    }

    static let nearbyRadiusMeters: CLLocationDistance = 5_000
    static let maximumNearbyRadiusMeters: CLLocationDistance = 2_500_000
    static let personalizedNearbyRadiusMeters: CLLocationDistance = 75_000
    static let addressEnrichmentMaximumRadiusMeters: CLLocationDistance = 40_000
    static let serverMapCellMinimumRadiusMeters: CLLocationDistance = 240_000
    static let maximumRenderedMapCellClusters = 56
    static let maximumContinuityMapCellClusters = 18
    static let nearbyMemoryCacheTTL: TimeInterval = 5 * 60
    static let nearbyMemoryCacheLimit = 48
    static let mapCellMemoryCacheTTL: TimeInterval = 10 * 60
    static let mapCellMemoryCacheLimit = 80
    static let nearbyReloadDebounce: Duration = .milliseconds(120)
    static let initialUserMapDistanceMeters: CLLocationDistance = 50_000
    static let currentLocationMapDistanceMeters: CLLocationDistance = 12_000

    static var defaultMapCenter: CLLocationCoordinate2D {
        #if DEBUG
        if usesSimulatorHoustonMapDefault {
            return houstonMapCenter
        }
        #endif

        return CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431)
    }

    static var initialMapCenter: CLLocationCoordinate2D {
        debugInitialMapCenter ?? defaultMapCenter
    }

    static var defaultMapDistanceMeters: CLLocationDistance {
        if let debugInitialMapDistanceMeters {
            return debugInitialMapDistanceMeters
        }

        #if DEBUG
        if usesSimulatorHoustonMapDefault {
            return 90_000
        }
        #endif

        return isDemoMode ? 9_000 : 50_000
    }

    static var shouldSkipInitialUserLocationAutocenter: Bool {
        #if DEBUG
        debugInitialMapCenter != nil || usesSimulatorHoustonMapDefault
        #else
        false
        #endif
    }

    static func nearbyRadius(for region: MKCoordinateRegion) -> CLLocationDistance {
        let visibleRadius = visibleHalfDiagonalMeters(for: region) * 1.08
        return min(max(visibleRadius, nearbyRadiusMeters), maximumNearbyRadiusMeters)
    }

    static func roundedNearbyCoordinate(_ value: CLLocationDegrees) -> CLLocationDegrees {
        round(value, decimalPlaces: 3)
    }

    static func roundedNearbyRadius(_ radius: CLLocationDistance) -> CLLocationDistance {
        let step: CLLocationDistance
        if radius > 100_000 {
            step = 10_000
        } else if radius > 25_000 {
            step = 2_500
        } else {
            step = 250
        }

        return max(MIN_NEARBY_RADIUS_METERS, (radius / step).rounded() * step)
    }

    static func nearbyCacheKey(center: CLLocationCoordinate2D, radius: CLLocationDistance, includesDevice: Bool) -> String {
        let latitude = roundedNearbyCoordinate(center.latitude)
        let longitude = roundedNearbyCoordinate(center.longitude)
        let roundedRadius = roundedNearbyRadius(radius)
        let scope = includesDevice ? "personal" : "public"
        return String(format: "%@|%.3f|%.3f|%.0f", scope, latitude, longitude, roundedRadius)
    }

    static func shouldUseServerMapCells(for radius: CLLocationDistance) -> Bool {
        switch mapRenderingTier(for: radius) {
        case .metro, .regional:
            true
        case .detail, .local:
            false
        }
    }

    static func mapCellSize(for radius: CLLocationDistance) -> CLLocationDistance {
        let cellSize: CLLocationDistance
        switch radius {
        case ..<350_000:
            cellSize = 50_000
        case ..<700_000:
            cellSize = 70_000
        case ..<1_200_000:
            cellSize = 95_000
        case ..<1_800_000:
            cellSize = 145_000
        default:
            cellSize = 220_000
        }

        return roundedMapCellSize(cellSize)
    }

    static func mapCellDisplayLimit(for radius: CLLocationDistance) -> Int {
        switch radius {
        case ..<350_000:
            return 56
        case ..<700_000:
            return 52
        case ..<1_200_000:
            return 44
        case ..<1_800_000:
            return 36
        default:
            return 32
        }
    }

    static func minimumMapCellDisplayCount(for radius: CLLocationDistance) -> Int {
        switch mapRenderingTier(for: radius) {
        case .detail, .local, .metro:
            return 2
        case .regional:
            return 3
        }
    }

    static func shouldShowContinuityMapCells(for radius: CLLocationDistance) -> Bool {
        switch mapRenderingTier(for: radius) {
        case .local:
            return true
        case .detail:
            return radius >= nearbyRadiusMeters * 2
        case .metro, .regional:
            return false
        }
    }

    static func mapCellContinuityMatchDistance(for cluster: MapCellCluster) -> CLLocationDistance {
        min(max(cluster.cellSizeMeters * 0.55, 8_000), 36_000)
    }

    static func maximumRenderedMapPlaces(for region: MKCoordinateRegion) -> Int {
        switch mapRenderingTier(for: region) {
        case .detail:
            return 180
        case .local:
            return 160
        case .metro, .regional:
            return 0
        }
    }

    static func roundedMapCellCoordinate(_ value: CLLocationDegrees, cellSize: CLLocationDistance) -> CLLocationDegrees {
        let step = mapCellCoordinateStep(for: roundedMapCellSize(cellSize))
        return roundToNearestStep(value, step: step)
    }

    static func roundedMapCellRadius(_ radius: CLLocationDistance) -> CLLocationDistance {
        max(serverMapCellMinimumRadiusMeters, (radius / 25_000).rounded() * 25_000)
    }

    static func roundedMapCellSize(_ cellSize: CLLocationDistance) -> CLLocationDistance {
        max(10_000, (cellSize / 5_000).rounded() * 5_000)
    }

    static func mapCellCacheKey(center: CLLocationCoordinate2D, radius: CLLocationDistance, cellSize: CLLocationDistance) -> String {
        let roundedCellSize = roundedMapCellSize(cellSize)
        return String(
            format: "cells|%.3f|%.3f|%.0f|%.0f",
            roundedMapCellCoordinate(center.latitude, cellSize: roundedCellSize),
            roundedMapCellCoordinate(center.longitude, cellSize: roundedCellSize),
            roundedMapCellRadius(radius),
            roundedCellSize
        )
    }

    static func clusterRadius(for region: MKCoordinateRegion) -> CLLocationDistance {
        let halfWidth = visibleHalfWidthMeters(for: region)
        switch mapRenderingTier(for: region) {
        case .detail:
            guard halfWidth >= 1_800 else { return 0 }
            return min(max(halfWidth / 18, 120), 2_400)
        case .local:
            return min(max(halfWidth / 24, 160), 7_500)
        case .metro, .regional:
            return 0
        }
    }

    static func clusterFocusDistance(for region: MKCoordinateRegion) -> CLLocationDistance {
        let width = visibleHalfWidthMeters(for: region) * 2
        return min(max(width * 0.45, 1_400), 14_000)
    }

    static func mapCellClusterFocusDistance(for cluster: MapCellCluster, region: MKCoordinateRegion) -> CLLocationDistance {
        let currentWidth = visibleHalfWidthMeters(for: region) * 2
        let cellFocus = cluster.cellSizeMeters * 4
        return min(max(min(currentWidth * 0.55, cellFocus), 25_000), 450_000)
    }

    static func mapRenderingTier(for region: MKCoordinateRegion) -> MapRenderingTier {
        mapRenderingTier(for: nearbyRadius(for: region))
    }

    static func mapRenderingTier(for radius: CLLocationDistance) -> MapRenderingTier {
        switch radius {
        case ..<20_000:
            return .detail
        case ..<serverMapCellMinimumRadiusMeters:
            return .local
        case ..<700_000:
            return .metro
        default:
            return .regional
        }
    }

    private static var isDemoMode: Bool {
        let processInfo = ProcessInfo.processInfo
        return processInfo.arguments.contains("--demo")
            || processInfo.environment["VIBE_MAP_DEMO"] == "1"
    }

    static var debugInitialSearchQuery: String? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--debug-search"),
              arguments.indices.contains(index + 1) else {
            return nil
        }

        return arguments[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
        #else
        return nil
        #endif
    }

    private static var debugInitialMapCenter: CLLocationCoordinate2D? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--debug-center"),
              arguments.indices.contains(index + 1) else {
            return nil
        }

        let pieces = arguments[index + 1].split(separator: ",")
        guard pieces.count == 2,
              let latitude = CLLocationDegrees(pieces[0]),
              let longitude = CLLocationDegrees(pieces[1]) else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        #else
        return nil
        #endif
    }

    private static var debugInitialMapDistanceMeters: CLLocationDistance? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--debug-distance"),
              arguments.indices.contains(index + 1),
              let distance = CLLocationDistance(arguments[index + 1]) else {
            return nil
        }

        return distance
        #else
        return nil
        #endif
    }

    private static var houstonMapCenter: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 29.7604, longitude: -95.3698)
    }

    private static var usesSimulatorHoustonMapDefault: Bool {
        #if DEBUG
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
        #else
        false
        #endif
    }

    private static func visibleHalfDiagonalMeters(for region: MKCoordinateRegion) -> CLLocationDistance {
        let center = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let corner = CLLocation(
            latitude: clampedLatitude(region.center.latitude + region.span.latitudeDelta / 2),
            longitude: region.center.longitude + region.span.longitudeDelta / 2
        )
        return center.distance(from: corner)
    }

    private static func visibleHalfWidthMeters(for region: MKCoordinateRegion) -> CLLocationDistance {
        let center = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let edge = CLLocation(
            latitude: region.center.latitude,
            longitude: region.center.longitude + region.span.longitudeDelta / 2
        )
        return center.distance(from: edge)
    }

    private static func clampedLatitude(_ latitude: CLLocationDegrees) -> CLLocationDegrees {
        min(max(latitude, -89.9), 89.9)
    }

    private static var MIN_NEARBY_RADIUS_METERS: CLLocationDistance {
        100
    }

    private static func round(_ value: Double, decimalPlaces: Int) -> Double {
        let scale = pow(10.0, Double(decimalPlaces))
        return (value * scale).rounded() / scale
    }

    private static func mapCellCoordinateStep(for cellSize: CLLocationDistance) -> CLLocationDegrees {
        let cellDegrees = cellSize / 111_320
        let step = min(max(cellDegrees * 0.5, 0.05), 0.5)
        return round(step, decimalPlaces: 3)
    }

    private static func roundToNearestStep(_ value: Double, step: Double) -> Double {
        guard step > 0 else { return value }
        return (value / step).rounded() * step
    }
}
