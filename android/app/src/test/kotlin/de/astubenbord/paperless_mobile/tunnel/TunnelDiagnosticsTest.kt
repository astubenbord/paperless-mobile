package de.astubenbord.paperless_mobile.tunnel

import org.junit.Assert.*
import org.junit.Test

class TunnelDiagnosticsTest {
    @Test fun selectsOnlyNonSecretFields() {
        val key = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        val config = WgConfig.parseAndPin("""
            [Interface]
            PrivateKey = $key
            Address = 192.0.2.2/32
            DNS = 192.0.2.53, example.org
            [Peer]
            PublicKey = $key
            AllowedIPs = 192.168.2.0/24
            Endpoint = vpn.example.com:51820
        """.trimIndent(), "de.example.app")
        val data = diagnosticMap(config, "UP", mapOf(config.peers.first().publicKey to PeerCounters(7, 9, 12)))
        assertFalse(data.toString().contains(key))
        assertEquals(listOf("192.0.2.53"), data["dnsServers"])
        assertEquals(listOf("example.org"), data["searchDomains"])
        val peer = (data["peers"] as List<*>).first() as Map<*, *>
        assertEquals("vpn.example.com", peer["endpointHost"])
        assertEquals(51820, peer["endpointPort"])
        assertEquals(listOf("192.168.2.0/24"), peer["allowedIps"])
        assertEquals(7L, peer["rxBytes"])
        assertFalse(data.toString().contains("Key", ignoreCase = true))
    }
}
