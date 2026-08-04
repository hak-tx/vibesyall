package com.brianhakel.vibesyall.data

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import java.security.MessageDigest
import java.util.UUID
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class SecureIdentityStore(context: Context) {
    private val preferences = context.getSharedPreferences("secure_identity", Context.MODE_PRIVATE)
    private val sessionPreferences = context.getSharedPreferences("vibes_session", Context.MODE_PRIVATE)
    private val alias = "vibes_yall_anonymous_identity"

    val deviceIdHash: String by lazy {
        val rawId = readEncryptedId() ?: UUID.randomUUID().toString().also(::writeEncryptedId)
        MessageDigest.getInstance("SHA-256")
            .digest(rawId.toByteArray(StandardCharsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
    }

    var accountSessionToken: String?
        get() = sessionPreferences.getString("account_session_token", null)
        set(value) {
            sessionPreferences.edit().apply {
                if (value.isNullOrBlank()) remove("account_session_token") else putString("account_session_token", value)
            }.apply()
        }

    private fun key(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keyStore.getKey(alias, null) as? SecretKey)?.let { return it }
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").run {
            init(
                KeyGenParameterSpec.Builder(
                    alias,
                    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
                )
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .build(),
            )
            generateKey()
        }
    }

    private fun readEncryptedId(): String? = runCatching {
        val encrypted = preferences.getString("device_id", null) ?: return null
        val iv = preferences.getString("device_id_iv", null) ?: return null
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, Base64.decode(iv, Base64.NO_WRAP)))
        String(cipher.doFinal(Base64.decode(encrypted, Base64.NO_WRAP)), StandardCharsets.UTF_8)
    }.getOrNull()

    private fun writeEncryptedId(value: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val encrypted = cipher.doFinal(value.toByteArray(StandardCharsets.UTF_8))
        preferences.edit()
            .putString("device_id", Base64.encodeToString(encrypted, Base64.NO_WRAP))
            .putString("device_id_iv", Base64.encodeToString(cipher.iv, Base64.NO_WRAP))
            .apply()
    }
}
