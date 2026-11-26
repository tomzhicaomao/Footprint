package com.footprint.service

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import java.util.Locale
import java.util.UUID
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * Offline Chinese TTS announcer tuned for e-bike riding & Bluetooth helmet headsets.
 * Requests transient ducking audio focus so background music/navigation lowers smoothly.
 */
class RideVoiceAnnouncer(context: Context) : TextToSpeech.OnInitListener {

    private val appContext = context.applicationContext
    private val audioManager = appContext.getSystemService(AudioManager::class.java)
    private var tts: TextToSpeech? = null
    @Volatile private var isReady = false
    @Volatile private var isShutDown = false
    private val pendingQueue = ConcurrentLinkedQueue<String>()
    private var focusRequest: AudioFocusRequest? = null

    private val audioAttrs: AudioAttributes =
            AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()

    init {
        try {
            tts = TextToSpeech(appContext, this)
        } catch (e: Exception) {
            Log.w("RideVoice", "Failed to initialize TextToSpeech: ${e.message}")
        }
    }

    override fun onInit(status: Int) {
        if (isShutDown) {
            shutdown()
            return
        }
        if (status == TextToSpeech.SUCCESS) {
            val engine = tts ?: return
            val res = engine.setLanguage(Locale.CHINA)
            if (res == TextToSpeech.LANG_MISSING_DATA || res == TextToSpeech.LANG_NOT_SUPPORTED) {
                val fallback = engine.setLanguage(Locale.CHINESE)
                if (fallback == TextToSpeech.LANG_MISSING_DATA || fallback == TextToSpeech.LANG_NOT_SUPPORTED) {
                    engine.setLanguage(Locale.getDefault())
                }
            }
            engine.setAudioAttributes(audioAttrs)
            engine.setSpeechRate(1.05f)
            engine.setPitch(1.0f)
            engine.setOnUtteranceProgressListener(
                    object : UtteranceProgressListener() {
                        override fun onStart(utteranceId: String?) {}
                        override fun onDone(utteranceId: String?) {
                            abandonAudioFocus()
                        }
                        @Deprecated("Deprecated in Java")
                        override fun onError(utteranceId: String?) {
                            abandonAudioFocus()
                        }
                        override fun onError(utteranceId: String?, errorCode: Int) {
                            abandonAudioFocus()
                        }
                    }
            )
            isReady = true
            while (pendingQueue.isNotEmpty()) {
                val next = pendingQueue.poll() ?: break
                speakInternal(next, TextToSpeech.QUEUE_ADD)
            }
        } else {
            Log.w("RideVoice", "TTS init failed with status=$status")
        }
    }

    fun speak(text: String, flush: Boolean = false) {
        if (isShutDown || text.isBlank()) return
        if (!isReady) {
            if (flush) pendingQueue.clear()
            if (pendingQueue.size < 4) pendingQueue.offer(text)
            return
        }
        speakInternal(text, if (flush) TextToSpeech.QUEUE_FLUSH else TextToSpeech.QUEUE_ADD)
    }

    private fun speakInternal(text: String, queueMode: Int) {
        try {
            requestDuckFocus()
            val utteranceId = "ride_${UUID.randomUUID()}"
            val params = Bundle().apply {
                putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, 1.0f)
            }
            tts?.speak(text, queueMode, params, utteranceId)
            Log.d("RideVoice", "Speaking: $text")
        } catch (e: Exception) {
            Log.w("RideVoice", "Speak failed: ${e.message}")
            abandonAudioFocus()
        }
    }

    @Suppress("DEPRECATION")
    private fun requestDuckFocus() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val req =
                        AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
                                .setAudioAttributes(audioAttrs)
                                .setAcceptsDelayedFocusGain(false)
                                .setOnAudioFocusChangeListener {}
                                .build()
                focusRequest = req
                audioManager?.requestAudioFocus(req)
            } else {
                audioManager?.requestAudioFocus(
                        null,
                        AudioManager.STREAM_MUSIC,
                        AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK
                )
            }
        } catch (_: Exception) {}
    }

    @Suppress("DEPRECATION")
    private fun abandonAudioFocus() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                focusRequest?.let { audioManager?.abandonAudioFocusRequest(it) }
                focusRequest = null
            } else {
                audioManager?.abandonAudioFocus(null)
            }
        } catch (_: Exception) {}
    }

    fun shutdown() {
        isShutDown = true
        isReady = false
        pendingQueue.clear()
        abandonAudioFocus()
        try {
            tts?.stop()
            tts?.shutdown()
        } catch (_: Exception) {}
        tts = null
    }
}
