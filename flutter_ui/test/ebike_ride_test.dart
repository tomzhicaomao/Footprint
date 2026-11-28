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
        'bluetoothDeviceMode': 'BLE',
        'bleRssiThreshold': -72,
        'bleLostTimeoutSec': 90,
        'voiceAnnounceEnabled': true,
        'voiceAnnounceIntervalKm': 2.0,
        'voiceLowBatteryAlertEnabled': true,
      });
      expect(parsed.hasBoundBluetooth, isTrue);
      expect(parsed.isBleMode, isTrue);
      expect(parsed.bleRssiThreshold, -72);
      expect(parsed.bleLostTimeoutSec, 90);
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
                  bluetoothDeviceName: 'Ninebot-F90M',
                  bluetoothDeviceMode: 'BLE',
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
      expect(find.text('BLE 近场感应 · Ninebot-F90M'), findsOneWidget);
      expect(find.text('语音播报 · 每2km'), findsOneWidget);
      expect(find.text('一键开始电动车骑行'), findsOneWidget);

      await tester.tap(find.text('BLE 近场感应 · Ninebot-F90M'));
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

  group('Day/Week/Month/Year trip period analytics', () {
    final sampleEntries = [
      {
        'id': 1,
        'title': '早通勤',
        'happenedOn': '2026-11-28',
        'distanceKm': 6.5,
        'durationSec': 1200,
        'avgSpeedKmh': 19.5,
      },
      {
        'id': 2,
        'title': '晚回家',
        'happenedOn': '2026-11-28',
        'distanceKm': 7.5,
        'durationSec': 1500,
        'avgSpeedKmh': 18.0,
      },
      {
        'id': 3,
        'title': '周中买菜',
        'happenedOn': '2026-11-25',
        'distanceKm': 3.0,
        'durationSec': 600,
        'avgSpeedKmh': 18.0,
      },
      {
        'id': 4,
        'title': '月初出行',
        'happenedOn': '2026-11-02',
        'distanceKm': 12.0,
        'durationSec': 1800,
        'avgSpeedKmh': 24.0,
      },
      {
        'id': 5,
        'title': '上个月长途',
        'happenedOn': '2026-10-15',
        'distanceKm': 20.0,
        'durationSec': 3600,
        'avgSpeedKmh': 20.0,
      },
    ];

    test('aggregates day, week, month, and year summaries accurately', () {
      final anchor = DateTime(2026, 11, 28);

      final day = computeTripPeriodSummary(sampleEntries, TripStatsPeriod.day, anchor, now: anchor);
      expect(day.tripCount, 2);
      expect(day.totalDistanceKm, closeTo(14.0, 0.01));
      expect(day.totalDurationSec, 2700);
      expect(day.bars, isEmpty);

      final week = computeTripPeriodSummary(sampleEntries, TripStatsPeriod.week, anchor, now: anchor);
      expect(week.tripCount, 3);
      expect(week.totalDistanceKm, closeTo(17.0, 0.01));
      expect(week.bars.length, 7);

      final month = computeTripPeriodSummary(sampleEntries, TripStatsPeriod.month, anchor, now: anchor);
      expect(month.tripCount, 4);
      expect(month.totalDistanceKm, closeTo(29.0, 0.01));
      expect(month.bars.length, 30);

      final year = computeTripPeriodSummary(sampleEntries, TripStatsPeriod.year, anchor, now: anchor);
      expect(year.tripCount, 5);
      expect(year.totalDistanceKm, closeTo(49.0, 0.01));
      expect(year.bars.length, 12);
    });

    testWidgets('PeriodTripStatsCard switches periods and triggers callbacks', (tester) async {
      TripStatsPeriod? pickedPeriod;
      int? shifted;
      final anchor = DateTime(2026, 11, 28);
      final summary = computeTripPeriodSummary(sampleEntries, TripStatsPeriod.week, anchor, now: anchor);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodTripStatsCard(
              summary: summary,
              onPeriodChanged: (p) => pickedPeriod = p,
              onShiftAnchor: (d) => shifted = d,
              onResetToToday: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('17.0', findRichText: true), findsOneWidget);
      expect(find.textContaining('3', findRichText: true), findsWidgets);
      await tester.tap(find.text('月'));
      expect(pickedPeriod, TripStatsPeriod.month);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      expect(shifted, -1);
    });
  });
}
