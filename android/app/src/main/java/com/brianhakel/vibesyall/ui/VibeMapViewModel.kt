package com.brianhakel.vibesyall.ui

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.brianhakel.vibesyall.BuildConfig
import com.brianhakel.vibesyall.data.AccountEligibility
import com.brianhakel.vibesyall.data.GooglePlacesRepository
import com.brianhakel.vibesyall.data.LocationRepository
import com.brianhakel.vibesyall.data.MapCellCluster
import com.brianhakel.vibesyall.data.PlacePrediction
import com.brianhakel.vibesyall.data.RatingResult
import com.brianhakel.vibesyall.data.VibePlace
import com.brianhakel.vibesyall.data.VibeTag
import com.brianhakel.vibesyall.data.VibesApi
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.PointOfInterest
import kotlinx.coroutines.Job
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

enum class MapDisplayStyle { Dark, Standard, Satellite }

sealed interface SearchResultItem {
    val key: String

    data class CommunityPlace(val place: VibePlace) : SearchResultItem {
        override val key: String = "community:${place.id}"
    }

    data class GooglePlace(val prediction: PlacePrediction) : SearchResultItem {
        override val key: String = "google:${prediction.placeId}"
    }
}

data class VibeMapUiState(
    val tags: List<VibeTag> = VibeTag.defaults,
    val selectedFilterIds: Set<String> = emptySet(),
    val nearbyPlaces: List<VibePlace> = emptyList(),
    val mapCells: List<MapCellCluster> = emptyList(),
    val searchQuery: String = "",
    val searchResults: List<SearchResultItem> = emptyList(),
    val isSearching: Boolean = false,
    val isLoadingMap: Boolean = true,
    val selectedPlace: VibePlace? = null,
    val ratingPlace: VibePlace? = null,
    val selectedRatingTagIds: Set<String> = emptySet(),
    val ratingResult: RatingResult? = null,
    val accountEligibility: AccountEligibility? = null,
    val showAccountSheet: Boolean = false,
    val accountMessage: String? = null,
    val panelExpanded: Boolean = true,
    val mapStyle: MapDisplayStyle = MapDisplayStyle.Dark,
    val cameraCenter: LatLng = LatLng(30.2672, -97.7431),
    val cameraZoom: Float = 9f,
    val userLocation: LatLng? = null,
    val locationPermissionGranted: Boolean = false,
    val mapsKeyMissing: Boolean = BuildConfig.MAPS_API_KEY.isBlank(),
    val errorMessage: String? = null,
)

class VibeMapViewModel(
    private val api: VibesApi,
    private val placesRepository: GooglePlacesRepository,
    private val locationRepository: LocationRepository,
) : ViewModel() {
    private val mutableState = MutableStateFlow(VibeMapUiState())
    val state: StateFlow<VibeMapUiState> = mutableState.asStateFlow()

    private var viewportJob: Job? = null
    private var clusterFocusJob: Job? = null
    private var searchJob: Job? = null
    private var lastViewportKey: String? = null
    private var pendingClusterFocus: Pair<LatLng, Float>? = null

    init {
        viewModelScope.launch {
            api.recordAnalytics("app_opened")
            runCatching { api.fetchTags() }
                .onSuccess { tags -> mutableState.update { it.copy(tags = tags) } }
            refreshLocationIfAvailable()
            loadViewport(mutableState.value.cameraCenter, mutableState.value.cameraZoom, immediate = true)
        }
    }

    fun onLocationPermissionResult(granted: Boolean) {
        mutableState.update { it.copy(locationPermissionGranted = granted) }
        if (granted) viewModelScope.launch { refreshLocationIfAvailable(centerMap = true) }
    }

    fun requestCurrentLocation() {
        viewModelScope.launch { refreshLocationIfAvailable(centerMap = true) }
    }

    private suspend fun refreshLocationIfAvailable(centerMap: Boolean = false) {
        val granted = locationRepository.hasPermission()
        val location = if (granted) locationRepository.currentLocation() else null
        mutableState.update { current ->
            current.copy(
                locationPermissionGranted = granted,
                userLocation = location ?: current.userLocation,
                cameraCenter = if (centerMap && location != null) location else current.cameraCenter,
                cameraZoom = if (centerMap && location != null) 12f else current.cameraZoom,
            )
        }
        if (centerMap && location != null) loadViewport(location, 12f, immediate = true)
    }

    fun onCameraIdle(center: LatLng, zoom: Float) {
        val completedClusterFocus = pendingClusterFocus?.let { (target, targetZoom) ->
            kotlin.math.abs(center.latitude - target.latitude) < 0.02 &&
                kotlin.math.abs(center.longitude - target.longitude) < 0.02 &&
                zoom >= targetZoom - 0.35f
        } == true
        if (completedClusterFocus) pendingClusterFocus = null
        mutableState.update { it.copy(cameraCenter = center, cameraZoom = zoom) }
        loadViewport(center, zoom, immediate = completedClusterFocus)
    }

    fun focusMapCell(cell: MapCellCluster) {
        val center = LatLng(cell.latitude, cell.longitude)
        val zoom = maxOf(mutableState.value.cameraZoom + 2.5f, 11f).coerceAtMost(14f)
        pendingClusterFocus = center to zoom
        mutableState.update {
            it.copy(
                cameraCenter = center,
                cameraZoom = zoom,
                mapCells = emptyList(),
                panelExpanded = false,
                selectedPlace = null,
            )
        }
        lastViewportKey = null
        clusterFocusJob?.cancel()
        clusterFocusJob = viewModelScope.launch {
            delay(700)
            val radius = radiusForZoom(zoom)
            val filter = selectedFilter()
            runCatching { api.fetchNearby(center.latitude, center.longitude, radius, filter, includeDevice = false) }
                .onSuccess { places ->
                    mutableState.update {
                        it.copy(
                            nearbyPlaces = places,
                            mapCells = emptyList(),
                            isLoadingMap = false,
                            errorMessage = null,
                        )
                    }
                    lastViewportKey = "%.3f|%.3f|%.0f|%s".format(
                        center.latitude,
                        center.longitude,
                        radius,
                        filter?.id.orEmpty(),
                    )
                }
                .onFailure(::showError)
        }
    }

    private fun loadViewport(center: LatLng, zoom: Float, immediate: Boolean = false) {
        val radius = radiusForZoom(zoom)
        val filter = selectedFilter()
        val key = "%.3f|%.3f|%.0f|%s".format(center.latitude, center.longitude, radius, filter?.id.orEmpty())
        if (key == lastViewportKey && !immediate) return
        viewportJob?.cancel()
        viewportJob = viewModelScope.launch {
            if (!immediate) delay(350)
            lastViewportKey = key
            mutableState.update { it.copy(isLoadingMap = true, errorMessage = null) }
            runCatching {
                if (radius >= 240_000) {
                    val cellSize = when {
                        radius < 350_000 -> 50_000.0
                        radius < 700_000 -> 70_000.0
                        radius < 1_200_000 -> 95_000.0
                        radius < 1_800_000 -> 145_000.0
                        else -> 220_000.0
                    }
                    val cells = api.fetchMapCells(center.latitude, center.longitude, radius, cellSize, filter, mutableState.value.tags)
                    mutableState.update { it.copy(mapCells = cells.take(56), nearbyPlaces = emptyList(), isLoadingMap = false) }
                } else {
                    val places = api.fetchNearby(center.latitude, center.longitude, radius, filter, includeDevice = false)
                    mutableState.update { it.copy(nearbyPlaces = places, mapCells = emptyList(), isLoadingMap = false) }
                }
            }.onFailure(::showError)
        }
    }

    fun toggleFilter(tag: VibeTag?) {
        mutableState.update { current ->
            val selected = if (tag == null) emptySet() else if (tag.id in current.selectedFilterIds) emptySet() else setOf(tag.id)
            current.copy(selectedFilterIds = selected)
        }
        lastViewportKey = null
        loadViewport(mutableState.value.cameraCenter, mutableState.value.cameraZoom, immediate = true)
        if (mutableState.value.searchQuery.isNotBlank()) updateSearchQuery(mutableState.value.searchQuery)
    }

    fun updateSearchQuery(query: String) {
        mutableState.update { it.copy(searchQuery = query) }
        searchJob?.cancel()
        if (query.trim().length < 2) {
            mutableState.update { it.copy(searchResults = emptyList(), isSearching = false) }
            return
        }
        searchJob = viewModelScope.launch {
            delay(280)
            mutableState.update { it.copy(isSearching = true, errorMessage = null) }
            val center = mutableState.value.cameraCenter
            val saved = async { runCatching { api.searchSavedPlaces(query.trim(), center.latitude, center.longitude) }.getOrDefault(emptyList()) }
            val google = async {
                if (mutableState.value.selectedFilterIds.isEmpty()) {
                    runCatching { placesRepository.predictions(query.trim(), center) }.getOrDefault(emptyList())
                } else emptyList()
            }
            val savedPlaces = saved.await().filter { place ->
                selectedFilter()?.let { filter -> place.stats?.topVibes?.any { it.tag.id == filter.id } == true } ?: true
            }
            val savedProviderIds = savedPlaces.mapNotNull(VibePlace::providerPlaceId).toSet()
            val results = buildList<SearchResultItem> {
                addAll(savedPlaces.map(SearchResultItem::CommunityPlace))
                addAll(google.await().filterNot { it.placeId in savedProviderIds }.map(SearchResultItem::GooglePlace))
            }
            mutableState.update { it.copy(searchResults = results.take(12), isSearching = false) }
            api.recordAnalytics("search_completed", mapOf("result_count" to results.size.toString()))
        }
    }

    fun clearSearch() {
        searchJob?.cancel()
        mutableState.update { it.copy(searchQuery = "", searchResults = emptyList(), isSearching = false) }
    }

    fun selectSearchResult(result: SearchResultItem) {
        viewModelScope.launch {
            mutableState.update { it.copy(isSearching = true, errorMessage = null) }
            runCatching {
                when (result) {
                    is SearchResultItem.CommunityPlace -> api.fetchPlace(result.place.id)
                    is SearchResultItem.GooglePlace -> {
                        val candidate = placesRepository.placeCandidate(result.prediction.placeId)
                        val saved = api.upsertPlace(candidate)
                        api.fetchPlace(saved.id)
                    }
                }
            }.onSuccess(::selectPlace).onFailure(::showError)
            mutableState.update { it.copy(isSearching = false) }
        }
    }

    fun selectNearbyPlace(place: VibePlace) {
        viewModelScope.launch {
            runCatching { api.fetchPlace(place.id) }.onSuccess(::selectPlace).onFailure(::showError)
        }
    }

    fun selectMapPoint(point: PointOfInterest) {
        viewModelScope.launch {
            mutableState.update { it.copy(isLoadingMap = true, errorMessage = null) }
            runCatching {
                val candidate = placesRepository.pointOfInterestCandidate(point.placeId, point.name, point.latLng)
                val saved = api.upsertPlace(candidate)
                api.fetchPlace(saved.id)
            }.onSuccess(::selectPlace).onFailure(::showError)
            mutableState.update { it.copy(isLoadingMap = false) }
        }
    }

    private fun selectPlace(place: VibePlace) {
        mutableState.update {
            it.copy(
                selectedPlace = place,
                searchQuery = "",
                searchResults = emptyList(),
                panelExpanded = false,
                cameraCenter = LatLng(place.latitude, place.longitude),
                cameraZoom = maxOf(it.cameraZoom, 14f),
            )
        }
        viewModelScope.launch { api.recordAnalytics("place_selected", mapOf("place_id" to place.id)) }
    }

    fun clearSelectedPlace() {
        mutableState.update { it.copy(selectedPlace = null, ratingPlace = null, ratingResult = null, panelExpanded = true) }
    }

    fun openRating(place: VibePlace = requireNotNull(mutableState.value.selectedPlace)) {
        mutableState.update {
            it.copy(
                ratingPlace = place,
                selectedRatingTagIds = place.myRating?.vibeTags?.map(VibeTag::id)?.toSet().orEmpty(),
                ratingResult = null,
            )
        }
    }

    fun toggleRatingTag(tag: VibeTag) {
        mutableState.update { current ->
            val next = current.selectedRatingTagIds.toMutableSet()
            if (!next.add(tag.id)) next.remove(tag.id)
            if (next.size > 3) return@update current
            current.copy(selectedRatingTagIds = next)
        }
    }

    fun submitRating() {
        val place = mutableState.value.ratingPlace ?: return
        val tags = mutableState.value.tags.filter { it.id in mutableState.value.selectedRatingTagIds }
        viewModelScope.launch {
            mutableState.update { it.copy(isLoadingMap = true, errorMessage = null) }
            runCatching { api.submitVibes(place.id, tags) }
                .onSuccess { result ->
                    replacePlace(result.place)
                    mutableState.update { it.copy(ratingPlace = result.place, selectedPlace = result.place, ratingResult = result) }
                    maybeOfferAccount()
                }
                .onFailure(::showError)
            mutableState.update { it.copy(isLoadingMap = false) }
        }
    }

    fun deleteRating() {
        val place = mutableState.value.ratingPlace ?: return
        viewModelScope.launch {
            mutableState.update { it.copy(isLoadingMap = true, errorMessage = null) }
            runCatching { api.deleteVibes(place.id) }
                .onSuccess { updated ->
                    replacePlace(updated)
                    mutableState.update {
                        it.copy(
                            ratingPlace = updated,
                            selectedPlace = updated,
                            selectedRatingTagIds = emptySet(),
                            ratingResult = null,
                        )
                    }
                }.onFailure(::showError)
            mutableState.update { it.copy(isLoadingMap = false) }
        }
    }

    fun closeRating() {
        mutableState.update { it.copy(ratingPlace = null, selectedRatingTagIds = emptySet(), ratingResult = null) }
    }

    fun setPanelExpanded(expanded: Boolean) {
        mutableState.update { it.copy(panelExpanded = expanded) }
    }

    fun cycleMapStyle() {
        mutableState.update { current ->
            current.copy(
                mapStyle = when (current.mapStyle) {
                    MapDisplayStyle.Dark -> MapDisplayStyle.Standard
                    MapDisplayStyle.Standard -> MapDisplayStyle.Satellite
                    MapDisplayStyle.Satellite -> MapDisplayStyle.Dark
                },
            )
        }
    }

    fun openAccount() {
        viewModelScope.launch {
            runCatching { api.accountEligibility() }
                .onSuccess { eligibility -> mutableState.update { it.copy(accountEligibility = eligibility, showAccountSheet = true) } }
                .onFailure(::showError)
        }
    }

    fun closeAccount() {
        mutableState.update { it.copy(showAccountSheet = false, accountMessage = null) }
    }

    fun signup(email: String) = accountAction { api.requestAccountSignup(email) }
    fun login(email: String) = accountAction { api.requestAccountLogin(email) }
    fun logout() = accountAction { api.logout() }
    fun deleteAccount(email: String) = accountAction { api.deleteAccount(email) }

    private fun accountAction(action: suspend () -> com.brianhakel.vibesyall.data.AccountActionResult) {
        viewModelScope.launch {
            runCatching { action() }
                .onSuccess { result ->
                    mutableState.update {
                        it.copy(accountMessage = result.message, accountEligibility = result.account ?: it.accountEligibility)
                    }
                }.onFailure(::showError)
        }
    }

    fun handleDeepLink(uri: Uri?) {
        uri ?: return
        val token = uri.getQueryParameter("session") ?: return
        api.acceptAccountSession(token)
        mutableState.update { it.copy(accountMessage = "Your VIBES Y'ALL account is connected on this device.") }
        openAccount()
    }

    fun dismissError() {
        mutableState.update { it.copy(errorMessage = null) }
    }

    private suspend fun maybeOfferAccount() {
        runCatching { api.accountEligibility() }.onSuccess { eligibility ->
            if (eligibility.eligible && !eligibility.emailVerified) {
                mutableState.update { it.copy(accountEligibility = eligibility, showAccountSheet = true) }
            }
        }
    }

    private fun replacePlace(updated: VibePlace) {
        mutableState.update { current ->
            current.copy(nearbyPlaces = current.nearbyPlaces.map { if (it.id == updated.id) updated else it })
        }
    }

    private fun selectedFilter(): VibeTag? = mutableState.value.tags.firstOrNull { it.id in mutableState.value.selectedFilterIds }

    private fun radiusForZoom(zoom: Float): Double = when {
        zoom >= 14 -> 10_000.0
        zoom >= 12 -> 35_000.0
        zoom >= 10 -> 110_000.0
        zoom >= 8 -> 300_000.0
        zoom >= 6 -> 800_000.0
        zoom >= 4 -> 1_600_000.0
        else -> 2_500_000.0
    }

    private fun showError(error: Throwable) {
        if (error is CancellationException) return
        mutableState.update { it.copy(isLoadingMap = false, isSearching = false, errorMessage = error.message ?: "Something went sideways.") }
    }

    class Factory(
        private val api: VibesApi,
        private val placesRepository: GooglePlacesRepository,
        private val locationRepository: LocationRepository,
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            VibeMapViewModel(api, placesRepository, locationRepository) as T
    }
}
