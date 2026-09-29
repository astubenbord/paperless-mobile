package de.astubenbord.paperless_mobile

import android.content.Context
import android.util.Log
import androidx.appsearch.app.AppSearchBatchResult
import androidx.appsearch.app.AppSearchResult
import androidx.appsearch.app.AppSearchSchema
import androidx.appsearch.app.AppSearchSchema.PropertyConfig
import androidx.appsearch.app.AppSearchSchema.StringPropertyConfig
import androidx.appsearch.app.AppSearchSession
import androidx.appsearch.app.GenericDocument
import androidx.appsearch.app.PutDocumentsRequest
import androidx.appsearch.app.RemoveByDocumentIdRequest
import androidx.appsearch.app.SearchSpec
import androidx.appsearch.app.SetSchemaRequest
import androidx.appsearch.localstorage.LocalStorage
import java.io.File
import java.security.MessageDigest
import java.text.Normalizer
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

data class IndexedDocument(val id: Int, val title: String?, val content: String?)

data class SearchHit(val id: String, val title: String, val snippet: String)

object SearchIndex {
    private const val DATABASE = "documents"
    // Renamed on schema changes: force override drops the old type, count() hits 0 and Dart runs a full sync.
    private const val SCHEMA_TYPE = "PaperlessDocumentV2"
    private const val PREFS = "search_index"
    private const val KEY_ACTIVE_USER = "active_user_id"
    private const val VOCAB_DIR = "search_vocab"
    private const val TAG = "SearchIndex"

    val executor: ExecutorService = Executors.newSingleThreadExecutor()

    // Guarded by the object monitor; the sets are concurrent because search iterates them unlocked.
    // Sets and files are only written on the executor, so loads, puts and invalidations never overlap.
    private val vocabularies = HashMap<String, MutableSet<String>>()
    private val loading = HashSet<String>()

    @Volatile
    private var session: AppSearchSession? = null

    @Synchronized
    private fun session(context: Context): AppSearchSession {
        session?.let { return it }
        val searchContext = LocalStorage.SearchContext.Builder(context.applicationContext, DATABASE).build()
        val created = LocalStorage.createSearchSessionAsync(searchContext).get()
        try {
            created.setSchemaAsync(
                SetSchemaRequest.Builder().addSchemas(schema()).setForceOverride(true).build()
            ).get()
        } catch (e: Throwable) {
            created.close()
            throw e
        }
        session = created
        return created
    }

    private fun schema(): AppSearchSchema = AppSearchSchema.Builder(SCHEMA_TYPE)
        .addProperty(
            StringPropertyConfig.Builder("title")
                .setCardinality(PropertyConfig.CARDINALITY_OPTIONAL)
                .setIndexingType(StringPropertyConfig.INDEXING_TYPE_NONE)
                .build()
        )
        .addProperty(textProperty("searchTitle"))
        .addProperty(textProperty("content"))
        .build()

    private fun textProperty(name: String) = StringPropertyConfig.Builder(name)
        .setCardinality(PropertyConfig.CARDINALITY_OPTIONAL)
        .setIndexingType(StringPropertyConfig.INDEXING_TYPE_PREFIXES)
        .setTokenizerType(StringPropertyConfig.TOKENIZER_TYPE_PLAIN)
        .build()

    // LocalStorage ships without ICU data, so Icing does not case-fold non-ASCII text itself.
    internal fun normalize(text: String) =
        Normalizer.normalize(text, Normalizer.Form.NFC).lowercase(Locale.ROOT).replace('ё', 'е')

    fun put(context: Context, userId: String, docs: List<IndexedDocument>) {
        if (docs.isEmpty()) return
        val request = PutDocumentsRequest.Builder().addGenericDocuments(docs.map { doc ->
            val builder = GenericDocument.Builder<GenericDocument.Builder<*>>(userId, doc.id.toString(), SCHEMA_TYPE)
            doc.title?.let {
                builder.setPropertyString("title", it)
                builder.setPropertyString("searchTitle", normalize(it))
            }
            doc.content?.let { builder.setPropertyString("content", normalize(it)) }
            builder.build()
        }).build()
        session(context).putAsync(request).get().throwOnFailure { false }
        addWords(context, userId, docs.flatMap { FuzzyMatcher.vocabWords(normalize("${it.title.orEmpty()} ${it.content.orEmpty()}")) })
    }

    fun retainOnly(context: Context, userId: String, ids: List<Int>) {
        val keep = ids.map { it.toString() }.toSet()
        val stale = listIds(context, userId).filterNot { it in keep }
        if (stale.isEmpty()) return
        session(context).removeAsync(
            RemoveByDocumentIdRequest.Builder(userId).addIds(stale).build()
        ).get().throwOnFailure { it.resultCode == AppSearchResult.RESULT_NOT_FOUND }
        clearVocabulary(context, userId)
    }

    private fun <V> AppSearchBatchResult<String, V>.throwOnFailure(ignore: (AppSearchResult<V>) -> Boolean) {
        val failures = failures.filterValues { !ignore(it) }
        if (failures.isNotEmpty()) {
            throw IllegalStateException(failures.entries.joinToString { "${it.key}: ${it.value.errorMessage}" })
        }
    }

    fun clear(context: Context, userId: String) {
        session(context).removeAsync("", namespaceSpec(userId).build()).get()
        clearVocabulary(context, userId)
    }

    fun count(context: Context, userId: String): Int = listIds(context, userId).size

    fun search(context: Context, userId: String, query: String, limit: Int): List<SearchHit> {
        val terms = FuzzyMatcher.tokenize(normalize(query))
        if (terms.isEmpty()) return emptyList()
        val hits = runQuery(context, userId, terms.joinToString(" "), limit)
        if (hits.size >= limit) return hits
        val vocab = vocabulary(context, userId) ?: return hits
        val fuzzyQuery = FuzzyMatcher.expandQuery(terms) { FuzzyMatcher.candidates(it, vocab) } ?: return hits
        return FuzzyMatcher.mergeHits(hits, runQuery(context, userId, fuzzyQuery, limit + hits.size), limit)
    }

    private fun runQuery(context: Context, userId: String, query: String, limit: Int): List<SearchHit> {
        val spec = namespaceSpec(userId)
            .setTermMatch(SearchSpec.TERM_MATCH_PREFIX)
            .setRankingStrategy(SearchSpec.RANKING_STRATEGY_RELEVANCE_SCORE)
            .setResultCountPerPage(limit)
            .setSnippetCount(limit)
            .setSnippetCountPerProperty(1)
            .setMaxSnippetSize(120)
            .build()
        val page = session(context).search(query, spec).use { it.nextPageAsync.get() }
        return page.take(limit).map { result ->
            val doc = result.genericDocument
            val snippet = result.matchInfos.firstOrNull { it.propertyPath == "content" }?.snippet
            SearchHit(doc.id, doc.getPropertyString("title").orEmpty(), snippet?.toString().orEmpty())
        }
    }

    fun setActiveUser(context: Context, userId: String?) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_ACTIVE_USER, userId)
            .apply()
    }

    fun activeUser(context: Context): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_ACTIVE_USER, null)

    private fun namespaceSpec(userId: String) = SearchSpec.Builder()
        .addFilterNamespaces(userId)
        .addFilterSchemas(SCHEMA_TYPE)

    private fun listIds(context: Context, userId: String): List<String> {
        val spec = namespaceSpec(userId)
            .addProjection(SCHEMA_TYPE, emptyList())
            .setResultCountPerPage(500)
            .build()
        val ids = mutableListOf<String>()
        session(context).search("", spec).use { results ->
            while (true) {
                val page = results.nextPageAsync.get()
                if (page.isEmpty()) break
                page.mapTo(ids) { it.genericDocument.id }
            }
        }
        return ids
    }

    private fun vocabFile(context: Context, userId: String): File {
        val hash = MessageDigest.getInstance("SHA-256").digest(userId.toByteArray())
            .joinToString("") { "%02x".format(it) }
        return File(File(context.filesDir, VOCAB_DIR), "$hash.txt")
    }

    // Null until the executor has loaded the file, or rebuilt it from the index when missing.
    @Synchronized
    private fun vocabulary(context: Context, userId: String): Set<String>? {
        vocabularies[userId]?.let { return it }
        if (loading.add(userId)) {
            executor.execute {
                try {
                    loadedVocabulary(context.applicationContext, userId)
                } catch (e: Exception) {
                    Log.w(TAG, "Vocabulary load failed", e)
                } finally {
                    synchronized(this) { loading.remove(userId) }
                }
            }
        }
        return null
    }

    private fun loadedVocabulary(context: Context, userId: String): MutableSet<String> {
        synchronized(this) { vocabularies[userId] }?.let { return it }
        val words: MutableSet<String> = ConcurrentHashMap.newKeySet()
        val file = vocabFile(context, userId)
        if (file.exists()) {
            file.forEachLine { if (it.isNotEmpty()) words.add(it) }
        } else {
            words.addAll(indexedWords(context, userId))
            if (words.isNotEmpty()) {
                file.parentFile?.mkdirs()
                val temp = File(file.parentFile, "${file.name}.tmp")
                temp.writeText(words.joinToString("\n", postfix = "\n"))
                check(temp.renameTo(file)) { "Cannot rename ${temp.name}" }
            }
        }
        synchronized(this) { vocabularies[userId] = words }
        return words
    }

    private fun addWords(context: Context, userId: String, candidates: List<String>) {
        val words = loadedVocabulary(context, userId)
        val added = candidates.filterNot { it in words }.distinct()
        if (added.isEmpty()) return
        val file = vocabFile(context, userId)
        file.parentFile?.mkdirs()
        file.appendText(added.joinToString("\n", postfix = "\n"))
        words.addAll(added)
    }

    @Synchronized
    private fun clearVocabulary(context: Context, userId: String) {
        vocabularies.remove(userId)
        vocabFile(context, userId).delete()
    }

    private fun indexedWords(context: Context, userId: String): Set<String> {
        val spec = namespaceSpec(userId)
            .addProjection(SCHEMA_TYPE, listOf("searchTitle", "content"))
            .setResultCountPerPage(100)
            .build()
        val words = HashSet<String>()
        session(context).search("", spec).use { results ->
            while (true) {
                val page = results.nextPageAsync.get()
                if (page.isEmpty()) break
                page.forEach { result ->
                    val doc = result.genericDocument
                    words.addAll(FuzzyMatcher.vocabWords("${doc.getPropertyString("searchTitle").orEmpty()} ${doc.getPropertyString("content").orEmpty()}"))
                }
            }
        }
        return words
    }
}
