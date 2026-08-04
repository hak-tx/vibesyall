package com.brianhakel.vibesyall.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val BrandNavy = Color(0xFF102C6B)
val BrandYellow = Color(0xFFDFD771)
val Ink = Color(0xFF0A0F14)
val MutedInk = Color(0xFF6E757F)
val Sheet = Color(0xFFFAF8F4)
val SoftSurface = Color(0xFFF1F2EE)

private val VibesColors = lightColorScheme(
    primary = BrandNavy,
    onPrimary = Color.White,
    secondary = BrandYellow,
    onSecondary = Ink,
    background = Sheet,
    onBackground = Ink,
    surface = Sheet,
    onSurface = Ink,
    surfaceVariant = SoftSurface,
    onSurfaceVariant = MutedInk,
    error = Color(0xFFB3261E),
)

@Composable
fun VibesYallTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = VibesColors, content = content)
}
