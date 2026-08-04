package com.brianhakel.vibesyall

import android.Manifest
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import com.brianhakel.vibesyall.ui.VibeMapScreen
import com.brianhakel.vibesyall.ui.VibeMapViewModel
import com.brianhakel.vibesyall.ui.theme.VibesYallTheme

class MainActivity : ComponentActivity() {
    private val appGraph: VibesYallApplication get() = application as VibesYallApplication
    private val viewModel: VibeMapViewModel by viewModels {
        VibeMapViewModel.Factory(appGraph.api, appGraph.placesRepository, appGraph.locationRepository)
    }

    private val locationPermission = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions(),
    ) { result ->
        viewModel.onLocationPermissionResult(result.values.any { it })
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        viewModel.handleDeepLink(intent?.data)
        setContent {
            VibesYallTheme {
                VibeMapScreen(
                    viewModel = viewModel,
                    requestLocationPermission = {
                        locationPermission.launch(
                            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
                        )
                    },
                )
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        viewModel.handleDeepLink(intent.data)
    }
}
