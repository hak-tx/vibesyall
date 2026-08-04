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
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
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
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Cyclone
import androidx.compose.material.icons.filled.Diamond
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Directions
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Help
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.RemoveCircle
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.ThumbDown
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Eco
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
import androidx.compose.material3.rememberModalBottomSheetState
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
import androidx.compose.ui.graphics.vector.ImageVector
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
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MapStyleOptions
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.MapProperties
import com.google.maps.android.compose.MapType
import com.google.maps.android.compose.MapUiSettings
import com.google.maps.android.compose.Marker
import com.google.maps.android.compose.MarkerComposable
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
    var showAppMenu by remember { mutableStateOf(false) }

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
        BoxWithConstraints(Modifier.fillMaxSize().padding(bottom = scaffoldPadding.calculateBottomPadding())) {
            val compactWidth = maxWidth < 380.dp
            val compactHeight = maxHeight < 700.dp
            val edgePadding = if (compactWidth) 10.dp else 16.dp
            val panelWidth = if (maxWidth >= 700.dp) (maxWidth * 0.48f).coerceIn(460.dp, 580.dp) else maxWidth
            val nearbyHeight = (maxHeight * 0.38f).coerceIn(250.dp, 370.dp)
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
                    onMenu = { showAppMenu = true },
                    horizontalPadding = edgePadding,
                )
                VibeFilters(
                    tags = state.tags,
                    selectedIds = state.selectedFilterIds,
                    onSelect = viewModel::toggleFilter,
                    horizontalPadding = edgePadding,
                )
                SearchResults(
                    query = state.searchQuery,
                    results = state.searchResults,
                    isSearching = state.isSearching,
                    mapsKeyMissing = state.mapsKeyMissing,
                    onSelect = viewModel::selectSearchResult,
                    horizontalPadding = edgePadding,
                    maxHeight = if (compactHeight) 280.dp else 390.dp,
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
                    compact = compactHeight || compactWidth,
                    modifier = Modifier.align(if (maxWidth >= 700.dp) Alignment.BottomStart else Alignment.BottomCenter).width(panelWidth),
                )
            } else {
                NearbyPanel(
                    places = state.nearbyPlaces,
                    cells = state.mapCells,
                    expanded = state.panelExpanded,
                    loading = state.isLoadingMap,
                    onExpandChange = viewModel::setPanelExpanded,
                    onSelect = viewModel::selectNearbyPlace,
                    expandedHeight = nearbyHeight,
                    modifier = Modifier.align(if (maxWidth >= 700.dp) Alignment.BottomStart else Alignment.BottomCenter).width(panelWidth),
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

    if (showAppMenu) {
        AppMenuSheet(
            onAccount = {
                showAppMenu = false
                viewModel.openAccount()
            },
            onDeleteAccount = {
                showAppMenu = false
                viewModel.openAccount()
            },
            onDismiss = { showAppMenu = false },
        )
    }
}

@Composable
private fun VibesGoogleMap(state: VibeMapUiState, viewModel: VibeMapViewModel) {
    var mapLoaded by remember { mutableStateOf(false) }
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

    LaunchedEffect(mapLoaded, state.cameraCenter, state.cameraZoom) {
        if (!mapLoaded) return@LaunchedEffect
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
        onMapLoaded = { mapLoaded = true },
    ) {
        state.nearbyPlaces.forEach { place ->
            MarkerComposable(
                keys = arrayOf<Any>(place.id, place.topVibe?.tag?.id.orEmpty(), state.selectedPlace?.id == place.id),
                state = MarkerState(LatLng(place.latitude, place.longitude)),
                title = place.name,
                snippet = place.topVibe?.let { "${it.tag.emoji} ${it.tag.displayName} · ${place.vibeCount} vibes" },
                onClick = {
                    viewModel.selectNearbyPlace(place)
                    true
                },
            ) {
                VibeMapMarker(
                    tag = place.topVibe?.tag,
                    selected = state.selectedPlace?.id == place.id,
                )
            }
        }
        state.mapCells.forEach { cell ->
            MarkerComposable(
                keys = arrayOf<Any>(cell.id, cell.topVibe?.id.orEmpty(), cell.count),
                state = MarkerState(LatLng(cell.latitude, cell.longitude)),
                title = "${cell.count} vibed places",
                snippet = cell.topVibe?.let { "${it.emoji} ${it.displayName} · ${cell.totalVibes} vibes" },
                onClick = {
                    viewModel.focusMapCell(cell)
                    true
                },
            ) {
                VibeMapMarker(tag = cell.topVibe, count = cell.count, regional = true)
            }
        }
    }
}

@Composable
private fun VibeMapMarker(
    tag: VibeTag?,
    count: Int? = null,
    selected: Boolean = false,
    regional: Boolean = false,
) {
    val accent = tag?.color ?: BrandNavy
    val markerSize = if (regional) 38.dp else if (selected) 36.dp else 30.dp
    Box(
        modifier = Modifier.size(markerSize + if (count != null) 14.dp else 0.dp),
        contentAlignment = Alignment.Center,
    ) {
        if (regional) {
            Box(
                Modifier
                    .size(markerSize + 8.dp)
                    .background(accent.copy(alpha = 0.18f), CircleShape),
            )
        }
        Surface(
            modifier = Modifier.size(markerSize),
            shape = CircleShape,
            color = if (selected) accent else Color.White.copy(alpha = 0.96f),
            border = BorderStroke(if (selected) 3.dp else 2.dp, if (selected) Color.White else Color.White.copy(alpha = 0.9f)),
            shadowElevation = 5.dp,
        ) {
            Box(contentAlignment = Alignment.Center) {
                VibeSymbol(
                    tag = tag,
                    tint = if (selected) Color.White else accent,
                    modifier = Modifier.size(if (regional) 19.dp else if (selected) 18.dp else 15.dp),
                )
            }
        }
        if (count != null && count > 1) {
            Surface(
                modifier = Modifier.align(Alignment.BottomEnd),
                shape = CircleShape,
                color = BrandNavy,
                border = BorderStroke(1.5.dp, Color.White),
                shadowElevation = 3.dp,
            ) {
                Text(
                    text = if (count > 99) "99+" else count.toString(),
                    modifier = Modifier.padding(horizontal = 5.dp, vertical = 2.dp),
                    color = Color.White,
                    fontWeight = FontWeight.Black,
                    fontSize = 10.sp,
                )
            }
        }
    }
}

@Composable
private fun VibeSymbol(tag: VibeTag?, tint: Color, modifier: Modifier = Modifier) {
    if (tag?.id == "needs_prayer") {
        Icon(
            painter = painterResource(R.drawable.ic_needs_prayer),
            contentDescription = null,
            tint = tint,
            modifier = modifier,
        )
        return
    }
    val icon: ImageVector = when (tag?.id) {
        "changed_my_life" -> Icons.Default.Star
        "fire" -> Icons.Default.LocalFireDepartment
        "worth_the_drive" -> Icons.Default.DirectionsCar
        "iconic" -> Icons.Default.AutoAwesome
        "hidden_gem" -> Icons.Default.Diamond
        "underrated" -> Icons.Default.TrendingUp
        "bougie" -> Icons.Default.WorkspacePremium
        "low_key" -> Icons.Default.Eco
        "mid" -> Icons.Default.RemoveCircle
        "chaos" -> Icons.Default.Cyclone
        "overrated" -> Icons.Default.ThumbDown
        "tourist_trap" -> Icons.Default.PhotoCamera
        "emotionally_damaging" -> Icons.Default.Cancel
        else -> Icons.Default.LocationOn
    }
    Icon(icon, contentDescription = null, tint = tint, modifier = modifier)
}

@Composable
private fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    onClear: () -> Unit,
    onMenu: () -> Unit,
    horizontalPadding: androidx.compose.ui.unit.Dp,
) {
    val focus = LocalFocusManager.current
    Row(
        modifier = Modifier.fillMaxWidth().padding(horizontal = horizontalPadding),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Surface(
            modifier = Modifier.weight(1f).height(48.dp),
            color = BrandNavy.copy(alpha = 0.82f),
            shape = RoundedCornerShape(16.dp),
            border = BorderStroke(1.dp, BrandYellow.copy(alpha = 0.18f)),
            shadowElevation = 8.dp,
        ) {
            BasicTextField(
                value = query,
                onValueChange = onQueryChange,
                modifier = Modifier.fillMaxSize(),
                singleLine = true,
                textStyle = MaterialTheme.typography.bodyLarge.copy(color = Color.White, fontSize = 17.sp),
                cursorBrush = androidx.compose.ui.graphics.SolidColor(BrandYellow),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { focus.clearFocus() }),
                decorationBox = { field ->
                    Row(
                        Modifier.fillMaxSize().padding(start = 14.dp, end = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Default.Search, null, tint = BrandYellow, modifier = Modifier.size(24.dp))
                        Spacer(Modifier.width(10.dp))
                        Box(Modifier.weight(1f)) {
                            if (query.isEmpty()) Text("Search a place...", color = BrandYellow.copy(alpha = 0.8f), fontSize = 17.sp)
                            field()
                        }
                        if (query.isNotEmpty()) {
                            IconButton(onClick = onClear, modifier = Modifier.size(38.dp)) {
                                Icon(Icons.Default.Clear, "Clear", tint = Color.White)
                            }
                        }
                    }
                },
            )
        }
        Box(
            modifier = Modifier.size(54.dp).clickable(onClick = onMenu),
            contentAlignment = Alignment.TopStart,
        ) {
            Surface(
                modifier = Modifier.size(50.dp),
                shape = RoundedCornerShape(15.dp),
                color = Color.White,
                border = BorderStroke(2.5.dp, Color.White),
                shadowElevation = 8.dp,
            ) {
                Image(
                    painter = painterResource(R.drawable.brand_logo),
                    contentDescription = "Open VIBES Y'ALL menu",
                    modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(13.dp)),
                )
            }
            Surface(
                modifier = Modifier.align(Alignment.BottomEnd).size(19.dp),
                shape = CircleShape,
                color = BrandNavy,
                border = BorderStroke(1.5.dp, BrandYellow),
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(Icons.Default.Menu, null, tint = BrandYellow, modifier = Modifier.size(12.dp))
                }
            }
        }
    }
}

@Composable
private fun VibeFilters(
    tags: List<VibeTag>,
    selectedIds: Set<String>,
    onSelect: (VibeTag?) -> Unit,
    horizontalPadding: androidx.compose.ui.unit.Dp,
) {
    LazyRow(
        modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
        contentPadding = PaddingValues(horizontal = horizontalPadding),
        horizontalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        item {
            FilterPill("All", null, selectedIds.isEmpty()) { onSelect(null) }
        }
        items(tags, key = VibeTag::id) { tag ->
            FilterPill(tag.mapLabel, tag, tag.id in selectedIds) { onSelect(tag) }
        }
    }
}

@Composable
private fun FilterPill(label: String, tag: VibeTag?, selected: Boolean, onClick: () -> Unit) {
    Surface(
        modifier = Modifier.clickable(onClick = onClick),
        color = if (selected) BrandNavy else Color.White.copy(alpha = 0.84f),
        contentColor = if (selected) Color.White else BrandNavy,
        border = if (selected) null else androidx.compose.foundation.BorderStroke(1.dp, BrandNavy.copy(alpha = 0.45f)),
        shape = RoundedCornerShape(50),
        shadowElevation = 2.dp,
    ) {
        Row(Modifier.height(30.dp).padding(horizontal = 9.dp), verticalAlignment = Alignment.CenterVertically) {
            if (tag == null) {
                Icon(Icons.Default.AutoAwesome, null, modifier = Modifier.size(12.dp))
            } else {
                VibeSymbol(tag, if (selected) Color.White else tag.color, Modifier.size(12.dp))
            }
            Spacer(Modifier.width(4.dp))
            Text(label, fontWeight = FontWeight.Bold, fontSize = 12.sp)
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
    horizontalPadding: androidx.compose.ui.unit.Dp,
    maxHeight: androidx.compose.ui.unit.Dp,
) {
    AnimatedVisibility(visible = query.length >= 2) {
        Card(
            modifier = Modifier.fillMaxWidth().padding(horizontal = horizontalPadding, vertical = 8.dp).heightIn(max = maxHeight),
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
    val vibeTag: VibeTag?
    when (result) {
        is SearchResultItem.CommunityPlace -> {
            title = result.place.name
            subtitle = result.place.locationLine.ifBlank { result.place.category.orEmpty() }
            distance = formatDistance(result.place.distanceMeters)
            vibeTag = result.place.topVibe?.tag
            vibe = result.place.topVibe?.let { "${it.tag.displayName} ${it.percentage}%" }
        }
        is SearchResultItem.GooglePlace -> {
            title = result.prediction.title
            subtitle = result.prediction.subtitle
            distance = formatDistance(result.prediction.distanceMeters?.toDouble())
            vibe = null
            vibeTag = null
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
            vibe?.let {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    vibeTag?.let { tag ->
                        VibeSymbol(tag, tag.color, Modifier.size(13.dp))
                        Spacer(Modifier.width(4.dp))
                    }
                    Text(it, color = BrandNavy, fontWeight = FontWeight.SemiBold, fontSize = 12.sp)
                }
            }
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
    expandedHeight: androidx.compose.ui.unit.Dp,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .height(if (expanded) expandedHeight else 70.dp),
        shape = PanelShape,
        colors = CardDefaults.cardColors(containerColor = Sheet.copy(alpha = 0.98f)),
        elevation = CardDefaults.cardElevation(14.dp),
    ) {
        Column(Modifier.fillMaxSize().padding(bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding())) {
            Row(
                modifier = Modifier.fillMaxWidth().clickable { onExpandChange(!expanded) }.padding(horizontal = 16.dp, vertical = 9.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text("What's Nearby", fontWeight = FontWeight.Black, fontSize = 20.sp, color = Ink)
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
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(color = place.topVibe?.tag?.color?.copy(alpha = 0.15f) ?: BrandNavy.copy(alpha = 0.08f), shape = CircleShape) {
            Box(Modifier.size(36.dp), contentAlignment = Alignment.Center) {
                val tag = place.topVibe?.tag
                if (tag == null) Icon(Icons.Default.AutoAwesome, null, tint = BrandNavy, modifier = Modifier.size(18.dp))
                else VibeSymbol(tag, tag.color, Modifier.size(18.dp))
            }
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
    compact: Boolean,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = PanelShape,
        colors = CardDefaults.cardColors(containerColor = Sheet.copy(alpha = 0.99f)),
        elevation = CardDefaults.cardElevation(16.dp),
    ) {
        Column(
            Modifier.padding(horizontal = 16.dp, vertical = if (compact) 10.dp else 13.dp)
                .padding(bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()),
        ) {
            Row(verticalAlignment = Alignment.Top) {
                Column(Modifier.weight(1f)) {
                    Text(place.name, fontWeight = FontWeight.Black, fontSize = if (compact) 23.sp else 25.sp, lineHeight = if (compact) 26.sp else 28.sp)
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
                Spacer(Modifier.height(if (compact) 8.dp else 10.dp))
                CommunityVibes(place)
            }
            Spacer(Modifier.height(if (compact) 9.dp else 12.dp))
            Button(onClick = onRate, modifier = Modifier.fillMaxWidth().height(if (compact) 46.dp else 50.dp), shape = RoundedCornerShape(15.dp)) {
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
                    VibeSymbol(breakdown.tag, breakdown.tag.color, Modifier.size(17.dp))
                    Spacer(Modifier.width(7.dp))
                    Text(breakdown.tag.displayName, Modifier.weight(1f), fontWeight = FontWeight.SemiBold)
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
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Sheet,
        dragHandle = null,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .imePadding()
                .padding(horizontal = 18.dp)
                .padding(bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding() + 8.dp),
        ) {
            Box(Modifier.fillMaxWidth().height(48.dp)) {
                Box(
                    Modifier
                        .align(Alignment.TopCenter)
                        .padding(top = 7.dp)
                        .size(width = 42.dp, height = 5.dp)
                        .background(Color.Black.copy(alpha = 0.18f), RoundedCornerShape(50)),
                )
                Button(
                    onClick = {
                        if (submitted) onDismiss()
                        else if (selectedIds.isEmpty()) onDismiss()
                        else onSubmit()
                    },
                    enabled = !loading,
                    modifier = Modifier.align(Alignment.CenterEnd).height(38.dp),
                    shape = RoundedCornerShape(50),
                    contentPadding = PaddingValues(horizontal = 18.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = BrandNavy),
                ) {
                    if (loading) {
                        CircularProgressIndicator(Modifier.size(17.dp), color = Color.White, strokeWidth = 2.dp)
                    } else {
                        Text("Done", fontWeight = FontWeight.Black, fontSize = 15.sp)
                    }
                }
            }

            CurrentPlaceSummary(place = place, onShare = onShare)

            if (submitted) {
                Spacer(Modifier.height(12.dp))
                Surface(color = BrandNavy, shape = RoundedCornerShape(18.dp)) {
                    Column(Modifier.fillMaxWidth().padding(16.dp)) {
                        Text("Your vibe is on the map", color = BrandYellow, fontWeight = FontWeight.Black, fontSize = 19.sp)
                        Text(
                            "You picked: ${tags.filter { it.id in selectedIds }.joinToString(" + ") { "${it.emoji} ${it.displayName}" }}",
                            color = Color.White,
                            modifier = Modifier.padding(top = 7.dp),
                        )
                    }
                }
                Spacer(Modifier.height(10.dp))
                CommunityVibes(place)
            } else {
                Spacer(Modifier.height(11.dp))
                Text("Pick one to three vibes", fontWeight = FontWeight.Black, fontSize = 22.sp, color = Ink)
                Spacer(Modifier.height(8.dp))

                tags.sortedBy(VibeTag::sortOrder).chunked(2).forEach { rowTags ->
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(bottom = 6.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        rowTags.forEach { tag ->
                            VibeChoice(
                                tag = tag,
                                selected = tag.id in selectedIds,
                                enabled = tag.id in selectedIds || selectedIds.size < 3,
                                onClick = { onToggle(tag) },
                                modifier = Modifier.weight(1f),
                            )
                        }
                        if (rowTags.size == 1) Spacer(Modifier.weight(1f))
                    }
                }

                if (place.myRating != null) {
                    TextButton(
                        onClick = onDelete,
                        modifier = Modifier.align(Alignment.CenterHorizontally).height(36.dp),
                        colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error),
                    ) {
                        Icon(Icons.Default.Delete, null, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(5.dp))
                        Text("Delete my vibes", fontSize = 12.sp)
                    }
                }
            }
        }
    }
}

@Composable
private fun CurrentPlaceSummary(place: VibePlace, onShare: () -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color(0xFFF9F9F4),
        shape = RoundedCornerShape(24.dp),
        border = BorderStroke(1.5.dp, BrandNavy.copy(alpha = 0.75f)),
        shadowElevation = 5.dp,
    ) {
        Column(Modifier.padding(13.dp)) {
            Row(verticalAlignment = Alignment.Top) {
                Surface(modifier = Modifier.size(34.dp), shape = CircleShape, color = BrandNavy) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.LocationOn, null, tint = BrandYellow, modifier = Modifier.size(20.dp))
                    }
                }
                Spacer(Modifier.width(8.dp))
                Column(Modifier.weight(1f)) {
                    Text(
                        place.name.uppercase(),
                        color = BrandNavy,
                        fontWeight = FontWeight.Black,
                        fontSize = if (place.name.length > 28) 18.sp else 22.sp,
                        lineHeight = 23.sp,
                        maxLines = 2,
                    )
                    if (place.locationLine.isNotBlank()) {
                        Row(Modifier.padding(top = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Directions, null, tint = BrandNavy, modifier = Modifier.size(15.dp))
                            Spacer(Modifier.width(5.dp))
                            Text(place.locationLine, color = BrandNavy, fontWeight = FontWeight.Bold, fontSize = 12.sp, lineHeight = 15.sp, maxLines = 2)
                        }
                    }
                    place.primaryCategory?.let {
                        Text(it, color = MutedInk, fontWeight = FontWeight.SemiBold, fontSize = 12.sp, modifier = Modifier.padding(top = 3.dp))
                    }
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text("SHARE IT.", color = BrandNavy, fontWeight = FontWeight.Black, fontSize = 11.sp)
                    Button(
                        onClick = onShare,
                        modifier = Modifier.padding(top = 3.dp).height(38.dp),
                        shape = RoundedCornerShape(50),
                        contentPadding = PaddingValues(horizontal = 13.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = BrandNavy),
                    ) {
                        Icon(Icons.Default.Share, null, tint = BrandYellow, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(5.dp))
                        Text("Share", fontWeight = FontWeight.Black, fontSize = 12.sp)
                    }
                }
            }

            if (place.vibeCount > 0) {
                Surface(
                    modifier = Modifier.fillMaxWidth().padding(top = 10.dp),
                    color = BrandNavy.copy(alpha = 0.055f),
                    shape = RoundedCornerShape(15.dp),
                    border = BorderStroke(1.dp, BrandNavy.copy(alpha = 0.24f)),
                ) {
                    Column(Modifier.padding(8.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("TOP VIBES HERE", color = BrandNavy, fontWeight = FontWeight.Black, fontSize = 10.sp, modifier = Modifier.weight(1f))
                            Text("${place.vibeCount} ${if (place.vibeCount == 1) "vibe" else "vibes"}", color = MutedInk, fontWeight = FontWeight.Bold, fontSize = 10.sp)
                        }
                        Row(Modifier.padding(top = 7.dp), horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                            place.stats?.topVibes?.take(2)?.forEach { breakdown ->
                                Surface(
                                    modifier = Modifier.weight(1f),
                                    color = Color.White.copy(alpha = 0.78f),
                                    shape = RoundedCornerShape(10.dp),
                                    border = BorderStroke(1.dp, breakdown.tag.color.copy(alpha = 0.22f)),
                                ) {
                                    Row(Modifier.padding(horizontal = 7.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                                        Surface(modifier = Modifier.size(24.dp), shape = CircleShape, color = breakdown.tag.color.copy(alpha = 0.14f)) {
                                            Box(contentAlignment = Alignment.Center) {
                                                VibeSymbol(breakdown.tag, breakdown.tag.color, Modifier.size(13.dp))
                                            }
                                        }
                                        Spacer(Modifier.width(5.dp))
                                        Text(breakdown.tag.displayName, Modifier.weight(1f), fontWeight = FontWeight.Black, fontSize = 10.sp, maxLines = 2)
                                        Text("${breakdown.percentage}%", color = breakdown.tag.color, fontWeight = FontWeight.Black, fontSize = 10.sp)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun VibeChoice(
    tag: VibeTag,
    selected: Boolean,
    enabled: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Surface(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.heightIn(min = 48.dp),
        color = if (selected) tag.color.copy(alpha = 0.11f) else Color(0xFFFDFDF9),
        contentColor = Ink,
        border = BorderStroke(if (selected) 2.dp else 1.dp, if (selected) tag.color.copy(alpha = 0.78f) else Color.Black.copy(alpha = 0.10f)),
        shape = RoundedCornerShape(13.dp),
        shadowElevation = 0.dp,
    ) {
        Row(Modifier.padding(horizontal = 9.dp, vertical = 7.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(modifier = Modifier.size(27.dp), shape = CircleShape, color = tag.color.copy(alpha = if (selected) 0.92f else 0.14f)) {
                Box(contentAlignment = Alignment.Center) {
                    VibeSymbol(tag, if (selected) Color.White else tag.color, Modifier.size(15.dp))
                }
            }
            Spacer(Modifier.width(7.dp))
            Text(
                tag.displayName,
                modifier = Modifier.weight(1f),
                fontWeight = FontWeight.Black,
                fontSize = 12.5.sp,
                lineHeight = 14.sp,
                maxLines = 2,
                color = if (enabled || selected) Ink else MutedInk.copy(alpha = 0.4f),
            )
            if (selected) {
                Surface(modifier = Modifier.size(20.dp), shape = CircleShape, color = tag.color) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.Check, null, tint = Color.White, modifier = Modifier.size(14.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun AppMenuSheet(
    onAccount: () -> Unit,
    onDeleteAccount: () -> Unit,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Sheet,
        dragHandle = null,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
    ) {
        Column(
            Modifier.fillMaxWidth().widthIn(max = 560.dp).verticalScroll(rememberScrollState())
                .padding(horizontal = 22.dp, vertical = 18.dp)
                .padding(bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("VIBES Y'ALL", Modifier.weight(1f), fontWeight = FontWeight.Black, fontSize = 30.sp, color = Ink)
                Surface(shape = CircleShape, color = BrandNavy.copy(alpha = 0.06f)) {
                    IconButton(onClick = onDismiss, modifier = Modifier.size(38.dp)) {
                        Icon(Icons.Default.Close, "Close menu", tint = Ink)
                    }
                }
            }
            Text(
                "Map-first place vibes. No account needed to explore or submit.",
                color = MutedInk, fontSize = 15.sp, lineHeight = 20.sp,
                modifier = Modifier.padding(top = 12.dp, bottom = 15.dp),
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Language, null, tint = Ink, modifier = Modifier.size(21.dp))
                Spacer(Modifier.width(9.dp))
                Text("Language", fontWeight = FontWeight.Black, fontSize = 17.sp)
            }
            Surface(
                modifier = Modifier.fillMaxWidth().padding(top = 8.dp, bottom = 10.dp),
                shape = RoundedCornerShape(50), color = BrandNavy.copy(alpha = 0.06f),
            ) {
                Row(Modifier.padding(3.dp)) {
                    Surface(Modifier.weight(1f), shape = RoundedCornerShape(50), color = Color.White, shadowElevation = 1.dp) {
                        Text("English", Modifier.padding(vertical = 8.dp), textAlign = androidx.compose.ui.text.style.TextAlign.Center, fontWeight = FontWeight.SemiBold)
                    }
                    Text("Español", Modifier.weight(1f).padding(vertical = 8.dp), textAlign = androidx.compose.ui.text.style.TextAlign.Center, color = MutedInk.copy(alpha = 0.55f))
                }
            }
            AppMenuRow(Icons.Default.Person, "Create or sign in", "Email links only. No password needed.", BrandNavy, onAccount)
            Divider(color = BrandNavy.copy(alpha = 0.07f))
            AppMenuRow(Icons.Default.Description, "Privacy Policy", null, MutedInk) { openWebPage(context, "https://vibesyall.com/privacy") }
            AppMenuRow(Icons.Default.Description, "Terms of Use", null, MutedInk) { openWebPage(context, "https://vibesyall.com/terms") }
            AppMenuRow(Icons.Default.Help, "Support", null, MutedInk) { openWebPage(context, "https://vibesyall.com/support") }
            Divider(color = BrandNavy.copy(alpha = 0.07f))
            AppMenuRow(Icons.Default.Delete, "Delete account", "Delete the optional account tied to this device and email.", MaterialTheme.colorScheme.error, onDeleteAccount)
        }
    }
}

@Composable
private fun AppMenuRow(icon: ImageVector, title: String, subtitle: String?, iconColor: Color, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Surface(shape = CircleShape, color = iconColor.copy(alpha = 0.1f)) {
            Box(Modifier.size(38.dp), contentAlignment = Alignment.Center) {
                Icon(icon, null, tint = iconColor, modifier = Modifier.size(21.dp))
            }
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(title, fontWeight = FontWeight.Black, fontSize = 17.sp, color = Ink)
            subtitle?.let { Text(it, color = MutedInk, fontSize = 12.5.sp, lineHeight = 15.sp) }
        }
        Icon(Icons.Default.ChevronRight, null, tint = MutedInk.copy(alpha = 0.7f))
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
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp, vertical = 8.dp)
                .padding(bottom = WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()),
        ) {
            Image(painterResource(R.drawable.brand_logo), null, Modifier.size(52.dp).clip(RoundedCornerShape(14.dp)))
            Spacer(Modifier.height(8.dp))
            Text("Keep your vibes with you", fontWeight = FontWeight.Black, fontSize = 24.sp)
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

private fun openWebPage(context: Context, url: String) {
    context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
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
