package com.footprint.service

import android.Manifest
import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.footprint.MainActivity
import com.footprint.data.model.TransportType
import com.footprint.receiver.BleProximityReceiver
import com.footprint.utils.PreferenceManager
import java.util.concurrent.ConcurrentHashMap

/**
 * Manages pairing-free BLE proximity detection for e-bikes (e.g., Ninebot, NIU, Yadea, Tailg, Aima)
 * whose BLE advertisements cannot be paired in system Bluetooth settings.
 *
 * Capabilities:
 * 1. Interactive nearby BLE scanner for binding an e-bike in Settings (sorted by e-bike hint & RSSI).
 * 2. Ultra-low-power hardware-filtered PendingIntent background scan (API 26+) to wake the app and
 *    start riding tracking automatically when approaching the bound e-bike.
 * 3. Lightweight active-ride BLE heartbeat scan to detect when the rider parks & walks away or turns
 *    off the e-bike, triggering auto-stop & save.
 */
object BleProximityManager {
    private const val TAG = "BleProximityManager"
    private const val PENDING_INTENT_REQUEST_CODE = 20481
    private const val ACTION_BLE_SCAN_RESULT = "com.footprint.action.BLE_PROXIMITY_SCAN_RESULT"
    private const val FALLBACK_CHANNEL_ID = "bt_auto_ride_channel"
    private const val FALLBACK_NOTIFY_ID = 1099
    private const val AUTO_START_COOLDOWN_MS = 35_000L

    private val EBIKE_KEYWORDS = listOf(
        "ninebot", "segway", "niu", "yadea", "tailg", "aima", "luyuan", "lvneng",
        "xinri", "soco", "horwin", "sunra", "ebike", "e-bike", "scooter", "moto",
        "bike", "nb-", "yd-", "tl-", "am-", "小牛", "九号", "雅迪", "台铃", "爱玛", "绿源"
    )

    data class ScannedBleDevice(
        val name: String,
        val address: String,
        val rssi: Int,
        val isLikelyEbike: Boolean,
        val lastSeenMs: Long
    )

    private val interactiveDevices = ConcurrentHashMap<String, ScannedBleDevice>()
    private var interactiveCallback: ScanCallback? = null
    @Volatile
    var isInteractiveScanning: Boolean = false
        private set

    private var activeRideCallback: ScanCallback? = null
    @Volatile
    var isBackgroundMonitorActive: Boolean = false
        private set

    @Volatile
    var lastSeenBoundAddress: String = ""
        private set
    @Volatile
    var lastSeenTimestampMs: Long = 0L
        private set
    @Volatile
    var lastSeenRssi: Int = -127
        private set
    @Volatile
    private var lastAutoStopTimestampMs: Long = 0L

    fun hasBleScanPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
        }
    }

    private fun getAdapter(context: Context): BluetoothAdapter? {
        return context.getSystemService(BluetoothManager::class.java)?.adapter
    }

    private fun getScanner(context: Context): BluetoothLeScanner? {
        val adapter = getAdapter(context) ?: return null
        if (!adapter.isEnabled) return null
        return adapter.bluetoothLeScanner
    }

    private fun isLikelyEbikeName(name: String): Boolean {
        if (name.isBlank()) return false
        val lower = name.lowercase()
        return EBIKE_KEYWORDS.any { lower.contains(it) }
    }

    @SuppressLint("MissingPermission")
    fun startInteractiveScan(context: Context): Pair<Boolean, String?> {
        if (!hasBleScanPermission(context)) {
            return false to "需要授予“附近设备（蓝牙扫描）”权限"
        }
        val adapter = getAdapter(context)
            ?: return false to "当前设备不支持蓝牙"
        if (!adapter.isEnabled) {
            return false to "请先开启手机蓝牙后再扫描"
        }
        val scanner = adapter.bluetoothLeScanner
            ?: return false to "当前设备不支持低功耗蓝牙 (BLE)"

        stopInteractiveScan(context)
        interactiveDevices.clear()

        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                recordInteractiveResult(context, result)
            }

            override fun onBatchScanResults(results: MutableList<ScanResult>) {
                for (r in results) {
                    recordInteractiveResult(context, r)
                }
            }

            override fun onScanFailed(errorCode: Int) {
                Log.w(TAG, "Interactive BLE scan failed with errorCode=$errorCode")
                isInteractiveScanning = false
            }
        }

        return try {
            val settings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .build()
            scanner.startScan(null, settings, callback)
            interactiveCallback = callback
            isInteractiveScanning = true
            Log.d(TAG, "Started interactive BLE scan")
            true to null
        } catch (e: SecurityException) {
            Log.w(TAG, "SecurityException starting interactive BLE scan: ${e.message}")
            false to "缺少蓝牙扫描权限: ${e.message}"
        } catch (e: Exception) {
            Log.w(TAG, "Failed to start interactive BLE scan: ${e.message}")
            false to "启动 BLE 扫描失败: ${e.message}"
        }
    }

    @SuppressLint("MissingPermission")
    private fun recordInteractiveResult(context: Context, result: ScanResult) {
        val device = result.device ?: return
        val address = device.address ?: return
        if (address.isBlank()) return

        val recordName = result.scanRecord?.deviceName?.trim().orEmpty()
        val deviceName = try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) ==
                PackageManager.PERMISSION_GRANTED
            ) {
                device.name?.trim().orEmpty()
            } else {
                ""
            }
        } catch (_: SecurityException) {
            ""
        }

        val existing = interactiveDevices[address]
        val resolvedName = when {
            recordName.isNotEmpty() -> recordName
            deviceName.isNotEmpty() -> deviceName
            existing != null && existing.name.isNotEmpty() -> existing.name
            else -> ""
        }

        interactiveDevices[address] = ScannedBleDevice(
            name = resolvedName,
            address = address,
            rssi = result.rssi,
            isLikelyEbike = isLikelyEbikeName(resolvedName),
            lastSeenMs = System.currentTimeMillis()
        )
    }

    @SuppressLint("MissingPermission")
    fun stopInteractiveScan(context: Context) {
        val cb = interactiveCallback ?: return
        interactiveCallback = null
        isInteractiveScanning = false
        try {
            getScanner(context)?.stopScan(cb)
            Log.d(TAG, "Stopped interactive BLE scan")
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping interactive BLE scan: ${e.message}")
        }
    }

    fun getScannedDevicesSnapshot(): List<Map<String, Any>> {
        val now = System.currentTimeMillis()
        // Drop devices unseen for > 20s to keep the list fresh
        val active = interactiveDevices.values.filter { now - it.lastSeenMs <= 20_000L }
        return active
            .sortedWith(
                compareByDescending<ScannedBleDevice> { it.isLikelyEbike }
                    .thenByDescending { it.name.isNotEmpty() }
                    .thenByDescending { it.rssi }
            )
            .take(40)
            .map { d ->
                mapOf(
                    "name" to d.name,
                    "address" to d.address,
                    "rssi" to d.rssi,
                    "isLikelyEbike" to d.isLikelyEbike,
                    "hasName" to d.name.isNotEmpty()
                )
            }
    }

    private fun buildBackgroundPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context.applicationContext, BleProximityReceiver::class.java).apply {
            action = ACTION_BLE_SCAN_RESULT
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getBroadcast(
            context.applicationContext,
            PENDING_INTENT_REQUEST_CODE,
            intent,
            flags
        )
    }

    /**
     * Registers or unregisters the ultra-low-power hardware-filtered BLE background scan
     * according to the user's current PreferenceManager settings.
     */
    @SuppressLint("MissingPermission")
    fun syncMonitorState(context: Context) {
        val appCtx = context.applicationContext
        val prefs = PreferenceManager(appCtx)
        val shouldMonitor =
            prefs.bluetoothAutoTrackEnabled &&
                prefs.bluetoothDeviceMode.equals("BLE", ignoreCase = true) &&
                prefs.bluetoothDeviceAddress.isNotBlank()

        if (!shouldMonitor) {
            stopBackgroundMonitor(appCtx)
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            Log.w(TAG, "Background PendingIntent BLE scan requires Android 8.0+")
            isBackgroundMonitorActive = false
            return
        }

        if (!hasBleScanPermission(appCtx)) {
            Log.w(TAG, "Cannot start BLE background monitor: missing scan permission")
            isBackgroundMonitorActive = false
            return
        }

        val scanner = getScanner(appCtx)
        if (scanner == null) {
            Log.d(TAG, "Bluetooth adapter disabled or BLE unsupported; deferring BLE monitor")
            isBackgroundMonitorActive = false
            return
        }

        val targetAddress = prefs.bluetoothDeviceAddress.uppercase()
        if (!BluetoothAdapter.checkBluetoothAddress(targetAddress)) {
            Log.w(TAG, "Invalid BLE address configured: $targetAddress")
            isBackgroundMonitorActive = false
            return
        }

        try {
            val pi = buildBackgroundPendingIntent(appCtx)
            // Stop previous registration cleanly before re-registering with updated address
            try {
                scanner.stopScan(pi)
            } catch (_: Exception) {}

            val filter = ScanFilter.Builder()
                .setDeviceAddress(targetAddress)
                .build()
            val settings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
                .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
                .setReportDelay(0L)
                .build()

            val resultCode = scanner.startScan(listOf(filter), settings, pi)
            isBackgroundMonitorActive = (resultCode == 0)
            Log.d(TAG, "BLE background proximity monitor synced for $targetAddress (code=$resultCode)")
        } catch (e: SecurityException) {
            Log.w(TAG, "SecurityException registering BLE background monitor: ${e.message}")
            isBackgroundMonitorActive = false
        } catch (e: Exception) {
            Log.w(TAG, "Failed to register BLE background monitor: ${e.message}")
            isBackgroundMonitorActive = false
        }
    }

    @SuppressLint("MissingPermission")
    fun stopBackgroundMonitor(context: Context) {
        isBackgroundMonitorActive = false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        try {
            val scanner = getScanner(context.applicationContext) ?: return
            scanner.stopScan(buildBackgroundPendingIntent(context.applicationContext))
            Log.d(TAG, "Stopped BLE background proximity monitor")
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping BLE background monitor: ${e.message}")
        }
    }

    /**
     * Called by BleProximityReceiver when the hardware-filtered background scan sees the bound e-bike.
     */
    fun onBackgroundScanResult(context: Context, address: String, rssi: Int) {
        val appCtx = context.applicationContext
        val prefs = PreferenceManager(appCtx)
        if (!prefs.bluetoothAutoTrackEnabled || !prefs.bluetoothDeviceMode.equals("BLE", ignoreCase = true)) {
            return
        }
        val boundAddress = prefs.bluetoothDeviceAddress
        if (boundAddress.isBlank() || !address.equals(boundAddress, ignoreCase = true)) {
            return
        }

        val now = System.currentTimeMillis()
        lastSeenBoundAddress = address
        lastSeenTimestampMs = now
        lastSeenRssi = rssi

        if (LocationTrackingService.isTracking.value) {
            // Keep ride alive & cancel any pending disconnect grace
            LocationTrackingService.cancelBluetoothAutoStop(appCtx)
            return
        }

        // Only auto-start when RSSI is strong enough (rider is right next to the e-bike)
        val threshold = prefs.bleRssiThreshold
        if (rssi < threshold) {
            return
        }

        // Prevent immediate re-trigger right after an auto-stop while still walking away
        if (now - lastAutoStopTimestampMs < AUTO_START_COOLDOWN_MS) {
            return
        }

        val displayName = prefs.bluetoothDeviceName.ifBlank { "爱车 BLE" }
        Log.d(TAG, "Bound BLE e-bike nearby: $displayName ($address), rssi=$rssi >= $threshold -> auto start")
        try {
            LocationTrackingService.startTracking(
                context = appCtx,
                transportType = TransportType.EBIKE.name,
                autoTriggered = true
            )
        } catch (e: Exception) {
            Log.w(TAG, "Background FGS start restricted on BLE proximity: ${e.message}")
            postQuickStartNotification(appCtx, displayName)
        }
    }

    /**
     * Lightweight BLE heartbeat scan running only while LocationTrackingService is actively recording,
     * ensuring fresh lastSeenTimestampMs so we accurately detect when the rider leaves the e-bike.
     */
    @SuppressLint("MissingPermission")
    fun startActiveRideScan(context: Context) {
        val appCtx = context.applicationContext
        val prefs = PreferenceManager(appCtx)
        if (!prefs.bluetoothAutoTrackEnabled ||
            !prefs.bluetoothDeviceMode.equals("BLE", ignoreCase = true) ||
            prefs.bluetoothDeviceAddress.isBlank()
        ) {
            return
        }
        if (!hasBleScanPermission(appCtx)) return
        val scanner = getScanner(appCtx) ?: return
        val targetAddress = prefs.bluetoothDeviceAddress.uppercase()
        if (!BluetoothAdapter.checkBluetoothAddress(targetAddress)) return

        stopActiveRideScan(appCtx)
        // Initialize lastSeenTimestampMs to now so we don't prematurely time out at ride start
        lastSeenBoundAddress = targetAddress
        lastSeenTimestampMs = System.currentTimeMillis()

        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val addr = result.device?.address ?: return
                if (addr.equals(targetAddress, ignoreCase = true)) {
                    lastSeenBoundAddress = addr
                    lastSeenTimestampMs = System.currentTimeMillis()
                    lastSeenRssi = result.rssi
                }
            }

            override fun onBatchScanResults(results: MutableList<ScanResult>) {
                for (r in results) {
                    onScanResult(ScanSettings.CALLBACK_TYPE_ALL_MATCHES, r)
                }
            }
        }

        try {
            val filter = ScanFilter.Builder().setDeviceAddress(targetAddress).build()
            val settings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_POWER)
                .build()
            scanner.startScan(listOf(filter), settings, callback)
            activeRideCallback = callback
            Log.d(TAG, "Started active-ride BLE heartbeat scan for $targetAddress")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to start active-ride BLE heartbeat scan: ${e.message}")
        }
    }

    @SuppressLint("MissingPermission")
    fun stopActiveRideScan(context: Context) {
        val cb = activeRideCallback ?: return
        activeRideCallback = null
        try {
            getScanner(context.applicationContext)?.stopScan(cb)
            Log.d(TAG, "Stopped active-ride BLE heartbeat scan")
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping active-ride BLE scan: ${e.message}")
        }
    }

    fun markAutoStoppedNow() {
        lastAutoStopTimestampMs = System.currentTimeMillis()
    }

    fun secondsSinceLastSeen(): Long {
        val ts = lastSeenTimestampMs
        if (ts <= 0L) return Long.MAX_VALUE
        return ((System.currentTimeMillis() - ts) / 1000L).coerceAtLeast(0L)
    }

    private fun postQuickStartNotification(context: Context, deviceName: String) {
        try {
            val nm = context.getSystemService(NotificationManager::class.java) ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val ch = NotificationChannel(
                    FALLBACK_CHANNEL_ID,
                    "蓝牙自动骑行提醒",
                    NotificationManager.IMPORTANCE_HIGH
                )
                nm.createNotificationChannel(ch)
            }
            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val openPi = PendingIntent.getActivity(
                context,
                FALLBACK_NOTIFY_ID,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val notif = NotificationCompat.Builder(context, FALLBACK_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_menu_mylocation)
                .setContentTitle("检测到附近爱车：$deviceName")
                .setContentText("点击打开 Footprint 立即记录电动车骑行轨迹")
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(openPi)
                .build()
            nm.notify(FALLBACK_NOTIFY_ID, notif)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to post BLE proximity notification: ${e.message}")
        }
    }
}
