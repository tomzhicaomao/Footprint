package com.footprint.receiver

import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanResult
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.footprint.service.BleProximityManager

/**
 * Receives PendingIntent callbacks from Android's hardware-filtered BLE background scanner
 * when the user's bound e-bike is advertising nearby (no Bluetooth pairing required).
 */
class BleProximityReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BleProximityReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val errorCode = intent.getIntExtra(BluetoothLeScanner.EXTRA_ERROR_CODE, -1)
        if (errorCode != -1) {
            Log.w(TAG, "BLE background scan callback errorCode=$errorCode")
            return
        }

        val results = extractScanResults(intent)
        if (results.isEmpty()) return

        // Pick the strongest RSSI packet in this batch for the matching device
        val best = results.maxByOrNull { it.rssi } ?: return
        val address = best.device?.address ?: return
        BleProximityManager.onBackgroundScanResult(context, address, best.rssi)
    }

    @Suppress("DEPRECATION")
    private fun extractScanResults(intent: Intent): List<ScanResult> {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableArrayListExtra(
                    BluetoothLeScanner.EXTRA_LIST_SCAN_RESULT,
                    ScanResult::class.java
                ) ?: emptyList()
            } else {
                intent.getParcelableArrayListExtra<ScanResult>(
                    BluetoothLeScanner.EXTRA_LIST_SCAN_RESULT
                ) ?: emptyList()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to extract BLE scan results: ${e.message}")
            emptyList()
        }
    }
}
