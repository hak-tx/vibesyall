package com.brianhakel.vibesyall.data

import com.brianhakel.vibesyall.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URI
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

class VibesApi(private val identityStore: SecureIdentityStore) {
    private val baseUrl = BuildConfig.API_BASE_URL.trimEnd('/')
    private val taxonomyVersion = "vibes_v3"

    suspend fun fetchTags(): List<VibeTag> {
        val root = request("GET", "/vibes/tags")
        val values = root.optJSONArray("tags") ?: root.optJSONArray("vibes") ?: JSONArray()
        return values.objects().mapNotNull { value ->
            val id = VibeTag.normalize(value.string("id") ?: value.string("slug") ?: value.string("display_name"))
                ?: return@mapNotNull null
            VibeTag(
                id = id,
                displayName = value.string("display_name") ?: VibeTag.find(id)?.displayName ?: id,
                emoji = value.string("emoji") ?: VibeTag.find(id)?.emoji.orEmpty(),
                sentimentGroup = value.string("sentiment_group") ?: VibeTag.find(id)?.sentimentGroup.orEmpty(),
                sortOrder = value.optInt("sort_order", VibeTag.find(id)?.sortOrder ?: 999),
            )
        }.sortedBy(VibeTag::sortOrder).ifEmpty { VibeTag.defaults }
    }

    suspend fun fetchNearby(
        latitude: Double,
        longitude: Double,
        radius: Double,
        vibeFilter: VibeTag?,
    ): List<VibePlace> {
        val query = mutableMapOf(
            "lat" to "%.5f".format(latitude),
            "lng" to "%.5f".format(longitude),
            "radius" to "%.0f".format(radius.coerceIn(5_000.0, 2_500_000.0)),
        )
        vibeFilter?.let { query["vibe_tag"] = it.id }
        return request("GET", "/places/nearby", query = query, includeDevice = true)
            .optJSONArray("places")
            .orEmptyObjects()
            .map(::parsePlace)
    }

    suspend fun fetchMapCells(
        latitude: Double,
        longitude: Double,
        radius: Double,
        cellSize: Double,
        vibeFilter: VibeTag?,
        tags: List<VibeTag>,
    ): List<MapCellCluster> {
        val query = mutableMapOf(
            "lat" to "%.4f".format(latitude),
            "lng" to "%.4f".format(longitude),
            "radius" to "%.0f".format(radius.coerceAtLeast(240_000.0)),
            "cell_size" to "%.0f".format(cellSize),
        )
        vibeFilter?.let { query["vibe_tag"] = it.id }
        return request("GET", "/places/map-cells", query = query)
            .optJSONArray("cells")
            .orEmptyObjects()
            .map { value ->
                MapCellCluster(
                    id = value.string("id") ?: "${value.optDouble("latitude")}:${value.optDouble("longitude")}",
                    latitude = value.optDouble("latitude"),
                    longitude = value.optDouble("longitude"),
                    count = value.optInt("count"),
                    totalVibes = value.optInt("total_vibes"),
                    topVibe = VibeTag.find(value.string("top_vibe_tag_id") ?: value.string("top_vibe_tag"), tags),
                    cellSizeMeters = value.optDouble("cell_size_meters", cellSize),
                )
            }
    }

    suspend fun searchSavedPlaces(queryText: String, latitude: Double, longitude: Double): List<VibePlace> =
        request(
            "GET",
            "/places/search",
            query = mapOf(
                "q" to queryText,
                "lat" to "%.5f".format(latitude),
                "lng" to "%.5f".format(longitude),
                "limit" to "10",
            ),
            includeDevice = true,
        ).optJSONArray("places").orEmptyObjects().map(::parsePlace)

    suspend fun fetchPlace(placeId: String): VibePlace = parsePlace(
        request("GET", "/places/${encodePath(placeId)}", includeDevice = true).getJSONObject("place"),
    )

    suspend fun upsertPlace(candidate: PlaceCandidate): VibePlace {
        val body = JSONObject().apply {
            put("provider", candidate.provider)
            candidate.providerPlaceId?.let { put("provider_place_id", it) }
            put("name", candidate.name)
            put("latitude", candidate.latitude)
            put("longitude", candidate.longitude)
            candidate.streetAddress?.let { put("street_address", it) }
            candidate.category?.let { put("category", it) }
            candidate.primaryCategory?.let { put("primary_category", it) }
            candidate.providerCategory?.let { put("provider_category", it) }
            candidate.city?.let { put("city", it) }
            candidate.region?.let { put("region", it) }
            candidate.country?.let { put("country", it) }
        }
        return parsePlace(request("POST", "/places", body = body).getJSONObject("place"))
    }

    suspend fun submitVibes(placeId: String, tags: List<VibeTag>): RatingResult {
        require(tags.isNotEmpty()) { "Pick at least one vibe." }
        require(tags.size <= 3) { "Pick up to three vibes." }
        val root = request(
            method = "POST",
            path = "/vibes",
            body = JSONObject().apply {
                put("place_id", placeId)
                put("device_id_hash", identityStore.deviceIdHash)
                put("vibe_tags", JSONArray(tags.distinctBy(VibeTag::id).take(3).map(VibeTag::id)))
                put("source", "android")
                put("app_version", BuildConfig.VERSION_NAME)
            },
            includeDevice = true,
        )
        val event = root.optJSONObject("vibe_event") ?: root.optJSONObject("rating")
        return RatingResult(
            place = parsePlace(root.getJSONObject("place")),
            rating = event?.let(::parseRating),
            wasFirstVibe = root.optJSONObject("discovery")?.optBoolean("was_first_vibe", false) == true,
        )
    }

    suspend fun deleteVibes(placeId: String): VibePlace = parsePlace(
        request(
            method = "DELETE",
            path = "/ratings/${encodePath(placeId)}",
            body = JSONObject(),
            includeDevice = true,
        ).getJSONObject("place"),
    )

    suspend fun accountEligibility(): AccountEligibility = parseEligibility(
        request("GET", "/account/eligibility", includeDevice = true).getJSONObject("account"),
    )

    suspend fun requestAccountSignup(email: String): AccountActionResult {
        val root = request(
            "POST",
            "/account/signup",
            body = JSONObject().put("email", email).put("device_id_hash", identityStore.deviceIdHash),
            includeDevice = true,
        )
        root.string("session_token")?.let { identityStore.accountSessionToken = it }
        return AccountActionResult(
            status = root.string("status").orEmpty(),
            message = root.string("message") ?: "Check your email to finish creating your account.",
            sessionToken = root.string("session_token"),
            account = root.optJSONObject("account")?.let(::parseEligibility),
        )
    }

    suspend fun requestAccountLogin(email: String): AccountActionResult {
        val root = request("POST", "/account/login", body = JSONObject().put("email", email))
        return AccountActionResult(
            status = root.string("status").orEmpty(),
            message = root.string("message") ?: "Check your email to finish signing in.",
        )
    }

    suspend fun logout(): AccountActionResult {
        val root = request("POST", "/account/logout", body = JSONObject())
        identityStore.accountSessionToken = null
        return AccountActionResult(root.string("status").orEmpty(), root.string("message") ?: "Signed out.")
    }

    suspend fun deleteAccount(email: String): AccountActionResult {
        val root = request(
            "POST",
            "/account/delete",
            body = JSONObject().put("email", email).put("device_id_hash", identityStore.deviceIdHash),
            includeDevice = true,
        )
        if (root.optBoolean("deleted")) identityStore.accountSessionToken = null
        return AccountActionResult(root.string("status").orEmpty(), root.string("message") ?: "Account deletion requested.")
    }

    suspend fun recordAnalytics(eventName: String, properties: Map<String, String> = emptyMap()) {
        runCatching {
            request(
                "POST",
                "/analytics/events",
                body = JSONObject().apply {
                    put("event_name", eventName)
                    put("platform", "android")
                    if (properties.isNotEmpty()) put("properties", JSONObject(properties))
                },
                includeDevice = true,
            )
        }
    }

    fun acceptAccountSession(token: String) {
        if (token.isNotBlank()) identityStore.accountSessionToken = token
    }

    private suspend fun request(
        method: String,
        path: String,
        query: Map<String, String> = emptyMap(),
        body: JSONObject? = null,
        includeDevice: Boolean = false,
    ): JSONObject = withContext(Dispatchers.IO) {
        val allQuery = query + ("taxonomy_version" to taxonomyVersion)
        val queryString = allQuery.entries.joinToString("&") { (key, value) ->
            "${urlEncode(key)}=${urlEncode(value)}"
        }
        val connection = URI.create("$baseUrl$path?$queryString").toURL().openConnection() as HttpURLConnection
        try {
            connection.requestMethod = method
            connection.connectTimeout = 15_000
            connection.readTimeout = 20_000
            connection.setRequestProperty("Accept", "application/json")
            connection.setRequestProperty("X-Vibe-Taxonomy-Version", taxonomyVersion)
            connection.setRequestProperty("X-Vibe-Source", "android")
            connection.setRequestProperty("X-Vibe-App-Version", "${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})")
            if (BuildConfig.BETA_ACCESS_TOKEN.isNotBlank()) {
                connection.setRequestProperty("X-Vibe-Beta-Token", BuildConfig.BETA_ACCESS_TOKEN)
            }
            if (includeDevice) connection.setRequestProperty("X-Vibe-Device-ID-Hash", identityStore.deviceIdHash)
            identityStore.accountSessionToken?.takeIf(String::isNotBlank)?.let {
                connection.setRequestProperty("Authorization", "Bearer $it")
            }
            if (body != null) {
                connection.doOutput = true
                connection.setRequestProperty("Content-Type", "application/json")
                connection.outputStream.use { it.write(body.toString().toByteArray(StandardCharsets.UTF_8)) }
            }

            val status = connection.responseCode
            val stream = if (status in 200..299) connection.inputStream else connection.errorStream
            val text = stream?.bufferedReader()?.use { it.readText() }.orEmpty()
            val parsed = if (text.isBlank()) JSONObject() else JSONObject(text)
            if (status !in 200..299) {
                throw VibesApiException(parsed.string("error") ?: "The vibe wires got crossed. ($status)")
            }
            parsed
        } catch (error: VibesApiException) {
            throw error
        } catch (error: IOException) {
            throw VibesApiException("VIBES Y'ALL couldn't reach the map. Check your connection and try again.", error)
        } finally {
            connection.disconnect()
        }
    }

    private fun parsePlace(value: JSONObject): VibePlace {
        val stats = value.optJSONObject("stats")?.let(::parseStats)
        val rating = (value.optJSONObject("my_rating") ?: value.optJSONObject("my_vibe_event"))?.let(::parseRating)
        return VibePlace(
            id = value.string("id").orEmpty(),
            provider = value.string("provider"),
            providerPlaceId = value.string("provider_place_id"),
            name = value.string("name") ?: "Unknown place",
            latitude = value.optDouble("latitude"),
            longitude = value.optDouble("longitude"),
            streetAddress = value.string("street_address"),
            category = value.string("category"),
            primaryCategory = value.string("primary_category"),
            providerCategory = value.string("provider_category"),
            city = value.string("city"),
            region = value.string("region"),
            country = value.string("country"),
            stats = stats,
            distanceMeters = value.nullableDouble("distance_meters"),
            myRating = rating,
        )
    }

    private fun parseStats(value: JSONObject): PlaceStats {
        val topVibes = value.optJSONArray("top_vibes").orEmptyObjects().mapNotNull { item ->
            val tag = VibeTag.find(item.string("vibe_tag_id") ?: item.string("slug") ?: item.string("vibe_tag"))
                ?: return@mapNotNull null
            VibeBreakdown(tag, item.optInt("count"), item.optInt("percentage"))
        }.sortedWith(compareByDescending<VibeBreakdown> { it.percentage }.thenByDescending { it.count })
        val fallbackTop = if (topVibes.isEmpty()) {
            VibeTag.find(value.string("top_vibe_tag_id") ?: value.string("top_vibe_tag"))?.let {
                listOf(VibeBreakdown(it, value.optInt("rating_count"), value.optDouble("top_vibe_percent", 100.0).toInt()))
            }.orEmpty()
        } else topVibes
        return PlaceStats(
            ratingCount = value.optInt("rating_count", value.optInt("total_vibes")),
            averageScore = value.optDouble("average_score"),
            topVibes = fallbackTop,
            recentVibeCount = value.optInt("recent_vibe_count", value.optInt("last_30_day_total_vibes")),
            recentPositivePercentage = value.optInt("recent_positive_percentage"),
        )
    }

    private fun parseRating(value: JSONObject): VibeRating {
        val rawTags = value.optJSONArray("vibe_tag_ids")
            ?: value.optJSONArray("vibe_tags")
            ?: JSONArray().apply {
                listOf("primary_vibe_tag_id", "secondary_vibe_tag_id", "third_vibe_tag_id", "vibe_tag").forEach { key ->
                    value.string(key)?.let(::put)
                }
            }
        val tags = rawTags.strings().mapNotNull(VibeTag::find).distinctBy(VibeTag::id)
        return VibeRating(
            id = value.string("id") ?: "rating:${value.string("place_id")}",
            placeId = value.string("place_id").orEmpty(),
            vibeTags = tags,
        )
    }

    private fun parseEligibility(value: JSONObject): AccountEligibility = AccountEligibility(
        eligible = value.optBoolean("eligible"),
        threshold = value.optInt("threshold", 10),
        vibedPlaceCount = value.optInt("vibed_place_count"),
        remainingPlaces = value.optInt("remaining_places"),
        benefits = value.optJSONArray("benefits").strings(),
        emailVerified = value.optJSONObject("profile")?.optBoolean("email_verified") == true,
    )

    private fun JSONObject.string(key: String): String? = if (isNull(key)) null else optString(key).trim().takeIf { it.isNotEmpty() }
    private fun JSONObject.nullableDouble(key: String): Double? = if (isNull(key) || !has(key)) null else optDouble(key).takeUnless(Double::isNaN)
    private fun JSONArray?.orEmptyObjects(): List<JSONObject> = this?.objects().orEmpty()
    private fun JSONArray?.strings(): List<String> = buildList {
        val source = this@strings ?: return@buildList
        for (index in 0 until source.length()) source.optString(index).takeIf(String::isNotBlank)?.let(::add)
    }
    private fun JSONArray.objects(): List<JSONObject> = buildList {
        for (index in 0 until length()) optJSONObject(index)?.let(::add)
    }
    private fun urlEncode(value: String): String = URLEncoder.encode(value, StandardCharsets.UTF_8.toString())
    private fun encodePath(value: String): String = urlEncode(value).replace("+", "%20")
}

class VibesApiException(message: String, cause: Throwable? = null) : Exception(message, cause)
