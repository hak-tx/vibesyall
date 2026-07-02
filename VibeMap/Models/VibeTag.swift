import Foundation
import SwiftUI

struct VibeVisualStyle {
    var color: Color
    var symbolName: String
}

enum VibeTag: String, CaseIterable, Codable, Identifiable, Hashable {
    case changedMyLife = "Changed my Life"
    case fire = "Fire"
    case worthTheDrive = "Worth the Drive"
    case iconic = "Iconic"
    case hiddenGem = "Hidden Gem"
    case underrated = "Underrated"
    case mid = "Mid"
    case chaos = "Chaos"
    case overrated = "Overrated"
    case touristTrap = "Tourist Trap"
    case needsPrayer = "Needs Prayer"
    case emotionallyDamaging = "Emotionally Damaging"

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        if let tag = VibeTag.fromServerValue(rawValue) {
            self = tag
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "\(rawValue) is not a supported vibe tag."
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var rankingScore: Double {
        switch self {
        case .changedMyLife:
            10
        case .fire:
            9
        case .worthTheDrive:
            8
        case .iconic:
            7
        case .hiddenGem:
            6.5
        case .underrated:
            6
        case .mid:
            5
        case .chaos:
            4
        case .overrated:
            3
        case .touristTrap:
            2
        case .needsPrayer:
            1
        case .emotionallyDamaging:
            0
        }
    }

    var mapLabel: String {
        switch self {
        case .changedMyLife:
            "Life"
        case .fire:
            "Fire"
        case .overrated:
            "Over"
        case .worthTheDrive:
            "Drive"
        case .emotionallyDamaging:
            "Damage"
        case .iconic:
            "Iconic"
        case .hiddenGem:
            "Gem"
        case .underrated:
            "Under"
        case .touristTrap:
            "Trap"
        case .mid:
            "Mid"
        case .chaos:
            "Chaos"
        case .needsPrayer:
            "Prayer"
        }
    }

    var visualStyle: VibeVisualStyle {
        switch self {
        case .changedMyLife:
            VibeVisualStyle(color: Color(red: 0.92, green: 0.56, blue: 0.12), symbolName: "star.fill")
        case .fire:
            VibeVisualStyle(color: Color(red: 1.0, green: 0.31, blue: 0.27), symbolName: "flame.fill")
        case .overrated:
            VibeVisualStyle(color: Color(red: 0.45, green: 0.48, blue: 0.56), symbolName: "hand.thumbsdown.fill")
        case .worthTheDrive:
            VibeVisualStyle(color: Color(red: 0.95, green: 0.46, blue: 0.12), symbolName: "car.fill")
        case .emotionallyDamaging:
            VibeVisualStyle(color: Color(red: 0.18, green: 0.20, blue: 0.25), symbolName: "xmark.circle.fill")
        case .iconic:
            VibeVisualStyle(color: Color(red: 0.08, green: 0.36, blue: 0.88), symbolName: "sparkles")
        case .hiddenGem:
            VibeVisualStyle(color: Color(red: 0.06, green: 0.53, blue: 0.42), symbolName: "diamond.fill")
        case .underrated:
            VibeVisualStyle(color: Color(red: 0.19, green: 0.48, blue: 0.86), symbolName: "arrow.up.forward.circle.fill")
        case .touristTrap:
            VibeVisualStyle(color: Color(red: 0.86, green: 0.58, blue: 0.05), symbolName: "camera.fill")
        case .mid:
            VibeVisualStyle(color: Color(red: 0.0, green: 0.55, blue: 0.52), symbolName: "minus.circle.fill")
        case .chaos:
            VibeVisualStyle(color: Color(red: 0.72, green: 0.18, blue: 0.18), symbolName: "tornado")
        case .needsPrayer:
            VibeVisualStyle(color: Color(red: 0.28, green: 0.31, blue: 0.80), symbolName: "hands.sparkles.fill")
        }
    }

    var guidanceGroup: VibeGuidanceGroup {
        switch self {
        case .changedMyLife, .fire, .worthTheDrive, .iconic:
            .loveIt
        case .hiddenGem, .underrated, .mid, .chaos:
            .its
        case .overrated, .touristTrap, .needsPrayer, .emotionallyDamaging:
            .skipIt
        }
    }

    static func normalizedSelection(_ tags: [VibeTag]) -> [VibeTag] {
        var seen = Set<VibeTag>()
        return tags.filter { seen.insert($0).inserted }.prefix(3).map { $0 }
    }

    static func bestToWorst(_ tags: [VibeTag]) -> [VibeTag] {
        tags.sorted { lhs, rhs in
            if lhs.rankingScore == rhs.rankingScore {
                let lhsIndex = allCases.firstIndex(of: lhs) ?? 0
                let rhsIndex = allCases.firstIndex(of: rhs) ?? 0
                return lhsIndex < rhsIndex
            }
            return lhs.rankingScore > rhs.rankingScore
        }
    }

    static func score(for tags: [VibeTag]) -> Double {
        let selectedTags = normalizedSelection(tags)
        guard !selectedTags.isEmpty else { return 0 }
        return selectedTags.map(\.rankingScore).reduce(0, +) / Double(selectedTags.count)
    }

    static func fromServerValue(_ rawValue: String) -> VibeTag? {
        VibeTag(rawValue: rawValue) ?? VibeTag.legacyTag(for: rawValue)
    }

    private static func legacyTag(for rawValue: String) -> VibeTag? {
        switch rawValue {
        case "Changed My Life", "Changed my life", "changed_my_life", "Inspiring":
            return .changedMyLife
        case "Fire", "fire", "Elite", "Unreasonably good", "Surprisingly solid", "Great":
            return .fire
        case "Worth the drive", "worth_the_drive":
            return .worthTheDrive
        case "Iconic", "iconic", "Certified", "America":
            return .iconic
        case "Hidden Gem", "Hidden gem", "hidden_gem":
            return .hiddenGem
        case "Underrated", "underrated":
            return .underrated
        case "Mid", "mid":
            return .mid
        case "Chaos", "chaos":
            return .chaos
        case "Overrated", "overrated":
            return .overrated
        case "Needs prayer", "needs_prayer":
            return .needsPrayer
        case "Tourist trap", "tourist_trap":
            return .touristTrap
        case "Emotionally damaging", "emotionally_damaging", "Never again", "Cringe", "UnAmerican", "Unamerican", "Un-American", "Un American":
            return .emotionallyDamaging
        default:
            return nil
        }
    }
}

enum VibeGuidanceGroup: String, CaseIterable, Identifiable {
    case loveIt = "Love it"
    case its = "It's..."
    case skipIt = "Skip it"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .loveIt:
            "hand.thumbsup.fill"
        case .its:
            "ellipsis.circle.fill"
        case .skipIt:
            "hand.thumbsdown.fill"
        }
    }
}
