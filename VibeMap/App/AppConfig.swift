import CoreLocation
import Foundation
import MapKit

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
        guard let token = Bundle.main.object(forInfoDictionaryKey: "VIBE_BETA_ACCESS_TOKEN") as? String else {
            return nil
        }

        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty, !trimmedToken.hasPrefix("$(") else {
            return nil
        }

        return trimmedToken
    }

    static let forceMockBackend = false
    static var useMockBackend: Bool {
        forceMockBackend || isDemoMode
    }

    static let nearbyRadiusMeters: CLLocationDistance = 5_000
    static let maximumNearbyRadiusMeters: CLLocationDistance = 2_500_000
    static let personalizedNearbyRadiusMeters: CLLocationDistance = 75_000
    static let addressEnrichmentMaximumRadiusMeters: CLLocationDistance = 40_000
    static let serverMapCellMinimumRadiusMeters: CLLocationDistance = 120_000
    static let maximumRenderedMapPlaces = 180
    static let nearbyMemoryCacheTTL: TimeInterval = 5 * 60
    static let nearbyMemoryCacheLimit = 48
    static let mapCellMemoryCacheTTL: TimeInterval = 10 * 60
    static let mapCellMemoryCacheLimit = 80
    static let nearbyReloadDebounce: Duration = .milliseconds(220)
    static let initialUserMapDistanceMeters: CLLocationDistance = 50_000
    static let currentLocationMapDistanceMeters: CLLocationDistance = 12_000

    static var defaultMapCenter: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431)
    }

    static var initialMapCenter: CLLocationCoordinate2D {
        debugInitialMapCenter ?? defaultMapCenter
    }

    static var defaultMapDistanceMeters: CLLocationDistance {
        isDemoMode ? 9_000 : 50_000
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
        radius >= serverMapCellMinimumRadiusMeters
    }

    static func mapCellSize(for radius: CLLocationDistance) -> CLLocationDistance {
        roundedMapCellSize(min(max(radius / 10, 12_000), 240_000))
    }

    static func roundedMapCellCoordinate(_ value: CLLocationDegrees, cellSize: CLLocationDistance) -> CLLocationDegrees {
        let decimalPlaces: Int
        if cellSize >= 100_000 {
            decimalPlaces = 1
        } else if cellSize >= 30_000 {
            decimalPlaces = 2
        } else {
            decimalPlaces = 3
        }

        return round(value, decimalPlaces: decimalPlaces)
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
        guard halfWidth >= 1_800 else { return 0 }
        return min(max(halfWidth / 16, 120), 42_000)
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
}
