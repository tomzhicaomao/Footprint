import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class EbikeConfig {
  final String ebikeName;
  final double fullRangeKm;
  final double sinceChargeKm;
  final int lastChargeTime;
  final bool autoPauseEnabled;
  final bool keepScreenOn;
  final String defaultTransport;
  final bool bluetoothAutoTrackEnabled;
  final bool bluetoothAutoStopEnabled;
  final String bluetoothDeviceAddress;
  final String bluetoothDeviceName;
  final bool voiceAnnounceEnabled;
  final double voiceAnnounceIntervalKm;
  final bool voiceLowBatteryAlertEnabled;

  const EbikeConfig({
    this.ebikeName = '我的电动车',
    this.fullRangeKm = 60.0,
    this.sinceChargeKm = 0.0,
    this.lastChargeTime = 0,
    this.autoPauseEnabled = true,
    this.keepScreenOn = true,
    this.defaultTransport = 'EBIKE',
    this.bluetoothAutoTrackEnabled = false,
    this.bluetoothAutoStopEnabled = true,
    this.bluetoothDeviceAddress = '',
    this.bluetoothDeviceName = '',
    this.voiceAnnounceEnabled = true,
    this.voiceAnnounceIntervalKm = 1.0,
    this.voiceLowBatteryAlertEnabled = true,
  });

  factory EbikeConfig.fromJson(Map<String, dynamic> json) {
    return EbikeConfig(
      ebikeName: (json['ebikeName'] as String?)?.isNotEmpty == true
          ? json['ebikeName'] as String
          : '我的电动车',
      fullRangeKm: ((json['fullRangeKm'] as num?)?.toDouble() ?? 60.0)
          .clamp(10.0, 300.0),
      sinceChargeKm:
          ((json['sinceChargeKm'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 9999.0),
      lastChargeTime: (json['lastChargeTime'] as num?)?.toInt() ?? 0,
      autoPauseEnabled: json['autoPauseEnabled'] as bool? ?? true,
      keepScreenOn: json['keepScreenOn'] as bool? ?? true,
      defaultTransport: (json['defaultTransport'] as String?) ?? 'EBIKE',
      bluetoothAutoTrackEnabled:
          json['bluetoothAutoTrackEnabled'] as bool? ?? false,
      bluetoothAutoStopEnabled:
          json['bluetoothAutoStopEnabled'] as bool? ?? true,
      bluetoothDeviceAddress:
          (json['bluetoothDeviceAddress'] as String?) ?? '',
      bluetoothDeviceName: (json['bluetoothDeviceName'] as String?) ?? '',
      voiceAnnounceEnabled: json['voiceAnnounceEnabled'] as bool? ?? true,
      voiceAnnounceIntervalKm:
          ((json['voiceAnnounceIntervalKm'] as num?)?.toDouble() ?? 1.0)
              .clamp(0.5, 20.0),
      voiceLowBatteryAlertEnabled:
          json['voiceLowBatteryAlertEnabled'] as bool? ?? true,
    );
  }

  double get remainingRangeKm =>
      (fullRangeKm - sinceChargeKm).clamp(0.0, fullRangeKm);

  double get batteryFraction =>
      fullRangeKm > 0 ? (remainingRangeKm / fullRangeKm).clamp(0.0, 1.0) : 0.0;

  bool get isLowBattery => batteryFraction <= 0.2;
  bool get isWarnBattery => batteryFraction <= 0.35;
  bool get hasBoundBluetooth => bluetoothDeviceAddress.isNotEmpty;

  EbikeConfig copyWith({
    String? ebikeName,
    double? fullRangeKm,
    double? sinceChargeKm,
    int? lastChargeTime,
    bool? autoPauseEnabled,
    bool? keepScreenOn,
    String? defaultTransport,
    bool? bluetoothAutoTrackEnabled,
    bool? bluetoothAutoStopEnabled,
    String? bluetoothDeviceAddress,
    String? bluetoothDeviceName,
    bool? voiceAnnounceEnabled,
    double? voiceAnnounceIntervalKm,
    bool? voiceLowBatteryAlertEnabled,
  }) {
    return EbikeConfig(
      ebikeName: ebikeName ?? this.ebikeName,
      fullRangeKm: fullRangeKm ?? this.fullRangeKm,
      sinceChargeKm: sinceChargeKm ?? this.sinceChargeKm,
      lastChargeTime: lastChargeTime ?? this.lastChargeTime,
      autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      defaultTransport: defaultTransport ?? this.defaultTransport,
      bluetoothAutoTrackEnabled:
          bluetoothAutoTrackEnabled ?? this.bluetoothAutoTrackEnabled,
      bluetoothAutoStopEnabled:
          bluetoothAutoStopEnabled ?? this.bluetoothAutoStopEnabled,
      bluetoothDeviceAddress:
          bluetoothDeviceAddress ?? this.bluetoothDeviceAddress,
      bluetoothDeviceName: bluetoothDeviceName ?? this.bluetoothDeviceName,
      voiceAnnounceEnabled: voiceAnnounceEnabled ?? this.voiceAnnounceEnabled,
      voiceAnnounceIntervalKm:
          voiceAnnounceIntervalKm ?? this.voiceAnnounceIntervalKm,
      voiceLowBatteryAlertEnabled:
          voiceLowBatteryAlertEnabled ?? this.voiceLowBatteryAlertEnabled,
    );
  }
}

class RidingTelemetry {
  final double totalDistanceMeters;
  final int pointCount;
  final double speedKmh;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final double accuracyMeters;
  final bool isAutoPaused;
  final bool isPaused;
  final String transportType;
  final String address;
  final double? lat;
  final double? lng;

  const RidingTelemetry({
    this.totalDistanceMeters = 0.0,
    this.pointCount = 0,
    this.speedKmh = 0.0,
    this.avgSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.accuracyMeters = 0.0,
    this.isAutoPaused = false,
    this.isPaused = false,
    this.transportType = 'EBIKE',
    this.address = '',
    this.lat,
    this.lng,
  });

  double get distanceKm => totalDistanceMeters / 1000.0;

  RidingTelemetry copyWith({
    double? totalDistanceMeters,
    int? pointCount,
    double? speedKmh,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    double? accuracyMeters,
    bool? isAutoPaused,
    bool? isPaused,
    String? transportType,
    String? address,
    double? lat,
    double? lng,
  }) {
    return RidingTelemetry(
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      pointCount: pointCount ?? this.pointCount,
      speedKmh: speedKmh ?? this.speedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      isAutoPaused: isAutoPaused ?? this.isAutoPaused,
      isPaused: isPaused ?? this.isPaused,
      transportType: transportType ?? this.transportType,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

String transportDisplayName(String code) {
  switch (code) {
    case 'EBIKE':
      return '电动车';
    case 'BIKE':
      return '自行车';
    case 'WALK':
      return '步行';
    case 'CAR':
      return '自驾';
    case 'TRAIN':
      return '铁路';
    case 'PLANE':
      return '航空';
    default:
      return '电动车';
  }
}

IconData transportDisplayIcon(String code) {
  switch (code) {
    case 'EBIKE':
      return Icons.electric_scooter;
    case 'BIKE':
      return Icons.directions_bike;
    case 'WALK':
      return Icons.directions_walk;
    case 'CAR':
      return Icons.directions_car;
    case 'TRAIN':
      return Icons.train;
    case 'PLANE':
      return Icons.flight;
    default:
      return Icons.electric_scooter;
  }
}

Color speedAccentColor(double speedKmh) {
  if (speedKmh < 8) return const Color(0xFF2196F3);
  if (speedKmh < 18) return const Color(0xFF00C853);
  if (speedKmh < 28) return const Color(0xFFFFB300);
  if (speedKmh < 40) return const Color(0xFFFF6D00);
  return const Color(0xFFFF3D00);
}

/// 首页电动车骑行专属看板：今日/本周/本月/累计里程 + 电池续航估算 + 一键出发
class EbikeGarageCard extends StatelessWidget {
  final EbikeConfig config;
  final double todayKm;
  final double weekKm;
  final double monthKm;
  final double totalEbikeKm;
  final int ebikeRideCount;
  final bool isCurrentlyTracking;
  final VoidCallback onStartRide;
  final VoidCallback onResetCharge;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenKeepAliveCheck;

  const EbikeGarageCard({
    super.key,
    required this.config,
    required this.todayKm,
    required this.weekKm,
    required this.monthKm,
    required this.totalEbikeKm,
    required this.ebikeRideCount,
    required this.isCurrentlyTracking,
    required this.onStartRide,
    required this.onResetCharge,
    required this.onOpenSettings,
    required this.onOpenKeepAliveCheck,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fraction = config.batteryFraction;
    final batteryColor = config.isLowBattery
        ? const Color(0xFFE53935)
        : config.isWarnBattery
            ? const Color(0xFFFF9800)
            : const Color(0xFF00B87C);

    final statusLabel = config.isLowBattery
        ? '电量偏低 · 建议充电'
        : config.isWarnBattery
            ? '余电一般 · 注意规划'
            : '续航充足';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF16202C),
                  const Color(0xFF1B2B3A),
                ]
              : [
                  Colors.white,
                  Color.alphaBlend(
                    cs.primary.withValues(alpha: 0.06),
                    const Color(0xFFF6F9FC),
                  ),
                ],
        ),
        border: Border.all(
          color: config.isLowBattery
              ? batteryColor.withValues(alpha: 0.55)
              : cs.outlineVariant.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : cs.primary).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: bike name + battery status pill + settings
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.electric_scooter, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.ebikeName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '累计骑行 $ebikeRideCount 次 · 减碳 ${(totalEbikeKm * 0.14).toStringAsFixed(1)} kg',
                      style: TextStyle(fontSize: 11, color: cs.outline),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '防杀后台自检',
                onPressed: onOpenKeepAliveCheck,
                icon: Icon(Icons.shield_outlined, size: 20, color: cs.primary),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: '爱车与续航设置',
                onPressed: onOpenSettings,
                icon: Icon(Icons.tune, size: 20, color: cs.onSurfaceVariant),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mileage 4-column summary
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _mileageCell(cs, '今日', todayKm),
                _vDivider(cs),
                _mileageCell(cs, '本周', weekKm),
                _vDivider(cs),
                _mileageCell(cs, '本月', monthKm),
                _vDivider(cs),
                _mileageCell(cs, '累计', totalEbikeKm),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Battery & estimated remaining range bar
          Row(
            children: [
              Icon(
                config.isLowBattery ? Icons.battery_alert : Icons.battery_charging_full,
                size: 16,
                color: batteryColor,
              ),
              const SizedBox(width: 4),
              Text(
                '预估剩余 ${config.remainingRangeKm.toStringAsFixed(1)} km',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: batteryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: batteryColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(fraction * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: batteryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: cs.outlineVariant.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(batteryColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '充满后已骑 ${config.sinceChargeKm.toStringAsFixed(1)} / ${config.fullRangeKm.toStringAsFixed(0)} km',
                style: TextStyle(fontSize: 11, color: cs.outline),
              ),
              GestureDetector(
                onTap: onResetCharge,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 14, color: cs.primary),
                    const SizedBox(width: 2),
                    Text(
                      '充满重置',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick status pills: Bluetooth Auto Start/Stop & Voice Announcements
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _featurePill(
                icon: config.bluetoothAutoTrackEnabled && config.hasBoundBluetooth
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                label: config.bluetoothAutoTrackEnabled && config.hasBoundBluetooth
                    ? '蓝牙自动启停 · ${config.bluetoothDeviceName.isNotEmpty ? config.bluetoothDeviceName : "已绑定"}'
                    : '蓝牙自动启停 · 去绑定',
                active: config.bluetoothAutoTrackEnabled && config.hasBoundBluetooth,
                activeColor: const Color(0xFF1E88E5),
                cs: cs,
                onTap: onOpenSettings,
              ),
              _featurePill(
                icon: config.voiceAnnounceEnabled
                    ? Icons.record_voice_over
                    : Icons.volume_off_outlined,
                label: config.voiceAnnounceEnabled
                    ? '语音播报 · 每${config.voiceAnnounceIntervalKm % 1 == 0 ? config.voiceAnnounceIntervalKm.toInt() : config.voiceAnnounceIntervalKm.toStringAsFixed(1)}km'
                    : '语音播报 · 已关闭',
                active: config.voiceAnnounceEnabled,
                activeColor: const Color(0xFF00897B),
                cs: cs,
                onTap: onOpenSettings,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary CTA: One-tap start riding
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onStartRide,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isCurrentlyTracking ? const Color(0xFF00A86B) : cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                isCurrentlyTracking ? Icons.speed : Icons.play_arrow_rounded,
                size: 22,
              ),
              label: Text(
                isCurrentlyTracking ? '骑行记录中 · 查看实时码表' : '一键开始电动车骑行',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featurePill({
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    required ColorScheme cs,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? activeColor.withValues(alpha: 0.35)
                : cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? activeColor : cs.outline),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? activeColor : cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mileageCell(ColorScheme cs, String label, double km) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: km >= 100 ? km.toStringAsFixed(0) : km.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(
                  text: ' km',
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: cs.outline)),
        ],
      ),
    );
  }

  Widget _vDivider(ColorScheme cs) {
    return Container(
      width: 1,
      height: 24,
      color: cs.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

/// 爱车与骑行设置弹窗（含续航、蓝牙自动启停、语音播报）
Future<EbikeConfig?> showEbikeConfigSheet(
  BuildContext context,
  EbikeConfig current,
) async {
  const channel = MethodChannel('com.footprint/data');
  final nameCtrl = TextEditingController(text: current.ebikeName);
  double fullRange = current.fullRangeKm;
  double sinceCharge = current.sinceChargeKm;
  bool autoPause = current.autoPauseEnabled;
  bool keepScreenOn = current.keepScreenOn;
  bool btAutoTrack = current.bluetoothAutoTrackEnabled;
  bool btAutoStop = current.bluetoothAutoStopEnabled;
  String btAddress = current.bluetoothDeviceAddress;
  String btName = current.bluetoothDeviceName;
  bool voiceEnabled = current.voiceAnnounceEnabled;
  double voiceIntervalKm = current.voiceAnnounceIntervalKm;
  bool voiceLowBattery = current.voiceLowBatteryAlertEnabled;

  Future<void> pickBluetoothDevice(
    BuildContext sheetCtx,
    void Function(VoidCallback) setModalState,
  ) async {
    try {
      final status = await Permission.bluetoothConnect.request();
      if (!status.isGranted) {
        if (sheetCtx.mounted) {
          ScaffoldMessenger.of(sheetCtx).showSnackBar(
            SnackBar(
              content: const Text('需要授予“附近设备（蓝牙）”权限才能读取已配对设备'),
              action: SnackBarAction(label: '去设置', onPressed: openAppSettings),
            ),
          );
        }
        return;
      }
      final jsonStr = await channel.invokeMethod<String>('getPairedBluetoothDevices');
      final List<dynamic> devices = jsonStr != null ? jsonDecode(jsonStr) : [];
      if (!sheetCtx.mounted) return;

      final selected = await showDialog<Map<String, String>>(
        context: sheetCtx,
        builder: (dCtx) {
          final cs = Theme.of(dCtx).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Row(
              children: [
                Icon(Icons.bluetooth_searching, size: 22),
                SizedBox(width: 8),
                Text('选择已配对蓝牙', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: devices.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '未找到已配对的蓝牙设备。\n请先在手机系统蓝牙中连接您的电动车或头盔耳机，再回到此处绑定。',
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.5),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: devices.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, idx) {
                        final dev = devices[idx] as Map<String, dynamic>;
                        final name = (dev['name'] as String?) ?? '未知设备';
                        final addr = (dev['address'] as String?) ?? '';
                        final isBound = addr.toUpperCase() == btAddress.toUpperCase();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.bluetooth,
                            color: isBound ? cs.primary : cs.onSurfaceVariant,
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(addr, style: TextStyle(fontSize: 11, color: cs.outline)),
                          trailing: isBound
                              ? Icon(Icons.check_circle, color: cs.primary, size: 20)
                              : null,
                          onTap: () => Navigator.pop(dCtx, {'name': name, 'address': addr}),
                        );
                      },
                    ),
            ),
            actions: [
              if (btAddress.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.pop(dCtx, {'name': '', 'address': ''}),
                  child: const Text('解除绑定', style: TextStyle(color: Colors.redAccent)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(dCtx),
                child: const Text('取消'),
              ),
            ],
          );
        },
      );

      if (selected != null) {
        setModalState(() {
          btName = selected['name'] ?? '';
          btAddress = selected['address'] ?? '';
          if (btAddress.isNotEmpty) {
            btAutoTrack = true;
          } else {
            btAutoTrack = false;
          }
        });
      }
    } on PlatformException catch (e) {
      if (sheetCtx.mounted) {
        ScaffoldMessenger.of(sheetCtx).showSnackBar(
          SnackBar(content: Text(e.message ?? '获取蓝牙设备失败')),
        );
      }
    } catch (e) {
      if (sheetCtx.mounted) {
        ScaffoldMessenger.of(sheetCtx).showSnackBar(
          SnackBar(content: Text('蓝牙读取异常: $e')),
        );
      }
    }
  }

  final result = await showModalBottomSheet<EbikeConfig>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final cs = Theme.of(context).colorScheme;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.electric_scooter, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            '电动车与骑行设置',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: '爱车名称',
                          hintText: '例如：九号 F90M / 雅迪冠能',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '满电标称/实际续航',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${fullRange.round()} km',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: fullRange.clamp(20.0, 150.0),
                        min: 20,
                        max: 150,
                        divisions: 26,
                        label: '${fullRange.round()} km',
                        onChanged: (v) => setModalState(() => fullRange = v),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '本轮充电已骑行里程（可手动微调）',
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            '${sinceCharge.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.secondary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: sinceCharge.clamp(0.0, fullRange),
                        min: 0,
                        max: fullRange,
                        onChanged: (v) => setModalState(() => sinceCharge = v),
                      ),
                      const Divider(height: 24),

                      // === 蓝牙自动启停区块 ===
                      Row(
                        children: [
                          const Icon(Icons.bluetooth_connected, size: 18, color: Color(0xFF1E88E5)),
                          const SizedBox(width: 6),
                          Text(
                            '蓝牙自动启停',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    btAddress.isNotEmpty
                                        ? (btName.isNotEmpty ? btName : '已绑定蓝牙设备')
                                        : '尚未绑定电动车 / 头盔蓝牙',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    btAddress.isNotEmpty
                                        ? btAddress
                                        : '绑定后，连接该蓝牙即自动开始记录',
                                    style: TextStyle(fontSize: 11, color: cs.outline),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () => pickBluetoothDevice(context, setModalState),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(btAddress.isNotEmpty ? '更换' : '选择设备'),
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('连接绑定蓝牙自动开始骑行'),
                        subtitle: const Text('支持电动车蓝牙或头盔蓝牙耳机'),
                        value: btAutoTrack,
                        onChanged: (v) async {
                          if (v && btAddress.isEmpty) {
                            await pickBluetoothDevice(context, setModalState);
                          } else {
                            setModalState(() => btAutoTrack = v);
                          }
                        },
                      ),
                      if (btAutoTrack)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('断开蓝牙自动结束并保存'),
                          subtitle: const Text('断开后等待 20 秒防误判，未重连则自动保存轨迹'),
                          value: btAutoStop,
                          onChanged: (v) => setModalState(() => btAutoStop = v),
                        ),
                      const Divider(height: 24),

                      // === 骑行语音播报区块 ===
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over, size: 18, color: Color(0xFF00897B)),
                          const SizedBox(width: 6),
                          Text(
                            '骑行语音播报 (TTS)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              try {
                                await channel.invokeMethod('testVoiceAnnouncement');
                              } catch (_) {}
                            },
                            icon: const Icon(Icons.volume_up, size: 16),
                            label: const Text('试听', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('开启骑行语音播报'),
                        subtitle: const Text('启停、里程节点自动播报，播放时自动压低背景音乐'),
                        value: voiceEnabled,
                        onChanged: (v) => setModalState(() => voiceEnabled = v),
                      ),
                      if (voiceEnabled) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                '里程播报间隔',
                                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                              ),
                              const Spacer(),
                              Wrap(
                                spacing: 8,
                                children: [1.0, 2.0, 5.0].map((km) {
                                  final sel = (voiceIntervalKm - km).abs() < 0.1;
                                  return ChoiceChip(
                                    label: Text('每 ${km.toInt()} km'),
                                    selected: sel,
                                    onSelected: (_) =>
                                        setModalState(() => voiceIntervalKm = km),
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('低续航语音提醒（剩余 < 20%）'),
                          subtitle: const Text('骑行中预估续航偏低时语音提醒及时充电'),
                          value: voiceLowBattery,
                          onChanged: (v) => setModalState(() => voiceLowBattery = v),
                        ),
                      ],
                      const Divider(height: 24),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('红绿灯自动暂停计时'),
                        subtitle: const Text('车速低于 1.8 km/h 持续 8 秒自动暂停，起步自动恢复'),
                        value: autoPause,
                        onChanged: (v) => setModalState(() => autoPause = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('骑行时默认屏幕常亮'),
                        subtitle: const Text('方便手机架在车把上随时查看时速与路线'),
                        value: keepScreenOn,
                        onChanged: (v) => setModalState(() => keepScreenOn = v),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(
                              ctx,
                              current.copyWith(
                                ebikeName: nameCtrl.text.trim().isEmpty
                                    ? '我的电动车'
                                    : nameCtrl.text.trim(),
                                fullRangeKm: fullRange,
                                sinceChargeKm: sinceCharge,
                                autoPauseEnabled: autoPause,
                                keepScreenOn: keepScreenOn,
                                bluetoothAutoTrackEnabled: btAutoTrack && btAddress.isNotEmpty,
                                bluetoothAutoStopEnabled: btAutoStop,
                                bluetoothDeviceAddress: btAddress,
                                bluetoothDeviceName: btName,
                                voiceAnnounceEnabled: voiceEnabled,
                                voiceAnnounceIntervalKm: voiceIntervalKm,
                                voiceLowBatteryAlertEnabled: voiceLowBattery,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '保存设置',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
  nameCtrl.dispose();
  return result;
}

/// 地图页底部实时骑行仪表盘卡片
class RidingTelemetryCard extends StatelessWidget {
  final RidingTelemetry telemetry;
  final ValueNotifier<String> durationNotifier;
  final EbikeConfig ebikeConfig;
  final bool keepScreenOn;
  final bool followCamera;
  final VoidCallback onToggleKeepScreenOn;
  final VoidCallback onToggleFollowCamera;
  final VoidCallback onOpenFullScreenHud;

  const RidingTelemetryCard({
    super.key,
    required this.telemetry,
    required this.durationNotifier,
    required this.ebikeConfig,
    required this.keepScreenOn,
    required this.followCamera,
    required this.onToggleKeepScreenOn,
    required this.onToggleFollowCamera,
    required this.onOpenFullScreenHud,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = speedAccentColor(telemetry.speedKmh);
    final projectedRemaining = (ebikeConfig.remainingRangeKm -
            (telemetry.transportType == 'EBIKE' ? telemetry.distanceKm : 0.0))
        .clamp(0.0, ebikeConfig.fullRangeKm);

    final (gpsLabel, gpsColor) = _gpsQuality(telemetry.accuracyMeters);

    return Card(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: telemetry.isAutoPaused
              ? Colors.orangeAccent.withValues(alpha: 0.7)
              : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: cs.surface.withValues(alpha: isDark ? 0.94 : 0.96),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top status strip
            Row(
              children: [
                Icon(
                  transportDisplayIcon(telemetry.transportType),
                  size: 16,
                  color: cs.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  transportDisplayName(telemetry.transportType),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: telemetry.isPaused
                        ? Colors.orange.withValues(alpha: 0.16)
                        : telemetry.isAutoPaused
                            ? Colors.amber.withValues(alpha: 0.2)
                            : const Color(0xFF00C853).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    telemetry.isPaused
                        ? '已暂停'
                        : telemetry.isAutoPaused
                            ? '等红灯暂停'
                            : '记录中',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: telemetry.isPaused
                          ? Colors.orange
                          : telemetry.isAutoPaused
                              ? Colors.amber.shade800
                              : const Color(0xFF00A86B),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: gpsColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.satellite_alt, size: 10, color: gpsColor),
                      const SizedBox(width: 3),
                      Text(
                        gpsLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: gpsColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _miniIconBtn(
                  icon: keepScreenOn ? Icons.wb_sunny : Icons.wb_sunny_outlined,
                  active: keepScreenOn,
                  tooltip: '屏幕常亮',
                  onTap: onToggleKeepScreenOn,
                  cs: cs,
                ),
                const SizedBox(width: 4),
                _miniIconBtn(
                  icon: followCamera ? Icons.navigation : Icons.navigation_outlined,
                  active: followCamera,
                  tooltip: '视角跟随',
                  onTap: onToggleFollowCamera,
                  cs: cs,
                ),
                const SizedBox(width: 4),
                _miniIconBtn(
                  icon: Icons.fullscreen,
                  active: false,
                  tooltip: '全屏骑行码表',
                  onTap: onOpenFullScreenHud,
                  cs: cs,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Hero Speed + Distance row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            telemetry.speedKmh.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 34,
                              height: 1.0,
                              fontWeight: FontWeight.w900,
                              color: accent,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'km/h',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('实时车速', style: TextStyle(fontSize: 11, color: cs.outline)),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            telemetry.distanceKm.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 32,
                              height: 1.0,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'km',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('本次里程', style: TextStyle(fontSize: 11, color: cs.outline)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.45)),
            const SizedBox(height: 10),

            // Secondary metrics row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: durationNotifier,
                  builder: (_, val, _) => _subMetric('骑行时长', val, cs),
                ),
                _subMetric('均速', '${telemetry.avgSpeedKmh.toStringAsFixed(1)} km/h', cs),
                _subMetric('极速', '${telemetry.maxSpeedKmh.toStringAsFixed(1)} km/h', cs),
                if (telemetry.transportType == 'EBIKE')
                  _subMetric(
                    '预估余航',
                    '${projectedRemaining.toStringAsFixed(0)} km',
                    cs,
                    highlightColor: projectedRemaining <= ebikeConfig.fullRangeKm * 0.2
                        ? Colors.redAccent
                        : null,
                  ),
              ],
            ),
            if (telemetry.address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: cs.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      telemetry.address,
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, Color) _gpsQuality(double accuracy) {
    if (accuracy <= 0) return ('定位中', Colors.blueGrey);
    if (accuracy <= 12) return ('GPS强 ±${accuracy.round()}m', const Color(0xFF00A86B));
    if (accuracy <= 28) return ('GPS良 ±${accuracy.round()}m', Colors.amber.shade700);
    return ('信号弱 ±${accuracy.round()}m', Colors.redAccent);
  }

  Widget _miniIconBtn({
    required IconData icon,
    required bool active,
    required String tooltip,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: active
                ? cs.primary.withValues(alpha: 0.16)
                : cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _subMetric(
    String label,
    String value,
    ColorScheme cs, {
    Color? highlightColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: highlightColor ?? cs.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: cs.outline)),
      ],
    );
  }
}

/// 全屏骑行码表 HUD（适合手机支架固定在车把上）
class FullScreenRideHud extends StatelessWidget {
  final ValueNotifier<RidingTelemetry> telemetryNotifier;
  final ValueNotifier<String> durationNotifier;
  final EbikeConfig ebikeConfig;
  final bool keepScreenOn;
  final VoidCallback onToggleKeepScreenOn;
  final VoidCallback onTogglePause;
  final VoidCallback onRequestStop;
  final VoidCallback onClose;

  const FullScreenRideHud({
    super.key,
    required this.telemetryNotifier,
    required this.durationNotifier,
    required this.ebikeConfig,
    required this.keepScreenOn,
    required this.onToggleKeepScreenOn,
    required this.onTogglePause,
    required this.onRequestStop,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0A0F18),
      child: SafeArea(
        child: ValueListenableBuilder<RidingTelemetry>(
          valueListenable: telemetryNotifier,
          builder: (context, t, _) {
            final accent = speedAccentColor(t.speedKmh);
            final speedProgress = (t.speedKmh / 50.0).clamp(0.0, 1.0);
            final projectedRemaining = (ebikeConfig.remainingRangeKm -
                    (t.transportType == 'EBIKE' ? t.distanceKm : 0.0))
                .clamp(0.0, ebikeConfig.fullRangeKm);
            final batteryFrac = ebikeConfig.fullRangeKm > 0
                ? (projectedRemaining / ebikeConfig.fullRangeKm).clamp(0.0, 1.0)
                : 0.0;
            final batteryColor = batteryFrac <= 0.2
                ? const Color(0xFFFF5252)
                : batteryFrac <= 0.35
                    ? Colors.amber
                    : const Color(0xFF00E676);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Top Bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              transportDisplayIcon(t.transportType),
                              size: 16,
                              color: accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${transportDisplayName(t.transportType)}码表',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (t.accuracyMeters > 0)
                        Text(
                          'GPS ±${t.accuracyMeters.round()}m',
                          style: TextStyle(
                            color: t.accuracyMeters <= 15
                                ? const Color(0xFF00E676)
                                : Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        onPressed: onToggleKeepScreenOn,
                        icon: Icon(
                          keepScreenOn ? Icons.wb_sunny : Icons.wb_sunny_outlined,
                          color: keepScreenOn ? Colors.amber : Colors.white54,
                        ),
                        tooltip: '屏幕常亮',
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.map_outlined, color: Colors.white),
                        tooltip: '返回地图',
                      ),
                    ],
                  ),

                  if (t.isAutoPaused || t.isPaused)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        t.isPaused ? '⏸ 已手动暂停记录' : '🚦 等红灯自动暂停中 · 起步即恢复',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Giant Digital Speedometer
                  Text(
                    t.speedKmh.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 92,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                      color: accent,
                      letterSpacing: -2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'KM / H',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Speed progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: speedProgress,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),

                  const Spacer(),

                  // 2x2 Big Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _hudTile(
                          '本次里程',
                          t.distanceKm.toStringAsFixed(2),
                          'km',
                          const Color(0xFF40C4FF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: durationNotifier,
                          builder: (_, dur, _) => _hudTile(
                            '有效骑行',
                            dur,
                            '',
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _hudTile(
                          '平均时速',
                          t.avgSpeedKmh.toStringAsFixed(1),
                          'km/h',
                          const Color(0xFF69F0AE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _hudTile(
                          '最高时速',
                          t.maxSpeedKmh.toStringAsFixed(1),
                          'km/h',
                          const Color(0xFFFFAB40),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Remaining battery range bar
                  if (t.transportType == 'EBIKE')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.battery_charging_full, color: batteryColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '预估剩余续航 ${projectedRemaining.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${(batteryFrac * 100).round()}%',
                                      style: TextStyle(
                                        color: batteryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: batteryFrac,
                                    minHeight: 5,
                                    backgroundColor: Colors.white12,
                                    valueColor: AlwaysStoppedAnimation<Color>(batteryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (t.address.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      t.address,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Glove-friendly large controls
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: FilledButton.icon(
                            onPressed: onTogglePause,
                            style: FilledButton.styleFrom(
                              backgroundColor: t.isPaused
                                  ? const Color(0xFF00C853)
                                  : Colors.orangeAccent.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: Icon(
                              t.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 28,
                            ),
                            label: Text(
                              t.isPaused ? '继续骑行' : '暂停',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: FilledButton.icon(
                            onPressed: onRequestStop,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD32F2F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.stop_rounded, size: 28),
                            label: const Text(
                              '结束骑行',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _hudTile(String label, String value, String unit, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 停止骑行防误触确认弹窗 -> 返回 'save' / 'discard' / null(继续)
Future<String?> showStopRideConfirmSheet(
  BuildContext context, {
  required RidingTelemetry telemetry,
  required String durationText,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final isVeryShort = telemetry.totalDistanceMeters < 50 && telemetry.pointCount < 3;
      return Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '结束本次${transportDisplayName(telemetry.transportType)}记录？',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _confirmMetric('里程', '${telemetry.distanceKm.toStringAsFixed(2)} km', cs),
                  _confirmMetric('用时', durationText, cs),
                  _confirmMetric('均速', '${telemetry.avgSpeedKmh.toStringAsFixed(1)} km/h', cs),
                  _confirmMetric('极速', '${telemetry.maxSpeedKmh.toStringAsFixed(1)} km/h', cs),
                ],
              ),
            ),
            if (isVeryShort) ...[
              const SizedBox(height: 10),
              Text(
                '当前移动距离较短（< 50米），若为误触可选择放弃本次记录。',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, 'save'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('结束并保存轨迹', style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('继续骑行'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, 'discard'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('放弃记录'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _confirmMetric(String label, String val, ColorScheme cs) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        val,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: cs.outline)),
    ],
  );
}

/// 防杀后台自检弹窗（解决国产手机息屏骑行断轨迹痛点）
Future<void> showBackgroundKeepAliveDialog(BuildContext context) async {
  const channel = MethodChannel('com.footprint/data');
  bool locWhenInUse = await Permission.locationWhenInUse.isGranted;
  bool locAlways = await Permission.locationAlways.isGranted;
  bool notifyGranted = await Permission.notification.isGranted;
  bool batteryExempt = false;
  try {
    batteryExempt = await channel.invokeMethod('isIgnoringBatteryOptimizations') == true;
  } catch (_) {}

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          Future<void> refresh() async {
            final l1 = await Permission.locationWhenInUse.isGranted;
            final l2 = await Permission.locationAlways.isGranted;
            final n1 = await Permission.notification.isGranted;
            bool b1 = false;
            try {
              b1 = await channel.invokeMethod('isIgnoringBatteryOptimizations') == true;
            } catch (_) {}
            setDialogState(() {
              locWhenInUse = l1;
              locAlways = l2;
              notifyGranted = n1;
              batteryExempt = b1;
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.shield_outlined, color: cs.primary),
                const SizedBox(width: 8),
                const Text('骑行防断连体检', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '骑车锁屏放兜里时，系统省电策略容易杀后台导致轨迹变成直线。请确保以下权限全部开启：',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  _checkItem(
                    title: '精确定位权限',
                    ok: locWhenInUse,
                    onFix: () async {
                      await Permission.locationWhenInUse.request();
                      await refresh();
                    },
                  ),
                  _checkItem(
                    title: '后台始终允许定位',
                    ok: locAlways,
                    onFix: () async {
                      await Permission.locationAlways.request();
                      await refresh();
                    },
                  ),
                  _checkItem(
                    title: '电池优化白名单（不限制后台）',
                    ok: batteryExempt,
                    onFix: () async {
                      try {
                        await channel.invokeMethod('requestBatteryOptimizationExemption');
                      } catch (_) {}
                      await Future.delayed(const Duration(milliseconds: 600));
                      await refresh();
                    },
                  ),
                  _checkItem(
                    title: '通知栏常驻权限',
                    ok: notifyGranted,
                    onFix: () async {
                      await Permission.notification.request();
                      await refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '💡 小贴士：小米/华为/OPPO/vivo 手机建议在系统“最近任务”界面将本应用下拉加锁，并开启“允许自启动”，骑行 2 小时也不掉线。',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('打开系统设置'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('完成'),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _checkItem({
  required String title,
  required bool ok,
  required VoidCallback onFix,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.warning_amber_rounded,
          color: ok ? const Color(0xFF00A86B) : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
        if (!ok)
          TextButton(
            onPressed: onFix,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('去开启'),
          )
        else
          const Text(
            '已就绪',
            style: TextStyle(fontSize: 12, color: Color(0xFF00A86B), fontWeight: FontWeight.w600),
          ),
      ],
    ),
  );
}

/// 骑行详情页速度变化曲线图
class RideSpeedChart extends StatelessWidget {
  final List<double> speedsKmh;
  final double avgSpeedKmh;
  final double maxSpeedKmh;

  const RideSpeedChart({
    super.key,
    required this.speedsKmh,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (speedsKmh.length < 2) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                '骑行速度曲线',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '均速 ${avgSpeedKmh.toStringAsFixed(1)} · 极速 ${maxSpeedKmh.toStringAsFixed(1)} km/h',
                style: TextStyle(fontSize: 11, color: cs.outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _SpeedChartPainter(
                speeds: speedsKmh,
                avgSpeed: avgSpeedKmh,
                primaryColor: cs.primary,
                gridColor: cs.outlineVariant.withValues(alpha: 0.45),
                labelColor: cs.outline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendDot('0-8 慢行', const Color(0xFF2196F3), cs),
              _legendDot('8-18 巡航', const Color(0xFF00C853), cs),
              _legendDot('18-28 畅行', const Color(0xFFFFB300), cs),
              _legendDot('28+ 疾驰', const Color(0xFFFF6D00), cs),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String text, Color color, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 10, color: cs.outline)),
      ],
    );
  }
}

class _SpeedChartPainter extends CustomPainter {
  final List<double> speeds;
  final double avgSpeed;
  final Color primaryColor;
  final Color gridColor;
  final Color labelColor;

  _SpeedChartPainter({
    required this.speeds,
    required this.avgSpeed,
    required this.primaryColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (speeds.length < 2) return;

    // Downsample to max 80 buckets for smooth rendering
    final List<double> sampled;
    if (speeds.length > 80) {
      sampled = List<double>.generate(80, (i) {
        final idx = (i * (speeds.length - 1) / 79).round();
        return speeds[idx];
      });
    } else {
      sampled = speeds;
    }

    final maxVal = math.max(
      15.0,
      sampled.fold<double>(0.0, (m, v) => math.max(m, v)) * 1.15,
    );

    const leftPad = 28.0;
    const topPad = 8.0;
    const bottomPad = 12.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - topPad - bottomPad;

    // Horizontal grid lines + y-axis labels
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int step = 0; step <= 2; step++) {
      final frac = step / 2.0;
      final y = topPad + chartH * (1 - frac);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: (maxVal * frac).round().toString(),
          style: TextStyle(color: labelColor, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Build line & fill path
    final linePath = Path();
    final fillPath = Path();
    for (int i = 0; i < sampled.length; i++) {
      final x = leftPad + (i / (sampled.length - 1)) * chartW;
      final y = topPad + chartH * (1 - (sampled[i] / maxVal).clamp(0.0, 1.0));
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, topPad + chartH);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(leftPad + chartW, topPad + chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.35),
          primaryColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Dashed average speed line
    if (avgSpeed > 0.5) {
      final avgY = topPad + chartH * (1 - (avgSpeed / maxVal).clamp(0.0, 1.0));
      final avgPaint = Paint()
        ..color = const Color(0xFF00C853).withValues(alpha: 0.75)
        ..strokeWidth = 1.2;
      double dx = leftPad;
      while (dx < size.width) {
        canvas.drawLine(Offset(dx, avgY), Offset(math.min(dx + 5, size.width), avgY), avgPaint);
        dx += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedChartPainter oldDelegate) {
    return oldDelegate.speeds != speeds || oldDelegate.avgSpeed != avgSpeed;
  }
}
