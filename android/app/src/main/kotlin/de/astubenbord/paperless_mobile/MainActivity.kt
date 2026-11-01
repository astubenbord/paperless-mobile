package de.astubenbord.paperless_mobile

import android.content.Intent
import de.astubenbord.paperless_mobile.tunnel.TunnelChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private var tunnelChannel: TunnelChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        tunnelChannel = TunnelChannel(this, flutterEngine)
    }

    @Deprecated("Android activity result API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (tunnelChannel?.onActivityResult(requestCode, resultCode, data) != true) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        tunnelChannel?.dispose()
        tunnelChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
