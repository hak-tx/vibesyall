package com.brianhakel.vibesyall.data

import androidx.compose.ui.graphics.Color

data class VibeTag(
    val id: String,
    val displayName: String,
    val emoji: String,
    val sentimentGroup: String,
    val sortOrder: Int,
) {
    val color: Color
        get() = when (id) {
            "changed_my_life" -> Color(0xFFEB8F1F)
            "fire" -> Color(0xFFFF4F45)
            "worth_the_drive" -> Color(0xFFF2741F)
            "iconic" -> Color(0xFF155CE0)
            "hidden_gem" -> Color(0xFF0F876B)
            "underrated" -> Color(0xFF307AD9)
            "bougie" -> Color(0xFF8045C2)
            "low_key" -> Color(0xFF2E944F)
            "mid" -> Color(0xFF008C85)
            "chaos" -> Color(0xFFB82E2E)
            "overrated" -> Color(0xFF737A8F)
            "tourist_trap" -> Color(0xFFDB940D)
            "needs_prayer" -> Color(0xFF474FCD)
            else -> Color(0xFF2E333F)
        }

    companion object {
        val defaults = listOf(
            VibeTag("changed_my_life", "Changed my Life", "⭐", "positive", 10),
            VibeTag("fire", "Fire", "🔥", "positive", 20),
            VibeTag("worth_the_drive", "Worth the Drive", "🚗", "positive", 30),
            VibeTag("iconic", "Iconic", "🌟", "identity", 40),
            VibeTag("hidden_gem", "Hidden Gem", "💎", "positive", 50),
            VibeTag("underrated", "Underrated", "📈", "positive", 60),
            VibeTag("bougie", "Bougie", "👑", "identity", 70),
            VibeTag("low_key", "Low-key", "🌿", "identity", 80),
            VibeTag("mid", "Mid", "😐", "neutral", 90),
            VibeTag("chaos", "Chaos", "🌪", "neutral", 100),
            VibeTag("overrated", "Overrated", "👎", "negative", 110),
            VibeTag("tourist_trap", "Tourist Trap", "📸", "negative", 120),
            VibeTag("needs_prayer", "Needs Prayer", "🙏", "negative", 130),
            VibeTag("emotionally_damaging", "Emotionally Damaging", "💀", "negative", 140),
        )

        fun normalize(value: String?): String? {
            val raw = value?.trim()?.lowercase()?.replace('-', '_')?.replace(' ', '_') ?: return null
            return when (raw) {
                "changed_my_life", "inspiring" -> "changed_my_life"
                "fire", "elite", "great", "unreasonably_good", "surprisingly_solid" -> "fire"
                "worth_the_drive" -> "worth_the_drive"
                "iconic", "certified", "america" -> "iconic"
                "hidden_gem" -> "hidden_gem"
                "underrated" -> "underrated"
                "bougie" -> "bougie"
                "low_key", "worth_it" -> "low_key"
                "mid" -> "mid"
                "chaos" -> "chaos"
                "overrated" -> "overrated"
                "tourist_trap" -> "tourist_trap"
                "needs_prayer" -> "needs_prayer"
                "emotionally_damaging", "never_again", "cringe", "unamerican", "un_american" -> "emotionally_damaging"
                else -> null
            }
        }

        fun find(value: String?, tags: List<VibeTag> = defaults): VibeTag? {
            val normalized = normalize(value) ?: return null
            return tags.firstOrNull { it.id == normalized } ?: defaults.firstOrNull { it.id == normalized }
        }
    }
}

data class VibeBreakdown(
    val tag: VibeTag,
    val count: Int,
    val percentage: Int,
)

data class PlaceStats(
    val ratingCount: Int,
    val averageScore: Double,
    val topVibes: List<VibeBreakdown>,
    val recentVibeCount: Int,
    val recentPositivePercentage: Int,
)

data class VibeRating(
    val id: String,
    val placeId: String,
    val vibeTags: List<VibeTag>,
)

data class VibePlace(
    val id: String,
    val provider: String?,
    val providerPlaceId: String?,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val streetAddress: String?,
    val category: String?,
    val primaryCategory: String?,
    val providerCategory: String?,
    val city: String?,
    val region: String?,
    val country: String?,
    val stats: PlaceStats?,
    val distanceMeters: Double?,
    val myRating: VibeRating?,
) {
    val vibeCount: Int get() = stats?.ratingCount ?: 0
    val locationLine: String
        get() = listOfNotNull(streetAddress, listOfNotNull(city, region).takeIf { it.isNotEmpty() }?.joinToString(", "))
            .filter { it.isNotBlank() }
            .joinToString(" · ")
    val topVibe: VibeBreakdown? get() = stats?.topVibes?.firstOrNull()
}

data class PlaceCandidate(
    val provider: String = "google",
    val providerPlaceId: String?,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val streetAddress: String?,
    val category: String?,
    val primaryCategory: String?,
    val providerCategory: String?,
    val city: String?,
    val region: String?,
    val country: String?,
    val distanceMeters: Double? = null,
)

data class MapCellCluster(
    val id: String,
    val latitude: Double,
    val longitude: Double,
    val count: Int,
    val totalVibes: Int,
    val topVibe: VibeTag?,
    val cellSizeMeters: Double,
)

data class PlacePrediction(
    val placeId: String,
    val title: String,
    val subtitle: String,
    val distanceMeters: Int?,
)

data class AccountEligibility(
    val eligible: Boolean,
    val threshold: Int,
    val vibedPlaceCount: Int,
    val remainingPlaces: Int,
    val benefits: List<String>,
    val emailVerified: Boolean,
)

data class AccountActionResult(
    val status: String,
    val message: String,
    val sessionToken: String? = null,
    val account: AccountEligibility? = null,
)

data class RatingResult(
    val place: VibePlace,
    val rating: VibeRating?,
    val wasFirstVibe: Boolean,
)

fun formatDistance(meters: Double?): String? {
    meters ?: return null
    val miles = meters / 1609.344
    return when {
        miles < 0.1 -> "<0.1 mi"
        miles < 10 -> "%.1f mi".format(miles)
        else -> "%.0f mi".format(miles)
    }
}
