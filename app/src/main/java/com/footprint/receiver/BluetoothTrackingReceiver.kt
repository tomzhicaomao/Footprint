package com.footprint.receiver

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.footprint.MainActivity
import com.footprint.data.model.TransportType
import com.footprint.service.BleProximityManager
import com.footprint.service.LocationTrackingService
import com.footprint.utils.PreferenceManager

/**
 * Listens for Bluetooth ACL connect/disconnect events for the user's bound e-bike or helmet headset
 * and automatically starts or gracefully stops riding tracking. Also re-syncs BLE proximity scanning
 * whenever the Bluetooth adapter is turned back on.
 */
class BluetoothTrackingReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BtTrackingReceiver"
        private const val FALLBACK_CHANNEL_ID = "bt_auto_ride_channel"
        private const val FALLBACK_NOTIFY_ID = 1099
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        if (action == BluetoothAdapter.ACTION_STATE_CHANGED) {
            val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
            if (state == BluetoothAdapter.STATE_ON) {
                Log.d(TAG, "Bluetooth adapter turned ON, syncing BLE proximity monitor")
                BleProximityManager.syncMonitorState(context)
            }
            return
        }

        if (action != BluetoothDevice.ACTION_ACL_CONNECTED &&
                        action != BluetoothDevice.ACTION_ACL_DISCONNECTED
        ) {
            return
        }

        val prefs = PreferenceManager(context)
        if (!prefs.bluetoothAutoTrackEnabled) return
        val boundAddress = prefs.bluetoothDeviceAddress
        if (boundAddress.isBlank()) return

        val device = extractBluetoothDevice(intent) ?: return
        val deviceAddress =
                try {
                    device.address
                } catch (_: SecurityException) {
                    return
                }
        if (deviceAddress.isNullOrBlank() || !deviceAddress.equals(boundAddress, ignoreCase = true)) {
            return
        }

        val displayName = prefs.bluetoothDeviceName.ifBlank { "爱车蓝牙" }

        when (action) {
            BluetoothDevice.ACTION_ACL_CONNECTED -> {
                Log.d(TAG, "Bound Bluetooth connected: $displayName ($deviceAddress)")
                if (LocationTrackingService.isTracking.value) {
                    // Cancel any pending disconnect grace countdown
                    LocationTrackingService.cancelBluetoothAutoStop(context)
                } else {
                    try {
                        LocationTrackingService.startTracking(
                                context = context,
                                transportType = TransportType.EBIKE.name,
                                autoTriggered = true
                        )
                    } catch (e: Exception) {
                        Log.w(TAG, "Background FGS start restricted, posting quick-start notification: ${e.message}")
                        postQuickStartNotification(context, displayName)
                    }
                }
            }
            BluetoothDevice.ACTION_ACL_DISCONNECTED -> {
                Log.d(TAG, "Bound Bluetooth disconnected: $displayName ($deviceAddress)")
                if (prefs.bluetoothAutoStopEnabled && LocationTrackingService.isTracking.value) {
                    LocationTrackingService.scheduleBluetoothAutoStop(context)
                }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun extractBluetoothDevice(intent: Intent): BluetoothDevice? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        } else {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        }
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
                    .setContentTitle("已连接 $deviceName")
                    .setContentText("点击打开 Footprint 开始记录电动车骑行轨迹")
                    .setAutoCancel(true)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setContentIntent(openPi)
                    .build()
            nm.notify(FALLBACK_NOTIFY_ID, notif)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to post fallback BT notification: ${e.message}")
        }
    }
}
