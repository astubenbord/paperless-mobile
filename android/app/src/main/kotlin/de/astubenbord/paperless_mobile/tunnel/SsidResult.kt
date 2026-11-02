package de.astubenbord.paperless_mobile.tunnel

internal fun normalizeSsid(raw: String?): String? {
    val value = raw?.trim()?.removeSurrounding("\"")?.trim() ?: return null
    return value.takeUnless { it.isEmpty() || it.equals("<unknown ssid>", true) || it == "0x" }
}

internal fun ssidResult(permitted: Boolean, locationEnabled: Boolean, wifi: Boolean, raw: String?): Map<String, String?> {
    val ssid = normalizeSsid(raw)
    val status = when {
        !permitted -> "permission_missing"
        !locationEnabled -> "location_off"
        !wifi -> "not_wifi"
        ssid == null -> "unknown"
        else -> "ok"
    }
    return mapOf("ssid" to if (status == "ok") ssid else null, "status" to status)
}
