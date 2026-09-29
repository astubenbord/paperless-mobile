package de.astubenbord.paperless_mobile

import org.junit.Assert.assertEquals
import org.junit.Test

class SearchIndexTest {
    @Test
    fun normalizeComposesNfd() {
        assertEquals("й", SearchIndex.normalize("й"))
    }

    @Test
    fun normalizeComposesNfdBeforeYoSwap() {
        assertEquals("елка", SearchIndex.normalize("Ёлка"))
    }
}
