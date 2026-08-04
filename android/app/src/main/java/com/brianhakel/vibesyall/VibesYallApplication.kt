package com.brianhakel.vibesyall

import android.app.Application
import com.brianhakel.vibesyall.data.GooglePlacesRepository
import com.brianhakel.vibesyall.data.LocationRepository
import com.brianhakel.vibesyall.data.SecureIdentityStore
import com.brianhakel.vibesyall.data.VibesApi

class VibesYallApplication : Application() {
    val identityStore by lazy { SecureIdentityStore(this) }
    val api by lazy { VibesApi(identityStore) }
    val placesRepository by lazy { GooglePlacesRepository(this) }
    val locationRepository by lazy { LocationRepository(this) }
}
