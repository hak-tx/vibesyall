package com.brianhakel.vibesyall.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class VibeTagTest {
    @Test
    fun currentTaxonomyMatchesBackendOrder() {
        assertEquals(14, VibeTag.defaults.size)
        assertEquals("changed_my_life", VibeTag.defaults.first().id)
        assertEquals("emotionally_damaging", VibeTag.defaults.last().id)
    }

    @Test
    fun legacyWorthItNormalizesToLowKey() {
        assertEquals("low_key", VibeTag.normalize("Worth It"))
        assertEquals("low_key", VibeTag.normalize("low-key"))
    }

    @Test
    fun unsupportedTagDoesNotLeakIntoSubmission() {
        assertNull(VibeTag.normalize("five stars"))
    }

    @Test
    fun distanceFormattingMatchesMapCards() {
        assertEquals("<0.1 mi", formatDistance(100.0))
        assertEquals("1.0 mi", formatDistance(1609.344))
        assertEquals("12 mi", formatDistance(19_312.128))
    }
}
