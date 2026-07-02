import Foundation

enum DemoScenario {
    static let austinPlaces = [
        VibePlace(
            id: "mock-joes",
            provider: "mock",
            providerPlaceId: "mock-joes",
            name: "Joe's Tiny Taco Window",
            latitude: 30.2672,
            longitude: -97.7431,
            streetAddress: "604 Congress Ave",
            category: "Restaurant",
            city: "Austin",
            region: "TX",
            country: "US",
            stats: PlaceStats(
                ratingCount: 18,
                averageScore: 8.7,
                topVibeTag: .changedMyLife,
                topVibes: [
                    VibeBreakdown(vibeTag: .changedMyLife, count: 10, percentage: 56),
                    VibeBreakdown(vibeTag: .fire, count: 8, percentage: 44),
                    VibeBreakdown(vibeTag: .iconic, count: 7, percentage: 39)
                ]
            ),
            distanceMeters: nil
        ),
        VibePlace(
            id: "mock-mall",
            provider: "mock",
            providerPlaceId: "mock-mall",
            name: "The Mall Fountain",
            latitude: 30.2711,
            longitude: -97.7548,
            streetAddress: "701 W 6th St",
            category: "Park",
            city: "Austin",
            region: "TX",
            country: "US",
            stats: PlaceStats(
                ratingCount: 9,
                averageScore: 3.2,
                topVibeTag: .emotionallyDamaging,
                topVibes: [
                    VibeBreakdown(vibeTag: .emotionallyDamaging, count: 5, percentage: 56),
                    VibeBreakdown(vibeTag: .touristTrap, count: 4, percentage: 44),
                    VibeBreakdown(vibeTag: .overrated, count: 3, percentage: 33)
                ]
            ),
            distanceMeters: nil
        ),
        VibePlace(
            id: "mock-diner",
            provider: "mock",
            providerPlaceId: "mock-diner",
            name: "Highway 9 Diner",
            latitude: 30.3072,
            longitude: -97.7007,
            streetAddress: "910 Airport Blvd",
            category: "Restaurant",
            city: "Austin",
            region: "TX",
            country: "US",
            stats: PlaceStats(
                ratingCount: 12,
                averageScore: 7.4,
                topVibeTag: .worthTheDrive,
                topVibes: [
                    VibeBreakdown(vibeTag: .worthTheDrive, count: 8, percentage: 67),
                    VibeBreakdown(vibeTag: .fire, count: 5, percentage: 42),
                    VibeBreakdown(vibeTag: .needsPrayer, count: 2, percentage: 17)
                ]
            ),
            distanceMeters: nil
        )
    ]
}
