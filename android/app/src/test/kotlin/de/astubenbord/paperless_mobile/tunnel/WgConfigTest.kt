package de.astubenbord.paperless_mobile.tunnel

import org.junit.Assert.*
import org.junit.Test

class WgConfigTest {
    private val key = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    private val config get() = """
        [Interface]
        PrivateKey = $key
        Address = 192.0.2.2/32
        IncludedApplications = org.example.other
        ExcludedApplications = org.example.excluded
        [Peer]
        PublicKey = $key
        AllowedIPs = 0.0.0.0/0
        Endpoint = vpn.example.com:51820
    """.trimIndent()

    @Test fun pinsOwnPackageAndRemovesExclusions() {
        val parsed = WgConfig.parseAndPin(config, "de.example.app.debug")
        assertEquals(setOf("de.example.app.debug"), parsed.`interface`.includedApplications)
        assertTrue(parsed.`interface`.excludedApplications.isEmpty())
        assertEquals(1, parsed.peers.size)
    }

    @Test fun rejectsOversizedUtf8() {
        val error = org.junit.Assert.assertThrows(WgConfigException::class.java) {
            WgConfig.parseAndPin("ä".repeat(32769), "de.example.app")
        }
        assertEquals("config_too_large", error.code)
    }

    @Test fun rejectsInvalidWithoutExposingSecrets() {
        val secret = "invented-secret-marker"
        val error = org.junit.Assert.assertThrows(WgConfigException::class.java) {
            WgConfig.parseAndPin(config.replace(key, secret), "de.example.app")
        }
        assertEquals("config_invalid", error.code)
        assertFalse(error.toString().contains(secret))
        assertNull(error.cause)
    }

    @Test fun rejectsMissingPeerOrEndpoint() {
        for (invalid in listOf(config.substringBefore("[Peer]"), config.replace("Endpoint = vpn.example.com:51820", ""))) {
            assertEquals("config_invalid", org.junit.Assert.assertThrows(WgConfigException::class.java) {
                WgConfig.parseAndPin(invalid, "de.example.app")
            }.code)
        }
    }
}
