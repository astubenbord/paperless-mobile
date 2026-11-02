package de.astubenbord.paperless_mobile.tunnel

import org.junit.Assert.*
import org.junit.Test

class SsidResultTest {
    @Test fun normalizesAndClassifies() {
        assertEquals("Home", normalizeSsid("\"Home\""))
        for (value in listOf("", "0x", "<unknown ssid>", "\"\"")) assertNull(normalizeSsid(value))
        assertEquals("permission_missing", ssidResult(false, true, true, "Home")["status"])
        assertEquals("location_off", ssidResult(true, false, true, "Home")["status"])
        assertEquals("not_wifi", ssidResult(true, true, false, null)["status"])
        assertEquals("unknown", ssidResult(true, true, true, "0x")["status"])
        assertEquals("Home", ssidResult(true, true, true, "Home")["ssid"])
    }
}
