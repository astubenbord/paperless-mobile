package de.astubenbord.paperless_mobile.tunnel

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Build
import androidx.core.content.ContextCompat
import android.net.VpnService
import com.wireguard.android.backend.BackendException
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel

class TunnelFailure(val code: String) : Exception(code)

/** All calls must run on the channel's single background executor. */
class TunnelController private constructor(context: Context) {
    private val context = context.applicationContext
    private val store = ConfigStore(this.context)
    private val backend by lazy { GoBackend(this.context) }
    private val tunnel = object : Tunnel {
        override fun getName() = "paperless_mobile"
        override fun onStateChange(newState: Tunnel.State) = Unit
    }

    fun importConfig(text: String): Map<String, Any> = safely {
        val config = WgConfig.parseAndPin(text, context.packageName)
        store.save(text)
        mapOf("endpointHost" to config.peers.first().endpoint.get().host,
            "peerCount" to config.peers.size,
            "interfaceAddresses" to config.`interface`.addresses.map { it.toString() })
    }
    @Suppress("DEPRECATION", "MissingPermission")
    fun currentSsid(): Map<String, String?> {
        val permitted = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!permitted) return ssidResult(false, true, false, null)
        val location = context.getSystemService(LocationManager::class.java)
        val locationEnabled = Build.VERSION.SDK_INT < 28 || location.isLocationEnabled
        if (!locationEnabled) return ssidResult(true, false, false, null)
        return try {
            val connectivity = context.getSystemService(ConnectivityManager::class.java)
            val active = connectivity.getNetworkCapabilities(connectivity.activeNetwork)
            val caps = if (active?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true &&
                !active.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) &&
                !active.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                connectivity.allNetworks.mapNotNull { connectivity.getNetworkCapabilities(it) }.filter {
                    !it.hasTransport(NetworkCapabilities.TRANSPORT_VPN) &&
                        it.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                        it.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
                }
            } else listOfNotNull(active)
            val wifi = caps.any { it.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) } &&
                caps.none { it.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) }
            val raw = if (wifi) context.getSystemService(WifiManager::class.java).connectionInfo?.ssid else null
            ssidResult(true, true, wifi, raw)
        } catch (_: SecurityException) {
            mapOf("ssid" to null, "status" to "unknown")
        }
    }

    fun hasConfig(): Boolean = safely { store.exists() }
    fun deleteConfig() = safely { store.delete() }
    fun up(): String = safely {
        if (VpnService.prepare(context) != null) throw TunnelFailure("vpn_not_authorized")
        val text = store.load() ?: throw TunnelFailure("config_missing")
        backend.setState(tunnel, Tunnel.State.UP, WgConfig.parseAndPin(text, context.packageName)).name
    }
    fun down(): String = safely { backend.setState(tunnel, Tunnel.State.DOWN, null).name }
    fun diagnostics(): Map<String, Any?> = safely {
        val text = store.load() ?: throw TunnelFailure("config_missing")
        val config = WgConfig.parseAndPin(text, context.packageName)
        val state = backend.getState(tunnel)
        val counters = if (state == Tunnel.State.UP) {
            val statistics = backend.getStatistics(tunnel)
            statistics.peers().associateWith { key ->
                val peer = statistics.peer(key)
                PeerCounters(peer?.rxBytes() ?: 0L, peer?.txBytes() ?: 0L, peer?.latestHandshakeEpochMillis() ?: 0L)
            }
        } else emptyMap()
        diagnosticMap(config, state.name, counters)
    }
    fun status(): String = safely { backend.getState(tunnel).name }

    private inline fun <T> safely(block: () -> T): T = try { block() }
    catch (e: TunnelFailure) { throw e }
    catch (e: WgConfigException) { throw TunnelFailure(e.code) }
    catch (e: BackendException) {
        throw TunnelFailure(when (e.reason) {
            BackendException.Reason.VPN_NOT_AUTHORIZED -> "vpn_not_authorized"
            BackendException.Reason.DNS_RESOLUTION_FAILURE -> "dns_failure"
            BackendException.Reason.TUNNEL_MISSING_CONFIG -> "config_missing"
            BackendException.Reason.UNABLE_TO_START_VPN -> "vpn_start_failed"
            BackendException.Reason.TUN_CREATION_ERROR -> "tun_failed"
            else -> "unknown"
        })
    } catch (_: SecurityException) { throw TunnelFailure("vpn_not_authorized") }
    catch (_: LinkageError) { throw TunnelFailure("library_missing") }
    catch (_: Exception) { throw TunnelFailure("unknown") }

    companion object {
        @Volatile private var instance: TunnelController? = null
        fun get(context: Context): TunnelController = instance ?: synchronized(this) {
            instance ?: TunnelController(context.applicationContext).also { instance = it }
        }
    }
}
