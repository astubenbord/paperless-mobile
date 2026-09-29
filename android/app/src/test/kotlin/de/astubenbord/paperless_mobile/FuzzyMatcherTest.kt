package de.astubenbord.paperless_mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class FuzzyMatcherTest {
    @Test
    fun tokenizeSplitsOnNonLetterOrDigit() {
        assertEquals(listOf("счет", "2024", "abc"), FuzzyMatcher.tokenize("счет-2024, abc!"))
    }

    @Test
    fun tokenizeKeepsCombiningMarks() {
        assertEquals(listOf("йод", "x"), FuzzyMatcher.tokenize("йод x"))
    }

    @Test
    fun tokenizeEmptyString() {
        assertEquals(emptyList<String>(), FuzzyMatcher.tokenize(""))
    }

    @Test
    fun vocabWordsDropShortAndLetterlessTokens() {
        assertEquals(listOf("счет", "12ab"), FuzzyMatcher.vocabWords("счет 2024 abc 12ab"))
    }

    @Test
    fun distanceOneForSubstitution() {
        assertEquals(1, FuzzyMatcher.distance("invoice", "invoise", 2))
    }

    @Test
    fun distanceOneForInsertion() {
        assertEquals(1, FuzzyMatcher.distance("invoice", "invoicee", 2))
    }

    @Test
    fun distanceOneForDeletion() {
        assertEquals(1, FuzzyMatcher.distance("invoice", "invoce", 2))
    }

    @Test
    fun distanceOneForTransposition() {
        assertEquals(1, FuzzyMatcher.distance("invoice", "invoiec", 2))
    }

    @Test
    fun distanceTwoForTwoSubstitutions() {
        assertEquals(2, FuzzyMatcher.distance("contract", "kontrakt", 2))
    }

    @Test
    fun distanceStopsAboveMax() {
        // Real distance is 6; the second row already exceeds max, so the scan returns max + 1.
        assertEquals(2, FuzzyMatcher.distance("abcdef", "uvwxyz", 1))
    }

    @Test
    fun distanceFromEmptyStringIsLength() {
        assertEquals(3, FuzzyMatcher.distance("", "abc", 5))
        assertEquals(3, FuzzyMatcher.distance("abc", "", 5))
    }

    @Test
    fun maxEditsByLength() {
        assertEquals(0, FuzzyMatcher.maxEdits(3))
        assertEquals(1, FuzzyMatcher.maxEdits(4))
        assertEquals(1, FuzzyMatcher.maxEdits(7))
        assertEquals(2, FuzzyMatcher.maxEdits(8))
    }

    @Test
    fun longWordsAllowTwoEdits() {
        assertEquals(listOf("contract"), FuzzyMatcher.candidates("kontrakt", listOf("contract")))
    }

    @Test
    fun midLengthWordsAllowOneEdit() {
        assertEquals(listOf("invoice"), FuzzyMatcher.candidates("invoise", listOf("invoice", "invoker")))
    }

    @Test
    fun shortWordsHaveNoCandidates() {
        assertEquals(emptyList<String>(), FuzzyMatcher.candidates("tax", listOf("tax", "tan", "taxi")))
    }

    @Test
    fun emptyTokenHasNoCandidates() {
        assertEquals(emptyList<String>(), FuzzyMatcher.candidates("", listOf("a", "ab")))
    }

    @Test
    fun letterlessTokenHasNoCandidates() {
        assertEquals(emptyList<String>(), FuzzyMatcher.candidates("2025", listOf("2024", "2026")))
    }

    @Test
    fun cyrillicTypos() {
        val vocab = listOf("снилс", "свидетельство", "паспорт")
        assertEquals(listOf("снилс"), FuzzyMatcher.candidates("снелс", vocab))
        assertEquals(listOf("свидетельство"), FuzzyMatcher.candidates("свидетелство", vocab))
    }

    @Test
    fun candidatesSortedByDistanceThenWord() {
        val vocab = listOf("dokumente", "documental", "docunent", "documents", "cabinet")
        assertEquals(
            listOf("documents", "docunent", "documental", "dokumente"),
            FuzzyMatcher.candidates("document", vocab),
        )
    }

    @Test
    fun candidatesRespectLimit() {
        val vocab = listOf("dokumente", "documental", "docunent", "documents")
        assertEquals(listOf("documents", "docunent"), FuzzyMatcher.candidates("document", vocab, limit = 2))
    }

    @Test
    fun tokenItselfExcluded() {
        assertEquals(listOf("invoices"), FuzzyMatcher.candidates("invoice", listOf("invoice", "invoices")))
    }

    @Test
    fun expandQueryGroupsTermsWithCandidates() {
        val candidates = mapOf("invoise" to listOf("invoice", "invoices"))
        assertEquals(
            "(invoise OR invoice OR invoices) 2024 tax",
            FuzzyMatcher.expandQuery(listOf("invoise", "2024", "tax")) { candidates[it].orEmpty() },
        )
    }

    @Test
    fun expandQueryNullWithoutCandidates() {
        assertNull(FuzzyMatcher.expandQuery(listOf("tax", "2024")) { emptyList() })
    }

    @Test
    fun expandQueryNullForNoTerms() {
        assertNull(FuzzyMatcher.expandQuery(emptyList()) { listOf("x") })
    }

    @Test
    fun mergeHitsPutsExactFirstAndDedupes() {
        assertEquals(
            listOf(hit("1"), hit("2"), hit("3")),
            FuzzyMatcher.mergeHits(listOf(hit("1"), hit("2")), listOf(hit("2"), hit("3")), 10),
        )
    }

    @Test
    fun mergeHitsRespectsLimit() {
        assertEquals(
            listOf(hit("1"), hit("2")),
            FuzzyMatcher.mergeHits(listOf(hit("1")), listOf(hit("2"), hit("3")), 2),
        )
    }

    @Test
    fun mergeHitsEmpty() {
        assertEquals(emptyList<SearchHit>(), FuzzyMatcher.mergeHits(emptyList(), emptyList(), 5))
    }

    private fun hit(id: String) = SearchHit(id, "title $id", "")
}
