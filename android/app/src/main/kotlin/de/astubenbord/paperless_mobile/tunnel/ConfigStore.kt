package de.astubenbord.paperless_mobile.tunnel

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.AtomicFile
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** noBackupFilesDir excludes the ciphertext from both cloud backup and device transfer. */
class ConfigStore(context: Context) {
    private val file = AtomicFile(File(context.applicationContext.noBackupFilesDir, "tunnel_config"))
    private val alias = "paperless_mobile_tunnel_config_v1"

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").run {
            init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
            generateKey()
        }
    }

    fun exists(): Boolean = file.baseFile.exists()
    fun delete() = file.delete()

    fun save(text: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val bytes = byteArrayOf(1, cipher.iv.size.toByte()) + cipher.iv + cipher.doFinal(text.toByteArray(Charsets.UTF_8))
        val stream = file.startWrite()
        try { stream.write(bytes); file.finishWrite(stream) } catch (e: Exception) { file.failWrite(stream); throw e }
    }

    fun load(): String? {
        if (!exists()) return null
        val bytes = file.readFully()
        require(bytes.size >= 30 && bytes.size <= WgConfig.MAX_BYTES + 64 && bytes[0] == 1.toByte())
        val ivSize = bytes[1].toInt() and 0xff
        require(ivSize == 12 && bytes.size >= 2 + ivSize + 16)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, bytes, 2, ivSize))
        return cipher.doFinal(bytes, 2 + ivSize, bytes.size - 2 - ivSize).toString(Charsets.UTF_8)
    }
}
