package de.astubenbord.paperless_mobile

import kotlin.math.abs
import kotlin.math.min

object FuzzyMatcher {
    private const val MIN_VOCAB_WORD = 4
    private val separator = Regex("[^\\p{L}\\p{M}\\p{N}]+")

    fun tokenize(normalizedText: String): List<String> =
        normalizedText.split(separator).filter { it.isNotEmpty() }

    fun vocabWords(normalizedText: String): List<String> =
        tokenize(normalizedText).filter { it.length >= MIN_VOCAB_WORD && it.any(Char::isLetter) }

    fun maxEdits(length: Int): Int = when {
        length < 4 -> 0
        length < 8 -> 1
        else -> 2
    }

    fun candidates(token: String, vocab: Collection<String>, limit: Int = 10): List<String> {
        val max = maxEdits(token.length)
        if (max == 0 || token.none(Char::isLetter)) return emptyList()
        return vocab.asSequence()
            .filter { it != token && abs(it.length - token.length) <= max }
            .map { it to distance(token, it, max) }
            .filter { it.second <= max }
            .sortedWith(compareBy({ it.second }, { it.first }))
            .take(limit)
            .map { it.first }
            .toList()
    }

    fun expandQuery(terms: List<String>, candidatesFor: (String) -> List<String>): String? {
        val expansions = terms.map(candidatesFor)
        if (expansions.all { it.isEmpty() }) return null
        return terms.zip(expansions).joinToString(" ") { (term, candidates) ->
            if (candidates.isEmpty()) term else (listOf(term) + candidates).joinToString(" OR ", "(", ")")
        }
    }

    fun mergeHits(exact: List<SearchHit>, fuzzy: List<SearchHit>, limit: Int): List<SearchHit> =
        (exact + fuzzy).distinctBy { it.id }.take(limit)

    // Optimal string alignment distance; returns max + 1 as soon as the result must exceed max.
    fun distance(a: String, b: String, max: Int): Int {
        var twoBack = IntArray(b.length + 1)
        var previous = IntArray(b.length + 1) { it }
        var current = IntArray(b.length + 1)
        for (i in 1..a.length) {
            current[0] = i
            var rowMin = i
            for (j in 1..b.length) {
                val cost = if (a[i - 1] == b[j - 1]) 0 else 1
                var value = min(min(previous[j] + 1, current[j - 1] + 1), previous[j - 1] + cost)
                if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
                    value = min(value, twoBack[j - 2] + 1)
                }
                current[j] = value
                rowMin = min(rowMin, value)
            }
            if (rowMin > max) return max + 1
            val recycled = twoBack
            twoBack = previous
            previous = current
            current = recycled
        }
        return min(previous[b.length], max + 1)
    }
}
