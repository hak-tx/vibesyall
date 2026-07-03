import Foundation

struct AccountEligibilityResponse: Decodable {
    var account: AccountEligibility
}

struct AccountEligibility: Decodable, Hashable {
    var eligible: Bool
    var threshold: Int
    var vibedPlaceCount: Int
    var remainingPlaces: Int
    var benefits: [String]
    var profile: AccountProfile?

    var progressText: String {
        if eligible {
            return "You have vibed \(vibedPlaceCount) places."
        }

        return "\(remainingPlaces) more places unlock account backup."
    }
}

struct AccountProfile: Decodable, Hashable {
    var id: String
    var emailVerified: Bool
    var emailVerifiedAt: String?
    var createdAt: String?
    var lastSeenAt: String?
}

struct AccountSignupRequest: Encodable {
    var email: String
    var deviceIdHash: String
}

struct AccountSignupResponse: Decodable {
    var status: String
    var emailSent: Bool
    var account: AccountEligibility
    var message: String
}

struct AccountDeletionRequest: Encodable {
    var email: String
    var deviceIdHash: String
}

struct AccountDeletionResponse: Decodable {
    var status: String
    var deleted: Bool
    var message: String
}

struct AccountSignupPrompt: Identifiable, Hashable {
    let id = UUID()
    var eligibility: AccountEligibility
}

enum AccountBenefit {
    static let defaultBenefits = [
        "Keep past and future vibes tied to one account.",
        "Switch devices without losing your place history.",
        "Edit older vibes when your opinion changes.",
        "Help keep the map authentic and harder to spam."
    ]
}
