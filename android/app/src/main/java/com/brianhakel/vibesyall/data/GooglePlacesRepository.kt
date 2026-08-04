package com.brianhakel.vibesyall.data

import android.content.Context
import android.util.Log
import com.brianhakel.vibesyall.BuildConfig
import com.google.android.gms.maps.model.LatLng
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.AutocompleteSessionToken
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.net.FetchPlaceRequest
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsRequest
import com.google.android.libraries.places.api.net.PlacesClient
import kotlinx.coroutines.tasks.await

class GooglePlacesRepository(context: Context) {
    private val enabled = BuildConfig.MAPS_API_KEY.isNotBlank()
    private val client: PlacesClient?
    private var sessionToken: AutocompleteSessionToken? = null

    init {
        if (enabled && !Places.isInitialized()) {
            Places.initializeWithNewPlacesApiEnabled(context.applicationContext, BuildConfig.MAPS_API_KEY)
        }
        client = if (enabled) Places.createClient(context.applicationContext) else null
    }

    suspend fun predictions(query: String, origin: LatLng): List<PlacePrediction> {
        val placesClient = client ?: return emptyList()
        if (query.isBlank()) {
            sessionToken = null
            return emptyList()
        }
        val token = sessionToken ?: AutocompleteSessionToken.newInstance().also { sessionToken = it }
        val request = FindAutocompletePredictionsRequest.builder()
            .setQuery(query)
            .setOrigin(origin)
            .setSessionToken(token)
            .build()
        return try {
            placesClient.findAutocompletePredictions(request).await().autocompletePredictions.map { prediction ->
                PlacePrediction(
                    placeId = prediction.placeId,
                    title = prediction.getPrimaryText(null).toString(),
                    subtitle = prediction.getSecondaryText(null).toString(),
                    distanceMeters = prediction.distanceMeters,
                )
            }
        } catch (error: Exception) {
            Log.w("VibesPlaces", "Google Places autocomplete failed: ${error.message}", error)
            throw error
        }
    }

    suspend fun placeCandidate(placeId: String): PlaceCandidate {
        val placesClient = client ?: throw IllegalStateException(
            "Add MAPS_API_KEY to android/local.properties to use Google place search.",
        )
        val fields = listOf(
            Place.Field.ID,
            Place.Field.DISPLAY_NAME,
            Place.Field.FORMATTED_ADDRESS,
            Place.Field.LOCATION,
            Place.Field.PRIMARY_TYPE,
            Place.Field.ADDRESS_COMPONENTS,
        )
        val request = FetchPlaceRequest.builder(placeId, fields)
            .setSessionToken(sessionToken)
            .build()
        val place = placesClient.fetchPlace(request).await().place
        sessionToken = null
        return place.toCandidate(placeId)
    }

    suspend fun pointOfInterestCandidate(placeId: String, name: String, coordinate: LatLng): PlaceCandidate =
        runCatching { placeCandidate(placeId) }.getOrElse {
            PlaceCandidate(
                providerPlaceId = placeId,
                name = name,
                latitude = coordinate.latitude,
                longitude = coordinate.longitude,
                streetAddress = null,
                category = null,
                primaryCategory = null,
                providerCategory = null,
                city = null,
                region = null,
                country = null,
            )
        }

    private fun Place.toCandidate(fallbackId: String): PlaceCandidate {
        val components = addressComponents?.asList().orEmpty()
        fun component(type: String): String? = components.firstOrNull { type in it.types }?.name
        val streetAddress = listOfNotNull(component("street_number"), component("route"))
            .joinToString(" ")
            .ifBlank { formattedAddress?.substringBefore(',') }
        return PlaceCandidate(
            provider = "google",
            providerPlaceId = id ?: fallbackId,
            name = displayName ?: "Unknown place",
            latitude = location?.latitude ?: 0.0,
            longitude = location?.longitude ?: 0.0,
            streetAddress = streetAddress,
            category = primaryType?.replace('_', ' ')?.replaceFirstChar(Char::uppercase),
            primaryCategory = primaryType?.replace('_', ' ')?.replaceFirstChar(Char::uppercase),
            providerCategory = primaryType,
            city = component("locality") ?: component("postal_town") ?: component("sublocality"),
            region = component("administrative_area_level_1"),
            country = component("country"),
        )
    }
}
