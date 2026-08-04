import XCTest
@testable import VibeMap

final class VibeTagTests: XCTestCase {
    func testLegacyWorthItDecodesAsLowKey() throws {
        let tag = try JSONDecoder().decode(VibeTag.self, from: Data(#""Worth It""#.utf8))

        XCTAssertEqual(tag, .lowKey)
    }

    func testLowKeyEncodesWithCanonicalAPIValue() throws {
        let encoded = try JSONEncoder().encode(VibeTag.lowKey)

        XCTAssertEqual(String(decoding: encoded, as: UTF8.self), #""Low-key""#)
    }

    func testNeedsPrayerUsesDedicatedPrayingHandsArtwork() {
        XCTAssertEqual(VibeTag.needsPrayer.visualStyle.assetName, "NeedsPrayerIcon")
        XCTAssertEqual(VibeTag.fire.visualStyle.assetName, nil)
    }

    func testNormalizedSelectionPreservesOrderRemovesDuplicatesAndCapsAtThree() {
        let normalized = VibeTag.normalizedSelection([.fire, .lowKey, .fire, .iconic, .bougie])

        XCTAssertEqual(normalized, [.fire, .lowKey, .iconic])
    }

    func testVisibleTopVibesSortsDescendingWithoutDestabilizingTies() {
        let stats = PlaceStats(
            ratingCount: 4,
            averageScore: 8,
            topVibeTag: .fire,
            topVibes: [
                VibeBreakdown(vibeTag: .worthTheDrive, count: 2, percentage: 50),
                VibeBreakdown(vibeTag: .fire, count: 4, percentage: 100),
                VibeBreakdown(vibeTag: .iconic, count: 2, percentage: 50),
            ]
        )

        XCTAssertEqual(stats.visibleTopVibes.map(\.vibeTag), [.fire, .worthTheDrive, .iconic])
    }

    func testNearbyShowMoreRevealsFourthMyVibe() {
        let nextLimit = NearbyPlacePagination.nextLimit(
            currentLimit: 10,
            displayedCount: 3,
            totalCount: 4,
            pageSize: 10,
            maximumLimit: 60
        )

        XCTAssertEqual(nextLimit, 20)
        XCTAssertEqual(min(nextLimit, 4), 4)
        XCTAssertTrue(
            NearbyPlacePagination.appliesInitialSectionCaps(
                isListExpanded: false,
                hasRequestedAdditionalPlaces: false
            )
        )
        XCTAssertFalse(
            NearbyPlacePagination.appliesInitialSectionCaps(
                isListExpanded: false,
                hasRequestedAdditionalPlaces: true
            )
        )
    }

    func testPlaceNameSearchMatchesMeaningfulPrefixesAndPossessives() {
        for query in ["Joe T", "Joe T G", "Joe T Garcia", "Joe T. Garcia's"] {
            for candidate in ["Joe T. Garcia’s", "Joe T Garcia's Mexican Restaurant"] {
                XCTAssertTrue(
                    PlaceNameSearchMatcher.matchTier(query: query, candidateName: candidate).isStrongMatch,
                    "Expected \(query) to match \(candidate)"
                )
            }
        }
    }

    func testPlaceNameSearchExcludesUnrelatedBusinesses() {
        for query in ["Joe T", "Joe T G"] {
            for candidate in ["Trader Joe’s", "Joe’s Crab Shack", "Joe Tacos", "Joe Tacos Restaurant", "Taco Joe Grill", "Garcia Auto Repair"] {
                XCTAssertEqual(
                    PlaceNameSearchMatcher.matchTier(query: query, candidateName: candidate),
                    .none,
                    "Did not expect \(query) to match \(candidate)"
                )
            }
        }
    }
}
