package de.astubenbord.paperless_mobile

import android.app.Activity
import android.app.SearchManager
import android.content.Intent
import android.os.Bundle

class SearchTrampolineActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val launch = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        intent.getStringExtra(SearchManager.EXTRA_DATA_KEY)?.toIntOrNull()?.let {
            launch.putExtra(MainActivity.EXTRA_OPEN_DOCUMENT_ID, it)
        }
        startActivity(launch)
        finish()
    }
}
