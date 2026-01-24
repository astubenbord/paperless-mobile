package de.astubenbord.paperless_mobile

import android.os.Handler
import android.os.Looper
import android.security.KeyChain
import android.security.KeyChainAliasCallback
import android.util.Base64
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException
import java.security.SecureRandom
import java.security.cert.X509Certificate
import java.util.concurrent.TimeUnit
import javax.net.ssl.HostnameVerifier
import javax.net.ssl.KeyManager
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocketFactory
import javax.net.ssl.TrustManager
import javax.net.ssl.X509KeyManager
import javax.net.ssl.X509TrustManager

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "paperless_mobile/android_keychain"
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "selectClientCertificate" -> {
                        val host = call.argument<String>("host")
                        val port = call.argument<Int>("port")
                        selectAlias(host, port, result)
                    }
                    "getCertificateSubject" -> {
                        val alias = call.argument<String>("alias")
                        if (alias.isNullOrBlank()) {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        Thread {
                            try {
                                val chain = KeyChain.getCertificateChain(this, alias)
                                val subj = chain?.firstOrNull()?.subjectX500Principal?.name
                                mainHandler.post { result.success(subj) }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("CERT_INFO", e.message, null) }
                            }
                        }.start()
                    }
                    "httpRequest" -> {
                        httpRequest(call, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun selectAlias(host: String?, port: Int?, result: MethodChannel.Result) {
        val callback = KeyChainAliasCallback { alias ->
            mainHandler.post { result.success(alias) }
        }

        // keyTypes: allow both RSA and EC. Some devices ignore null and require non-empty.
        val keyTypes = arrayOf("RSA", "EC")
        val issuers: Array<java.security.Principal>? = null

        try {
            KeyChain.choosePrivateKeyAlias(
                this,
                callback,
                keyTypes,
                issuers,
                host,
                port ?: -1,
                null
            )
        } catch (e: Exception) {
            result.error("KEYCHAIN", e.message, null)
        }
    }

    private fun httpRequest(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        val alias = call.argument<String>("alias")
        val method = call.argument<String>("method") ?: "GET"
        val url = call.argument<String>("url")
        val headers = call.argument<Map<String, String>>("headers") ?: emptyMap()
        val followRedirects = call.argument<Boolean>("followRedirects") ?: true

        val connectTimeoutMs = call.argument<Int>("connectTimeoutMs")
        val readTimeoutMs = call.argument<Int>("readTimeoutMs")
        val writeTimeoutMs = call.argument<Int>("writeTimeoutMs")

        val bodyBytes: ByteArray? = when (val b = call.argument<Any>("body")) {
            is ByteArray -> b
            is List<*> -> b.filterIsInstance<Number>().map { it.toInt().toByte() }.toByteArray()
            is String -> Base64.decode(b, Base64.DEFAULT)
            else -> null
        }

        if (alias.isNullOrBlank()) {
            result.error("NO_ALIAS", "No KeyChain alias provided", null)
            return
        }
        if (url.isNullOrBlank()) {
            result.error("NO_URL", "No URL provided", null)
            return
        }

        Thread {
            try {
                val client = buildOkHttpClient(alias, followRedirects, connectTimeoutMs, readTimeoutMs, writeTimeoutMs)
                val reqBuilder = Request.Builder().url(url)
                for ((k, v) in headers) {
                    reqBuilder.addHeader(k, v)
                }

                val contentType = headers["Content-Type"]?.toMediaTypeOrNull()
                val requestBody = if (bodyBytes != null) {
                    bodyBytes.toRequestBody(contentType)
                } else {
                    // OkHttp requires a body for some methods (e.g., POST) even if empty.
                    if (method.equals("POST", true) || method.equals("PUT", true) || method.equals("PATCH", true)) {
                        ByteArray(0).toRequestBody(contentType)
                    } else {
                        null
                    }
                }

                val request = when (method.uppercase()) {
                    "GET" -> reqBuilder.get().build()
                    "HEAD" -> reqBuilder.head().build()
                    "POST" -> reqBuilder.post(requestBody!!).build()
                    "PUT" -> reqBuilder.put(requestBody!!).build()
                    "PATCH" -> reqBuilder.patch(requestBody!!).build()
                    "DELETE" -> if (requestBody != null) reqBuilder.delete(requestBody).build() else reqBuilder.delete().build()
                    else -> reqBuilder.method(method.uppercase(), requestBody).build()
                }

                client.newCall(request).execute().use { resp ->
                    val respBytes = resp.body?.bytes() ?: ByteArray(0)
                    val respHeaders = mutableMapOf<String, List<String>>()
                    for (name in resp.headers.names()) {
                        respHeaders[name] = resp.headers.values(name)
                    }
                    val payload = mapOf(
                        "statusCode" to resp.code,
                        "reasonPhrase" to resp.message,
                        "headers" to respHeaders,
                        "body" to respBytes
                    )
                    mainHandler.post { result.success(payload) }
                }
            } catch (e: IOException) {
                mainHandler.post { result.error("IO", e.message, null) }
            } catch (e: Exception) {
                mainHandler.post { result.error("HTTP", e.message, null) }
            }
        }.start()
    }

    private fun buildOkHttpClient(
        alias: String,
        followRedirects: Boolean,
        connectTimeoutMs: Int?,
        readTimeoutMs: Int?,
        writeTimeoutMs: Int?
    ): OkHttpClient {
        val trustAllCerts = arrayOf<TrustManager>(object : X509TrustManager {
            override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {}
            override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {}
            override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()
        })
        val trustManager = trustAllCerts[0] as X509TrustManager

        val keyManager: X509KeyManager = object : X509KeyManager {
            override fun getClientAliases(keyType: String?, issuers: Array<out java.security.Principal>?): Array<String> = arrayOf(alias)
            override fun chooseClientAlias(keyType: Array<out String>?, issuers: Array<out java.security.Principal>?, socket: java.net.Socket?): String = alias
            override fun getServerAliases(keyType: String?, issuers: Array<out java.security.Principal>?): Array<String>? = null
            override fun chooseServerAlias(keyType: String?, issuers: Array<out java.security.Principal>?, socket: java.net.Socket?): String? = null
            override fun getCertificateChain(aliasRequested: String?): Array<X509Certificate>? {
                val a = aliasRequested ?: alias
                val chain = KeyChain.getCertificateChain(this@MainActivity, a) ?: return null
                @Suppress("UNCHECKED_CAST")
                return chain as Array<X509Certificate>
            }
            override fun getPrivateKey(aliasRequested: String?): java.security.PrivateKey? {
                val a = aliasRequested ?: alias
                return KeyChain.getPrivateKey(this@MainActivity, a)
            }
        }

        val sslContext = SSLContext.getInstance("TLS")
        sslContext.init(arrayOf<KeyManager>(keyManager), trustAllCerts, SecureRandom())
        val sslSocketFactory: SSLSocketFactory = sslContext.socketFactory

        val verifier = HostnameVerifier { _, _ -> true }

        val builder = OkHttpClient.Builder()
            .sslSocketFactory(sslSocketFactory, trustManager)
            .hostnameVerifier(verifier)
            .followRedirects(followRedirects)
            .followSslRedirects(followRedirects)

        if (connectTimeoutMs != null) builder.connectTimeout(connectTimeoutMs.toLong(), TimeUnit.MILLISECONDS)
        if (readTimeoutMs != null) builder.readTimeout(readTimeoutMs.toLong(), TimeUnit.MILLISECONDS)
        if (writeTimeoutMs != null) builder.writeTimeout(writeTimeoutMs.toLong(), TimeUnit.MILLISECONDS)

        return builder.build()
    }
}
