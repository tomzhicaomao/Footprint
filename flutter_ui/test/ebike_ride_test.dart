import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ui/ebike_ride_widgets.dart';

void main() {
  group('EbikeConfig battery & range estimator', () {
    test('calculates remaining range and warning flags accurately', () {
      const full = EbikeConfig(fullRangeKm: 60, sinceChargeKm: 10);
      expect(full.remainingRangeKm, closeTo(50.0, 0.01));
      expect(full.batteryFraction, closeTo(50 / 60, 0.001));
      expect(full.isWarnBattery, isFalse);
      expect(full.isLowBattery, isFalse);

      const warn = EbikeConfig(fullRangeKm: 60, sinceChargeKm: 42);
      expect(warn.remainingRangeKm, closeTo(18.0, 0.01));
      expect(warn.isWarnBattery, isTrue);
      expect(warn.isLowBattery, isFalse);

      const low = EbikeConfig(fullRangeKm: 60, sinceChargeKm: 52);
      expect(low.remainingRangeKm, closeTo(8.0, 0.01));
      expect(low.isLowBattery, isTrue);

      const over = EbikeConfig(fullRangeKm: 60, sinceChargeKm: 75);
      expect(over.remainingRangeKm, 0.0);
      expect(over.batteryFraction, 0.0);

      final parsed = EbikeConfig.fromJson({
        'ebikeName': '九号 F90M',
        'fullRangeKm': 75,
        'sinceChargeKm': 15,
        'bluetoothAutoTrackEnabled': true,
        'bluetoothAutoStopEnabled': true,
        'bluetoothDeviceAddress': 'AA:BB:CC:DD:EE:FF',
        'bluetoothDeviceName': 'Ninebot-F90M',
        'voiceAnnounceEnabled': true,
        'voiceAnnounceIntervalKm': 2.0,
        'voiceLowBatteryAlertEnabled': true,
      });
      expect(parsed.hasBoundBluetooth, isTrue);
      expect(parsed.bluetoothAutoTrackEnabled, isTrue);
      expect(parsed.bluetoothDeviceName, 'Ninebot-F90M');
      expect(parsed.voiceAnnounceEnabled, isTrue);
      expect(parsed.voiceAnnounceIntervalKm, 2.0);
    });
  });

  group('E-Bike widgets render cleanly', () {
    testWidgets('EbikeGarageCard renders stats, BT/Voice pills, and triggers callbacks', (tester) async {
      bool started = false;
      bool reset = false;
      bool openedSettings = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EbikeGarageCard(
                config: const EbikeConfig(
                  ebikeName: '测试电驴',
                  fullRangeKm: 80,
                  sinceChargeKm: 20,
                  bluetoothAutoTrackEnabled: true,
                  bluetoothDeviceAddress: '11:22:33:44:55:66',
                  bluetoothDeviceName: 'Vimoto-V9S',
                  voiceAnnounceEnabled: true,
                  voiceAnnounceIntervalKm: 2.0,
                ),
                todayKm: 12.5,
                weekKm: 45.2,
                monthKm: 128.0,
                totalEbikeKm: 560.4,
                ebikeRideCount: 38,
                isCurrentlyTracking: false,
                onStartRide: () => started = true,
                onResetCharge: () => reset = true,
                onOpenSettings: () => openedSettings = true,
                onOpenKeepAliveCheck: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('测试电驴'), findsOneWidget);
      expect(find.text('预估剩余 60.0 km'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('蓝牙自动启停 · Vimoto-V9S'), findsOneWidget);
      expect(find.text('语音播报 · 每2km'), findsOneWidget);
      expect(find.text('一键开始电动车骑行'), findsOneWidget);

      await tester.tap(find.text('蓝牙自动启停 · Vimoto-V9S'));
      expect(openedSettings, isTrue);

      await tester.tap(find.text('充满重置'));
      expect(reset, isTrue);

      await tester.tap(find.text('一键开始电动车骑行'));
      expect(started, isTrue);
    });

    testWidgets('RidingTelemetryCard shows speed, mileage, auto-pause and GPS', (tester) async {
      final duration = ValueNotifier<String>('00:15:30');
      addTearDown(duration.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RidingTelemetryCard(
              telemetry: const RidingTelemetry(
                totalDistanceMeters: 5420,
                speedKmh: 24.6,
                avgSpeedKmh: 21.0,
                maxSpeedKmh: 31.2,
                accuracyMeters: 8.0,
                isAutoPaused: true,
                transportType: 'EBIKE',
                address: '朝阳区建国路',
              ),
              durationNotifier: duration,
              ebikeConfig: const EbikeConfig(fullRangeKm: 60, sinceChargeKm: 10),
              keepScreenOn: true,
              followCamera: true,
              onToggleKeepScreenOn: () {},
              onToggleFollowCamera: () {},
              onOpenFullScreenHud: () {},
            ),
          ),
        ),
      );

      expect(find.text('24.6'), findsOneWidget);
      expect(find.text('5.42'), findsOneWidget);
      expect(find.text('00:15:30'), findsOneWidget);
      expect(find.text('等红灯暂停'), findsOneWidget);
      expect(find.text('朝阳区建国路'), findsOneWidget);
    });
  });
}
