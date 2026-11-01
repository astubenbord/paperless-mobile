package de.astubenbord.paperless_mobile.tunnel

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class TunnelChannel(private val activity: FlutterFragmentActivity, engine: FlutterEngine) {
    private val main = Handler(Looper.getMainLooper())
    private val controller = TunnelController.get(activity)
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "de.astubenbord.paperless_mobile/tunnel")
    private var permissionResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermitted" -> try { result.success(VpnService.prepare(activity) == null) }
                    catch (_: Exception) { result.error("unknown", null, null) }
                "requestPermission" -> requestPermission(result)
                "importConfig", "hasConfig", "deleteConfig", "up", "down", "status" -> {
                    val text = if (call.method == "importConfig") call.argument<String>("text") else null
                    if (call.method == "importConfig" && text == null) {
                        result.error("config_invalid", null, null)
                    } else executor.execute {
                        try {
                            val value: Any? = when (call.method) {
                                "importConfig" -> controller.importConfig(text!!)
                                "hasConfig" -> controller.hasConfig()
                                "deleteConfig" -> { controller.deleteConfig(); null }
                                "up" -> controller.up()
                                "down" -> controller.down()
                                else -> controller.status()
                            }
                            main.post { result.success(value) }
                        } catch (e: TunnelFailure) { main.post { result.error(e.code, null, null) } }
                        catch (_: Exception) { main.post { result.error("unknown", null, null) } }
                        catch (_: LinkageError) { main.post { result.error("library_missing", null, null) } }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (permissionResult != null) { result.error("unknown", null, null); return }
        try {
            val intent = VpnService.prepare(activity)
            if (intent == null) result.success(true)
            else {
                permissionResult = result
                @Suppress("DEPRECATION")
                activity.startActivityForResult(intent, REQUEST_VPN)
            }
        } catch (_: Exception) { permissionResult = null; result.error("unknown", null, null) }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_VPN || permissionResult == null) return false
        val result = permissionResult
        permissionResult = null
        try { result?.success(resultCode == Activity.RESULT_OK && VpnService.prepare(activity) == null) }
        catch (_: Exception) { result?.error("unknown", null, null) }
        return true
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        permissionResult?.error("unknown", null, null)
        permissionResult = null
    }

    companion object {
        private const val REQUEST_VPN = 49731
        private val executor = Executors.newSingleThreadExecutor()
    }
}
