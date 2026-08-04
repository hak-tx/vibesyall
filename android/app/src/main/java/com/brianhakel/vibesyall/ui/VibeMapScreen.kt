@file:OptIn(
    androidx.compose.material3.ExperimentalMaterial3Api::class,
    androidx.compose.foundation.layout.ExperimentalLayoutApi::class,
)

package com.brianhakel.vibesyall.ui

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Directions
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.brianhakel.vibesyall.R
import com.brianhakel.vibesyall.data.MapCellCluster
import com.brianhakel.vibesyall.data.PlacePrediction
import com.brianhakel.vibesyall.data.VibePlace
import com.brianhakel.vibesyall.data.VibeTag
import com.brianhakel.vibesyall.data.formatDistance
import com.brianhakel.vibesyall.ui.theme.BrandNavy
import com.brianhakel.vibesyall.ui.theme.BrandYellow
import com.brianhakel.vibesyall.ui.theme.Ink
import com.brianhakel.vibesyall.ui.theme.MutedInk
import com.brianhakel.vibesyall.ui.theme.Sheet
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.BitmapDescriptorFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MapStyleOptions
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.MapProperties
import com.google.maps.android.compose.MapType
import com.google.maps.android.compose.MapUiSettings
import com.google.maps.android.compose.Marker
import com.google.maps.android.compose.MarkerState
import com.google.maps.android.compose.rememberCameraPositionState
import kotlinx.coroutines.delay

private val PanelShape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)

@Composable
fun VibeMapScreen(
    viewModel: VibeMapViewModel,
    requestLocationPermission: () -> Unit,
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current

    LaunchedEffect(Unit) {
        if (!state.locationPermissionGranted) requestLocationPermission()
    }
    LaunchedEffect(state.errorMessage) {
        state.errorMessage?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.dismissError()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = Sheet,
    ) { scaffoldPadding ->
        Box(Modifier.fillMaxSize().padding(bottom = scaffoldPadding.calculateBottomPadding())) {
            VibesGoogleMap(state = state, viewModel = viewModel)

            Column(
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .padding(top = WindowInsets.statusBars.asPaddingValues().calculateTopPadding() + 8.dp),
            ) {
                SearchBar(
                    query = state.searchQuery,
                    onQueryChange = viewModel::updateSearchQuery,
                    onClear = viewModel::clearSearch,
                    onAccount = viewModel::openAccount,
                )
                VibeFilters(
                    tags = state.tags,
                    selectedIds = state.selectedFilterIds,
                    onSelect = viewModel::toggleFilter,
                )
                SearchResults(
                    query = state.searchQuery,
                    results = state.searchResults,
                    isSearching = state.isSearching,
                    mapsKeyMissing = state.mapsKeyMissing,
                    onSelect = viewModel::selectSearchResult,
                )
            }

            MapControls(
                style = state.mapStyle,
                onStyle = viewModel::cycleMapStyle,
                onLocation = {
                    if (state.locationPermissionGranted) viewModel.requestCurrentLocation() else requestLocationPermission()
                },
                modifier = Modifier
                    .align(Alignment.CenterEnd)
                    .padding(end = 14.dp, bottom = if (state.panelExpanded) 190.dp else 80.dp),
            )

            if (state.mapsKeyMissing) {
                MissingMapsKeyBanner(
                    Modifier
                        .align(Alignment.Center)
                        .padding(horizontal = 28.dp),
                )
            }

            if (state.selectedPlace != null) {
                SelectedPlacePanel(
                    place = state.selectedPlace!!,
                    onClose = viewModel::clearSelectedPlace,
                    onRate = { viewModel.openRating() },
                    onDirections = { openDirections(context, state.selectedPlace!!) },
                    onShare = { sharePlace(context, state.selectedPlace!!) },
                    modifier = Modifier.align(Alignment.BottomCenter),
                )
            } else {
                NearbyPanel(
                    places = state.nearbyPlaces,
                    cells = state.mapCells,
                    expanded = state.panelExpanded,
                    loading = state.isLoadingMap,
                    onExpandChange = viewModel::setPanelExpanded,
                    onSelect = viewModel::selectNearbyPlace,
                    modifier = Modifier.align(Alignment.BottomCenter),
                )
            }
        }
    }

    state.ratingPlace?.let { place ->
        RatingSheet(
            place = place,
            tags = state.tags,
            selectedIds = state.selectedRatingTagIds,
            submitted = state.ratingResult != null,
            loading = state.isLoadingMap,
            onToggle = viewModel::toggleRatingTag,
            onSubmit = viewModel::submitRating,
            onDelete = viewModel::deleteRating,
            onShare = { sharePlace(context, state.ratingResult?.place ?: place) },
            onDismiss = viewModel::closeRating,
        )
    }

    if (state.showAccountSheet) {
        AccountSheet(
            eligibility = state.accountEligibility,
            message = state.accountMessage,
            onSignup = viewModel::signup,
            onLogin = viewModel::login,
            onLogout = viewModel::logout,
            onDelete = viewModel::deleteAccount,
            onDismiss = viewModel::closeAccount,
        )
    }
}

@Composable
private fun VibesGoogleMap(state: VibeMapUiState, viewModel: VibeMapViewModel) {
    val cameraState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(state.cameraCenter, state.cameraZoom)
    }
    val mapType = if (state.mapStyle == MapDisplayStyle.Satellite) MapType.HYBRID else MapType.NORMAL
    val darkStyle = if (state.mapStyle == MapDisplayStyle.Dark) remember { MapStyleOptions(DarkMapStyle) } else null
    val properties = MapProperties(
        isMyLocationEnabled = state.locationPermissionGranted,
        mapType = mapType,
        mapStyleOptions = darkStyle,
    )
    val uiSettings = MapUiSettings(
        compassEnabled = false,
        myLocationButtonEnabled = false,
        zoomControlsEnabled = false,
        mapToolbarEnabled = false,
    )

    LaunchedEffect(state.cameraCenter, state.cameraZoom) {
        val current = cameraState.position
        val target = state.cameraCenter
        if (kotlin.math.abs(current.target.latitude - target.latitude) > 0.0001 ||
            kotlin.math.abs(current.target.longitude - target.longitude) > 0.0001 ||
            kotlin.math.abs(current.zoom - state.cameraZoom) > 0.2f
        ) {
            cameraState.animate(CameraUpdateFactory.newLatLngZoom(target, state.cameraZoom), 450)
        }
    }
    LaunchedEffect(cameraState.isMoving) {
        if (!cameraState.isMoving) {
            delay(80)
            viewModel.onCameraIdle(cameraState.position.target, cameraState.position.zoom)
        }
    }

    GoogleMap(
        modifier = Modifier.fillMaxSize(),
        cameraPositionState = cameraState,
        properties = properties,
        uiSettings = uiSettings,
        onMapClick = { viewModel.setPanelExpanded(false) },
        onPOIClick = viewModel::selectMapPoint,
    ) {
        state.nearbyPlaces.forEach { place ->
            Marker(
                state = MarkerState(LatLng(place.latitude, place.longitude)),
                title = place.name,
                snippet = place.topVibe?.let { "${it.tag.emoji} ${it.tag.displayName} · ${place.vibeCount} vibes" },
                icon = BitmapDescriptorFactory.defaultMarker(
                    place.topVibe?.tag?.color?.let(::colorToMarkerHue) ?: BitmapDescriptorFactory.HUE_AZURE,
                ),
                onClick = {
                    viewModel.selectNearbyPlace(place)
                    true
                },
            )
        }
        state.mapCells.forEach { cell ->
            Marker(
                state = MarkerState(LatLng(cell.latitude, cell.longitude)),
                title = "${cell.count} vibed places",
                snippet = cell.topVibe?.let { "${it.emoji} ${it.displayName} · ${cell.totalVibes} vibes" },
                icon = BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_ORANGE),
            )
        }
    }
}

private fun colorToMarkerHue(color: Color): Float {
    val hsv = FloatArray(3)
    android.graphics.Color.colorToHSV(color.toArgb(), hsv)
    return hsv[0]
}

@Composable
private fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    onClear: () -> Unit,
    onAccount: () -> Unit,
) {
    val focus = LocalFocusManager.current
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Surface(
            modifier = Modifier.weight(1f),
            color = BrandNavy.copy(alpha = 0.94f),
            shape = RoundedCornerShape(18.dp),
            shadowElevation = 8.dp,
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Image(
                    painter = painterResource(R.drawable.brand_logo),
                    contentDescription = "VIBES Y'ALL",
                    modifier = Modifier.size(38.dp).clip(CircleShape),
                )
                Spacer(Modifier.width(5.dp))
                OutlinedTextField(
                    value = query,
                    onValueChange = onQueryChange,
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    placeholder = { Text("Search places", color = BrandYellow.copy(alpha = 0.88f)) },
                    leadingIcon = { Icon(Icons.Default.Search, null, tint = BrandYellow) },
                    trailingIcon = if (query.isNotEmpty()) {
                        { IconButton(onClick = onClear) { Icon(Icons.Default.Clear, "Clear", tint = Color.White) } }
                    } else null,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                    keyboardActions = KeyboardActions(onSearch = { focus.clearFocus() }),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = Color.Transparent,
                        unfocusedBorderColor = Color.Transparent,
                        cursorColor = BrandYellow,
                    ),
                )
            }
        }
        FilledIconButton(
            onClick = onAccount,
            modifier = Modifier.size(48.dp),
            colors = IconButtonDefaults.filledIconButtonColors(containerColor = BrandNavy),
        ) {
            Icon(Icons.Default.Person, "Account", tint = BrandYellow)
        }
    }
}

@Composable
private fun VibeFilters(tags: List<VibeTag>, selectedIds: Set<String>, onSelect: (VibeTag?) -> Unit) {
    LazyRow(
        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
        contentPadding = PaddingValues(horizontal = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        item {
            FilterPill("All", "✦", selectedIds.isEmpty()) { onSelect(null) }
        }
        items(tags, key = VibeTag::id) { tag ->
            FilterPill(tag.displayName, tag.emoji, tag.id in selectedIds) { onSelect(tag) }
        }
    }
}

@Composable
private fun FilterPill(label: String, emoji: String, selected: Boolean, onClick: () -> Unit) {
    Surface(
        modifier = Modifier.clickable(onClick = onClick),
        color = if (selected) BrandNavy else Color.White.copy(alpha = 0.84f),
        contentColor = if (selected) Color.White else BrandNavy,
        border = if (selected) null else androidx.compose.foundation.BorderStroke(1.dp, BrandNavy.copy(alpha = 0.45f)),
        shape = RoundedCornerShape(50),
        shadowElevation = 2.dp,
    ) {
        Row(Modifier.padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(emoji, fontSize = 14.sp)
            Spacer(Modifier.width(5.dp))
            Text(label, fontWeight = FontWeight.SemiBold, fontSize = 13.sp)
        }
    }
}

@Composable
private fun SearchResults(
    query: String,
    results: List<SearchResultItem>,
    isSearching: Boolean,
    mapsKeyMissing: Boolean,
    onSelect: (SearchResultItem) -> Unit,
) {
    AnimatedVisibility(visible = query.length >= 2) {
        Card(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 8.dp).heightIn(max = 390.dp),
            colors = CardDefaults.cardColors(containerColor = Sheet.copy(alpha = 0.98f)),
            shape = RoundedCornerShape(20.dp),
            elevation = CardDefaults.cardElevation(10.dp),
        ) {
            when {
                isSearching -> Row(Modifier.padding(22.dp), verticalAlignment = Alignment.CenterVertically) {
                    CircularProgressIndicator(Modifier.size(22.dp), strokeWidth = 2.dp)
                    Spacer(Modifier.width(12.dp))
                    Text("Reading the map…")
                }
                results.isEmpty() -> Column(Modifier.padding(22.dp)) {
                    Text("No matching vibed places yet.", fontWeight = FontWeight.Bold)
                    Text(
                        if (mapsKeyMissing) "Add the Google Maps key to include every Google place."
                        else "Try another place name or move the map closer.",
                        color = MutedInk,
                        fontSize = 13.sp,
                    )
                }
                else -> LazyColumn {
                    items(results, key = SearchResultItem::key) { result ->
                        SearchResultRow(result, onClick = { onSelect(result) })
                        Divider(color = BrandNavy.copy(alpha = 0.08f))
                    }
                }
            }
        }
    }
}

@Composable
private fun SearchResultRow(result: SearchResultItem, onClick: () -> Unit) {
    val title: String
    val subtitle: String
    val distance: String?
    val vibe: String?
    when (result) {
        is SearchResultItem.CommunityPlace -> {
            title = result.place.name
            subtitle = result.place.locationLine.ifBlank { result.place.category.orEmpty() }
            distance = formatDistance(result.place.distanceMeters)
            vibe = result.place.topVibe?.let { "${it.tag.emoji} ${it.tag.displayName} ${it.percentage}%" }
        }
        is SearchResultItem.GooglePlace -> {
            title = result.prediction.title
            subtitle = result.prediction.subtitle
            distance = formatDistance(result.prediction.distanceMeters?.toDouble())
            vibe = null
        }
    }
    Row(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Default.LocationOn, null, tint = if (vibe != null) BrandNavy else MutedInk)
        Spacer(Modifier.width(11.dp))
        Column(Modifier.weight(1f)) {
            Text(title, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            if (subtitle.isNotBlank()) Text(subtitle, color = MutedInk, fontSize = 13.sp, maxLines = 2)
            vibe?.let { Text(it, color = BrandNavy, fontWeight = FontWeight.SemiBold, fontSize = 12.sp) }
        }
        distance?.let { Text(it, color = MutedInk, fontSize = 12.sp) }
    }
}

@Composable
private fun MapControls(
    style: MapDisplayStyle,
    onStyle: () -> Unit,
    onLocation: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(9.dp)) {
        FilledIconButton(
            onClick = onStyle,
            colors = IconButtonDefaults.filledIconButtonColors(containerColor = Color.White.copy(alpha = 0.92f)),
        ) {
            Icon(Icons.Default.Layers, "Map style: ${style.name}", tint = BrandNavy)
        }
        FilledIconButton(
            onClick = onLocation,
            colors = IconButtonDefaults.filledIconButtonColors(containerColor = Color.White.copy(alpha = 0.92f)),
        ) {
            Icon(Icons.Default.MyLocation, "My location", tint = Color(0xFF1877F2))
        }
    }
}

@Composable
private fun MissingMapsKeyBanner(modifier: Modifier = Modifier) {
    Surface(modifier, color = BrandNavy.copy(alpha = 0.94f), shape = RoundedCornerShape(18.dp), shadowElevation = 10.dp) {
        Column(Modifier.padding(18.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Text("Google Maps key needed", color = BrandYellow, fontWeight = FontWeight.Black, fontSize = 18.sp)
            Spacer(Modifier.height(4.dp))
            Text(
                "The Android app is built. Add MAPS_API_KEY to android/local.properties to render Google Maps and place search.",
                color = Color.White,
                fontSize = 13.sp,
            )
        }
    }
}

@Composable
private fun NearbyPanel(
    places: List<VibePlace>,
    cells: List<MapCellCluster>,
    expanded: Boolean,
    loading: Boolean,
    onExpandChange: (Boolean) -> Unit,
    onSelect: (VibePlace) -> Unit,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .height(if (expanded) 330.dp else 76.dp),
        shape = PanelShape,
        colors = CardDefaults.cardColors(containerColor = Sheet.copy(alpha = 0.98f)),
        elevation = CardDefaults.cardElevation(14.dp),
    ) {
        Column(Modifier.fillMaxSize().padding(bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding())) {
            Row(
                modifier = Modifier.fillMaxWidth().clickable { onExpandChange(!expanded) }.padding(horizontal = 20.dp, vertical = 13.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text("What's Nearby", fontWeight = FontWeight.Black, fontSize = 21.sp, color = Ink)
                    val summary = when {
                        cells.isNotEmpty() -> "${cells.sumOf(MapCellCluster::count)} vibed places across this map"
                        places.isNotEmpty() -> "${places.size} places with community vibes"
                        loading -> "Reading this part of the map…"
                        else -> "Be the first to add a vibe around here"
                    }
                    Text(summary, color = MutedInk, fontSize = 12.sp)
                }
                if (loading) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
                Icon(if (expanded) Icons.Default.KeyboardArrowDown else Icons.Default.KeyboardArrowUp, "Toggle")
            }
            if (expanded) {
                Divider(color = BrandNavy.copy(alpha = 0.08f))
                if (places.isEmpty()) {
                    Column(Modifier.fillMaxWidth().padding(24.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(if (cells.isNotEmpty()) "Zoom in to see individual places." else "No vibes here yet.", fontWeight = FontWeight.Bold)
                        Text("Search or tap any Google Maps POI to add the first one.", color = MutedInk, fontSize = 13.sp)
                    }
                } else {
                    LazyColumn(contentPadding = PaddingValues(bottom = 12.dp)) {
                        items(places, key = VibePlace::id) { place ->
                            NearbyPlaceRow(place = place, onClick = { onSelect(place) })
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun NearbyPlaceRow(place: VibePlace, onClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 20.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(color = place.topVibe?.tag?.color?.copy(alpha = 0.15f) ?: BrandNavy.copy(alpha = 0.08f), shape = CircleShape) {
            Text(place.topVibe?.tag?.emoji ?: "✦", modifier = Modifier.padding(10.dp), fontSize = 20.sp)
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(place.name, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(place.category ?: place.locationLine, color = MutedInk, fontSize = 12.sp, maxLines = 1)
            place.topVibe?.let { Text("${it.tag.displayName} ${it.percentage}%", color = it.tag.color, fontWeight = FontWeight.Bold, fontSize = 12.sp) }
        }
        Column(horizontalAlignment = Alignment.End) {
            formatDistance(place.distanceMeters)?.let { Text(it, color = MutedInk, fontSize = 11.sp) }
            Text("${place.vibeCount} ${if (place.vibeCount == 1) "vibe" else "vibes"}", color = BrandNavy, fontSize = 11.sp)
        }
    }
}

@Composable
private fun SelectedPlacePanel(
    place: VibePlace,
    onClose: () -> Unit,
    onRate: () -> Unit,
    onDirections: () -> Unit,
    onShare: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = PanelShape,
        colors = CardDefaults.cardColors(containerColor = Sheet.copy(alpha = 0.99f)),
        elevation = CardDefaults.cardElevation(16.dp),
    ) {
        Column(
            Modifier.padding(horizontal = 20.dp, vertical = 16.dp)
                .padding(bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()),
        ) {
            Row(verticalAlignment = Alignment.Top) {
                Column(Modifier.weight(1f)) {
                    Text(place.name, fontWeight = FontWeight.Black, fontSize = 27.sp, lineHeight = 30.sp)
                    if (place.locationLine.isNotBlank()) {
                        Row(Modifier.clickable(onClick = onDirections).padding(top = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Directions, null, tint = BrandNavy, modifier = Modifier.size(17.dp))
                            Spacer(Modifier.width(5.dp))
                            Text(place.locationLine, color = BrandNavy, fontSize = 13.sp, maxLines = 2)
                        }
                    }
                    place.primaryCategory?.let { Text(it, color = MutedInk, fontWeight = FontWeight.SemiBold, fontSize = 13.sp) }
                }
                IconButton(onClick = onShare) { Icon(Icons.Default.Share, "Share") }
                IconButton(onClick = onClose) { Icon(Icons.Default.Close, "Close") }
            }
            if (place.vibeCount > 0) {
                Spacer(Modifier.height(12.dp))
                CommunityVibes(place)
            }
            Spacer(Modifier.height(14.dp))
            Button(onClick = onRate, modifier = Modifier.fillMaxWidth().height(52.dp), shape = RoundedCornerShape(15.dp)) {
                Text(if (place.myRating == null) "Vibe this place" else "Update my vibes", fontWeight = FontWeight.Black)
            }
        }
    }
}

@Composable
private fun CommunityVibes(place: VibePlace) {
    Surface(color = Color(0xFFF6F3E6), shape = RoundedCornerShape(16.dp)) {
        Column(Modifier.fillMaxWidth().padding(14.dp)) {
            Text("Everyone else", fontWeight = FontWeight.Black, color = BrandNavy)
            place.stats?.topVibes?.take(3)?.forEach { breakdown ->
                Row(Modifier.fillMaxWidth().padding(top = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("${breakdown.tag.emoji} ${breakdown.tag.displayName}", Modifier.weight(1f), fontWeight = FontWeight.SemiBold)
                    Text("${breakdown.percentage}%", color = breakdown.tag.color, fontWeight = FontWeight.Black)
                }
            }
            Text("Based on ${place.vibeCount} ${if (place.vibeCount == 1) "person" else "people"}", color = MutedInk, fontSize = 11.sp, modifier = Modifier.padding(top = 5.dp))
        }
    }
}

@Composable
private fun RatingSheet(
    place: VibePlace,
    tags: List<VibeTag>,
    selectedIds: Set<String>,
    submitted: Boolean,
    loading: Boolean,
    onToggle: (VibeTag) -> Unit,
    onSubmit: () -> Unit,
    onDelete: () -> Unit,
    onShare: () -> Unit,
    onDismiss: () -> Unit,
) {
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = Sheet, dragHandle = null) {
        LazyColumn(
            modifier = Modifier.fillMaxWidth().imePadding(),
            contentPadding = PaddingValues(horizontal = 20.dp, vertical = 18.dp),
        ) {
            item {
                Row(verticalAlignment = Alignment.Top) {
                    Column(Modifier.weight(1f)) {
                        Text(place.name, fontWeight = FontWeight.Black, fontSize = 27.sp, lineHeight = 30.sp)
                        Text(place.locationLine, color = MutedInk, fontSize = 13.sp, maxLines = 2)
                    }
                    IconButton(onClick = onDismiss) { Icon(Icons.Default.Close, "Close") }
                }
            }
            if (submitted) {
                item {
                    Spacer(Modifier.height(12.dp))
                    Surface(color = BrandNavy, shape = RoundedCornerShape(20.dp)) {
                        Column(Modifier.fillMaxWidth().padding(18.dp)) {
                            Text("Your vibe is on the map", color = BrandYellow, fontWeight = FontWeight.Black, fontSize = 20.sp)
                            Text(
                                "You picked: ${tags.filter { it.id in selectedIds }.joinToString(" + ") { "${it.emoji} ${it.displayName}" }}",
                                color = Color.White,
                                modifier = Modifier.padding(top = 8.dp),
                            )
                        }
                    }
                    Spacer(Modifier.height(12.dp))
                    CommunityVibes(place)
                    Spacer(Modifier.height(14.dp))
                    Button(onClick = onShare, modifier = Modifier.fillMaxWidth()) {
                        Icon(Icons.Default.Share, null)
                        Spacer(Modifier.width(8.dp))
                        Text("Share this place")
                    }
                    TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) { Text("Done") }
                }
            } else {
                item {
                    Spacer(Modifier.height(8.dp))
                    Text("What’s the vibe?", fontWeight = FontWeight.Black, fontSize = 22.sp)
                    Text("Pick one to three. Your whole button is tappable.", color = MutedInk, fontSize = 13.sp)
                }
                val groups = listOf(
                    "Love it" to tags.filter { it.sentimentGroup == "positive" },
                    "It’s…" to tags.filter { it.sentimentGroup in setOf("identity", "neutral") },
                    "Skip it" to tags.filter { it.sentimentGroup == "negative" },
                )
                groups.forEach { (label, groupTags) ->
                    item {
                        Text(label, modifier = Modifier.padding(top = 17.dp, bottom = 8.dp), fontWeight = FontWeight.Black, color = BrandNavy)
                        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            groupTags.forEach { tag ->
                                VibeChoice(tag, tag.id in selectedIds, enabled = tag.id in selectedIds || selectedIds.size < 3) { onToggle(tag) }
                            }
                        }
                    }
                }
                item {
                    Spacer(Modifier.height(18.dp))
                    Button(
                        onClick = onSubmit,
                        enabled = selectedIds.isNotEmpty() && !loading,
                        modifier = Modifier.fillMaxWidth().height(54.dp),
                        shape = RoundedCornerShape(15.dp),
                    ) {
                        if (loading) CircularProgressIndicator(Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                        else Text(if (place.myRating == null) "Put my vibes on the map" else "Update my vibes", fontWeight = FontWeight.Black)
                    }
                    if (place.myRating != null) {
                        TextButton(onClick = onDelete, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)) {
                            Icon(Icons.Default.Delete, null)
                            Spacer(Modifier.width(5.dp))
                            Text("Delete my vibes")
                        }
                    }
                    Spacer(Modifier.height(WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()))
                }
            }
        }
    }
}

@Composable
private fun VibeChoice(tag: VibeTag, selected: Boolean, enabled: Boolean, onClick: () -> Unit) {
    Surface(
        modifier = Modifier.clickable(enabled = enabled, onClick = onClick),
        color = if (selected) tag.color else Color.White,
        contentColor = if (selected) Color.White else Ink,
        border = androidx.compose.foundation.BorderStroke(1.5.dp, if (selected) tag.color else tag.color.copy(alpha = if (enabled) 0.55f else 0.18f)),
        shape = RoundedCornerShape(13.dp),
        shadowElevation = if (selected) 4.dp else 0.dp,
    ) {
        Row(Modifier.padding(horizontal = 12.dp, vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(tag.emoji)
            Spacer(Modifier.width(6.dp))
            Text(tag.displayName, fontWeight = FontWeight.Bold, fontSize = 13.sp, color = if (enabled || selected) Color.Unspecified else MutedInk.copy(alpha = 0.4f))
            if (selected) {
                Spacer(Modifier.width(5.dp))
                Icon(Icons.Default.Check, null, modifier = Modifier.size(15.dp))
            }
        }
    }
}

@Composable
private fun AccountSheet(
    eligibility: com.brianhakel.vibesyall.data.AccountEligibility?,
    message: String?,
    onSignup: (String) -> Unit,
    onLogin: (String) -> Unit,
    onLogout: () -> Unit,
    onDelete: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    var email by remember { mutableStateOf("") }
    var confirmDelete by remember { mutableStateOf(false) }
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = Sheet) {
        Column(
            Modifier.fillMaxWidth().padding(horizontal = 22.dp, vertical = 10.dp)
                .padding(bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()),
        ) {
            Image(painterResource(R.drawable.brand_logo), null, Modifier.size(64.dp).clip(CircleShape))
            Spacer(Modifier.height(10.dp))
            Text("Keep your vibes with you", fontWeight = FontWeight.Black, fontSize = 26.sp)
            val progress = eligibility?.let {
                if (it.eligible) "You’ve vibed ${it.vibedPlaceCount} places. Account backup is unlocked."
                else "${it.remainingPlaces} more places unlock account backup. Signup stays optional."
            }
            progress?.let { Text(it, color = MutedInk, modifier = Modifier.padding(top = 5.dp)) }
            eligibility?.benefits?.take(4)?.forEach { benefit ->
                Row(Modifier.padding(top = 8.dp)) {
                    Text("✓", color = BrandNavy, fontWeight = FontWeight.Black)
                    Spacer(Modifier.width(8.dp))
                    Text(benefit, fontSize = 13.sp)
                }
            }
            message?.let {
                Surface(color = BrandYellow.copy(alpha = 0.32f), shape = RoundedCornerShape(12.dp), modifier = Modifier.padding(top = 14.dp)) {
                    Text(it, Modifier.fillMaxWidth().padding(12.dp), color = BrandNavy, fontWeight = FontWeight.SemiBold)
                }
            }
            Spacer(Modifier.height(14.dp))
            OutlinedTextField(
                value = email,
                onValueChange = { email = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Email") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email, imeAction = ImeAction.Done),
            )
            Spacer(Modifier.height(10.dp))
            if (eligibility?.emailVerified == true) {
                Button(onClick = onLogout, modifier = Modifier.fillMaxWidth()) { Text("Sign out") }
            } else {
                Button(
                    onClick = { onSignup(email.trim()) },
                    enabled = eligibility?.eligible == true && email.contains('@'),
                    modifier = Modifier.fillMaxWidth(),
                ) { Text("Create account", fontWeight = FontWeight.Black) }
                OutlinedButton(onClick = { onLogin(email.trim()) }, enabled = email.contains('@'), modifier = Modifier.fillMaxWidth()) {
                    Text("I already have an account")
                }
            }
            TextButton(onClick = { confirmDelete = !confirmDelete }, modifier = Modifier.fillMaxWidth()) {
                Text(if (confirmDelete) "Tap again below to confirm" else "Delete account", color = MaterialTheme.colorScheme.error)
            }
            if (confirmDelete) {
                OutlinedButton(
                    onClick = { onDelete(email.trim()) },
                    enabled = email.contains('@'),
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.error),
                ) { Text("Permanently delete my account") }
            }
            TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) { Text("Maybe later") }
        }
    }
}

private fun openDirections(context: Context, place: VibePlace) {
    val uri = Uri.parse("google.navigation:q=${place.latitude},${place.longitude}")
    val intent = Intent(Intent.ACTION_VIEW, uri).apply { setPackage("com.google.android.apps.maps") }
    if (intent.resolveActivity(context.packageManager) != null) context.startActivity(intent)
    else context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}")))
}

private fun sharePlace(context: Context, place: VibePlace) {
    val community = place.stats?.topVibes?.take(3)?.joinToString(", ") { "${it.tag.emoji} ${it.tag.displayName} ${it.percentage}%" }
    val text = buildString {
        append("${place.name} on VIBES Y'ALL")
        if (!community.isNullOrBlank()) append("\n$community")
        append("\nhttps://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}")
        append("\nhttps://vibesyall.com")
    }
    context.startActivity(
        Intent.createChooser(
            Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, text) },
            "Share this vibe",
        ),
    )
}

private const val DarkMapStyle = """[
  {"elementType":"geometry","stylers":[{"color":"#172238"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#d7d8c2"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#172238"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#44516a"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#1d2940"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#24344d"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1f3a35"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#34445e"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#596477"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2d3b52"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f1a2c"}]}
]"""
