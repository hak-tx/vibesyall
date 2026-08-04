import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

fun String.asBuildConfigString(): String = "\"" + replace("\\", "\\\\").replace("\"", "\\\"") + "\""

val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use(::load)
}

val fastlaneBetaToken = rootProject.file("../fastlane/.env.testflight")
    .takeIf { it.exists() }
    ?.readLines()
    ?.firstOrNull { it.startsWith("VIBE_BETA_ACCESS_TOKEN=") }
    ?.substringAfter('=')
    ?.trim()
    .orEmpty()

val mapsApiKey = (localProperties.getProperty("MAPS_API_KEY") ?: System.getenv("MAPS_API_KEY")).orEmpty()
val betaAccessToken = (localProperties.getProperty("VIBE_BETA_ACCESS_TOKEN")
    ?: System.getenv("VIBE_BETA_ACCESS_TOKEN")
    ?: fastlaneBetaToken).trim()

android {
    namespace = "com.brianhakel.vibesyall"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.brianhakel.vibesyall"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables.useSupportLibrary = true
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
        buildConfigField("String", "API_BASE_URL", "https://api.vibesyall.com".asBuildConfigString())
        buildConfigField("String", "MAPS_API_KEY", mapsApiKey.asBuildConfigString())
        buildConfigField("String", "BETA_ACCESS_TOKEN", betaAccessToken.asBuildConfigString())
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions.jvmTarget = "17"
    buildFeatures {
        compose = true
        buildConfig = true
    }
    packaging.resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2025.10.01")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.activity:activity-compose:1.11.0")
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.9.4")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.9.4")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.9.4")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.10.2")

    implementation("com.google.maps.android:maps-compose:6.12.0")
    implementation("com.google.android.libraries.places:places:5.1.1")
    implementation("com.google.android.gms:play-services-location:21.3.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.10.2")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
