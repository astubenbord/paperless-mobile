package de.astubenbord.paperless_mobile.tunnel

import com.wireguard.config.Config

/** Never attach parser exceptions: their messages may contain secret key material. */
class WgConfigException(val code: String) : Exception(code)

object WgConfig {
    const val MAX_BYTES = 64 * 1024

    fun parseAndPin(text: String, packageName: String): Config {
        if (text.toByteArray(Charsets.UTF_8).size > MAX_BYTES) {
            throw WgConfigException("config_too_large")
        }
        val config = try {
            require(packageName.matches(Regex("[A-Za-z0-9_]+(?:\\.[A-Za-z0-9_]+)+")))
            var inInterface = false
            val pinned = buildString {
                for (line in text.lineSequence()) {
                    val content = line.substringBefore('#').trim()
                    if (content.startsWith("[")) {
                        inInterface = content.equals("[Interface]", ignoreCase = true)
                        appendLine(line)
                        if (inInterface) appendLine("IncludedApplications = $packageName")
                    } else if (!(inInterface && content.substringBefore('=').trim().let {
                        it.equals("IncludedApplications", true) || it.equals("ExcludedApplications", true)
                    })) appendLine(line)
                }
            }
            Config.parse(pinned.reader().buffered())
        } catch (_: Exception) {
            throw WgConfigException("config_invalid")
        }
        if (config.peers.isEmpty() || config.peers.any { !it.endpoint.isPresent }) {
            throw WgConfigException("config_invalid")
        }
        return config
    }
}
