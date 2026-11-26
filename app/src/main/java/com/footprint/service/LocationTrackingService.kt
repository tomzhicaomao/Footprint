package com.footprint.service

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.location.AMapLocationListener
import com.footprint.data.model.Mood
import com.footprint.data.model.TransportType
import com.footprint.utils.PreferenceManager
import java.util.Calendar
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class LocationTrackingService : Service(), AMapLocationListener {

    private var locationClient: AMapLocationClient? = null
    private var locationOption: AMapLocationClientOption? = null
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private lateinit var repository: com.footprint.data.repository.FootprintRepository
    private lateinit var preferenceManager: PreferenceManager
    private lateinit var notificationManager: NotificationManager
    private var _notificationUpdateJob: Job? = null
    private var _btAutoStopJob: Job? = null
    private var _voiceAnnouncer: RideVoiceAnnouncer? = null
    private var _nextVoiceMilestoneKm: Double = 1.0
    private var _lowBatteryVoiceAlerted: Boolean = false
    private val trackingPathBuffer = mutableListOf<AMapLocation>()
    private val pendingTrackPoints = mutableListOf<AMapLocation>()

    // Rate limiting & telemetry helpers
    private var _lastSaveTime: Long = 0
    private var _lastNotifyTime: Long = 0
    private var _lastDistancePersist: Float = 0.0f
    private var _lastTrackingMode: TrackingMode? = null
    private var _lastMovementElapsedTime: Long = 0L
    private var _lowSpeedSinceElapsedMs: Long = 0L
    private var _autoPauseAnchorLocation: AMapLocation? = null
    private var _smoothedSpeedMs: Float = 0f
    private var _startAddress: String = ""

    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID = "location_tracking_channel"
        const val ACTION_START_TRACKING = "com.footprint.START_TRACKING"
        const val ACTION_STOP_TRACKING = "com.footprint.STOP_TRACKING"
        const val ACTION_PAUSE_TRACKING = "com.footprint.PAUSE_TRACKING"
        const val ACTION_RESUME_TRACKING = "com.footprint.RESUME_TRACKING"
        const val ACTION_RESTORE_TRACKING = "com.footprint.RESTORE_TRACKING"
        const val ACTION_SCHEDULE_BT_AUTO_STOP = "com.footprint.SCHEDULE_BT_AUTO_STOP"
        const val ACTION_CANCEL_BT_AUTO_STOP = "com.footprint.CANCEL_BT_AUTO_STOP"
        const val EXTRA_TRANSPORT_TYPE = "extra_transport_type"
        const val EXTRA_DISCARD_SESSION = "extra_discard_session"
        const val EXTRA_AUTO_TRIGGERED = "extra_auto_triggered"
        private const val BT_DISCONNECT_GRACE_MS = 20000L

        // Thresholds tuned for e-bike / urban riding accuracy
        private const val MAX_SPEED_EBIKE_MS = 28.0f // ~100 km/h ceiling rejects GPS teleports
        private const val MAX_SPEED_WALK_MS = 10.0f // ~36 km/h
        private const val MAX_SPEED_GENERAL_MS = 50.0f // ~180 km/h
        private const val MAX_ACCURACY_STRICT_M = 35.0f
        private const val MAX_ACCURACY_COLD_START_M = 65.0f
        private const val MIN_CRUISE_DISTANCE_M = 1.5f
        private const val MIN_VALID_LATLNG = 0.1
        private const val BASE_INTERVAL_MS = 2500L
        private const val STATIONARY_INTERVAL_MS = 20000L
        private const val WAIT_INTERVAL_MS = 3000L
        private const val WALKING_INTERVAL_MS = 4000L
        private const val MOVING_INTERVAL_MS = 2000L
        private const val FAST_MOVING_INTERVAL_MS = 1500L
        private const val TRACK_BATCH_WINDOW_MS = 15000L
        private const val TRACK_BATCH_SIZE = 5
        private const val NOTIFICATION_UPDATE_INTERVAL_MS = 10000L
        private const val DISTANCE_PERSIST_STEP_M = 30.0f
        private const val STATIONARY_GRACE_MS = 300000L // 5 min before relaxing interval
        private const val AUTO_PAUSE_DELAY_MS = 8000L // 8s low speed -> red-light auto-pause
        private const val AUTO_PAUSE_SPEED_THRESHOLD_MS = 0.5f // < 1.8 km/h
        private const val AUTO_RESUME_SPEED_THRESHOLD_MS = 1.2f // >= 4.3 km/h
        private const val AUTO_RESUME_DISTANCE_M = 10.0f
        private const val STATIONARY_JITTER_DISTANCE_M = 8.0f
        private const val LOCATION_HTTP_TIMEOUT_MS = 10000L
        private const val RESTART_REQUEST_CODE = 2201
        private const val RESTART_DELAY_MS = 5000L

        private val _sharedIsTracking = MutableStateFlow(false)
        val isTracking: StateFlow<Boolean> = _sharedIsTracking.asStateFlow()

        private val _sharedIsPaused = MutableStateFlow(false)
        val isPaused: StateFlow<Boolean> = _sharedIsPaused.asStateFlow()

        private val _sharedIsAutoPaused = MutableStateFlow(false)
        val isAutoPaused: StateFlow<Boolean> = _sharedIsAutoPaused.asStateFlow()

        private val _sharedCurrentLocation = MutableStateFlow<AMapLocation?>(null)
        val currentLocation: StateFlow<AMapLocation?> = _sharedCurrentLocation.asStateFlow()

        private val _totalDistanceTraveled = MutableStateFlow(0.0f)
        val totalDistance: StateFlow<Float> = _totalDistanceTraveled.asStateFlow()

        private val _currentSpeedKmh = MutableStateFlow(0.0f)
        val currentSpeedKmh: StateFlow<Float> = _currentSpeedKmh.asStateFlow()

        private val _maxSpeedKmh = MutableStateFlow(0.0f)
        val maxSpeedKmh: StateFlow<Float> = _maxSpeedKmh.asStateFlow()

        private val _gpsAccuracy = MutableStateFlow(0.0f)
        val gpsAccuracy: StateFlow<Float> = _gpsAccuracy.asStateFlow()

        private val _activeTransportType = MutableStateFlow(TransportType.EBIKE.name)
        val activeTransportType: StateFlow<String> = _activeTransportType.asStateFlow()

        private var _accumulatedDurationMs: Long = 0
        private var _lastResumeTime: Long = 0

        val totalDurationMs: Long
            get() {
                if (!_sharedIsTracking.value) return 0L
                val isEffectivelyPaused = _sharedIsPaused.value || _sharedIsAutoPaused.value
                val currentSegment =
                        if (isEffectivelyPaused || _lastResumeTime <= 0L) 0L
                        else (System.currentTimeMillis() - _lastResumeTime).coerceAtLeast(0L)
                return (_accumulatedDurationMs + currentSegment).coerceAtLeast(0L)
            }

        val avgSpeedKmh: Double
            get() {
                val sec = totalDurationMs / 1000.0
                if (sec < 3.0 || _totalDistanceTraveled.value < 5f) return 0.0
                val hours = sec / 3600.0
                return (_totalDistanceTraveled.value / 1000.0) / hours
            }

        private var _sessionStartTime: Long = 0
        val sessionStartTime: Long
            get() = _sessionStartTime

        private var _lastLocation: AMapLocation? = null

        private val _sharedTrackingPath = MutableStateFlow<List<AMapLocation>>(emptyList())
        val trackingPath: StateFlow<List<AMapLocation>> = _sharedTrackingPath.asStateFlow()

        private val _locationError = MutableStateFlow<String?>(null)
        val locationError: StateFlow<String?> = _locationError.asStateFlow()

        fun clearError() {
            _locationError.value = null
        }

        fun startTracking(
                context: Context,
                transportType: String? = null,
                autoTriggered: Boolean = false
        ) {
            val intent =
                    Intent(context, LocationTrackingService::class.java).apply {
                        action = ACTION_START_TRACKING
                        if (!transportType.isNullOrBlank()) {
                            putExtra(EXTRA_TRANSPORT_TYPE, transportType)
                        }
                        putExtra(EXTRA_AUTO_TRIGGERED, autoTriggered)
                    }
            ContextCompat.startForegroundService(context, intent)
        }

        fun stopTracking(context: Context, discard: Boolean = false) {
            val intent =
                    Intent(context, LocationTrackingService::class.java).apply {
                        action = ACTION_STOP_TRACKING
                        putExtra(EXTRA_DISCARD_SESSION, discard)
                    }
            ContextCompat.startForegroundService(context, intent)
        }

        fun pauseTracking(context: Context) {
            val intent =
                    Intent(context, LocationTrackingService::class.java).apply {
                        action = ACTION_PAUSE_TRACKING
                    }
            ContextCompat.startForegroundService(context, intent)
        }

        fun resumeTracking(context: Context) {
            val intent =
                    Intent(context, LocationTrackingService::class.java).apply {
                        action = ACTION_RESUME_TRACKING
                    }
            ContextCompat.startForegroundService(context, intent)
        }

        fun restoreTracking(context: Context) {
            val intent =
                    Intent(context, LocationTrackingService::class.java).apply {
                        action = ACTION_RESTORE_TRACKING
                    }
            ContextCompat.startForegroundService(context, intent)
        }

        fun scheduleBluetoothAutoStop(context: Context) {
            val intent =
                    Intent(context, LocationTrackingService::class.java).apply {
                        action = ACTION_SCHEDULE_BT_AUTO_STOP
                    }
            ContextCompat.startForegroundService(context, intent)
        }

        fun cancelBluetoothAutoStop(context: Context) {
            val intent =
                    Intent(context, LocationTrackingService::class.java).apply {
                        action = ACTION_CANCEL_BT_AUTO_STOP
                    }
            ContextCompat.startForegroundService(context, intent)
        }
    }

    private enum class TrackingMode(
            val intervalMs: Long,
            val locationMode: AMapLocationClientOption.AMapLocationMode
    ) {
        STATIONARY(
                STATIONARY_INTERVAL_MS,
                AMapLocationClientOption.AMapLocationMode.Battery_Saving
        ),
        WAIT(
                WAIT_INTERVAL_MS,
                AMapLocationClientOption.AMapLocationMode.Hight_Accuracy
        ),
        WALKING(
                WALKING_INTERVAL_MS,
                AMapLocationClientOption.AMapLocationMode.Hight_Accuracy
        ),
        MOVING(
                MOVING_INTERVAL_MS,
                AMapLocationClientOption.AMapLocationMode.Hight_Accuracy
        ),
        FAST(
                FAST_MOVING_INTERVAL_MS,
                AMapLocationClientOption.AMapLocationMode.Hight_Accuracy
        )
    }

    override fun onCreate() {
        super.onCreate()
        Log.d("FootprintLoc", "Service onCreate")
        repository = (application as com.footprint.FootprintApplication).repository
        preferenceManager = PreferenceManager(applicationContext)
        notificationManager = getSystemService(NotificationManager::class.java)
        createNotificationChannel()

        // 禁止在 onCreate 时自动恢复 is_tracking = true，
        // 只有通过显式的 ACTION_START_TRACKING 或 ACTION_RESTORE_TRACKING 才会开启。
        _sharedIsTracking.value = false
        _sharedIsPaused.value = false
        _sharedIsAutoPaused.value = false
        _activeTransportType.value = preferenceManager.defaultTrackingTransport
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                    NotificationChannel(CHANNEL_ID, "骑行与足迹记录", NotificationManager.IMPORTANCE_LOW)
                            .apply {
                                description = "实时显示骑行里程、车速和位置"
                                setShowBadge(false)
                                enableVibration(false)
                                setSound(null, null)
                            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun initLocationClient() {
        if (locationClient != null) return
        try {
            Log.d("FootprintLoc", "Initializing AMap SDK (GPS-first riding profile)")
            locationClient = AMapLocationClient(applicationContext)
            locationClient?.setLocationListener(this)

            locationOption =
                    AMapLocationClientOption().apply {
                        locationMode = AMapLocationClientOption.AMapLocationMode.Hight_Accuracy
                        interval = BASE_INTERVAL_MS
                        isNeedAddress = true
                        isMockEnable = false
                        isLocationCacheEnable = false
                        isOnceLocation = false
                        isSensorEnable = true
                        isGpsFirst = true
                        httpTimeOut = LOCATION_HTTP_TIMEOUT_MS
                    }
            locationClient?.setLocationOption(locationOption)
        } catch (e: Exception) {
            Log.e("FootprintLoc", "SDK初始化失败: ${e.message}")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null || intent.action == null) {
            // System restart (START_STICKY)
            restoreTrackingStateFromPrefs()
            if (_sharedIsTracking.value) {
                Log.d("FootprintLoc", "Restoring tracking after system kill")
                resumeTrackingFlow()
            } else {
                stopSelf(startId)
            }
            return START_STICKY
        }

        when (intent.action) {
            ACTION_START_TRACKING -> {
                cancelRestartAlarm()
                _btAutoStopJob?.cancel()
                _btAutoStopJob = null

                val autoTriggered = intent.getBooleanExtra(EXTRA_AUTO_TRIGGERED, false)
                val requestedTransport =
                        intent.getStringExtra(EXTRA_TRANSPORT_TYPE)
                                ?: preferenceManager.defaultTrackingTransport
                val validTransport =
                        try {
                            TransportType.valueOf(requestedTransport).name
                        } catch (_: Exception) {
                            TransportType.EBIKE.name
                        }
                _activeTransportType.value = validTransport
                preferenceManager.defaultTrackingTransport = validTransport

                _sharedIsPaused.value = false
                _sharedIsAutoPaused.value = false
                _totalDistanceTraveled.value = 0.0f
                _currentSpeedKmh.value = 0.0f
                _maxSpeedKmh.value = 0.0f
                _gpsAccuracy.value = 0.0f
                _smoothedSpeedMs = 0f
                _startAddress = ""
                _lastLocation = null
                _autoPauseAnchorLocation = null
                _lowSpeedSinceElapsedMs = 0L
                _sessionStartTime = System.currentTimeMillis()
                _lastResumeTime = _sessionStartTime
                _accumulatedDurationMs = 0
                _lastSaveTime = 0L
                _lastNotifyTime = 0L
                _lastDistancePersist = 0.0f
                _lastTrackingMode = null
                _lastMovementElapsedTime = SystemClock.elapsedRealtime()
                _nextVoiceMilestoneKm = preferenceManager.voiceAnnounceIntervalKm.toDouble().coerceAtLeast(0.5)
                _lowBatteryVoiceAlerted = false
                trackingPathBuffer.clear()
                pendingTrackPoints.clear()
                _sharedTrackingPath.value = emptyList()

                getSharedPreferences("tracking_prefs", Context.MODE_PRIVATE)
                        .edit()
                        .putBoolean("is_tracking", true)
                        .putBoolean("is_paused", false)
                        .putFloat("total_distance", 0.0f)
                        .putFloat("max_speed_kmh", 0.0f)
                        .putLong("session_start", _sessionStartTime)
                        .putLong("accumulated_duration_ms", 0L)
                        .putString("transport_type", validTransport)
                        .putString("start_address", "")
                        .apply()

                resumeTrackingFlow()
                val label = getTransportDisplayLabel()
                if (autoTriggered) {
                    val btName = preferenceManager.bluetoothDeviceName.ifBlank { "爱车蓝牙" }
                    speakIfEnabled("已连接${btName}，自动开始记录${label}骑行", flush = true)
                } else {
                    speakIfEnabled("开始记录${label}骑行，祝您一路平安", flush = true)
                }
                Log.d("FootprintLoc", "定位服务已启动, mode=$validTransport, auto=$autoTriggered, Session start: $_sessionStartTime")
            }
            ACTION_RESTORE_TRACKING -> {
                restoreTrackingStateFromPrefs()
                if (_sharedIsTracking.value) {
                    val interval = preferenceManager.voiceAnnounceIntervalKm.toDouble().coerceAtLeast(0.5)
                    val currentKm = _totalDistanceTraveled.value / 1000.0
                    _nextVoiceMilestoneKm = (kotlin.math.floor(currentKm / interval) + 1.0) * interval
                    resumeTrackingFlow()
                    Log.d("FootprintLoc", "定位服务已按持久化状态恢复")
                } else {
                    stopSelf()
                }
            }
            ACTION_PAUSE_TRACKING -> {
                if (_sharedIsTracking.value && !_sharedIsPaused.value) {
                    if (!_sharedIsAutoPaused.value && _lastResumeTime > 0L) {
                        _accumulatedDurationMs += (System.currentTimeMillis() - _lastResumeTime).coerceAtLeast(0L)
                    }
                    _sharedIsPaused.value = true
                    _sharedIsAutoPaused.value = false
                    _currentSpeedKmh.value = 0.0f
                    _smoothedSpeedMs = 0f
                    _lowSpeedSinceElapsedMs = 0L
                    _autoPauseAnchorLocation = null
                    locationClient?.stopLocation()
                    flushPendingTrackPointsAsync()
                    persistTrackingSnapshot(forceDistance = true)

                    getSharedPreferences("tracking_prefs", Context.MODE_PRIVATE)
                        .edit()
                        .putBoolean("is_paused", true)
                        .putLong("accumulated_duration_ms", _accumulatedDurationMs)
                        .apply()

                    updateNotificationImmediately(
                        _totalDistanceTraveled.value.toInt(),
                        0f,
                        _sharedCurrentLocation.value?.toAddressString() ?: "已暂停记录"
                    )
                    speakIfEnabled("骑行记录已暂停", flush = true)
                    Log.d("FootprintLoc", "定位服务已暂停")
                }
            }
            ACTION_RESUME_TRACKING -> {
                if (_sharedIsTracking.value && _sharedIsPaused.value) {
                    _btAutoStopJob?.cancel()
                    _btAutoStopJob = null
                    _sharedIsPaused.value = false
                    _sharedIsAutoPaused.value = false
                    _lastResumeTime = System.currentTimeMillis()
                    _lastNotifyTime = 0L
                    _lowSpeedSinceElapsedMs = 0L
                    _autoPauseAnchorLocation = null
                    // Clear _lastLocation on manual resume so paused relocation doesn't add a straight-line distance jump
                    _lastLocation = null
                    enableAmapBackgroundLocation()
                    locationClient?.startLocation()

                    getSharedPreferences("tracking_prefs", Context.MODE_PRIVATE)
                        .edit()
                        .putBoolean("is_paused", false)
                        .apply()

                    updateNotificationImmediately(
                        _totalDistanceTraveled.value.toInt(),
                        0f,
                        _sharedCurrentLocation.value?.toAddressString() ?: "已恢复记录"
                    )
                    speakIfEnabled("继续记录骑行", flush = true)
                    Log.d("FootprintLoc", "定位服务已恢复")
                }
            }
            ACTION_SCHEDULE_BT_AUTO_STOP -> {
                if (_sharedIsTracking.value) {
                    _btAutoStopJob?.cancel()
                    updateNotificationImmediately(
                            _totalDistanceTraveled.value.toInt(),
                            0f,
                            "蓝牙已断开，20秒后自动结束并保存..."
                    )
                    _btAutoStopJob =
                            serviceScope.launch {
                                delay(BT_DISCONNECT_GRACE_MS)
                                if (_sharedIsTracking.value) {
                                    Log.d("FootprintLoc", "Bluetooth disconnect grace elapsed, auto-stopping ride")
                                    performStopAndSave(discard = false, autoStoppedByBt = true)
                                }
                            }
                } else {
                    stopSelf()
                }
            }
            ACTION_CANCEL_BT_AUTO_STOP -> {
                if (_btAutoStopJob != null) {
                    _btAutoStopJob?.cancel()
                    _btAutoStopJob = null
                    updateNotificationImmediately(
                            _totalDistanceTraveled.value.toInt(),
                            _currentSpeedKmh.value / 3.6f,
                            _sharedCurrentLocation.value?.toAddressString() ?: "蓝牙已重连，继续记录"
                    )
                    speakIfEnabled("蓝牙已重新连接，继续记录", flush = false)
                }
            }
            ACTION_STOP_TRACKING -> {
                val discard = intent.getBooleanExtra(EXTRA_DISCARD_SESSION, false)
                performStopAndSave(discard = discard, autoStoppedByBt = false)
            }
        }
        return START_STICKY
    }

    private fun performStopAndSave(discard: Boolean, autoStoppedByBt: Boolean) {
        cancelRestartAlarm()
        _btAutoStopJob?.cancel()
        _btAutoStopJob = null

        val finalDurationMs = totalDurationMs
        val finalDistanceMeters = _totalDistanceTraveled.value.toDouble()
        val finalMaxSpeedKmh = _maxSpeedKmh.value.toDouble()
        val finalTransport = _activeTransportType.value
        val finalStartAddr = _startAddress
        val finalAvgSpeed = avgSpeedKmh

        locationClient?.stopLocation()
        _notificationUpdateJob?.cancel()
        persistTrackingSnapshot(forceDistance = true)
        _sharedIsTracking.value = false
        _sharedIsPaused.value = false
        _sharedIsAutoPaused.value = false
        _currentSpeedKmh.value = 0.0f
        _smoothedSpeedMs = 0f

        getSharedPreferences("tracking_prefs", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("is_tracking", false)
                .putBoolean("is_paused", false)
                .apply()

        serviceScope.launch {
            withContext(NonCancellable) {
                var spokeSummary = false
                if (!discard) {
                    flushPendingTrackPointsSync()
                    saveTrackingSessionAsFootprint(
                            durationMs = finalDurationMs,
                            trackedDistanceMeters = finalDistanceMeters,
                            maxSpeedKmh = finalMaxSpeedKmh,
                            transportName = finalTransport,
                            startAddress = finalStartAddr
                    )
                    val km = finalDistanceMeters / 1000.0
                    if (preferenceManager.voiceAnnounceEnabled && km >= 0.05) {
                        val msg =
                                if (autoStoppedByBt) {
                                    "蓝牙已断开，本次骑行${"%.1f".format(km)}公里，轨迹已自动保存"
                                } else {
                                    "骑行结束，本次共骑行${"%.1f".format(km)}公里，平均时速${"%.0f".format(finalAvgSpeed)}公里每小时，轨迹已保存"
                                }
                        speakIfEnabled(msg, flush = true)
                        spokeSummary = true
                    }
                } else {
                    pendingTrackPoints.clear()
                    _totalDistanceTraveled.value = 0.0f
                    _maxSpeedKmh.value = 0.0f
                    _sharedTrackingPath.value = emptyList()
                    Log.d("FootprintLoc", "Tracking session discarded by user")
                }
                if (spokeSummary) {
                    delay(3500L)
                }
                locationClient?.disableBackgroundLocation(true)
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
    }

    private fun ensureVoiceAnnouncer(): RideVoiceAnnouncer {
        return _voiceAnnouncer ?: RideVoiceAnnouncer(applicationContext).also {
            _voiceAnnouncer = it
        }
    }

    private fun speakIfEnabled(text: String, flush: Boolean = false) {
        if (!preferenceManager.voiceAnnounceEnabled) return
        ensureVoiceAnnouncer().speak(text, flush)
    }

    private fun checkRideVoiceTriggers() {
        if (!preferenceManager.voiceAnnounceEnabled) return
        val distanceKm = _totalDistanceTraveled.value / 1000.0
        val intervalKm = preferenceManager.voiceAnnounceIntervalKm.toDouble().coerceAtLeast(0.5)

        // 1. Per-N-km milestone announcement
        if (distanceKm >= _nextVoiceMilestoneKm) {
            val milestone = _nextVoiceMilestoneKm
            while (_nextVoiceMilestoneKm <= distanceKm) {
                _nextVoiceMilestoneKm += intervalKm
            }
            val minutes = (totalDurationMs / 60000L).coerceAtLeast(1L)
            val avg = avgSpeedKmh
            val kmStr =
                    if (milestone % 1.0 < 0.05) milestone.toInt().toString()
                    else "%.1f".format(milestone)
            speakIfEnabled(
                    "已骑行${kmStr}公里，用时${minutes}分钟，平均时速${"%.0f".format(avg)}公里每小时",
                    flush = false
            )
        }

        // 2. One-time low-battery / remaining range alert during an E-Bike ride
        if (!_lowBatteryVoiceAlerted &&
                        preferenceManager.voiceLowBatteryAlertEnabled &&
                        _activeTransportType.value == TransportType.EBIKE.name
        ) {
            val fullRange = preferenceManager.ebikeFullRangeKm.toDouble()
            val projectedUsed = preferenceManager.ebikeSinceChargeKm.toDouble() + distanceKm
            val remaining = (fullRange - projectedUsed).coerceAtLeast(0.0)
            if (fullRange > 0 && remaining <= fullRange * 0.2) {
                _lowBatteryVoiceAlerted = true
                speakIfEnabled(
                        "注意，电动车预估剩余续航约${remaining.toInt()}公里，请及时充电",
                        flush = false
                )
            }
        }
    }

    private fun getMaxPlausibleSpeedMs(): Float {
        return when (_activeTransportType.value) {
            TransportType.WALK.name -> MAX_SPEED_WALK_MS
            TransportType.EBIKE.name, TransportType.BIKE.name -> MAX_SPEED_EBIKE_MS
            else -> MAX_SPEED_GENERAL_MS
        }
    }

    private fun isStrictAccuracyMode(): Boolean {
        return _activeTransportType.value == TransportType.EBIKE.name ||
                _activeTransportType.value == TransportType.BIKE.name ||
                _activeTransportType.value == TransportType.WALK.name
    }

    override fun onLocationChanged(location: AMapLocation?) {
        if (location == null) return
        if (location.errorCode != 0) {
            Log.e(
                    "FootprintLoc",
                    "Location Error: ${location.errorCode} - ${location.errorInfo}"
            )
            if (location.errorCode == 7 || location.errorCode == 12) {
                val userMsg =
                        when (location.errorCode) {
                            7 -> "Key鉴权失败：请检查高德后台包名"
                            12 -> "缺少定位权限：请在设置中授予"
                            else -> "未知定位错误: ${location.errorCode}"
                        }
                _locationError.value = userMsg
            }
            return
        }

        // Reject invalid 0,0 coordinates
        if (abs(location.latitude) <= MIN_VALID_LATLNG ||
                        abs(location.longitude) <= MIN_VALID_LATLNG
        ) {
            return
        }

        _gpsAccuracy.value = location.accuracy
        val accuracyLimit =
                if (_lastLocation == null) MAX_ACCURACY_COLD_START_M
                else if (isStrictAccuracyMode()) MAX_ACCURACY_STRICT_M
                else 80.0f

        if (location.accuracy <= 0f || location.accuracy > accuracyLimit) {
            Log.d(
                    "FootprintLoc",
                    "Filtered low-accuracy fix: acc=${location.accuracy}m (limit=${accuracyLimit}m, type=${location.locationType})"
            )
            return
        }

        val clonedLocation = location.clone()
        _sharedCurrentLocation.value = clonedLocation
        _locationError.value = null

        if (!_sharedIsTracking.value || _sharedIsPaused.value) {
            return
        }

        val now = System.currentTimeMillis()
        val nowElapsed = SystemClock.elapsedRealtime()
        val autoPauseEnabled =
                preferenceManager.ebikeAutoPauseEnabled && isStrictAccuracyMode()

        // Capture first readable start address
        if (_startAddress.isEmpty()) {
            val candidateAddr = clonedLocation.toReadableAddressOrEmpty()
            if (candidateAddr.isNotEmpty()) {
                _startAddress = candidateAddr
                getSharedPreferences("tracking_prefs", Context.MODE_PRIVATE)
                        .edit()
                        .putString("start_address", candidateAddr)
                        .apply()
            }
        }

        var isValidPoint = false
        var meaningfulMovement = false
        var rawSpeedMs = location.speed.coerceAtLeast(0f)

        val prevLoc = _lastLocation
        if (prevLoc != null) {
            val distance = location.distanceTo(prevLoc)
            val timeDeltaMs = (location.time - prevLoc.time).let {
                if (it > 0) it else 1000L
            }
            val timeDeltaSec = (timeDeltaMs / 1000.0).coerceAtLeast(0.5)
            val computedSpeedMs = (distance / timeDeltaSec).toFloat()

            // Prefer GPS Doppler speed when available and sensible
            rawSpeedMs =
                    if (location.speed > 0.3f && location.accuracy <= 25f) {
                        location.speed
                    } else {
                        computedSpeedMs
                    }

            val maxSpeedMs = getMaxPlausibleSpeedMs()
            if (computedSpeedMs > maxSpeedMs) {
                Log.w(
                        "FootprintLoc",
                        "Ignored GPS glitch: $distance m in ${timeDeltaSec}s (${computedSpeedMs * 3.6} km/h)"
                )
                return
            }

            // Handle red-light auto-pause state machine
            if (autoPauseEnabled) {
                handleAutoPauseState(
                        location = clonedLocation,
                        rawSpeedMs = rawSpeedMs,
                        distanceFromLast = distance,
                        nowWallMs = now,
                        nowElapsedMs = nowElapsed
                )
            } else if (_sharedIsAutoPaused.value) {
                exitAutoPause(now)
            }

            // Dynamic anti-drift distance threshold: stricter when slow/stopped
            val minDistanceRequired =
                    if (rawSpeedMs >= 2.0f) {
                        MIN_CRUISE_DISTANCE_M
                    } else {
                        max(2.8f, min(location.accuracy * 0.45f, 8.0f))
                    }

            if (_sharedIsAutoPaused.value) {
                _smoothedSpeedMs = 0f
                _currentSpeedKmh.value = 0f
                updateAdaptiveTrackingProfile(0f, false)
            } else if (distance < minDistanceRequired) {
                // Smooth speed towards 0 when stationary
                _smoothedSpeedMs = if (rawSpeedMs < 0.4f) 0f else (_smoothedSpeedMs * 0.5f + rawSpeedMs * 0.5f)
                _currentSpeedKmh.value = (_smoothedSpeedMs * 3.6f).coerceAtLeast(0f)
                updateAdaptiveTrackingProfile(_smoothedSpeedMs, false)
            } else {
                isValidPoint = true
                meaningfulMovement =
                        distance >= STATIONARY_JITTER_DISTANCE_M || rawSpeedMs >= 1.0f
                _totalDistanceTraveled.value += distance
                _smoothedSpeedMs =
                        if (_smoothedSpeedMs <= 0.1f) rawSpeedMs
                        else (_smoothedSpeedMs * 0.35f + rawSpeedMs * 0.65f)
                val speedKmh = (_smoothedSpeedMs * 3.6f).coerceIn(0f, maxSpeedMs * 3.6f)
                _currentSpeedKmh.value = speedKmh

                // Record max speed only on reliable GPS readings
                if (location.accuracy <= 25f &&
                                timeDeltaSec >= 1.0 &&
                                speedKmh > _maxSpeedKmh.value &&
                                speedKmh <= maxSpeedMs * 3.6f
                ) {
                    _maxSpeedKmh.value = speedKmh
                }
            }
        } else {
            // First valid point of this tracking segment
            isValidPoint = true
            meaningfulMovement = true
            _smoothedSpeedMs = rawSpeedMs
            _currentSpeedKmh.value = (rawSpeedMs * 3.6f).coerceAtLeast(0f)
        }

        if (isValidPoint) {
            // Store inferred/smoothed speed on clonedLocation so track_points & speed chart have accurate values
            if (clonedLocation.speed <= 0f && _smoothedSpeedMs > 0f) {
                clonedLocation.speed = _smoothedSpeedMs
            }
            queueTrackPoint(clonedLocation, now)

            trackingPathBuffer.add(clonedLocation)
            _sharedTrackingPath.value = trackingPathBuffer.toList()
            _lastLocation = clonedLocation

            updateAdaptiveTrackingProfile(_smoothedSpeedMs, meaningfulMovement)
            persistTrackingSnapshot()
            checkRideVoiceTriggers()

            if (now - _lastNotifyTime > NOTIFICATION_UPDATE_INTERVAL_MS) {
                _lastNotifyTime = now
                updateNotificationImmediately(
                        _totalDistanceTraveled.value.toInt(),
                        _smoothedSpeedMs,
                        clonedLocation.toAddressString()
                )
            }
        }
    }

    private fun handleAutoPauseState(
            location: AMapLocation,
            rawSpeedMs: Float,
            distanceFromLast: Float,
            nowWallMs: Long,
            nowElapsedMs: Long
    ) {
        if (!_sharedIsAutoPaused.value) {
            if (rawSpeedMs < AUTO_PAUSE_SPEED_THRESHOLD_MS && distanceFromLast < 4.0f) {
                if (_lowSpeedSinceElapsedMs == 0L) {
                    _lowSpeedSinceElapsedMs = nowElapsedMs
                    _autoPauseAnchorLocation = location
                } else if (nowElapsedMs - _lowSpeedSinceElapsedMs >= AUTO_PAUSE_DELAY_MS) {
                    // Enter red-light auto-pause
                    if (_lastResumeTime > 0L) {
                        _accumulatedDurationMs += (nowWallMs - _lastResumeTime).coerceAtLeast(0L)
                    }
                    _sharedIsAutoPaused.value = true
                    _currentSpeedKmh.value = 0f
                    _smoothedSpeedMs = 0f
                    updateNotificationImmediately(
                            _totalDistanceTraveled.value.toInt(),
                            0f,
                            location.toAddressString()
                    )
                    Log.d("FootprintLoc", "Entered red-light auto-pause")
                }
            } else {
                _lowSpeedSinceElapsedMs = 0L
                _autoPauseAnchorLocation = null
            }
        } else {
            val anchorDist = _autoPauseAnchorLocation?.let { location.distanceTo(it) } ?: distanceFromLast
            if (rawSpeedMs >= AUTO_RESUME_SPEED_THRESHOLD_MS || anchorDist >= AUTO_RESUME_DISTANCE_M) {
                exitAutoPause(nowWallMs)
            }
        }
    }

    private fun exitAutoPause(nowWallMs: Long) {
        _sharedIsAutoPaused.value = false
        _lastResumeTime = nowWallMs
        _lowSpeedSinceElapsedMs = 0L
        _autoPauseAnchorLocation = null
        _lastMovementElapsedTime = SystemClock.elapsedRealtime()
        Log.d("FootprintLoc", "Exited red-light auto-pause")
    }

    private fun restoreTrackingStateFromPrefs() {
        val prefs = getSharedPreferences("tracking_prefs", Context.MODE_PRIVATE)
        val isTracking = prefs.getBoolean("is_tracking", false)
        val isPaused = prefs.getBoolean("is_paused", false)

        _sharedIsTracking.value = isTracking
        _sharedIsPaused.value = isPaused
        _sharedIsAutoPaused.value = false

        if (!isTracking) {
            _totalDistanceTraveled.value = 0.0f
            _maxSpeedKmh.value = 0.0f
            _currentSpeedKmh.value = 0.0f
            _sessionStartTime = 0L
            _accumulatedDurationMs = 0L
            _lastResumeTime = 0L
            return
        }

        _sessionStartTime = prefs.getLong("session_start", System.currentTimeMillis())
        _totalDistanceTraveled.value = prefs.getFloat("total_distance", 0.0f)
        _maxSpeedKmh.value = prefs.getFloat("max_speed_kmh", 0.0f)
        _activeTransportType.value =
                prefs.getString("transport_type", preferenceManager.defaultTrackingTransport)
                        ?: TransportType.EBIKE.name
        _startAddress = prefs.getString("start_address", "") ?: ""
        _lastDistancePersist = _totalDistanceTraveled.value
        _lastMovementElapsedTime = SystemClock.elapsedRealtime()
        val now = System.currentTimeMillis()
        val savedAccumulated = prefs.getLong("accumulated_duration_ms", -1L)
        _accumulatedDurationMs =
                if (savedAccumulated >= 0L) savedAccumulated
                else if (isPaused) 0L
                else (now - _sessionStartTime).coerceAtLeast(0L)
        _lastResumeTime = if (isPaused) 0L else now
    }

    private fun getTransportDisplayLabel(): String {
        return try {
            TransportType.valueOf(_activeTransportType.value).label
        } catch (_: Exception) {
            "电动车"
        }
    }

    private fun buildNotification(
            distanceMeters: Int,
            speedMs: Float,
            address: String
    ): Notification {
        val remoteViews =
                android.widget.RemoteViews(
                        packageName,
                        com.footprint.R.layout.notification_tracking
                )

        val distanceKm = distanceMeters / 1000.0
        val speedKmh = speedMs * 3.6f
        val duration = formatDuration(totalDurationMs)
        val transportLabel = getTransportDisplayLabel()

        val titleText =
                when {
                    _sharedIsPaused.value -> "${transportLabel}记录已暂停"
                    _sharedIsAutoPaused.value -> "等红灯自动暂停 · $transportLabel"
                    else -> "正在记录${transportLabel}轨迹"
                }

        remoteViews.setTextViewText(com.footprint.R.id.notification_title, titleText)
        remoteViews.setTextViewText(
                com.footprint.R.id.notification_distance,
                "%.2f km".format(distanceKm)
        )
        remoteViews.setTextViewText(
                com.footprint.R.id.notification_speed,
                "%.1f km/h".format(speedKmh)
        )
        remoteViews.setTextViewText(com.footprint.R.id.notification_time, duration)
        remoteViews.setTextViewText(
                com.footprint.R.id.notification_address,
                when {
                    _sharedIsPaused.value -> "已手动暂停 · ${address.ifEmpty { "等待继续" }}"
                    _sharedIsAutoPaused.value -> "临时停靠 · 起步自动恢复"
                    else -> address.ifEmpty { "正在定位骑行路线..." }
                }
        )

        val stopIntent =
                Intent(this, LocationTrackingService::class.java).apply {
                    action = ACTION_STOP_TRACKING
                }
        val stopPendingIntent =
                PendingIntent.getService(
                        this,
                        0,
                        stopIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

        val mainIntent = Intent(this, com.footprint.MainActivity::class.java)
        val mainPendingIntent =
                PendingIntent.getActivity(
                        this,
                        0,
                        mainIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

        val builder =
                NotificationCompat.Builder(this, CHANNEL_ID)
                        .setSmallIcon(android.R.drawable.ic_menu_mylocation)
                        .setCustomContentView(remoteViews)
                        .setStyle(NotificationCompat.DecoratedCustomViewStyle())
                        .setContentIntent(mainPendingIntent)
                        .setOngoing(true)
                        .setOnlyAlertOnce(true)
                        .setPriority(NotificationCompat.PRIORITY_LOW)
                        .setCategory(NotificationCompat.CATEGORY_SERVICE)
                        .addAction(
                                android.R.drawable.ic_menu_close_clear_cancel,
                                "结束保存",
                                stopPendingIntent
                        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
        }

        if (_sharedIsPaused.value) {
            val resumeIntent =
                    Intent(this, LocationTrackingService::class.java).apply {
                        action = ACTION_RESUME_TRACKING
                    }
            val resumePI =
                    PendingIntent.getService(
                            this,
                            2,
                            resumeIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
            builder.addAction(android.R.drawable.ic_media_play, "继续", resumePI)
        } else {
            val pauseIntent =
                    Intent(this, LocationTrackingService::class.java).apply {
                        action = ACTION_PAUSE_TRACKING
                    }
            val pausePI =
                    PendingIntent.getService(
                            this,
                            3,
                            pauseIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
            builder.addAction(android.R.drawable.ic_media_pause, "暂停", pausePI)
        }

        return builder.build()
    }

    private fun formatDuration(ms: Long): String {
        val seconds = (ms / 1000) % 60
        val minutes = (ms / (1000 * 60)) % 60
        val hours = (ms / (1000 * 60 * 60))
        return "%02d:%02d:%02d".format(hours, minutes, seconds)
    }

    private fun resumeTrackingFlow() {
        startForegroundSafely()

        if (ActivityCompat.checkSelfPermission(
                        this,
                        android.Manifest.permission.ACCESS_FINE_LOCATION
                ) != PackageManager.PERMISSION_GRANTED
        ) {
            _locationError.value = "缺少定位权限：请在设置中授予"
            Log.w("FootprintLoc", "Tracking restore/start skipped because location permission is missing")
            startNotificationUpdates()
            return
        }

        initLocationClient()
        _sharedIsTracking.value = true

        // Recover points from database to restore the trace line
        serviceScope.launch {
            try {
                val points = repository.getTrackPointsBySessionId(_sessionStartTime)
                trackingPathBuffer.clear()
                trackingPathBuffer.addAll(
                        points.map {
                            AMapLocation("").apply {
                                latitude = it.latitude
                                longitude = it.longitude
                                speed = it.speed
                                altitude = it.altitude
                                accuracy = it.accuracy
                                time = it.timestamp
                            }
                        }
                )
                _sharedTrackingPath.value = trackingPathBuffer.toList()
                Log.d("FootprintLoc", "Recovered ${_sharedTrackingPath.value.size} points from DB")
            } catch (e: Exception) {
                Log.e("FootprintLoc", "Failed to recover points: ${e.message}")
            }
        }

        if (!_sharedIsPaused.value) {
            val initialMode =
                    if (_activeTransportType.value == TransportType.EBIKE.name ||
                                    _activeTransportType.value == TransportType.BIKE.name
                    ) {
                        TrackingMode.MOVING
                    } else {
                        TrackingMode.WALKING
                    }
            applyTrackingMode(initialMode)
            enableAmapBackgroundLocation()
            locationClient?.startLocation()
        }
        startNotificationUpdates()
    }

    private fun enableAmapBackgroundLocation() {
        try {
            val notification = buildNotification(_totalDistanceTraveled.value.toInt(), 0f, "")
            locationClient?.enableBackgroundLocation(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.w("FootprintLoc", "Failed to enable AMap background location: ${e.message}")
        }
    }

    private fun startForegroundSafely() {
        try {
            val notification = buildNotification(_totalDistanceTraveled.value.toInt(), 0f, "")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e("FootprintLoc", "Failed to start foreground service: ${e.message}", e)
        }
    }

    private fun updateAdaptiveTrackingProfile(
            speedMs: Float,
            meaningfulMovement: Boolean
    ) {
        if (meaningfulMovement) {
            _lastMovementElapsedTime = SystemClock.elapsedRealtime()
        }
        val speedKmh = speedMs * 3.6f
        val hasBeenLongStationary =
                _lastMovementElapsedTime > 0L &&
                        SystemClock.elapsedRealtime() - _lastMovementElapsedTime >= STATIONARY_GRACE_MS

        val isRidingMode =
                _activeTransportType.value == TransportType.EBIKE.name ||
                        _activeTransportType.value == TransportType.BIKE.name

        val newMode =
                when {
                    speedKmh > 25f -> TrackingMode.FAST
                    speedKmh > 6f -> TrackingMode.MOVING
                    hasBeenLongStationary -> TrackingMode.STATIONARY
                    isRidingMode -> TrackingMode.WAIT // Stay responsive at red lights!
                    speedKmh > 1.5f -> TrackingMode.WALKING
                    else -> TrackingMode.WALKING
                }
        applyTrackingMode(newMode)
    }

    private fun applyTrackingMode(mode: TrackingMode) {
        if (_lastTrackingMode == mode) return
        locationOption?.let { currentOption ->
            currentOption.interval = mode.intervalMs
            currentOption.locationMode = mode.locationMode
            locationClient?.setLocationOption(currentOption)
            _lastTrackingMode = mode
            Log.d(
                    "FootprintLoc",
                    "Tracking profile updated: ${mode.name}, interval=${mode.intervalMs}ms"
            )
        }
    }

    private fun queueTrackPoint(location: AMapLocation, now: Long) {
        pendingTrackPoints.add(location)
        if (pendingTrackPoints.size >= TRACK_BATCH_SIZE ||
                        now - _lastSaveTime >= TRACK_BATCH_WINDOW_MS
        ) {
            flushPendingTrackPointsAsync()
            _lastSaveTime = now
        }
    }

    private fun flushPendingTrackPointsAsync() {
        if (pendingTrackPoints.isEmpty()) return
        val snapshot = pendingTrackPoints.toList()
        pendingTrackPoints.clear()
        serviceScope.launch {
            try {
                repository.saveTrackPoints(snapshot, _sessionStartTime)
            } catch (e: Exception) {
                Log.e("FootprintLoc", "Failed to flush points: ${e.message}")
                pendingTrackPoints.addAll(0, snapshot)
            }
        }
    }

    private suspend fun flushPendingTrackPointsSync() {
        if (pendingTrackPoints.isEmpty()) return
        val snapshot = pendingTrackPoints.toList()
        pendingTrackPoints.clear()
        try {
            repository.saveTrackPoints(snapshot, _sessionStartTime)
        } catch (e: Exception) {
            pendingTrackPoints.addAll(0, snapshot)
            throw e
        }
    }

    private fun persistTrackingSnapshot(forceDistance: Boolean = false) {
        if (!_sharedIsTracking.value) return
        val distance = _totalDistanceTraveled.value
        if (!forceDistance && distance - _lastDistancePersist < DISTANCE_PERSIST_STEP_M) return
        _lastDistancePersist = distance
        getSharedPreferences("tracking_prefs", Context.MODE_PRIVATE)
                .edit()
                .putFloat("total_distance", distance)
                .putFloat("max_speed_kmh", _maxSpeedKmh.value)
                .putLong("session_start", _sessionStartTime)
                .putLong("accumulated_duration_ms", totalDurationMs)
                .apply()
    }

    private fun startNotificationUpdates() {
        _notificationUpdateJob?.cancel()
        _notificationUpdateJob =
                serviceScope.launch {
                    while (isActive && _sharedIsTracking.value) {
                        delay(NOTIFICATION_UPDATE_INTERVAL_MS)
                        updateNotificationImmediately(
                                _totalDistanceTraveled.value.toInt(),
                                _currentSpeedKmh.value / 3.6f,
                                _sharedCurrentLocation.value?.toAddressString() ?: ""
                        )
                    }
                }
    }

    private fun updateNotificationImmediately(dist: Int, speed: Float, addr: String) {
        if (!_sharedIsTracking.value) return
        serviceScope.launch {
            try {
                val notification = buildNotification(dist, speed, addr)
                notificationManager.notify(NOTIFICATION_ID, notification)
            } catch (e: Exception) {
                Log.e("FootprintLoc", "Update notification failed: ${e.message}")
            }
        }
    }

    private fun buildRestorePendingIntent(): PendingIntent {
        val intent =
                Intent(this, LocationTrackingService::class.java).apply {
                    action = ACTION_RESTORE_TRACKING
                    setPackage(packageName)
                }
        return PendingIntent.getService(
                this,
                RESTART_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun scheduleRestartAlarm() {
        if (!getSharedPreferences("tracking_prefs", Context.MODE_PRIVATE)
                        .getBoolean("is_tracking", false)
        ) {
            return
        }
        val alarmManager = getSystemService(AlarmManager::class.java)
        val triggerAt = SystemClock.elapsedRealtime() + RESTART_DELAY_MS
        val pendingIntent = buildRestorePendingIntent()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP,
                        triggerAt,
                        pendingIntent
                )
            } else {
                alarmManager.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pendingIntent)
            }
            Log.d("FootprintLoc", "Scheduled tracking service restore alarm")
        } catch (e: Exception) {
            Log.w("FootprintLoc", "Failed to schedule restore alarm: ${e.message}")
        }
    }

    private fun cancelRestartAlarm() {
        try {
            getSystemService(AlarmManager::class.java).cancel(buildRestorePendingIntent())
        } catch (_: Exception) {}
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        if (_sharedIsTracking.value && !_sharedIsPaused.value) {
            persistTrackingSnapshot(forceDistance = true)
            flushPendingTrackPointsAsync()
            scheduleRestartAlarm()
            startForegroundSafely()
        }
        Log.d("FootprintLoc", "Service onTaskRemoved")
    }

    private fun buildAutoRideTitle(transport: TransportType): String {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        val period =
                when (hour) {
                    in 5..9 -> "早间"
                    in 10..11 -> "上午"
                    in 12..13 -> "午间"
                    in 14..17 -> "午后"
                    in 18..20 -> "傍晚"
                    else -> "夜间"
                }
        return when (transport) {
            TransportType.EBIKE -> "${period}电动车骑行"
            TransportType.BIKE -> "${period}自行车骑行"
            TransportType.WALK -> "${period}徒步记录"
            TransportType.CAR -> "${period}自驾出行"
            else -> "${period}自动轨迹"
        }
    }

    private suspend fun saveTrackingSessionAsFootprint(
            durationMs: Long,
            trackedDistanceMeters: Double,
            maxSpeedKmh: Double,
            transportName: String,
            startAddress: String
    ) {
        val endTime = System.currentTimeMillis()
        val sessionPoints = repository.getTrackPointsBySessionId(_sessionStartTime)
        val points =
                if (sessionPoints.isNotEmpty()) sessionPoints
                else repository.getTrackPointsOnce(_sessionStartTime, endTime)

        if (points.size >= 2) {
            val totalDistanceM =
                    if (trackedDistanceMeters > 1.0) trackedDistanceMeters
                    else calculateTotalDistance(points)
            val distanceKm = totalDistanceM / 1000.0
            val durationSec = (durationMs / 1000L).coerceAtLeast(1L)
            val avgSpeed =
                    if (durationSec >= 3L) {
                        distanceKm / (durationSec / 3600.0)
                    } else 0.0
            val peakSpeed = maxOf(maxSpeedKmh, avgSpeed)

            val transport =
                    try {
                        TransportType.valueOf(transportName)
                    } catch (_: Exception) {
                        TransportType.EBIKE
                    }

            val carbonSaved =
                    when (transport) {
                        TransportType.EBIKE -> distanceKm * 0.14
                        TransportType.BIKE -> distanceKm * 0.12
                        TransportType.WALK -> distanceKm * 0.16
                        TransportType.TRAIN -> distanceKm * 0.04
                        else -> 0.0
                    }

            val iconName =
                    when (transport) {
                        TransportType.EBIKE -> "ElectricScooter"
                        TransportType.BIKE -> "DirectionsBike"
                        TransportType.CAR -> "DirectionsCar"
                        else -> "RunCircle"
                    }

            val lastLocation = _sharedCurrentLocation.value
            val endAddress = lastLocation?.toAddressString() ?: "未知地点"
            val today = java.time.LocalDate.now()

            val routeLine =
                    if (startAddress.isNotEmpty() && startAddress != endAddress) {
                        "路线：$startAddress → $endAddress\n"
                    } else ""
            val detailSummary =
                    "${routeLine}本次${transport.label}里程 ${"%.2f".format(distanceKm)} km，" +
                            "骑行耗时 ${formatDuration(durationMs)}，" +
                            "平均时速 ${"%.1f".format(avgSpeed)} km/h，" +
                            "最高时速 ${"%.1f".format(peakSpeed)} km/h（共 ${points.size} 个轨迹点）。"

            val tags =
                    when (transport) {
                        TransportType.EBIKE -> listOf("电动车", "骑行轨迹")
                        TransportType.BIKE -> listOf("自行车", "骑行轨迹")
                        TransportType.CAR -> listOf("自驾", "行车轨迹")
                        else -> listOf("自动追踪")
                    }

            val entry =
                    com.footprint.data.model.FootprintEntry(
                            title = buildAutoRideTitle(transport),
                            location = endAddress,
                            detail = detailSummary,
                            mood = Mood.RELAXED,
                            tags = tags,
                            distanceKm = distanceKm,
                            photos = emptyList(),
                            energyLevel = 6,
                            happenedOn = today,
                            latitude = lastLocation?.latitude ?: points.last().latitude,
                            longitude = lastLocation?.longitude ?: points.last().longitude,
                            altitude = lastLocation?.altitude ?: points.last().altitude,
                            weather = null,
                            temperature = null,
                            transportType = transport,
                            carbonSavedKg = carbonSaved,
                            adcode = lastLocation?.adCode ?: points.last().adcode,
                            icon = iconName,
                            sessionId = _sessionStartTime,
                            durationSec = durationSec,
                            avgSpeedKmh = avgSpeed,
                            maxSpeedKmh = peakSpeed
                    )
            repository.saveEntry(entry)

            // Automatically accumulate e-bike mileage since last full charge
            if (transport == TransportType.EBIKE && distanceKm > 0.01) {
                preferenceManager.addEbikeChargeMileage(distanceKm)
            }

            Log.d(
                    "FootprintLoc",
                    "Tracking session saved: ${entry.title}, ${entry.distanceKm} km, avg=${avgSpeed} km/h, points=${points.size}"
            )
            _totalDistanceTraveled.value = 0.0f
            _maxSpeedKmh.value = 0.0f
            _sharedTrackingPath.value = emptyList()
        } else {
            Log.d("FootprintLoc", "Track too short, not saving (points: ${points.size})")
            _totalDistanceTraveled.value = 0.0f
            _maxSpeedKmh.value = 0.0f
            _sharedTrackingPath.value = emptyList()
        }
    }

    private fun calculateTotalDistance(
            points: List<com.footprint.data.local.TrackPointEntity>
    ): Double {
        var distance = 0.0
        for (i in 0 until points.size - 1) {
            val start = points[i]
            val end = points[i + 1]
            // Skip distance across large time gaps (e.g., manual pause > 5 min)
            if (end.timestamp - start.timestamp > 300_000L) continue
            val results = FloatArray(1)
            android.location.Location.distanceBetween(
                    start.latitude,
                    start.longitude,
                    end.latitude,
                    end.longitude,
                    results
            )
            distance += results[0]
        }
        return distance
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        _btAutoStopJob?.cancel()
        if (_sharedIsTracking.value && !_sharedIsPaused.value) {
            persistTrackingSnapshot(forceDistance = true)
            scheduleRestartAlarm()
        }
        locationClient?.stopLocation()
        locationClient?.onDestroy()
        _voiceAnnouncer?.shutdown()
        _voiceAnnouncer = null
        runBlocking(NonCancellable) {
            flushPendingTrackPointsSync()
        }
        trackingPathBuffer.clear()
        serviceScope.cancel()
        super.onDestroy()
    }
}

fun AMapLocation.toReadableAddressOrEmpty(): String {
    return when {
        !this.poiName.isNullOrEmpty() && !this.district.isNullOrEmpty() ->
            "${this.district} · ${this.poiName}"
        !this.street.isNullOrEmpty() && !this.district.isNullOrEmpty() ->
            "${this.district} ${this.street}"
        !this.address.isNullOrEmpty() -> this.address
        !this.city.isNullOrEmpty() && !this.district.isNullOrEmpty() ->
            "${this.city} ${this.district}"
        !this.poiName.isNullOrEmpty() -> this.poiName
        else -> ""
    }
}

// Extension function to convert AMapLocation to address string (if available)
fun AMapLocation.toAddressString(): String {
    val readable = toReadableAddressOrEmpty()
    return readable.ifEmpty { String.format("%.3f, %.3f", this.latitude, this.longitude) }
}
