package de.astubenbord.paperless_mobile

import android.app.SearchManager
import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.provider.BaseColumns
import android.util.Log

class SearchSuggestionsProvider : ContentProvider() {
    override fun onCreate(): Boolean = true

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor {
        val cursor = MatrixCursor(COLUMNS)
        val context = context ?: return cursor
        val query = if (uri.pathSegments.contains(SearchManager.SUGGEST_URI_PATH_QUERY)) {
            uri.lastPathSegment.takeUnless { it == SearchManager.SUGGEST_URI_PATH_QUERY }
        } else {
            selectionArgs?.firstOrNull()
        }
        val userId = SearchIndex.activeUser(context)
        if (userId == null || query.isNullOrBlank()) return cursor
        val limit = uri.getQueryParameter(SearchManager.SUGGEST_PARAMETER_LIMIT)?.toIntOrNull()?.coerceIn(1, 50) ?: 10
        try {
            SearchIndex.search(context, userId, query, limit).forEachIndexed { index, hit ->
                cursor.addRow(
                    arrayOf<Any>(
                        index,
                        hit.title.ifBlank { "#${hit.id}" },
                        hit.snippet,
                        R.mipmap.ic_launcher.toString(),
                        hit.id,
                    )
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Search suggestions failed", e)
            return MatrixCursor(COLUMNS)
        }
        return cursor
    }

    override fun getType(uri: Uri): String = SearchManager.SUGGEST_MIME_TYPE

    override fun insert(uri: Uri, values: ContentValues?): Uri? = throw UnsupportedOperationException()

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int =
        throw UnsupportedOperationException()

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = throw UnsupportedOperationException()

    private companion object {
        const val TAG = "SearchSuggestions"
        val COLUMNS = arrayOf(
            BaseColumns._ID,
            SearchManager.SUGGEST_COLUMN_TEXT_1,
            SearchManager.SUGGEST_COLUMN_TEXT_2,
            SearchManager.SUGGEST_COLUMN_ICON_1,
            SearchManager.SUGGEST_COLUMN_INTENT_EXTRA_DATA,
        )
    }
}
