package com.footprint.utils

import android.content.Context
import android.content.SharedPreferences
import com.footprint.ui.theme.ThemeMode

class PreferenceManager(context: Context) {
    private val prefs: SharedPreferences =
            context.getSharedPreferences("footprint_prefs", Context.MODE_PRIVATE)

    var themeMode: ThemeMode
        get() {
            val name = prefs.getString("theme_mode", ThemeMode.SYSTEM.name)
            return try {
                ThemeMode.valueOf(name ?: ThemeMode.SYSTEM.name)
            } catch (e: Exception) {
                ThemeMode.SYSTEM
            }
        }
        set(value) {
            prefs.edit().putString("theme_mode", value.name).apply()
        }

    var isFirstLaunch: Boolean
        get() = prefs.getBoolean("is_first_launch", true)
        set(value) = prefs.edit().putBoolean("is_first_launch", value).apply()

    var nickname: String
        get() = prefs.getString("user_nickname", "旅行者") ?: "旅行者"
        set(value) = prefs.edit().putString("user_nickname", value).apply()

    var avatarId: String
        get() = prefs.getString("user_avatar_id", "avatar_1") ?: "avatar_1"
        set(value) = prefs.edit().putString("user_avatar_id", value).apply()

    var themeStyle: com.footprint.ui.theme.AppThemeStyle
        get() {
            val name =
                    prefs.getString(
                            "theme_style",
                            com.footprint.ui.theme.AppThemeStyle.CLASSIC.name
                    )
            return try {
                com.footprint.ui.theme.AppThemeStyle.valueOf(
                        name ?: com.footprint.ui.theme.AppThemeStyle.CLASSIC.name
                )
            } catch (e: Exception) {
                com.footprint.ui.theme.AppThemeStyle.CLASSIC
            }
        }
        set(value) {
            prefs.edit().putString("theme_style", value.name).apply()
        }

    var hasSeededV5: Boolean
        get() = prefs.getBoolean("has_seeded_v5", false)
        set(value) = prefs.edit().putBoolean("has_seeded_v5", value).apply()

    var blurStrength: Float
        get() = prefs.getFloat("blur_strength", 16f)
        set(value) = prefs.edit().putFloat("blur_strength", value).apply()

    var hapticFeedbackEnabled: Boolean
        get() = prefs.getBoolean("haptic_feedback", true)
        set(value) = prefs.edit().putBoolean("haptic_feedback", value).apply()

    var artAuthorName: String
        get() = prefs.getString("art_author_name", "漂泊的灵魂") ?: "漂泊的灵魂"
        set(value) = prefs.edit().putString("art_author_name", value).apply()

    var artFontName: String
        get() = prefs.getString("art_font_name", "Default") ?: "Default"
        set(value) = prefs.edit().putString("art_font_name", value).apply()

    var artColorStyle: String
        get() = prefs.getString("art_color_style", "Neon Green") ?: "Neon Green"
        set(value) = prefs.edit().putString("art_color_style", value).apply()

    var artTextColor: String
        get() = prefs.getString("art_text_color", "White") ?: "White"
        set(value) = prefs.edit().putString("art_text_color", value).apply()

    var artTextItalic: Boolean
        get() = prefs.getBoolean("art_text_italic", false)
        set(value) = prefs.edit().putBoolean("art_text_italic", value).apply()

    var artTextBorder: Boolean
        get() = prefs.getBoolean("art_text_border", false)
        set(value) = prefs.edit().putBoolean("art_text_border", value).apply()

    var polaroidFrameStyle: String
        get() = prefs.getString("polaroid_frame_style", "CLASSIC_WHITE") ?: "CLASSIC_WHITE"
        set(value) = prefs.edit().putString("polaroid_frame_style", value).apply()

    var polaroidFramePadding: Float
        get() = prefs.getFloat("polaroid_frame_padding", 0.5f)
        set(value) = prefs.edit().putFloat("polaroid_frame_padding", value).apply()

    var polaroidInnerBorder: Float
        get() = prefs.getFloat("polaroid_inner_border", 1f)
        set(value) = prefs.edit().putFloat("polaroid_inner_border", value).apply()

    var woodType: com.footprint.ui.screens.art.WoodType
        get() {
            val name = prefs.getString("wood_type", com.footprint.ui.screens.art.WoodType.ASH.name)
            return try {
                com.footprint.ui.screens.art.WoodType.valueOf(
                        name ?: com.footprint.ui.screens.art.WoodType.ASH.name
                )
            } catch (e: Exception) {
                com.footprint.ui.screens.art.WoodType.ASH
            }
        }
        set(value) = prefs.edit().putString("wood_type", value.name).apply()

    var engravingDepth: Float
        get() = prefs.getFloat("engraving_depth", 0.5f)
        set(value) = prefs.edit().putFloat("engraving_depth", value).apply()

    var canvasGrain: Float
        get() = prefs.getFloat("canvas_grain", 0.3f)
        set(value) = prefs.edit().putFloat("canvas_grain", value).apply()

    var armorType: com.footprint.ui.screens.art.ArmorType
        get() {
            val name =
                    prefs.getString(
                            "armor_type",
                            com.footprint.ui.screens.art.ArmorType.GUNMETAL.name
                    )
            return try {
                com.footprint.ui.screens.art.ArmorType.valueOf(
                        name ?: com.footprint.ui.screens.art.ArmorType.GUNMETAL.name
                )
            } catch (e: Exception) {
                com.footprint.ui.screens.art.ArmorType.GUNMETAL
            }
        }
        set(value) = prefs.edit().putString("armor_type", value.name).apply()

    var mechanicalSeams: Float
        get() = prefs.getFloat("mechanical_seams", 0.5f)
        set(value) = prefs.edit().putFloat("mechanical_seams", value).apply()

    var hasHazardStriping: Boolean
        get() = prefs.getBoolean("has_hazard_striping", false)
        set(value) = prefs.edit().putBoolean("has_hazard_striping", value).apply()

    // Stealth flag for the secret feature (avoid naming it 'Lucas' or 'Birthday')
    var isMaintenanceModeValidated: Boolean
        get() = prefs.getBoolean("is_maintenance_legacy_v2", false)
        set(value) = prefs.edit().putBoolean("is_maintenance_legacy_v2", value).apply()

    var eternalLettersJson: String
        get() = prefs.getString("eternal_letters_json", "[]") ?: "[]"
        set(value) = prefs.edit().putString("eternal_letters_json", value).apply()

    var eternalBondProfileJson: String
        get() = prefs.getString("eternal_bond_profile_json", "{}") ?: "{}"
        set(value) = prefs.edit().putString("eternal_bond_profile_json", value).apply()

    var eternalInnerGateUnlocked: Boolean
        get() = prefs.getBoolean("eternal_inner_gate_unlocked", false)
        set(value) = prefs.edit().putBoolean("eternal_inner_gate_unlocked", value).apply()

    // --- E-Bike Riding & Battery Range Preferences ---
    var ebikeName: String
        get() = prefs.getString("ebike_name", "我的电动车") ?: "我的电动车"
        set(value) = prefs.edit().putString("ebike_name", value.ifBlank { "我的电动车" }).apply()

    var ebikeFullRangeKm: Float
        get() = prefs.getFloat("ebike_full_range_km", 60.0f).coerceIn(10f, 300f)
        set(value) = prefs.edit().putFloat("ebike_full_range_km", value.coerceIn(10f, 300f)).apply()

    var ebikeSinceChargeKm: Float
        get() = prefs.getFloat("ebike_since_charge_km", 0.0f).coerceAtLeast(0f)
        set(value) = prefs.edit().putFloat("ebike_since_charge_km", value.coerceAtLeast(0f)).apply()

    var ebikeLastChargeTime: Long
        get() = prefs.getLong("ebike_last_charge_time", 0L)
        set(value) = prefs.edit().putLong("ebike_last_charge_time", value).apply()

    var ebikeAutoPauseEnabled: Boolean
        get() = prefs.getBoolean("ebike_auto_pause_enabled", true)
        set(value) = prefs.edit().putBoolean("ebike_auto_pause_enabled", value).apply()

    var ebikeKeepScreenOn: Boolean
        get() = prefs.getBoolean("ebike_keep_screen_on", true)
        set(value) = prefs.edit().putBoolean("ebike_keep_screen_on", value).apply()

    var defaultTrackingTransport: String
        get() = prefs.getString("default_tracking_transport", "EBIKE") ?: "EBIKE"
        set(value) = prefs.edit().putString("default_tracking_transport", value).apply()

    fun addEbikeChargeMileage(deltaKm: Double) {
        if (deltaKm <= 0.0) return
        ebikeSinceChargeKm = (ebikeSinceChargeKm + deltaKm.toFloat()).coerceAtLeast(0f)
    }

    fun resetEbikeCharge() {
        prefs.edit()
            .putFloat("ebike_since_charge_km", 0.0f)
            .putLong("ebike_last_charge_time", System.currentTimeMillis())
            .apply()
    }

    // --- Bluetooth Auto Start/Stop Preferences ---
    var bluetoothAutoTrackEnabled: Boolean
        get() = prefs.getBoolean("bt_auto_track_enabled", false)
        set(value) = prefs.edit().putBoolean("bt_auto_track_enabled", value).apply()

    var bluetoothAutoStopEnabled: Boolean
        get() = prefs.getBoolean("bt_auto_stop_enabled", true)
        set(value) = prefs.edit().putBoolean("bt_auto_stop_enabled", value).apply()

    var bluetoothDeviceAddress: String
        get() = prefs.getString("bt_device_address", "") ?: ""
        set(value) = prefs.edit().putString("bt_device_address", value.trim()).apply()

    var bluetoothDeviceName: String
        get() = prefs.getString("bt_device_name", "") ?: ""
        set(value) = prefs.edit().putString("bt_device_name", value.trim()).apply()

    // --- Ride Voice Announcement (TTS) Preferences ---
    var voiceAnnounceEnabled: Boolean
        get() = prefs.getBoolean("voice_announce_enabled", true)
        set(value) = prefs.edit().putBoolean("voice_announce_enabled", value).apply()

    var voiceAnnounceIntervalKm: Float
        get() = prefs.getFloat("voice_announce_interval_km", 1.0f).coerceIn(0.5f, 20.0f)
        set(value) = prefs.edit().putFloat("voice_announce_interval_km", value.coerceIn(0.5f, 20.0f)).apply()

    var voiceLowBatteryAlertEnabled: Boolean
        get() = prefs.getBoolean("voice_low_battery_alert_enabled", true)
        set(value) = prefs.edit().putBoolean("voice_low_battery_alert_enabled", value).apply()
}
