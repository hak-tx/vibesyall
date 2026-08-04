package com.brianhakel.vibesyall.data

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.maps.model.LatLng
import kotlinx.coroutines.tasks.await

class LocationRepository(private val context: Context) {
    private val client = LocationServices.getFusedLocationProviderClient(context)

    fun hasPermission(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    suspend fun currentLocation(): LatLng? {
        if (!hasPermission()) return null
        val location = runCatching {
            client.getCurrentLocation(Priority.PRIORITY_BALANCED_POWER_ACCURACY, null).await()
                ?: client.lastLocation.await()
        }.getOrNull() ?: return null
        return LatLng(location.latitude, location.longitude)
    }
}
