import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'main.dart';
import 'ebike_ride_widgets.dart';

class FootprintDetailPage extends StatefulWidget {
  final dynamic entry;
  const FootprintDetailPage({super.key, this.entry});

  @override
  State<FootprintDetailPage> createState() => _FootprintDetailPageState();
}

class _FootprintDetailPageState extends State<FootprintDetailPage> {
  static const _dataChannel = MethodChannel('com.footprint/data');
  late Map<String, dynamic> entry;
  List<Map<String, dynamic>> trackPoints = [];
  List<double> speedSamplesKmh = [];
  MethodChannel? _mapChannel;
  bool _isExportingGpx = false;

  late String title;
  late String location;
  late String date;
  late Color accentColor;
  late String weather;
  late String detail;
  late double distance;
  late int energy;
  late List<String> photos;
  late String travelMode;
  late IconData travelIcon;
  late String rawTransport;
  int? sessionId;
  int durationSec = 0;
  double avgSpeedKmh = 0.0;
  double maxSpeedKmh = 0.0;
  double carbonSavedKg = 0.0;

  @override
  void initState() {
    super.initState();
    entry = widget.entry != null ? Map<String, dynamic>.from(widget.entry!) : {};

    title = entry['title'] ?? "未命名足迹";
    location = entry['location'] ?? "未知地点";

    // Format location if it looks like raw coordinates
    final coordRegex = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)');
    final match = coordRegex.firstMatch(location);
    if (match != null) {
      try {
        double lat = double.parse(match.group(1)!);
        double lng = double.parse(match.group(2)!);
        location = "${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}";
      } catch (_) {}
    }

    date = entry['happenedOn'] ?? "未知日期";
    weather = entry['weather'] ?? "-";
    detail = entry['detail'] ?? entry['notes'] ?? "没有记录详细内容。";
    distance = (entry['distanceKm'] as num?)?.toDouble() ?? 0.0;
    energy = (entry['energyLevel'] as num?)?.toInt() ?? 0;
    sessionId = (entry['sessionId'] as num?)?.toInt();
    durationSec = (entry['durationSec'] as num?)?.toInt() ?? 0;
    avgSpeedKmh = (entry['avgSpeedKmh'] as num?)?.toDouble() ?? 0.0;
    maxSpeedKmh = (entry['maxSpeedKmh'] as num?)?.toDouble() ?? 0.0;
    carbonSavedKg = (entry['carbonSavedKg'] as num?)?.toDouble() ??
        (entry['carbonSaved'] as num?)?.toDouble() ??
        0.0;

    // Parse photos if it's a list or comma-separated string
    final rawPhotos = entry['photos'];
    if (rawPhotos is List) {
      photos = rawPhotos.map((e) => e.toString()).toList();
    } else if (rawPhotos is String && rawPhotos.isNotEmpty) {
      photos = rawPhotos.split(',').map((s) => s.trim()).toList();
    } else {
      photos = [];
    }

    rawTransport = (entry['transportType'] ?? entry['transportMethod'] ?? "UNKNOWN").toString();
    switch (rawTransport) {
      case "EBIKE":
        travelMode = "电动车";
        travelIcon = Icons.electric_scooter;
        accentColor = const Color(0xFF00897B);
        break;
      case "WALK":
        travelMode = "步行";
        travelIcon = Icons.directions_walk;
        accentColor = const Color(0xFF1E88E5);
        break;
      case "BIKE":
        travelMode = "骑行";
        travelIcon = Icons.directions_bike;
        accentColor = const Color(0xFF43A047);
        break;
      case "CAR":
        travelMode = "自驾";
        travelIcon = Icons.directions_car;
        accentColor = const Color(0xFFFB8C00);
        break;
      case "TRAIN":
        travelMode = "铁路";
        travelIcon = Icons.train;
        accentColor = const Color(0xFF5E35B1);
        break;
      case "PLANE":
        travelMode = "航空";
        travelIcon = Icons.flight;
        accentColor = const Color(0xFF039BE5);
        break;
      default:
        travelMode = "未知";
        travelIcon = Icons.route;
        accentColor = Colors.blueGrey;
    }

    _loadTrackPoints();
  }

  Future<void> _loadTrackPoints() async {
    try {
      String? result;
      // 1. Prefer exact sessionId query so multiple rides on the same day never merge
      if (sessionId != null && sessionId! > 0) {
        result = await _dataChannel.invokeMethod<String>(
          'getTrackPointsBySession',
          {'sessionId': sessionId},
        );
      }

      // 2. Fallback to local-timezone day range for legacy entries
      if ((result == null || result == '[]') && entry['happenedOn'] != null) {
        final parsedDate = DateTime.parse(entry['happenedOn']);
        final startTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day)
            .millisecondsSinceEpoch;
        final endTime = startTime + 86400000 - 1;
        result = await _dataChannel.invokeMethod<String>(
          'getTrackPoints',
          {'startTime': startTime, 'endTime': endTime},
        );
      }

      if (result != null) {
        final List<dynamic> list = jsonDecode(result);
        final parsedPoints = list
            .map((p) => {
                  'lat': (p['latitude'] as num).toDouble(),
                  'lng': (p['longitude'] as num).toDouble(),
                  'speed': (p['speed'] as num?)?.toDouble() ?? 0.0,
                  'timestamp': (p['timestamp'] as num?)?.toInt() ?? 0,
                })
            .toList();

        // Extract speed samples (km/h) for chart and derive stats for legacy rides
        final speeds = <double>[];
        double derivedMax = 0.0;
        double sumSpd = 0.0;
        int movingSamples = 0;
        for (int i = 0; i < parsedPoints.length; i++) {
          final spdMs = (parsedPoints[i]['speed'] as double);
          final spdKmh = (spdMs * 3.6).clamp(0.0, 120.0);
          speeds.add(spdKmh);
          if (spdKmh > derivedMax) derivedMax = spdKmh;
          if (spdKmh > 1.0) {
            sumSpd += spdKmh;
            movingSamples++;
          }
        }

        int derivedDurationSec = durationSec;
        if (derivedDurationSec <= 0 && parsedPoints.length >= 2) {
          final firstTs = parsedPoints.first['timestamp'] as int;
          final lastTs = parsedPoints.last['timestamp'] as int;
          if (lastTs > firstTs) {
            derivedDurationSec = ((lastTs - firstTs) / 1000).round();
          }
        }

        double derivedAvg = avgSpeedKmh;
        if (derivedAvg <= 0 && distance > 0.02 && derivedDurationSec >= 5) {
          derivedAvg = distance / (derivedDurationSec / 3600.0);
        } else if (derivedAvg <= 0 && movingSamples > 0) {
          derivedAvg = sumSpd / movingSamples;
        }

        final finalMax = maxSpeedKmh > 0 ? maxSpeedKmh : derivedMax;

        if (mounted) {
          setState(() {
            trackPoints = parsedPoints;
            speedSamplesKmh = speeds;
            durationSec = derivedDurationSec;
            avgSpeedKmh = derivedAvg;
            maxSpeedKmh = finalMax;
          });
          _pushTrackToMap();
        }
      }
    } catch (e) {
      debugPrint("Load track points fail: $e");
    }
  }

  void _pushTrackToMap() {
    if (_mapChannel == null || trackPoints.isEmpty) return;
    _mapChannel?.invokeMethod('setTrackingPath', {
      'points': trackPoints,
      'showEndpoints': true,
      'fitBounds': true,
    });
  }

  Future<void> _exportGpx() async {
    if (_isExportingGpx) return;
    setState(() => _isExportingGpx = true);
    try {
      int startMs = 0;
      int endMs = 0;
      if (entry['happenedOn'] != null) {
        final d = DateTime.parse(entry['happenedOn']);
        startMs = DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
        endMs = startMs + 86400000 - 1;
      }
      await _dataChannel.invokeMethod('exportTrackGpx', {
        'title': title,
        'sessionId': sessionId ?? 0,
        'startTime': startMs,
        'endTime': endMs,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPX 轨迹文件已成功导出'),
            backgroundColor: Color(0xFF00A86B),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted && e.code != 'CANCELLED') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? '导出 GPX 失败'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingGpx = false);
    }
  }

  String _formatDurationText(int totalSec) {
    if (totalSec <= 0) return '-';
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    if (m > 0) {
      return '$m分${s.toString().padLeft(2, '0')}秒';
    }
    return '$s秒';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRideEntry = rawTransport == 'EBIKE' || rawTransport == 'BIKE' || durationSec > 0;
    final hasSpeedData = speedSamplesKmh.length >= 2 && speedSamplesKmh.any((v) => v > 0.8);

    return Scaffold(
      backgroundColor: isDark ? cs.surface : Colors.transparent,
      body: Stack(
        children: [
          if (!isDark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.68),
                      kAtelierCanvas,
                      const Color(0xFFEDE2D7),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: -110,
            right: -90,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.14),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.transparent,
                iconTheme: IconThemeData(color: cs.onSurface),
                actions: [
                  if (trackPoints.length >= 2)
                    IconButton(
                      tooltip: '导出 GPX 轨迹',
                      icon: _isExportingGpx
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      onPressed: _exportGpx,
                    ),
                  IconButton(
                    tooltip: '编辑足迹',
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final result = await navigator.push(
                        MaterialPageRoute(
                          builder: (context) => AddFootprintPage(initialEntry: widget.entry),
                        ),
                      );
                      if (result == true && mounted) {
                        navigator.pop(true);
                      }
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.alphaBlend(
                                Colors.white.withValues(alpha: 0.18),
                                accentColor.withValues(alpha: 0.72),
                              ),
                              accentColor.withValues(alpha: 0.24),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(36),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              isDark ? cs.surface : kAtelierCanvas,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(travelIcon, size: 14, color: accentColor),
                                  const SizedBox(width: 5),
                                  Text(
                                    travelMode,
                                    style: tt.labelMedium?.copyWith(
                                      color: accentColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: tt.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: cs.primary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    location,
                                    style: tt.bodyMedium?.copyWith(color: cs.primary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text("•", style: TextStyle(color: cs.outline)),
                                ),
                                Text(date, style: tt.bodyMedium?.copyWith(color: cs.outline)),
                              ],
                            ),
                            if (carbonSavedKg > 0.01) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C853).withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.eco, size: 15, color: Color(0xFF00A86B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '绿色出行减碳 ${carbonSavedKg.toStringAsFixed(2)} kg · 约省油费 ¥${(distance * 0.65).toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF00A86B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  // Primary Stats Row (Riding telemetry vs general)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: isRideEntry
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statDrop("总里程", "${distance.toStringAsFixed(2)} km", travelIcon, cs, tt),
                              _statDrop("骑行用时", _formatDurationText(durationSec), Icons.timer_outlined, cs, tt),
                              _statDrop(
                                "平均时速",
                                avgSpeedKmh > 0 ? "${avgSpeedKmh.toStringAsFixed(1)} km/h" : "-",
                                Icons.speed,
                                cs,
                                tt,
                              ),
                              _statDrop(
                                "最高时速",
                                maxSpeedKmh > 0 ? "${maxSpeedKmh.toStringAsFixed(1)} km/h" : "-",
                                Icons.flash_on,
                                cs,
                                tt,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statDrop("里程", "${distance.toStringAsFixed(2)} km", travelIcon, cs, tt),
                              _statDrop("出行", travelMode, travelIcon, cs, tt),
                              _statDrop("天气", weather, Icons.wb_sunny_outlined, cs, tt),
                              _statDrop("轨迹点", "${trackPoints.length}", Icons.route, cs, tt),
                            ],
                          ),
                  ),

                  // Detail Body
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      detail,
                      style: tt.bodyLarge?.copyWith(
                        height: 1.7,
                        letterSpacing: 0.3,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),

                  // Speed Curve Chart (when riding speed data exists)
                  if (hasSpeedData) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: RideSpeedChart(
                        speedsKmh: speedSamplesKmh,
                        avgSpeedKmh: avgSpeedKmh,
                        maxSpeedKmh: maxSpeedKmh,
                      ),
                    ),
                  ],

                  // Gallery
                  if (photos.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 12),
                      child: Text("瞬间", style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final photoPath = photos[index];
                          final file = File(photoPath);
                          return GestureDetector(
                            onTap: () => _showFullImage(context, photoPath),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: file.existsSync()
                                  ? Image.file(
                                      file,
                                      width: 150,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => _photoPlaceholder(cs),
                                    )
                                  : _photoPlaceholder(cs),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text("骑行轨迹地图", style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (trackPoints.length >= 2)
                          TextButton.icon(
                            onPressed: _pushTrackToMap,
                            icon: const Icon(Icons.fit_screen, size: 16),
                            label: const Text('全景居中', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AndroidView(
                          viewType: 'com.footprint/amap',
                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                          },
                          onPlatformViewCreated: (id) {
                            _mapChannel = MethodChannel('com.footprint/amap_$id');
                            _mapChannel?.invokeMethod('setTheme', isDark);
                            _mapChannel?.invokeMethod('setMapMode', 'STANDARD');
                            if (trackPoints.isNotEmpty) {
                              _pushTrackToMap();
                            } else if (entry['latitude'] != null && entry['longitude'] != null) {
                              _mapChannel?.invokeMethod('centerLocation', {
                                'latitude': (entry['latitude'] as num).toDouble(),
                                'longitude': (entry['longitude'] as num).toDouble(),
                                'zoom': 15.0,
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statDrop(String label, String value, IconData icon, ColorScheme cs, TextTheme tt) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: tt.labelSmall?.copyWith(color: cs.outline)),
        ],
      ),
    );
  }

  Widget _photoPlaceholder(ColorScheme cs) {
    return Container(
      width: 150,
      height: 200,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
    );
  }

  void _showFullImage(BuildContext context, String path) {
    final file = File(path);
    if (!file.existsSync()) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(file, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
