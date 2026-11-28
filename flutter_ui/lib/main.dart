import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:city_pickers/city_pickers.dart';
import 'footprint_detail_page.dart';
import 'goal_planner_page.dart';
import 'badge_hall_screen.dart';
import 'easter_egg.dart';
import 'ebike_ride_widgets.dart';
import 'package:flutter/foundation.dart';

const String kAppVersionName = '4.0.0';
const int kAppBuildNumber = 62;
const String kAppVersionLabel = 'Footprint v$kAppVersionName (Build $kAppBuildNumber)';

const Color kAtelierCanvas = Color(0xFFF4EFE7);
const Color kAtelierSurface = Color(0xFFFFFCF7);
const Color kAtelierPrimary = Color(0xFF163A59);
const Color kAtelierAccent = Color(0xFFD47A53);
const Color kAtelierMint = Color(0xFF5D948E);
const Color kAtelierInk = Color(0xFF1B2430);
const Color kAtelierMuted = Color(0xFF66727D);
const Color kAtelierOutline = Color(0xFFD8D0C3);
const Color kAtelierSurfaceSoft = Color(0xFFEAE2D6);

class _FootprintPalette {
  final Color seed;
  final Color canvas;
  final Color surface;
  final Color surfaceHigh;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color ink;
  final Color muted;
  final Color outline;
  final Color shadow;
  final double radius;
  final double cardElevation;

  const _FootprintPalette({
    required this.seed,
    required this.canvas,
    required this.surface,
    required this.surfaceHigh,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.ink,
    required this.muted,
    required this.outline,
    required this.shadow,
    required this.radius,
    required this.cardElevation,
  });
}

_FootprintPalette _paletteForStyle(String style, bool isDark) {
  switch (style) {
    case 'CYBERPUNK':
      return _FootprintPalette(
        seed: const Color(0xFF00B8C8),
        canvas: isDark ? const Color(0xFF091012) : const Color(0xFFEAF6F5),
        surface: isDark ? const Color(0xFF111A1D) : const Color(0xFFF8FFFE),
        surfaceHigh: isDark ? const Color(0xFF1A292D) : const Color(0xFFDDEDEC),
        primary: isDark ? const Color(0xFF54DCE8) : const Color(0xFF0B6D78),
        secondary: isDark ? const Color(0xFFFF8FB5) : const Color(0xFFB73562),
        tertiary: isDark ? const Color(0xFFA6E887) : const Color(0xFF4A7C35),
        ink: isDark ? const Color(0xFFE9FBFA) : const Color(0xFF102226),
        muted: isDark ? const Color(0xFF8BA3A8) : const Color(0xFF587075),
        outline: isDark ? const Color(0xFF31474D) : const Color(0xFFB7D1D0),
        shadow: isDark ? Colors.black : const Color(0xFF437A83),
        radius: 14,
        cardElevation: 0,
      );
    case 'FOREST':
      return _FootprintPalette(
        seed: const Color(0xFF426B45),
        canvas: isDark ? const Color(0xFF101811) : const Color(0xFFEFF4EC),
        surface: isDark ? const Color(0xFF172218) : const Color(0xFFFBFFF8),
        surfaceHigh: isDark ? const Color(0xFF243224) : const Color(0xFFDDE8D7),
        primary: isDark ? const Color(0xFFA8D5A2) : const Color(0xFF2F5E35),
        secondary: isDark ? const Color(0xFFD8BD80) : const Color(0xFF8A6B2F),
        tertiary: isDark ? const Color(0xFF95C8BA) : const Color(0xFF3D7469),
        ink: isDark ? const Color(0xFFF0F7EC) : const Color(0xFF1E2B1F),
        muted: isDark ? const Color(0xFF9AA995) : const Color(0xFF65745F),
        outline: isDark ? const Color(0xFF3A4937) : const Color(0xFFC9D7C3),
        shadow: isDark ? Colors.black : const Color(0xFF8AA27E),
        radius: 20,
        cardElevation: 0,
      );
    case 'SAHARA':
      return _FootprintPalette(
        seed: const Color(0xFFB8763E),
        canvas: isDark ? const Color(0xFF1A130E) : const Color(0xFFF5EDE0),
        surface: isDark ? const Color(0xFF241A13) : const Color(0xFFFFFBF4),
        surfaceHigh: isDark ? const Color(0xFF35261B) : const Color(0xFFEAD8BE),
        primary: isDark ? const Color(0xFFE3B77C) : const Color(0xFF8B5428),
        secondary: isDark ? const Color(0xFFE39573) : const Color(0xFFB35D45),
        tertiary: isDark ? const Color(0xFFDCCB92) : const Color(0xFF796C36),
        ink: isDark ? const Color(0xFFF9EFE3) : const Color(0xFF33251B),
        muted: isDark ? const Color(0xFFB19B83) : const Color(0xFF806E5A),
        outline: isDark ? const Color(0xFF4E3A2B) : const Color(0xFFD9C4A6),
        shadow: isDark ? Colors.black : const Color(0xFFB98D61),
        radius: 18,
        cardElevation: 0,
      );
    case 'EMBER':
      return _FootprintPalette(
        seed: const Color(0xFF9E2F2E),
        canvas: isDark ? const Color(0xFF1A0F10) : const Color(0xFFF6ECE8),
        surface: isDark ? const Color(0xFF241617) : const Color(0xFFFFFBF8),
        surfaceHigh: isDark ? const Color(0xFF372121) : const Color(0xFFF0DCD5),
        primary: isDark ? const Color(0xFFE98F86) : const Color(0xFF8F2C2C),
        secondary: isDark ? const Color(0xFFD6A15B) : const Color(0xFFA3632C),
        tertiary: isDark ? const Color(0xFFC7A3A0) : const Color(0xFF6F5552),
        ink: isDark ? const Color(0xFFFBEFED) : const Color(0xFF2E1D1D),
        muted: isDark ? const Color(0xFFB69A97) : const Color(0xFF7B6562),
        outline: isDark ? const Color(0xFF4D3131) : const Color(0xFFD8BFB8),
        shadow: isDark ? Colors.black : const Color(0xFFB27C73),
        radius: 16,
        cardElevation: 0,
      );
    case 'AUTO':
      return _paletteForStyle(isDark ? 'CYBERPUNK' : 'CLASSIC', isDark);
    case 'CLASSIC':
    default:
      return _FootprintPalette(
        seed: kAtelierPrimary,
        canvas: isDark ? const Color(0xFF111417) : kAtelierCanvas,
        surface: isDark ? const Color(0xFF1A1D22) : kAtelierSurface,
        surfaceHigh: isDark ? const Color(0xFF2A2E35) : kAtelierSurfaceSoft,
        primary: isDark ? const Color(0xFFA9C4E2) : kAtelierPrimary,
        secondary: isDark ? const Color(0xFFFFB794) : kAtelierAccent,
        tertiary: isDark ? const Color(0xFF9DD9D3) : kAtelierMint,
        ink: isDark ? const Color(0xFFF3EEE7) : kAtelierInk,
        muted: isDark ? const Color(0xFF8C939D) : kAtelierMuted,
        outline: isDark ? const Color(0xFF444B56) : kAtelierOutline,
        shadow: isDark ? Colors.black : const Color(0xFF8DA3B8),
        radius: 24,
        cardElevation: 0,
      );
  }
}

ThemeData buildFootprintTheme({
  required Brightness brightness,
  String style = 'CLASSIC',
}) {
  final isDark = brightness == Brightness.dark;
  final palette = _paletteForStyle(style, isDark);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: palette.seed,
    brightness: brightness,
  ).copyWith(
    primary: palette.primary,
    onPrimary: Colors.white,
    primaryContainer: Color.alphaBlend(palette.primary.withOpacity(isDark ? 0.26 : 0.14), palette.surface),
    onPrimaryContainer: isDark ? Colors.white : palette.primary,
    secondary: palette.secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color.alphaBlend(palette.secondary.withOpacity(isDark ? 0.24 : 0.16), palette.surface),
    onSecondaryContainer: isDark ? Colors.white : palette.secondary,
    tertiary: palette.tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: Color.alphaBlend(palette.tertiary.withOpacity(isDark ? 0.22 : 0.16), palette.surface),
    onTertiaryContainer: isDark ? Colors.white : palette.tertiary,
    surface: palette.surface,
    onSurface: palette.ink,
    surfaceContainerHighest: palette.surfaceHigh,
    outline: palette.muted,
    outlineVariant: palette.outline,
    error: const Color(0xFFC75050),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.canvas,
    canvasColor: palette.canvas,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: palette.cardElevation,
      shadowColor: palette.shadow.withOpacity(isDark ? 0.35 : 0.16),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(palette.radius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      labelStyle: TextStyle(color: colorScheme.outline),
      hintStyle: TextStyle(color: colorScheme.outline.withOpacity(0.8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular((palette.radius - 6).clamp(10, 18).toDouble()),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular((palette.radius - 6).clamp(10, 18).toDouble()),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular((palette.radius - 6).clamp(10, 18).toDouble()),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.surface,
      contentTextStyle: TextStyle(color: colorScheme.onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: colorScheme.outlineVariant),
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700),
      secondaryLabelStyle: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular((palette.radius - 4).clamp(10, 18).toDouble())),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular((palette.radius - 4).clamp(10, 18).toDouble())),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular((palette.radius - 2).clamp(12, 22).toDouble())),
    ),
    dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(color: colorScheme.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
  );
}

Widget buildAvatar(String avatarId, {double radius = 24, Color? bgColor, Color? fgColor}) {
  if (avatarId.contains('/') || avatarId.contains('\\')) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: FileImage(File(avatarId)),
      backgroundColor: bgColor,
    );
  }
  IconData iconData = Icons.face;
  if (avatarId == 'avatar_2') iconData = Icons.account_circle;
  if (avatarId == 'avatar_3') iconData = Icons.smart_toy;
  if (avatarId == 'avatar_4') iconData = Icons.fingerprint;
  return CircleAvatar(
    radius: radius,
    backgroundColor: bgColor,
    child: Icon(iconData, color: fgColor),
  );
}

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const MyApp());
}

// --- 顶级定义的录入页面 (1:1 复刻) ---
class AddFootprintPage extends StatefulWidget {
  final dynamic initialEntry;
  const AddFootprintPage({super.key, this.initialEntry});
  @override
  State<AddFootprintPage> createState() => _AddFootprintPageState();
}

class _AddFootprintPageState extends State<AddFootprintPage> {
  late TextEditingController _titleController;
  late TextEditingController _detailedLocationController;

  String _selectedRegion = "";
  late TextEditingController _detailController;
  late TextEditingController _distanceController;
  late TextEditingController _tagsController;
  late TextEditingController _tempController;
  late TextEditingController _altController;

  String selectedIcon = "ElectricScooter";
  double energyLevel = 6.0;
  String selectedWeather = "晴朗";
  String selectedTransport = "电动车";
  DateTime selectedDate = DateTime.now();
  List<File> photos = [];

  final List<String> availableIcons = [
    "LocationOn", "ElectricScooter", "DirectionsBike", "Restaurant", "LocalCafe", "Park",
    "Flight", "Train", "ShoppingBag", "CameraAlt",
  ];

  final List<String> weathers = ["晴朗", "多云", "阴天", "雨", "雪", "风", "雾"];
  final List<String> transports = ["电动车", "步行", "骑行", "自驾", "铁路", "航空", "未知"];

  @override
  void initState() {
    super.initState();
    final e = widget.initialEntry;
    _titleController = TextEditingController(text: e?['title'] ?? '');
    final locStr = e?['location'] as String? ?? '';
    final locParts = locStr.split(' ');
    if (locParts.length > 1) {
      _selectedRegion = locParts[0];
      _detailedLocationController = TextEditingController(text: locParts.sublist(1).join(' '));
    } else {
      _selectedRegion = "";
      _detailedLocationController = TextEditingController(text: locStr);
    }
    _detailController = TextEditingController(text: e?['detail'] ?? '');
    _distanceController = TextEditingController(text: e != null ? (e['distanceKm']?.toString() ?? '5.0') : "5.0");
    _tagsController = TextEditingController(text: (e?['tags'] as List<dynamic>?)?.join(', ') ?? '');
    _tempController = TextEditingController();
    _altController = TextEditingController();

    if (e != null) {
      if (e['icon'] != null && availableIcons.contains(e['icon'])) selectedIcon = e['icon'];
      if (e['energyLevel'] != null) energyLevel = (e['energyLevel'] as num).toDouble();
      if (e['weather'] != null) selectedWeather = weathers.contains(e['weather']) ? e['weather'] : "晴朗";
      final t = e['transportType'] ?? e['transportMethod'];
      if (t != null) {
        switch(t) {
          case "EBIKE": selectedTransport = "电动车"; break;
          case "WALK": selectedTransport = "步行"; break;
          case "BIKE": selectedTransport = "骑行"; break;
          case "CAR": selectedTransport = "自驾"; break;
          case "TRAIN": selectedTransport = "铁路"; break;
          case "PLANE": selectedTransport = "航空"; break;
          default: selectedTransport = transports.contains(t) ? t : "电动车";
        }
      }
      
      final dateStr = e['happenedOn'] as String?;
      if (dateStr != null) {
        try { selectedDate = DateTime.parse(dateStr); } catch (_) {}
      }

      final ps = (e['photos'] ?? e['photoPaths']) as List<dynamic>?;
      if (ps != null) {
        photos.addAll(ps.where((p) => p != null).map((p) => File(p.toString())));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailedLocationController.dispose();
    _distanceController.dispose();
    _tagsController.dispose();
    _tempController.dispose();
    _altController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // 1. 权限检查与申请
      if (Platform.isAndroid) {
        // 根据 Android 版本申请不同权限
        bool granted = false;
        // 如果是 Android 13 (API 33) 及以上，申请媒体图片权限
        if (await Permission.photos.isGranted || await Permission.photos.request().isGranted) {
          granted = true;
        } else if (await Permission.storage.isGranted || await Permission.storage.request().isGranted) {
          // 对于旧版本 Android，尝试申请存储权限
          granted = true;
        }
        
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("需要存储权限才能读取照片")));
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("正在打开系统选择器..."), duration: Duration(milliseconds: 500))
        );
      }

      // 2. 使用 FilePicker 的 Custom 模式，这比 FileType.image 在 Android 上更稳健
      // 且能规避 ImagePicker 常见的 missing_valid_image_uri 平台错误
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        allowMultiple: true,
      );
      
      if (result != null && result.paths.isNotEmpty) {
        final List<File> validFiles = [];
        for (String? path in result.paths) {
          if (path != null) {
            final file = File(path);
            if (await file.exists()) {
              validFiles.add(file);
            }
          }
        }
        
        if (mounted && validFiles.isNotEmpty) {
          setState(() => photos.addAll(validFiles));
        }
      }
    } catch (e) {
      debugPrint("Photo Picker Error: $e");
      String errorMsg = e.toString();
      // 如果依然报错，可能是环境极端问题，提供更详细的提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("选择照片失败: $errorMsg"),
            action: SnackBarAction(label: "重试", onPressed: _pickImage),
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
        .copyWith(statusBarColor: Theme.of(context).scaffoldBackgroundColor);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: overlayStyle,
          title: Text(widget.initialEntry == null ? '记录新的足迹' : '编辑足迹记录', style: const TextStyle(fontWeight: FontWeight.w900)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark
                          ? Color.alphaBlend(cs.primary.withOpacity(0.06), Theme.of(context).scaffoldBackgroundColor)
                          : Color.alphaBlend(cs.primary.withOpacity(0.04), Colors.white),
                      Theme.of(context).scaffoldBackgroundColor,
                      Color.alphaBlend(cs.secondary.withOpacity(isDark ? 0.05 : 0.08), Theme.of(context).scaffoldBackgroundColor),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -80,
              right: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDCEAF3).withOpacity(0.54),
                ),
              ),
            ),
            ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10355B).withOpacity(0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF163A59), Color(0xFF3C6B8F)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.edit_location_alt_outlined, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.initialEntry == null ? '把这次抵达认真收藏' : '把这段记忆重新润色',
                        style: tt.titleMedium?.copyWith(
                          color: kAtelierInk,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '地点、路线、里程和照片会一起沉淀成这次出行的完整记录。',
                        style: tt.bodySmall?.copyWith(
                          color: kAtelierMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '标题',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                locale: const Locale('zh'),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '记录日期',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // --- 省市区选择框 ---
          InkWell(
            onTap: () async {
              FocusScope.of(context).unfocus();
              Result? result = await CityPickers.showCityPicker(
                 context: context,
                 itemExtent: 45,
                     theme: ThemeData(
                         brightness: Theme.of(context).brightness,
                         primaryColor: cs.primary,
                         colorScheme: Theme.of(context).brightness == Brightness.dark 
                            ? ColorScheme.dark(primary: cs.primary, onPrimary: Colors.white, surface: const Color(0xFF121212))
                            : ColorScheme.light(primary: cs.primary, onPrimary: Colors.white),
                         textButtonTheme: TextButtonThemeData(
                           style: TextButton.styleFrom(
                             foregroundColor: cs.primary, 
                             textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                           )
                         ),
                      ),
              );
              if (result != null) {
                final region = "${result.provinceName ?? ''} ${result.cityName ?? ''} ${result.areaName ?? ''}".trim();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("已确认地点: $region"),
                      duration: const Duration(seconds: 2),
                    )
                  );
                }
                setState(() {
                   _selectedRegion = region;
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '地点/行政区划',
                prefixIcon: const Icon(Icons.map_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _selectedRegion.isEmpty ? "点击选择省/市/区" : _selectedRegion,
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedRegion.isEmpty ? cs.outline : cs.onSurface,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // --- 详细目的地输入框 ---
          TextField(
             controller: _detailedLocationController,
             decoration: InputDecoration(
               labelText: '详细地址 (如景点、餐馆、小区)',
               prefixIcon: const Icon(Icons.place_outlined),
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
             ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: '标签 (用逗号分隔)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          Text("选择图标", style: tt.labelSmall?.copyWith(color: cs.outline)),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: availableIcons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                bool isSelected = selectedIcon == availableIcons[index];
                return GestureDetector(
                  onTap: () => setState(() => selectedIcon = availableIcons[index]),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: isSelected ? cs.primary : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    child: Icon(_getIconData(availableIcons[index]), color: isSelected ? Colors.white : cs.onSurfaceVariant, size: 20),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: selectedTransport,
                decoration: InputDecoration(labelText: '出行方式', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: transports.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => selectedTransport = v!),
              )),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<String>(
                value: selectedWeather,
                decoration: InputDecoration(labelText: '天气', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: weathers.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                onChanged: (v) => setState(() => selectedWeather = v!),
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextField(
                controller: _distanceController,
                decoration: InputDecoration(labelText: '里程(km)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                keyboardType: TextInputType.number,
              )),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _tempController,
                decoration: InputDecoration(labelText: '气温(℃)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                keyboardType: TextInputType.number,
              )),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _altController,
                decoration: InputDecoration(labelText: '海拔(m)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                keyboardType: TextInputType.number,
              )),
            ],
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _detailController,
            maxLines: 4,
            decoration: InputDecoration(labelText: '故事', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          Text("照片记录", style: tt.labelMedium),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add_a_photo, size: 32),
                  ),
                ),
                const SizedBox(width: 12),
                ...photos.map((f) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12), 
                        child: Image.file(
                          f, 
                          width: 80, height: 80, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint("Error loading image ${f.path}: $error");
                            return Container(
                              width: 80, height: 80, color: Colors.red,
                              child: const Icon(Icons.error, color: Colors.white),
                            );
                          }
                        )
                      ),
                      Positioned(
                        right: 0, top: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => photos.remove(f)),
                          child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), padding: const EdgeInsets.all(4), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                        ),
                      )
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () async {
              final String mappedMood =
                  (widget.initialEntry?['mood'] as String?) ?? "RELAXED";

              // Map Transport
              String mappedTransport = "UNKNOWN";
              switch(selectedTransport) {
                case "电动车": mappedTransport = "EBIKE"; break;
                case "步行": mappedTransport = "WALK"; break;
                case "骑行": mappedTransport = "BIKE"; break;
                case "自驾": mappedTransport = "CAR"; break;
                case "铁路": mappedTransport = "TRAIN"; break;
                case "航空": mappedTransport = "PLANE"; break;
              }

              final entryData = {
                "id": widget.initialEntry?['id'] ?? 0,
                "title": _titleController.text,
                "location": "${_selectedRegion} ${_detailedLocationController.text}".trim(),
                "detail": _detailController.text,
                "mood": mappedMood,
                "tags": _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                "distanceKm": double.tryParse(_distanceController.text) ?? 5.0,
                "photos": photos.map((e) => e.path).toList(),
                "photoPaths": photos.map((e) => e.path).toList(), // For compatibility
                "energyLevel": energyLevel.toInt(),
                "happenedOn": "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                "icon": selectedIcon,
                "weather": selectedWeather,
                "temperature": double.tryParse(_tempController.text),
                "altitude": double.tryParse(_altController.text),
                "transportType": mappedTransport,
                "latitude": widget.initialEntry?['latitude'],
                "longitude": widget.initialEntry?['longitude'],
                "sessionId": widget.initialEntry?['sessionId'],
                "durationSec": widget.initialEntry?['durationSec'] ?? 0,
                "avgSpeedKmh": widget.initialEntry?['avgSpeedKmh'] ?? 0.0,
                "maxSpeedKmh": widget.initialEntry?['maxSpeedKmh'] ?? 0.0,
                "carbonSavedKg": widget.initialEntry?['carbonSavedKg'] ?? 0.0,
              };

              try {
                await const MethodChannel('com.footprint/data').invokeMethod('saveFootprint', jsonEncode(entryData));
                if (mounted) Navigator.pop(context, true);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("保存失败: $e")));
              }
            },
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text(widget.initialEntry == null ? "记录足迹" : "保存修改", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case "ElectricScooter":
        return Icons.electric_scooter;
      case "Restaurant":
        return Icons.restaurant;
      case "LocalCafe":
        return Icons.local_cafe;
      case "Park":
        return Icons.park;
      case "Flight":
        return Icons.flight;
      case "Train":
        return Icons.train;
      case "DirectionsBike":
        return Icons.directions_bike;
      case "ShoppingBag":
        return Icons.shopping_bag;
      case "CameraAlt":
        return Icons.camera_alt;
      default:
        return Icons.location_on;
    }
  }
}

class AddGoalPage extends StatefulWidget {
  final dynamic initialGoal;
  const AddGoalPage({super.key, this.initialGoal});

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  late TextEditingController _titleController;
  late TextEditingController _detailedLocationController;
  String _selectedRegion = "";
  late TextEditingController _notesController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final g = widget.initialGoal;
    _titleController = TextEditingController(text: g?['title'] ?? '');
    final locStr = g?['targetLocation'] as String? ?? '';
    final locParts = locStr.split(' ');
    if (locParts.length > 1) {
      _selectedRegion = locParts[0];
      _detailedLocationController = TextEditingController(text: locParts.sublist(1).join(' '));
    } else {
      _selectedRegion = "";
      _detailedLocationController = TextEditingController(text: locStr);
    }
    _notesController = TextEditingController(text: g?['notes'] ?? '');
    if (g?['targetDate'] != null) {
      try { _selectedDate = DateTime.parse(g['targetDate']); } catch(_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailedLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
        .copyWith(statusBarColor: Theme.of(context).scaffoldBackgroundColor);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: overlayStyle,
          title: Text(widget.initialGoal == null ? '新增旅行目标' : '编辑旅行目标', style: const TextStyle(fontWeight: FontWeight.w900)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark
                          ? Color.alphaBlend(cs.primary.withOpacity(0.06), Theme.of(context).scaffoldBackgroundColor)
                          : Color.alphaBlend(cs.primary.withOpacity(0.04), Colors.white),
                      Theme.of(context).scaffoldBackgroundColor,
                      Color.alphaBlend(cs.secondary.withOpacity(isDark ? 0.05 : 0.08), Theme.of(context).scaffoldBackgroundColor),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -70,
              left: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5D6BF).withOpacity(0.4),
                ),
              ),
            ),
            ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10355B).withOpacity(0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD47A53), Color(0xFFE7A27E)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.flag_outlined, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.initialGoal == null ? '给下一次远行一个方向' : '继续打磨这段计划',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: kAtelierInk,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '把想去的地方、时间和注记写清楚，之后回看会更像一份真正的旅程提案。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: kAtelierMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '目标名称',
              hintText: '例如：川西环线摄影',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          // --- 省市区选择框 ---
          InkWell(
            onTap: () async {
              FocusScope.of(context).unfocus();
              Result? result = await CityPickers.showCityPicker(
                 context: context,
                 itemExtent: 45,
                     theme: ThemeData(
                         brightness: Theme.of(context).brightness,
                         primaryColor: cs.primary,
                         colorScheme: Theme.of(context).brightness == Brightness.dark 
                            ? ColorScheme.dark(primary: cs.primary, onPrimary: Colors.white, surface: const Color(0xFF121212))
                            : ColorScheme.light(primary: cs.primary, onPrimary: Colors.white),
                         textButtonTheme: TextButtonThemeData(
                           style: TextButton.styleFrom(
                             foregroundColor: cs.primary, 
                             textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                           )
                         ),
                      ),
              );
              if (result != null) {
                final region = "${result.provinceName ?? ''} ${result.cityName ?? ''} ${result.areaName ?? ''}".trim();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("已确认地点: $region"),
                      duration: const Duration(seconds: 2),
                    )
                  );
                }
                setState(() {
                   _selectedRegion = region;
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '地点/行政区划',
                prefixIcon: const Icon(Icons.map_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _selectedRegion.isEmpty ? "点击选择省/市/区" : _selectedRegion,
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedRegion.isEmpty ? cs.outline : cs.onSurface,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // --- 详细目的地输入框 ---
          TextField(
             controller: _detailedLocationController,
             decoration: InputDecoration(
               labelText: '详细目的地 (如景区或具体位置)',
               prefixIcon: const Icon(Icons.place_outlined),
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
             ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2030),
                locale: const Locale('zh'),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '预期日期',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                "${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '计划备注',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () async {
              final goalData = {
                "id": widget.initialGoal?['id'] ?? 0,
                "title": _titleController.text,
                "targetLocation": "${_selectedRegion} ${_detailedLocationController.text}".trim(),
                "targetDate": "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                "notes": _notesController.text,
                "isCompleted": widget.initialGoal?['isCompleted'] ?? false,
                "progress": widget.initialGoal?['progress'] ?? 0,
                "icon": widget.initialGoal?['icon'] ?? "Flag",
              };

              try {
                await const MethodChannel('com.footprint/data').invokeMethod('saveGoal', jsonEncode(goalData));
                if (mounted) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(widget.initialGoal == null ? "目标已添加" : "修改已保存")),
                  );
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("保存失败: $e")));
              }
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(widget.initialGoal == null ? "保存目标" : "保存修改", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String themeModeStr = "SYSTEM";
  String nickname = "探索者";
  String avatarId = "avatar_1";
  String themeStyleStr = "CLASSIC";
  bool hapticEnabled = true;
  bool isMaintValid = false;
  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    const channel = MethodChannel('com.footprint/data');
    try {
      final jsonStr = await channel.invokeMethod<String>('getSettings');
      if (jsonStr != null) {
        final data = jsonDecode(jsonStr);
        setState(() {
          nickname = data['nickname'] ?? "探索者";
          avatarId = data['avatarId'] ?? "avatar_1";
          themeModeStr = data['themeMode'] ?? "SYSTEM";
          themeStyleStr = data['themeStyle'] ?? "CLASSIC";
          hapticEnabled = data['hapticEnabled'] ?? true;
          isMaintValid = data['isMaintValid'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Settings Error: $e");
    }
  }

  ThemeMode _getThemeMode() {
    switch (themeModeStr) {
      case "LIGHT":
        return ThemeMode.light;
      case "DARK":
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _getThemeMode(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      theme: buildFootprintTheme(
        brightness: Brightness.light,
        style: themeStyleStr,
      ),
      darkTheme: buildFootprintTheme(
        brightness: Brightness.dark,
        style: themeStyleStr,
      ),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlayStyle = (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: MainContainer(
        nickname: nickname,
        avatarId: avatarId,
        themeMode: themeModeStr,
        themeStyle: themeStyleStr,
        hapticEnabled: hapticEnabled,
        isMaintValid: isMaintValid,
        onSettingsChanged: _loadAllSettings,
      ),
    );
  }
}

class MainContainer extends StatefulWidget {
  final String nickname;
  final String avatarId;
  final String themeMode;
  final String themeStyle;
  final bool hapticEnabled;
  final bool isMaintValid;
  final VoidCallback onSettingsChanged;
  const MainContainer({
    super.key,
    required this.nickname,
    required this.avatarId,
    required this.themeMode,
    required this.themeStyle,
    required this.hapticEnabled,
    required this.isMaintValid,
    required this.onSettingsChanged,
  });
  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer>
    with TickerProviderStateMixin {
  static const List<String> _tabLabels = <String>[
    '行程',
    '地图',
  ];
  static const List<IconData> _selectedTabIcons = <IconData>[
    Icons.route,
    Icons.map,
  ];
  static const List<IconData> _unselectedTabIcons = <IconData>[
    Icons.route_outlined,
    Icons.map_outlined,
  ];
  int _selectedIndex = 0;
  late AnimationController _navController;
  late Animation<double> _elasticAnimation;
  bool _isHiding = false;

  // GlobalKey 用于通知地图页面和行程页面 tab 切换事件
  final GlobalKey<_ExploreMapScreenState> _mapKey = GlobalKey<_ExploreMapScreenState>();
  final GlobalKey<_DashboardScreenState> _dashboardKey = GlobalKey<_DashboardScreenState>();

  // Tab 切换弹性动画
  late AnimationController _tabBounceController;
  late Animation<double> _tabBounceAnimation;

  @override
  void initState() {
    super.initState();
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _elasticAnimation = CurvedAnimation(
      parent: _navController,
      curve: const ElasticOutCurve(0.8),
      reverseCurve: Curves.easeInCubic,
    );
    _navController.value = 1.0;

    _tabBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _tabBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.12).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95).chain(CurveTween(curve: Curves.easeInOut)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 25),
    ]).animate(_tabBounceController);
  }

  void _handleScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      if (delta == null || delta == 0) return;
      if (delta > 8.0 && !_isHiding && _navController.status != AnimationStatus.reverse) {
        _isHiding = true;
        _navController.reverse();
      } else if (delta < -8.0 && _isHiding && _navController.status != AnimationStatus.forward) {
        _isHiding = false;
        _navController.forward();
      }
    }
  }

  void _onTabTap(int index) {
    if (_selectedIndex == index) return;
    final prevIndex = _selectedIndex;
    setState(() => _selectedIndex = index);
    _tabBounceController.forward(from: 0.0);
    if (widget.hapticEnabled) HapticFeedback.lightImpact();

    // 离开地图页时通知停止后台定位（除非正在追踪）
    if (prevIndex == 1 && index != 1) {
      _mapKey.currentState?.onTabDeselected();
    }
    // 进入地图页时通知恢复
    if (index == 1 && prevIndex != 1) {
      _mapKey.currentState?.onTabActivated();
    }
    // 返回行程页时自动刷新骑行统计与电量续航
    if (index == 0 && prevIndex != 0) {
      _dashboardKey.currentState?.refreshFromExternal();
    }
  }

  void _startRideFromDashboard() {
    _onTabTap(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapKey.currentState?.startRideFromExternal();
    });
  }

  @override
  void dispose() {
    _navController.dispose();
    _tabBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        key: _dashboardKey,
        nickname: widget.nickname,
        avatarId: widget.avatarId,
        themeMode: widget.themeMode,
        themeStyle: widget.themeStyle,
        hapticEnabled: widget.hapticEnabled,
        isMaintValid: widget.isMaintValid,
        onSettingsChanged: widget.onSettingsChanged,
        onStartRide: _startRideFromDashboard,
      ),
      ExploreMapScreen(
        key: _mapKey,
        themeMode: widget.themeMode,
        onRideFinished: () => _dashboardKey.currentState?.refreshFromExternal(),
      ),
    ];

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? Color.alphaBlend(cs.primary.withOpacity(0.06), Theme.of(context).scaffoldBackgroundColor)
                        : Color.alphaBlend(cs.primary.withOpacity(0.04), Colors.white),
                    Theme.of(context).scaffoldBackgroundColor,
                    Color.alphaBlend(cs.secondary.withOpacity(isDark ? 0.05 : 0.08), Theme.of(context).scaffoldBackgroundColor),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -110,
            left: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? cs.secondaryContainer : const Color(0xFFF8D8BE))
                    .withOpacity(isDark ? 0.12 : 0.42),
              ),
            ),
          ),
          Positioned(
            top: 110,
            right: -90,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? cs.primaryContainer : const Color(0xFFDCEBF3))
                    .withOpacity(isDark ? 0.16 : 0.58),
              ),
            ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) { _handleScroll(notification); return false; },
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: Listenable.merge([_elasticAnimation, _tabBounceAnimation]),
        builder: (context, child) {
          final rawT = _elasticAnimation.value;
          final clampedT = rawT.clamp(0.0, 1.0);
          final fullWidth = MediaQuery.of(context).size.width - 64;
          const dropSize = 64.0;
          final currentWidth = math.max(dropSize, dropSize + (fullWidth - dropSize) * rawT);
          final overallScale = clampedT < 0.15 ? (clampedT / 0.15) : 1.0;
          final cs = Theme.of(context).colorScheme;

          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Transform.scale(
                scale: overallScale,
                child: Container(
                  width: currentWidth, height: dropSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.surface.withValues(alpha: 0.98),
                        Color.alphaBlend(
                          (isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHighest)
                              .withOpacity(0.46),
                          cs.surface,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(dropSize / 2),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : const Color(0xFF8DA3B8))
                            .withValues(alpha: (isDark ? 0.28 : 0.12) * clampedT),
                        blurRadius: 26 * clampedT,
                        offset: Offset(0, 14 * clampedT),
                      ),
                      BoxShadow(
                        color: (isDark ? Colors.white : Colors.white)
                            .withValues(alpha: (isDark ? 0.08 : 0.65) * clampedT),
                        blurRadius: 16 * clampedT,
                        offset: Offset(0, -4 * clampedT),
                      ),
                    ],
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.65 * clampedT)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(dropSize / 2),
                    child: OverflowBox(
                      minWidth: fullWidth, maxWidth: fullWidth, minHeight: dropSize, maxHeight: dropSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: List.generate(2, (index) {
                          final double step = fullWidth / 2;
                          final double currentX = (index - 0.5) * step * clampedT;
                          final bool isSelected = _selectedIndex == index;
                          // 当前选中 tab 的弹性缩放
                          final double iconScale = isSelected ? _tabBounceAnimation.value : 1.0;

                          return Positioned(
                            left: (fullWidth / 2) + currentX - 44,
                            child: Opacity(
                              opacity: (clampedT * 5 - 4).clamp(0.0, 1.0),
                              child: GestureDetector(
                                onTap: () => _onTabTap(index),
                                child: Transform.scale(
                                  scale: iconScale,
                                  child: Container(
                                    width: 88,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      gradient: isSelected
                                          ? LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                cs.primary,
                                                Color.alphaBlend(
                                                  cs.secondary
                                                      .withOpacity(0.3),
                                                  cs.primary,
                                                ),
                                              ],
                                            )
                                          : null,
                                      color: isSelected ? null : Colors.transparent,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isSelected ? _selectedTabIcons[index] : _unselectedTabIcons[index],
                                          color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                                          size: 22,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _tabLabels[index],
                                          style: TextStyle(
                                            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- 状态页 ---
class DashboardScreen extends StatefulWidget {
  final String nickname;
  final String avatarId;
  final String themeMode;
  final String themeStyle;
  final bool hapticEnabled;
  final bool isMaintValid;
  final VoidCallback onSettingsChanged;
  final VoidCallback? onStartRide;

  const DashboardScreen({
    super.key,
    required this.nickname,
    required this.avatarId,
    required this.themeMode,
    required this.themeStyle,
    required this.hapticEnabled,
    required this.isMaintValid,
    required this.onSettingsChanged,
    this.onStartRide,
  });
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _TimelineMonth {
  final int month;
  final List<dynamic> entries;

  const _TimelineMonth({
    required this.month,
    required this.entries,
  });
}

class _DashboardScreenState extends State<DashboardScreen> {
  TripStatsPeriod _period = TripStatsPeriod.week;
  DateTime _anchorDate = DateTime.now();
  bool _showSearchBar = false;
  List<dynamic> allTimeEntries = [];
  List<dynamic> _searchResults = const [];
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // E-Bike riding garage state
  EbikeConfig _ebikeConfig = const EbikeConfig();
  double _todayRideKm = 0.0;
  double _weekRideKm = 0.0;
  double _monthRideKm = 0.0;
  double _totalEbikeKm = 0.0;
  int _ebikeRideCount = 0;
  bool _isCurrentlyTracking = false;

  void refreshFromExternal() {
    if (mounted) _loadEntries();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 9) return "早安";
    if (hour >= 9 && hour < 12) return "上午好";
    if (hour >= 12 && hour < 14) return "午安";
    if (hour >= 14 && hour < 18) return "下午好";
    if (hour >= 18 && hour < 23) return "晚安";
    return "夜深了";
  }

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _buildSearchResults(List<dynamic> entries, String query) {
    if (query.isEmpty) return const [];
    return entries.where((e) {
      final loc = (e['location'] as String? ?? '').toLowerCase();
      final title = (e['title'] as String? ?? '').toLowerCase();
      final detail = (e['detail'] as String? ?? '').toLowerCase();
      final tags = ((e['tags'] as List?)?.join(' ') ?? '').toLowerCase();
      return loc.contains(query) ||
          title.contains(query) ||
          detail.contains(query) ||
          tags.contains(query);
    }).toList(growable: false);
  }

  Future<void> _loadEntries() async {
    const channel = MethodChannel('com.footprint/data');
    try {
      final jsonStr = await channel.invokeMethod<String>('getAllEntries');

      EbikeConfig loadedEbikeConfig = _ebikeConfig;
      bool trackingNow = false;
      try {
        final ebikeJson = await channel.invokeMethod<String>('getEbikeConfig');
        if (ebikeJson != null) {
          loadedEbikeConfig = EbikeConfig.fromJson(jsonDecode(ebikeJson));
        }
        final trackStateJson = await channel.invokeMethod<String>('getTrackingState');
        if (trackStateJson != null) {
          trackingNow = jsonDecode(trackStateJson)['isTracking'] == true;
        }
      } catch (_) {}

      if (jsonStr != null) {
        if (!mounted) return;
        final List<dynamic> entries = jsonDecode(jsonStr);
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        final weekStart = todayOnly.subtract(Duration(days: todayOnly.weekday - 1));
        final monthStart = DateTime(today.year, today.month, 1);

        double todayKm = 0.0;
        double weekKm = 0.0;
        double monthKm = 0.0;
        double totalEbike = 0.0;
        int ebikeCount = 0;

        for (final e in entries) {
          final t = (e['transportType'] ?? '').toString().toUpperCase();
          final tags = (e['tags'] as List?)?.map((x) => x.toString()).toList() ?? const <String>[];
          final isRide = t == 'EBIKE' || t == 'BIKE' || tags.contains('电动车') || tags.contains('骑行轨迹');
          final dKm = (e['distanceKm'] as num?)?.toDouble() ?? 0.0;
          if (isRide) {
            totalEbike += dKm;
            ebikeCount++;
          }
          final dateStr = e['happenedOn'] as String?;
          if (isRide && dateStr != null && dateStr.length >= 10) {
            try {
              final dt = DateTime.parse(dateStr.substring(0, 10));
              if (!dt.isBefore(todayOnly)) todayKm += dKm;
              if (!dt.isBefore(weekStart)) weekKm += dKm;
              if (!dt.isBefore(monthStart)) monthKm += dKm;
            } catch (_) {}
          }
        }

        final searchResults = _buildSearchResults(entries, _searchQuery);

        setState(() {
          allTimeEntries = entries;
          _searchResults = searchResults;
          _ebikeConfig = loadedEbikeConfig;
          _todayRideKm = todayKm;
          _weekRideKm = weekKm;
          _monthRideKm = monthKm;
          _totalEbikeKm = totalEbike;
          _ebikeRideCount = ebikeCount;
          _isCurrentlyTracking = trackingNow;
        });
      }
    } catch (e) {
      debugPrint("Error loading entries: $e");
    }
  }

  Future<void> _handleResetCharge() async {
    const channel = MethodChannel('com.footprint/data');
    try {
      await channel.invokeMethod('resetEbikeCharge');
      if (widget.hapticEnabled) HapticFeedback.mediumImpact();
      await _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已重置充电里程 · 预估满电续航 ${_ebikeConfig.fullRangeKm.round()} km'),
            backgroundColor: const Color(0xFF00A86B),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _handleOpenEbikeSettings() async {
    final updated = await showEbikeConfigSheet(context, _ebikeConfig);
    if (updated == null) return;
    const channel = MethodChannel('com.footprint/data');
    try {
      await channel.invokeMethod('saveEbikeConfig', {
        'ebikeName': updated.ebikeName,
        'fullRangeKm': updated.fullRangeKm,
        'sinceChargeKm': updated.sinceChargeKm,
        'autoPauseEnabled': updated.autoPauseEnabled,
        'keepScreenOn': updated.keepScreenOn,
        'bluetoothAutoTrackEnabled': updated.bluetoothAutoTrackEnabled,
        'bluetoothAutoStopEnabled': updated.bluetoothAutoStopEnabled,
        'bluetoothDeviceAddress': updated.bluetoothDeviceAddress,
        'bluetoothDeviceName': updated.bluetoothDeviceName,
        'bluetoothDeviceMode': updated.bluetoothDeviceMode,
        'bleRssiThreshold': updated.bleRssiThreshold,
        'bleLostTimeoutSec': updated.bleLostTimeoutSec,
        'voiceAnnounceEnabled': updated.voiceAnnounceEnabled,
        'voiceAnnounceIntervalKm': updated.voiceAnnounceIntervalKm,
        'voiceLowBatteryAlertEnabled': updated.voiceLowBatteryAlertEnabled,
      });
      await _loadEntries();
    } catch (_) {}
  }

  Future<void> _showDetail(dynamic entryData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FootprintDetailPage(entry: entryData)),
    );
    if (result == true) {
      _loadEntries();
    }
  }

  Future<bool> _confirmAndDeleteEntry(dynamic entry) async {
    final id = (entry['id'] as num?)?.toInt();
    if (id == null) return false;
    final title = (entry['title'] as String?) ?? '这条行程';
    final distKm = (entry['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除行程记录'),
        content: Text('确定要删除「$title」(${distKm.toStringAsFixed(1)} km) 吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    const channel = MethodChannel('com.footprint/data');
    try {
      await channel.invokeMethod('deleteFootprint', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除行程记录')),
        );
      }
      await _loadEntries();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = computeTripPeriodSummary(allTimeEntries, _period, _anchorDate);
    final topPadding = MediaQuery.of(context).padding.top + (_showSearchBar ? 132.0 : 76.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? Color.alphaBlend(cs.primary.withValues(alpha: 0.06), Theme.of(context).scaffoldBackgroundColor)
                        : Color.alphaBlend(cs.primary.withValues(alpha: 0.04), Colors.white),
                    Theme.of(context).scaffoldBackgroundColor,
                    Color.alphaBlend(cs.secondary.withValues(alpha: isDark ? 0.05 : 0.08), Theme.of(context).scaffoldBackgroundColor),
                  ],
                ),
              ),
            ),
          ),
          ListView(
            padding: EdgeInsets.only(
              top: topPadding,
              bottom: 130,
              left: 16,
              right: 16,
            ),
            children: [
              EbikeGarageCard(
                config: _ebikeConfig,
                todayKm: _todayRideKm,
                weekKm: _weekRideKm,
                monthKm: _monthRideKm,
                totalEbikeKm: _totalEbikeKm,
                ebikeRideCount: _ebikeRideCount,
                isCurrentlyTracking: _isCurrentlyTracking,
                onStartRide: () => widget.onStartRide?.call(),
                onResetCharge: _handleResetCharge,
                onOpenSettings: _handleOpenEbikeSettings,
                onOpenKeepAliveCheck: () => showBackgroundKeepAliveDialog(context),
              ),
              const SizedBox(height: 16),
              PeriodTripStatsCard(
                summary: summary,
                onPeriodChanged: (p) => setState(() {
                  _period = p;
                  _anchorDate = DateTime.now();
                }),
                onShiftAnchor: (delta) => setState(() {
                  _anchorDate = shiftTripAnchor(_anchorDate, _period, delta);
                }),
                onResetToToday: () => setState(() {
                  _anchorDate = DateTime.now();
                }),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route, color: cs.primary, size: 17),
                      const SizedBox(width: 6),
                      Text(
                        '行程明细 (${summary.entries.length})',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      if (widget.hapticEnabled) HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddFootprintPage()),
                      ).then((_) => widget.onSettingsChanged());
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('补录', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._buildPeriodEntryList(cs, summary.entries),
            ],
          ),
          if (_searchQuery.isNotEmpty)
            Positioned.fill(
              top: MediaQuery.of(context).padding.top + 124,
              child: Container(
                color: cs.surface,
                child: ListView(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 120),
                  children: [
                    Text(
                      "搜索结果 (${_searchResults.length})",
                      style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ..._searchResults.map((e) => _buildTripItemCard(cs, e)),
                    if (_searchResults.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: Center(child: Text("没有找到匹配的行程", style: TextStyle(color: Colors.grey))),
                      ),
                  ],
                ),
              ),
            ),
          _fixedTop(cs, tt),
        ],
      ),
    );
  }

  List<Widget> _buildPeriodEntryList(ColorScheme cs, List<dynamic> entries) {
    if (entries.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 36),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Icon(Icons.electric_scooter_outlined, size: 32, color: cs.outline),
              const SizedBox(height: 8),
              Text('该时间段暂无行程记录', style: TextStyle(color: cs.outline, fontSize: 13)),
            ],
          ),
        ),
      ];
    }

    return entries.map((entry) => _buildTripItemCard(cs, entry)).toList();
  }

  Widget _buildTripItemCard(ColorScheme cs, dynamic entry) {
    final String dateStr = entry['happenedOn'] ?? '';
    final String displayDate = dateStr.length >= 10 ? dateStr.substring(5, 10) : dateStr;
    final transportStr = (entry['transportType'] ?? '').toString().toUpperCase();
    final IconData iconData = transportDisplayIcon(transportStr);
    final dist = (entry['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final durSec = (entry['durationSec'] as num?)?.toInt() ?? 0;
    final avgSpd = (entry['avgSpeedKmh'] as num?)?.toDouble() ?? 0.0;

    String loc = (entry['location'] ?? '未知地点').toString();
    final coordRegex = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)');
    final match = coordRegex.firstMatch(loc);
    if (match != null) {
      try {
        final lat = double.parse(match.group(1)!);
        final lng = double.parse(match.group(2)!);
        loc = '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}';
      } catch (_) {}
    }

    final metaParts = <String>[displayDate, loc];
    if (durSec > 0) metaParts.add(formatCompactDuration(durSec));
    if (avgSpd > 0.5) metaParts.add('均速 ${avgSpd.toStringAsFixed(0)}km/h');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('trip_${entry['id']}_${dateStr}_${dist}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmAndDeleteEntry(entry),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: InkWell(
          onTap: () => _showDetail(entry),
          borderRadius: BorderRadius.circular(18),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primaryContainer,
                    child: Icon(iconData, color: cs.onPrimaryContainer, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry['title'] ?? '未命名行程',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          metaParts.join(' · '),
                          style: TextStyle(fontSize: 11, color: cs.outline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${dist.toStringAsFixed(1)} km',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: cs.outline),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fixedTop(ColorScheme cs, TextTheme tt) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          color: cs.surface.withValues(alpha: 0.94),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 10,
            left: 16,
            right: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()} · 行程记录',
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '今日已骑 ${_todayRideKm.toStringAsFixed(1)} km · 共 ${allTimeEntries.length} 条行程',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.outline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '搜索行程',
                    icon: Icon(
                      _showSearchBar ? Icons.search_off_rounded : Icons.search_rounded,
                      color: _showSearchBar ? cs.primary : cs.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _showSearchBar = !_showSearchBar;
                        if (!_showSearchBar) {
                          _searchQuery = "";
                          _searchResults = const [];
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        }
                      });
                    },
                  ),
                  IconButton(
                    tooltip: '应用设置',
                    icon: Icon(Icons.settings_outlined, color: cs.onSurfaceVariant),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(
                            nickname: widget.nickname,
                            avatarId: widget.avatarId,
                            themeMode: widget.themeMode,
                            themeStyle: widget.themeStyle,
                            hapticEnabled: widget.hapticEnabled,
                            isMaintValid: widget.isMaintValid,
                            onUpdate: widget.onSettingsChanged,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              if (_showSearchBar) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (val) {
                    final query = val.trim().toLowerCase();
                    setState(() {
                      _searchQuery = query;
                      _searchResults = _buildSearchResults(allTimeEntries, query);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '搜索行程名称、地点或备注...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = "";
                                _searchResults = const [];
                                _searchController.clear();
                              });
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

// --- 探索地图页 (ExploreMapScreen) - 电动车骑行与足迹探索 ---
class ExploreMapScreen extends StatefulWidget {
  final String themeMode;
  final VoidCallback? onRideFinished;
  const ExploreMapScreen({
    super.key,
    required this.themeMode,
    this.onRideFinished,
  });
  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen>
    with WidgetsBindingObserver {
  static const dataChannel = MethodChannel('com.footprint/data');
  static const streamChannel = EventChannel('com.footprint/stream');
  String mapMode = 'STANDARD';
  String _historyTrackScope = 'NONE'; // NONE, TODAY, WEEK, MONTH, ALL
  String? _lastHistoryScope;
  MethodChannel? _mapChannel;
  List<dynamic> _allEntries = [];
  bool? _lastNativeShowHistory;
  String? _lastNativeMode;
  bool? _lastNativeThemeIsDark;
  bool? _lastNativeFogEnabled;
  int? _lastNativeEntriesHash;
  int? _lastNativeCapsulesHash;
  int? _lastNativeFogHash;

  // Flutter 高德定位客户端 (仅供单击定位兜底使用)
  final AMapFlutterLocation _locationClient = AMapFlutterLocation();
  StreamSubscription<Map<String, Object>>? _locationSubscription;
  StreamSubscription? _streamSubscription;

  // === 定位状态管理 ===
  bool _isLocating = false;    // 是否正在执行单次定位
  bool _isMapActive = true;    // 当前是否在地图 tab
  bool _userRequestedLocation = false; // 是否手动点击了定位

  // === 骑行追踪状态 ===
  bool _isTracking = false;
  bool _isPaused = false;
  bool _isAutoPaused = false;
  bool _isFullScreenHud = false;
  bool _keepScreenOn = true;
  bool _followCamera = true;
  String _selectedTransport = 'EBIKE';
  EbikeConfig _ebikeConfig = const EbikeConfig();

  final List<Map<String, double>> _trackingPath = [];
  double _totalDistance = 0.0;
  int _sessionStartTime = 0;
  int _lastKnownDurationMs = 0;
  double? _lastLat;
  double? _lastLng;
  List<dynamic> _capsules = [];
  bool _batteryOptimizationPromptShown = false;
  Timer? _durationTimer;
  final ValueNotifier<String> _durationNotifier = ValueNotifier<String>('00:00:00');
  final ValueNotifier<RidingTelemetry> _telemetryNotifier =
      ValueNotifier(const RidingTelemetry());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEntries();
    _loadEbikeConfig();
    // 初始化高德隐私合规（不自动开启定位）
    AMapFlutterLocation.updatePrivacyShow(true, true);
    AMapFlutterLocation.updatePrivacyAgree(true);
    _initApiKey();

    _recoverTrackingState();

    _streamSubscription = streamChannel.receiveBroadcastStream().listen((event) {
      if (!mounted) return;
      try {
        final data = jsonDecode(event as String);
        final type = data['type'];
        if (type == 'status') {
          final nextTracking = data['isTracking'] == true;
          final nextPaused = data['isPaused'] == true;
          final nextAutoPaused = data['isAutoPaused'] == true;
          final nextTransport =
              (data['transportType'] as String?) ?? _selectedTransport;

          setState(() {
            _isTracking = nextTracking;
            _isPaused = nextPaused;
            _isAutoPaused = nextAutoPaused;
            _selectedTransport = nextTransport;

            if (data['durationMs'] != null && _isTracking) {
              _lastKnownDurationMs = (data['durationMs'] as num).toInt();
              _sessionStartTime =
                  DateTime.now().millisecondsSinceEpoch - _lastKnownDurationMs;
              _durationNotifier.value = _formatDuration(_lastKnownDurationMs);
            }

            _updateNativeLocationState();
            _updateNativeMap();
            if (!_isTracking) {
              _isFullScreenHud = false;
              _durationNotifier.value = '00:00:00';
              _telemetryNotifier.value = const RidingTelemetry();
              _durationTimer?.cancel();
              _applyKeepScreenOn(false);
              _mapChannel?.invokeMethod('setFollowLocation', false);
            } else {
              _telemetryNotifier.value = _telemetryNotifier.value.copyWith(
                isPaused: _isPaused,
                isAutoPaused: _isAutoPaused,
                transportType: _selectedTransport,
              );
              if (_durationTimer == null || !_durationTimer!.isActive) {
                _startDurationTimer();
              }
            }
          });
        } else if (type == 'location') {
          if (_isTracking && data['data'] != null) {
            final d = data['data'] as Map<String, dynamic>;
            final lat = (d['latitude'] as num).toDouble();
            final lng = (d['longitude'] as num).toDouble();
            _lastLat = lat;
            _lastLng = lng;
            _telemetryNotifier.value = _telemetryNotifier.value.copyWith(
              lat: lat,
              lng: lng,
              accuracyMeters: (d['accuracy'] as num?)?.toDouble() ??
                  _telemetryNotifier.value.accuracyMeters,
              speedKmh: (d['speedKmh'] as num?)?.toDouble() ??
                  _telemetryNotifier.value.speedKmh,
              avgSpeedKmh: (d['avgSpeedKmh'] as num?)?.toDouble() ??
                  _telemetryNotifier.value.avgSpeedKmh,
              maxSpeedKmh: (d['maxSpeedKmh'] as num?)?.toDouble() ??
                  _telemetryNotifier.value.maxSpeedKmh,
              pointCount: (d['pointCount'] as num?)?.toInt() ??
                  _telemetryNotifier.value.pointCount,
              address: (d['address'] as String?)?.isNotEmpty == true
                  ? d['address'] as String
                  : _telemetryNotifier.value.address,
            );
          }
        } else if (type == 'distance') {
          _totalDistance = (data['distance'] as num).toDouble();
          _telemetryNotifier.value = _telemetryNotifier.value.copyWith(
            totalDistanceMeters: _totalDistance,
            avgSpeedKmh: (data['avgSpeedKmh'] as num?)?.toDouble() ??
                _telemetryNotifier.value.avgSpeedKmh,
            maxSpeedKmh: (data['maxSpeedKmh'] as num?)?.toDouble() ??
                _telemetryNotifier.value.maxSpeedKmh,
            pointCount: (data['pointCount'] as num?)?.toInt() ??
                _telemetryNotifier.value.pointCount,
          );
        } else if (type == 'telemetry') {
          if (_isTracking) {
            _telemetryNotifier.value = _telemetryNotifier.value.copyWith(
              speedKmh: (data['speedKmh'] as num?)?.toDouble() ?? 0.0,
              avgSpeedKmh: (data['avgSpeedKmh'] as num?)?.toDouble() ??
                  _telemetryNotifier.value.avgSpeedKmh,
              maxSpeedKmh: (data['maxSpeedKmh'] as num?)?.toDouble() ??
                  _telemetryNotifier.value.maxSpeedKmh,
              accuracyMeters: (data['accuracy'] as num?)?.toDouble() ??
                  _telemetryNotifier.value.accuracyMeters,
              isAutoPaused: data['isAutoPaused'] == true,
              pointCount: (data['pointCount'] as num?)?.toInt() ??
                  _telemetryNotifier.value.pointCount,
            );
          }
        }
      } catch (e) {
        debugPrint('Stream Error: $e');
      }
    });
  }

  Future<void> _loadEbikeConfig() async {
    try {
      final cfgStr = await dataChannel.invokeMethod<String>('getEbikeConfig');
      if (cfgStr != null && mounted) {
        final cfg = EbikeConfig.fromJson(jsonDecode(cfgStr));
        setState(() {
          _ebikeConfig = cfg;
          if (!_isTracking) {
            _selectedTransport = cfg.defaultTransport;
            _keepScreenOn = cfg.keepScreenOn;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _applyKeepScreenOn(bool enabled) async {
    try {
      await dataChannel.invokeMethod('setKeepScreenOn', enabled);
    } catch (_) {}
  }

  /// 从首页「一键开始电动车骑行」按钮调用
  void startRideFromExternal() {
    if (!mounted) return;
    if (_isTracking) {
      setState(() => _isFullScreenHud = true);
    } else {
      setState(() => _selectedTransport = 'EBIKE');
      _startTracking();
    }
  }

  Future<void> _initApiKey() async {
    try {
      final String jsonStr = await dataChannel.invokeMethod('getAppCredentials');
      final creds = jsonDecode(jsonStr);
      final String amapKey = creds['amapKey'] ?? "";
      if (amapKey.isNotEmpty) {
        AMapFlutterLocation.setApiKey(amapKey, "");
        debugPrint("AMap API Key set in Flutter: $amapKey");
      }
    } catch (e) {
      debugPrint("Error initializing API Key: $e");
    }
  }

  Future<void> _recoverTrackingState() async {
    try {
      final json = await dataChannel.invokeMethod('getTrackingState');
      final state = jsonDecode(json);
      if (state['isTracking'] == true) {
        final transport = (state['transportType'] as String?) ?? 'EBIKE';
        setState(() {
          _isTracking = true;
          _isPaused = state['isPaused'] == true;
          _isAutoPaused = state['isAutoPaused'] == true;
          _selectedTransport = transport;
          _totalDistance = (state['totalDistance'] as num).toDouble();
          _lastKnownDurationMs = (state['totalDurationMs'] as num).toInt();
          _sessionStartTime =
              DateTime.now().millisecondsSinceEpoch - _lastKnownDurationMs;
          _trackingPath.clear();
          for (var p in state['path']) {
            _trackingPath.add({
              'latitude': (p['latitude'] as num).toDouble(),
              'longitude': (p['longitude'] as num).toDouble(),
            });
          }
        });
        final lastPoint = _trackingPath.isNotEmpty ? _trackingPath.last : null;
        _lastLat = lastPoint?['latitude'];
        _lastLng = lastPoint?['longitude'];
        _durationNotifier.value = _formatDuration(_lastKnownDurationMs);
        _telemetryNotifier.value = RidingTelemetry(
          totalDistanceMeters: _totalDistance,
          pointCount: (state['pointCount'] as num?)?.toInt() ?? _trackingPath.length,
          speedKmh: (state['currentSpeedKmh'] as num?)?.toDouble() ?? 0.0,
          avgSpeedKmh: (state['avgSpeedKmh'] as num?)?.toDouble() ?? 0.0,
          maxSpeedKmh: (state['maxSpeedKmh'] as num?)?.toDouble() ?? 0.0,
          accuracyMeters: (state['accuracy'] as num?)?.toDouble() ?? 0.0,
          isPaused: _isPaused,
          isAutoPaused: _isAutoPaused,
          transportType: transport,
          address: (state['address'] as String?) ?? '',
          lat: _lastLat,
          lng: _lastLng,
        );
        _startDurationTimer();
        _applyKeepScreenOn(_keepScreenOn);
        _mapChannel?.invokeMethod('setFollowLocation', _followCamera);
        _updateNativeMap();
      }
    } catch (e) {
      debugPrint('Error recovering state: $e');
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isTracking || _isPaused || _isAutoPaused) return;

      int now = DateTime.now().millisecondsSinceEpoch;
      late final String nextDuration;
      if (_sessionStartTime <= 1000000) {
        nextDuration = _formatDuration(_lastKnownDurationMs);
      } else {
        int elapsed = now - _sessionStartTime;
        if (elapsed > 3600000 * 1000 || elapsed < 0) {
          elapsed = _lastKnownDurationMs;
        }
        nextDuration = _formatDuration(elapsed);
      }

      if (_durationNotifier.value != nextDuration) {
        _durationNotifier.value = nextDuration;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _applyKeepScreenOn(false);
    _locationSubscription?.cancel();
    _streamSubscription?.cancel();
    _locationClient.destroy();
    _durationTimer?.cancel();
    _durationNotifier.dispose();
    _telemetryNotifier.dispose();
    super.dispose();
  }

  // === 应用生命周期管理：后台时停止地图蓝点定位（追踪由原生 ForegroundService 独立负责）===
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopLocationIfIdle();
      _mapChannel?.invokeMethod('setLocationEnabled', false);
    } else if (state == AppLifecycleState.resumed) {
      _updateNativeLocationState();
      if (_isTracking) {
        _recoverTrackingState();
      }
    }
  }

  /// Tab 切换离开地图页时调用
  void onTabDeselected() {
    _isMapActive = false;
    _stopLocationIfIdle();
    _updateNativeLocationState();
  }

  /// Tab 切换进入地图页时调用
  void onTabActivated() {
    _isMapActive = true;
    _loadEbikeConfig();
    _updateNativeLocationState();
  }

  /// 在非追踪/非定位时停止定位服务
  void _stopLocationIfIdle() {
    if (!_isTracking && !_isLocating) {
      _locationSubscription?.cancel();
      _locationClient.stopLocation();
    }
  }

  void _updateNativeLocationState() {
    // 只有在点击定位时并且当前界面是地图界面时才会定位 -> (_userRequestedLocation && _isMapActive)
    // 开始记录足迹后，只要没有停止记录足迹，不管在前后台都会一直定位 (由服务控制)。为保持地图篮点显示，跟踪时也开启
    bool shouldEnable = false;
    if (_isTracking) {
      shouldEnable = _isMapActive;
    } else {
      // 如果用户点击了定位，或者正在定位过程中，且地图处于激活状态，开启原生定位
      shouldEnable = (_userRequestedLocation || _isLocating) && _isMapActive;
    }
    _mapChannel?.invokeMethod('setLocationEnabled', shouldEnable);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNativeMap();
  }

  @override
  void didUpdateWidget(covariant ExploreMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) {
      _lastNativeThemeIsDark = null;
      _updateNativeMap();
    }
  }

  List<dynamic> _fogPoints = [];

  Future<void> _loadEntries() async {
    try {
      final String jsonStr = await dataChannel.invokeMethod('getAllEntries');
      final String fogPointsJson = await dataChannel.invokeMethod('getAllFogPoints');
      final String capsulesJson = await dataChannel.invokeMethod('getAllTimeCapsules');
      setState(() {
        _allEntries = jsonDecode(jsonStr);
        _fogPoints = jsonDecode(fogPointsJson);
        _capsules = jsonDecode(capsulesJson);
      });
      _lastNativeEntriesHash = null;
      _lastNativeCapsulesHash = null;
      _lastNativeFogHash = null;
      _updateNativeMap();
    } catch (e) {
      debugPrint("Failed to load map entries: $e");
    }
  }

  void _onMapCreated(int id) {
    _mapChannel = MethodChannel('com.footprint/amap_$id');
    _lastNativeShowHistory = null;
    _lastNativeMode = null;
    _lastNativeThemeIsDark = null;
    _lastNativeFogEnabled = null;
    _lastNativeEntriesHash = null;
    _lastNativeCapsulesHash = null;
    _lastNativeFogHash = null;
    _mapChannel?.setMethodCallHandler((call) async {
      if (call.method == 'onMarkerClick') {
        int entryId = call.arguments;
        if (!mounted) return;
        final entry = _allEntries.firstWhere((e) => e['id'] == entryId, orElse: () => null);
        if (entry != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FootprintDetailPage(entry: entry),
            ),
          );
        }
      } else if (call.method == 'onCapsuleClick') {
        int capsuleId = call.arguments;
        _showCapsuleDialog(capsuleId);
      }
    });
    _updateNativeMap();
  }

  void _showCapsuleDialog(int capsuleId) {
    if (!mounted) return;
    final capsule = _capsules.firstWhere((c) => c['id'] == capsuleId, orElse: () => null);
    if (capsule == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.timer, color: Colors.cyan),
            const SizedBox(width: 10),
            Text(
              capsule['isUnlocked'] ? "时光胶囊已开启" : "时光胶囊锁定中",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (capsule['isUnlocked']) ...[
              Text(
                capsule['message'],
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 15),
              Text(
                "埋藏时间: ${DateTime.fromMillisecondsSinceEpoch(capsule['creationTime']).toString().split('.')[0]}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ] else ...[
              const Text(
                "这是一颗未来的胶囊，还没到开启时刻，或者您还没到达预设位置。",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("我知道了", style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }

  int? _scopeStartMs() {
    if (_historyTrackScope == 'NONE' || _historyTrackScope == 'ALL') return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_historyTrackScope) {
      case 'TODAY':
        return today.millisecondsSinceEpoch;
      case 'WEEK':
        return today.subtract(Duration(days: today.weekday - 1)).millisecondsSinceEpoch;
      case 'MONTH':
        return DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      default:
        return null;
    }
  }

  void _updateNativeMap() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const bool fogEnabled = false;
    if (_lastNativeThemeIsDark != isDark) {
      _mapChannel?.invokeMethod('setTheme', isDark);
      _lastNativeThemeIsDark = isDark;
    }
    if (_lastNativeMode != mapMode) {
      _mapChannel?.invokeMethod('setMapMode', mapMode);
      _lastNativeMode = mapMode;
    }
    if (_lastNativeFogEnabled != fogEnabled) {
      _mapChannel?.invokeMethod('setFogEnabled', fogEnabled);
      _lastNativeFogEnabled = fogEnabled;
    }

    final bool showHistory = _historyTrackScope != 'NONE';
    final int? startMs = _scopeStartMs();
    final List<dynamic> scopedPoints = !showHistory
        ? const []
        : (startMs == null
            ? _fogPoints
            : _fogPoints
                .where((p) => ((p['timestamp'] as num?)?.toInt() ?? 0) >= startMs)
                .toList(growable: false));
    final List<dynamic> scopedEntries = !showHistory
        ? const []
        : (startMs == null
            ? _allEntries
            : _allEntries.where((e) {
                final raw = e['happenedOn']?.toString();
                if (raw != null && raw.length >= 10) {
                  final dt = DateTime.tryParse(raw.substring(0, 10));
                  if (dt != null) return dt.millisecondsSinceEpoch >= startMs;
                }
                return ((e['timestamp'] as num?)?.toInt() ?? 0) >= startMs;
              }).toList(growable: false));

    final entriesHash = Object.hash(
      _historyTrackScope,
      scopedEntries.length,
      scopedEntries.isNotEmpty ? scopedEntries.last['id'] : null,
    );
    final fogHash = Object.hash(
      _historyTrackScope,
      scopedPoints.length,
      scopedPoints.isNotEmpty ? scopedPoints.first['timestamp'] : null,
      scopedPoints.isNotEmpty ? scopedPoints.last['timestamp'] : null,
    );

    if (showHistory) {
      if (_lastNativeShowHistory != true ||
          _lastHistoryScope != _historyTrackScope ||
          _lastNativeEntriesHash != entriesHash) {
        _mapChannel?.invokeMethod('setEntries', scopedEntries);
        _lastNativeEntriesHash = entriesHash;
      }
      if (_lastNativeShowHistory != true) {
        _mapChannel?.invokeMethod('setCapsules', []);
        _lastNativeCapsulesHash = 0;
      }
      if (_lastNativeShowHistory != true ||
          _lastHistoryScope != _historyTrackScope ||
          _lastNativeFogHash != fogHash) {
        _mapChannel?.invokeMethod('setHistoryPoints', scopedPoints);
        _lastNativeFogHash = fogHash;
      }
    } else {
      if (_lastNativeShowHistory != false) {
        _mapChannel?.invokeMethod('setEntries', []);
        _mapChannel?.invokeMethod('setCapsules', []);
        _mapChannel?.invokeMethod('setHistoryPoints', []);
        _lastNativeEntriesHash = null;
        _lastNativeCapsulesHash = null;
        _lastNativeFogHash = null;
      }
    }
    _lastNativeShowHistory = showHistory;
    _lastHistoryScope = _historyTrackScope;
  }

  // === 定位按钮：直接使用原生地图的位置居中 ===
  Future<void> _handleLocateMe() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("需要位置权限才能进行定位"), backgroundColor: Colors.orange,
            action: SnackBarAction(label: "去设置", textColor: Colors.white, onPressed: () => openAppSettings()),
          ));
        }
        return;
      }

      // === 策略1：直接让原生地图居中到它自己已知的蓝点位置 ===
      setState(() {
        _userRequestedLocation = true;
        _isLocating = true;
      });
      _updateNativeLocationState();

      try {
        final nativeResult = await _mapChannel?.invokeMethod('centerLocation', {'zoom': 17.0});
        if (nativeResult == true) {
          setState(() {
            _isLocating = false;
            _userRequestedLocation = false;
          });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("定位成功"), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
          return;
        }
      } catch (e) {
        debugPrint("Native centerLocation failed: $e, trying Flutter SDK fallback...");
      }

      // === 策略2：原生没有位置数据时，使用 Flutter AMap 定位 SDK 获取坐标 ===
      _locationClient.setLocationOption(AMapLocationOption(onceLocation: true, locationMode: AMapLocationMode.Hight_Accuracy, needAddress: true));
      _locationSubscription?.cancel();
      bool hasResult = false;
      _locationSubscription = _locationClient.onLocationChanged().listen((result) async {
        if (!mounted || hasResult) return;
        final double? lat = result['latitude'] as double?;
        final double? lng = result['longitude'] as double?;
        final errorCode = result['errorCode'];
        
        if (errorCode != null && errorCode != 0) {
          hasResult = true;
          setState(() {
            _isLocating = false;
            _userRequestedLocation = false;
          });
          _updateNativeLocationState();
          _locationSubscription?.cancel();
          _locationClient.stopLocation();
          if (!mounted) return;
          String errMsg;
          switch (errorCode) {
            case 7: errMsg = "高德Key鉴权失败：请到设置中检查API Key是否正确，包名和SHA1是否匹配";
            case 12: errMsg = "缺少定位权限：请在系统设置中授予位置权限";
            case 4: errMsg = "网络连接异常：请检查网络设置";
            case 13: errMsg = "GPS信号不可用：请到开阔地带重试";
            default: errMsg = "定位失败(错误码:$errorCode): ${result['errorInfo'] ?? '未知错误'}";
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errMsg), backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
            action: errorCode == 7 ? SnackBarAction(label: "设置Key", textColor: Colors.white, onPressed: () => _showApiKeyDialog()) : null,
          ));
          return;
        }
        if (lat != null && lng != null && lat > 1.0 && lng > 1.0) {
          hasResult = true;
          setState(() {
            _isLocating = false;
            _userRequestedLocation = false;
          });
          _updateNativeLocationState();
          await _mapChannel?.invokeMethod('centerLocation', {'latitude': lat, 'longitude': lng, 'zoom': 17.0});
          _locationSubscription?.cancel();
          _locationClient.stopLocation();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("定位成功"), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
        }
      });
      _locationClient.startLocation();
      Future.delayed(const Duration(seconds: 10), () {
        if (!hasResult && mounted) {
          setState(() {
            _isLocating = false;
            _userRequestedLocation = false;
          });
          _updateNativeLocationState();
          _locationSubscription?.cancel();
          _locationClient.stopLocation();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("定位超时：请检查GPS是否开启及网络状况"), backgroundColor: Colors.orange));
        }
      });
    } catch (e) {
      setState(() {
        _isLocating = false;
        _userRequestedLocation = false;
      });
      _updateNativeLocationState();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("定位异常: $e"), backgroundColor: Colors.redAccent));
    }
  }

  // === 开始追踪：启动原生前台服务 ===
  Future<void> _startTracking() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("需要位置权限才能记录骑行轨迹"), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    final alwaysStatus = await Permission.locationAlways.status;
    if (!alwaysStatus.isGranted) {
      final requestedAlways = await Permission.locationAlways.request();
      if (!requestedAlways.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("建议授予“始终允许”位置权限，息屏骑行轨迹更完整"),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: "去设置",
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
    try {
      final ignoringBattery =
          await dataChannel.invokeMethod('isIgnoringBatteryOptimizations') == true;
      if (!ignoringBattery && !_batteryOptimizationPromptShown) {
        _batteryOptimizationPromptShown = true;
        await dataChannel.invokeMethod('requestBatteryOptimizationExemption');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("建议允许后台电池白名单，长时间骑行不易中断"),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (_) {}

    setState(() {
      _trackingPath.clear();
      _totalDistance = 0.0;
      _lastLat = null;
      _lastLng = null;
      _isAutoPaused = false;
      _followCamera = true;
      _keepScreenOn = _ebikeConfig.keepScreenOn;
      _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    });
    _durationNotifier.value = '00:00:00';
    _telemetryNotifier.value = RidingTelemetry(transportType: _selectedTransport);

    try {
      await _mapChannel?.invokeMethod('centerLocation', {'zoom': 17.5});
      await _mapChannel?.invokeMethod('setFollowLocation', _followCamera);
    } catch (_) {}

    try {
      await dataChannel.invokeMethod('startTracking', {
        'transportType': _selectedTransport,
      });
      await _applyKeepScreenOn(_keepScreenOn);
      setState(() {
        _isTracking = true;
        _isPaused = false;
        _isAutoPaused = false;
        _lastKnownDurationMs = 0;
        _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
      });
      _startDurationTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("启动追踪失败: $e"), backgroundColor: Colors.orange),
        );
      }
    }
  }

  // === 暂停追踪 ===
  Future<void> _pauseTracking() async {
    try {
      await dataChannel.invokeMethod('pauseTracking');
      final json = await dataChannel.invokeMethod('getTrackingState');
      final state = jsonDecode(json);
      setState(() {
        _isPaused = true;
        _isAutoPaused = false;
        _lastKnownDurationMs = (state['totalDurationMs'] as num).toInt();
      });
      _telemetryNotifier.value = _telemetryNotifier.value.copyWith(
        isPaused: true,
        isAutoPaused: false,
        speedKmh: 0.0,
      );
    } catch (e) {
      debugPrint('Error pausing tracking: $e');
    }
  }

  // === 恢复追踪 ===
  Future<void> _resumeTracking() async {
    try {
      await dataChannel.invokeMethod('resumeTracking');
      setState(() {
        _isPaused = false;
        _isAutoPaused = false;
        _sessionStartTime =
            DateTime.now().millisecondsSinceEpoch - _lastKnownDurationMs;
      });
      _telemetryNotifier.value = _telemetryNotifier.value.copyWith(
        isPaused: false,
        isAutoPaused: false,
      );
    } catch (e) {
      debugPrint('Error resuming tracking: $e');
    }
  }

  // === 防误触停止确认 ===
  Future<void> _requestStopTracking() async {
    final choice = await showStopRideConfirmSheet(
      context,
      telemetry: _telemetryNotifier.value,
      durationText: _durationNotifier.value,
    );
    if (choice == 'save') {
      await _stopTracking(discard: false);
    } else if (choice == 'discard') {
      await _stopTracking(discard: true);
    }
  }

  // === 停止追踪 ===
  Future<void> _stopTracking({bool discard = false}) async {
    _durationTimer?.cancel();
    final savedDistanceKm = _telemetryNotifier.value.distanceKm;

    try {
      await dataChannel.invokeMethod('stopTracking', {'discard': discard});
    } catch (e) {
      debugPrint('Error stopping tracking: $e');
    }

    await _applyKeepScreenOn(false);
    await _mapChannel?.invokeMethod('setFollowLocation', false);

    setState(() {
      _isTracking = false;
      _isPaused = false;
      _isAutoPaused = false;
      _isFullScreenHud = false;
      _trackingPath.clear();
      _totalDistance = 0.0;
      _lastLat = null;
      _lastLng = null;
    });
    _durationNotifier.value = '00:00:00';
    _telemetryNotifier.value = const RidingTelemetry();
    _mapChannel?.invokeMethod('setTrackingPath', <Map<String, double>>[]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            discard
                ? '已放弃本次记录'
                : '本次${transportDisplayName(_selectedTransport)}已保存 · ${savedDistanceKm.toStringAsFixed(2)} km',
          ),
          backgroundColor: discard ? Colors.blueGrey : const Color(0xFF00A86B),
        ),
      );
    }

    // 延迟重新加载，给 Kotlin 保存 DB 和更新电量留一点时间
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _loadEntries();
        _loadEbikeConfig();
        widget.onRideFinished?.call();
      }
    });
  }

  String _formatDuration(int ms) {
    final s = (ms ~/ 1000) % 60, m = (ms ~/ 60000) % 60, h = ms ~/ 3600000;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toggleKeepScreenOn() {
    setState(() => _keepScreenOn = !_keepScreenOn);
    _applyKeepScreenOn(_keepScreenOn);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_keepScreenOn ? '已开启屏幕常亮' : '已关闭屏幕常亮'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _toggleFollowCamera() {
    setState(() => _followCamera = !_followCamera);
    _mapChannel?.invokeMethod('setFollowLocation', _followCamera);
    if (_followCamera) {
      _mapChannel?.invokeMethod('centerLocation', {'zoom': 17.5});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topInset = MediaQuery.of(context).padding.top;
    final surfaceGlass = cs.surface.withValues(alpha: isDark ? 0.90 : 0.94);
    final borderGlass = cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.45);
    final softShadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.10),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];

    return Stack(
      children: [
        Positioned.fill(child: NativeMapView(onCreated: _onMapCreated)),

        // 顶部统一极简悬浮栏（仅保留标准地图状态胶囊 + 整合工具栏）
        if (!_isFullScreenHud)
          Positioned(
            top: topInset + 12,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 左侧：标准模式 & 爱车/骑行状态胶囊
                    Flexible(
                      child: GestureDetector(
                        onTap: _isTracking
                            ? () => setState(() => _isFullScreenHud = true)
                            : _handleLocateMe,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: surfaceGlass,
                            borderRadius: BorderRadius.circular(21),
                            border: Border.all(color: borderGlass),
                            boxShadow: softShadow,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isTracking
                                      ? (_isPaused
                                          ? Colors.orangeAccent
                                          : const Color(0xFF00C853))
                                      : cs.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _isTracking
                                      ? (_isPaused ? '已暂停记录' : '骑行记录中')
                                      : '标准地图',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                              if (!_isTracking) ...[
                                Container(
                                  width: 1,
                                  height: 12,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  color: borderGlass,
                                ),
                                Icon(
                                  Icons.battery_charging_full,
                                  size: 14,
                                  color: _ebikeConfig.isLowBattery
                                      ? Colors.redAccent
                                      : const Color(0xFF00A86B),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${_ebikeConfig.remainingRangeKm.toStringAsFixed(0)}km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                                if (_ebikeConfig.bluetoothAutoTrackEnabled &&
                                    _ebikeConfig.hasBoundBluetooth) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    _ebikeConfig.isBleMode
                                        ? Icons.radar_rounded
                                        : Icons.bluetooth_connected,
                                    size: 14,
                                    color: const Color(0xFF1E88E5),
                                  ),
                                ],
                              ] else ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.fullscreen,
                                  size: 16,
                                  color: cs.onSurfaceVariant,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 右侧：统一磨砂工具胶囊（定位回中 / 防断连体检 / 地图设置）
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: surfaceGlass,
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: borderGlass),
                        boxShadow: softShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _topToolIconBtn(
                            icon: Icons.my_location_rounded,
                            tooltip: '回到当前位置',
                            color: cs.primary,
                            onTap: _handleLocateMe,
                          ),
                          Container(width: 1, height: 18, color: borderGlass),
                          _topToolIconBtn(
                            icon: Icons.shield_outlined,
                            tooltip: '骑行防断连体检',
                            color: cs.onSurfaceVariant,
                            onTap: () => showBackgroundKeepAliveDialog(context),
                          ),
                          Container(width: 1, height: 18, color: borderGlass),
                          _topToolIconBtn(
                            icon: Icons.tune_rounded,
                            tooltip: '地图 API 设置',
                            color: cs.onSurfaceVariant,
                            onTap: _showApiKeyDialog,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!_isTracking) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: surfaceGlass,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderGlass),
                      boxShadow: softShadow,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          ('NONE', '隐藏轨迹'),
                          ('TODAY', '今日轨迹'),
                          ('WEEK', '本周轨迹'),
                          ('MONTH', '本月轨迹'),
                          ('ALL', '全部轨迹'),
                        ].map((item) {
                          final selected = _historyTrackScope == item.$1;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _historyTrackScope = item.$1);
                              _updateNativeMap();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(
                                color: selected ? cs.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                item.$2,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // 底部一体化骑行控制底座（未追踪态：出行方式分段条 + 全宽一键开始）
        if (!_isTracking && !_isFullScreenHud)
          Positioned(
            bottom: 102,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: surfaceGlass,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderGlass),
                boxShadow: softShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(
                        alpha: isDark ? 0.45 : 0.65,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _transportChip('EBIKE', '电动车', Icons.electric_scooter, cs),
                        _transportChip('BIKE', '单车', Icons.directions_bike, cs),
                        _transportChip('WALK', '步行', Icons.directions_walk, cs),
                        _transportChip('CAR', '自驾', Icons.directions_car, cs),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _startTracking,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        _selectedTransport == 'EBIKE'
                            ? Icons.electric_scooter
                            : Icons.play_arrow_rounded,
                        size: 22,
                      ),
                      label: Text(
                        '开始${transportDisplayName(_selectedTransport)}记录',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 追踪中：全宽实时骑行仪表盘 + 对称控制栏（不再被右侧 FAB 挤压）
        if (_isTracking && !_isFullScreenHud)
          Positioned(
            bottom: 102,
            left: 14,
            right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<RidingTelemetry>(
                  valueListenable: _telemetryNotifier,
                  builder: (context, telemetry, _) => RidingTelemetryCard(
                    telemetry: telemetry,
                    durationNotifier: _durationNotifier,
                    ebikeConfig: _ebikeConfig,
                    keepScreenOn: _keepScreenOn,
                    followCamera: _followCamera,
                    onToggleKeepScreenOn: _toggleKeepScreenOn,
                    onToggleFollowCamera: _toggleFollowCamera,
                    onOpenFullScreenHud: () =>
                        setState(() => _isFullScreenHud = true),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: FilledButton.tonalIcon(
                          onPressed: () =>
                              _isPaused ? _resumeTracking() : _pauseTracking(),
                          style: FilledButton.styleFrom(
                            backgroundColor: _isPaused
                                ? const Color(0xFF00C853)
                                : surfaceGlass,
                            foregroundColor: _isPaused
                                ? Colors.white
                                : Colors.orange.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: _isPaused
                                  ? BorderSide.none
                                  : BorderSide(color: borderGlass),
                            ),
                          ),
                          icon: Icon(
                            _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            size: 22,
                          ),
                          label: Text(
                            _isPaused ? '继续骑行' : '暂停记录',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: FilledButton.icon(
                          onPressed: _requestStopTracking,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.stop_rounded, size: 22),
                          label: const Text(
                            '结束并保存',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // 全屏骑行码表 HUD 模式
        if (_isTracking && _isFullScreenHud)
          Positioned.fill(
            child: FullScreenRideHud(
              telemetryNotifier: _telemetryNotifier,
              durationNotifier: _durationNotifier,
              ebikeConfig: _ebikeConfig,
              keepScreenOn: _keepScreenOn,
              onToggleKeepScreenOn: _toggleKeepScreenOn,
              onTogglePause: () =>
                  _isPaused ? _resumeTracking() : _pauseTracking(),
              onRequestStop: _requestStopTracking,
              onClose: () => setState(() => _isFullScreenHud = false),
            ),
          ),
      ],
    );
  }

  Widget _topToolIconBtn({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 40,
          height: 42,
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }

  Widget _transportChip(String code, String label, IconData icon, ColorScheme cs) {
    final selected = _selectedTransport == code;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTransport = code);
          dataChannel.invokeMethod('saveEbikeConfig', {'defaultTransport': code});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showApiKeyDialog() async {
    try {
      final String jsonStr = await dataChannel.invokeMethod('getAppCredentials');
      final creds = jsonDecode(jsonStr);
      final String pkgName = creds['packageName'] ?? "";
      final String sha1 = creds['sha1'] ?? "";
      final String amapKey = creds['amapKey'] ?? "";
      final String googleKey = creds['googleKey'] ?? "";
      final String selectedType = creds['selectedMapType'] ?? "AMAP";
      
      if (!mounted) return;
      
      final TextEditingController amapCtrl = TextEditingController(text: amapKey);
      final TextEditingController googleCtrl = TextEditingController(text: googleKey);
      String currentType = selectedType;
      
      await showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final colorScheme = Theme.of(context).colorScheme;
              return AlertDialog(
                title: const Text("地图 API 设置"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("应用凭证 (用于申请 Key):", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                      const SizedBox(height: 8),
                      Text("Package Name:", style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6))),
                      _buildCopyableRow(context, pkgName, "已复制包名"),
                      const SizedBox(height: 8),
                      Text("SHA1:", style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.6))),
                      _buildCopyableRow(context, sha1, "已复制 SHA1"),
                      const Divider(height: 32),
                      
                      const Text("选择默认地图类型:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'AMAP', label: Text('高德地图'), icon: Icon(Icons.map)),
                          ButtonSegment(value: 'GOOGLE', label: Text('谷歌地图'), icon: Icon(Icons.language)),
                        ],
                        selected: {currentType},
                        onSelectionChanged: (newSelection) {
                          setDialogState(() => currentType = newSelection.first);
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      if (currentType == 'AMAP') ...[
                        TextField(
                          controller: amapCtrl,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: "AMAP Key (高德)",
                            hintText: "请输入您的高德地图 API Key",
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("提示: 请确保在控制台开启了 Android 平台的 SDK 权限。", 
                          style: TextStyle(fontSize: 11, color: colorScheme.outline)),
                      ] else ...[
                        TextField(
                          controller: googleCtrl,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: "Google Maps Key",
                            hintText: "请输入您的 Google API Key",
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("如何获取 Google Key?", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer)),
                              const SizedBox(height: 4),
                              Text("1. 访问 Google Cloud Console\n2. 启用 'Maps SDK for Android'\n3. 创建 API Key 并限制为 Android 应用\n4. 添加上方的包名和 SHA1 指纹", 
                                style: TextStyle(fontSize: 11, color: colorScheme.onSecondaryContainer)),
                              TextButton.icon(
                                onPressed: () => dataChannel.invokeMethod('openUrl', 'https://console.cloud.google.com/google/maps-apis/credentials'),
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: const Text("前往控制台", style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text("取消", style: TextStyle(color: colorScheme.outline)),
                  ),
                  FilledButton(
                    onPressed: () {
                      dataChannel.invokeMethod('saveAmapKey', amapCtrl.text);
                      dataChannel.invokeMethod('saveGoogleKey', googleCtrl.text);
                      dataChannel.invokeMethod('saveMapType', currentType);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("设置已保存，部分更改需重启应用生效"))
                      );
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("保存"),
                  ),
                ],
              );
            }
          );
        }
      );
    } catch (e) {
      debugPrint("获取凭证失败: $e");
    }
  }

  Widget _buildCopyableRow(BuildContext context, String text, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 1)));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: "monospace",
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.content_copy,
              size: 14,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// --- 设置页 (SettingsScreen) - 1:1 模块化复刻 ---
class SettingsScreen extends StatefulWidget {
  final String nickname;
  final String avatarId;
  final String themeMode;
  final String themeStyle;
  final bool hapticEnabled;
  final bool isMaintValid;
  final VoidCallback onUpdate;
  const SettingsScreen({
    super.key,
    required this.nickname,
    required this.avatarId,
    required this.themeMode,
    required this.themeStyle,
    required this.hapticEnabled,
    required this.isMaintValid,
    required this.onUpdate,
  });
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const channel = MethodChannel('com.footprint/data');
  late String _themeMode;
  late String _themeStyle;
  late bool _hapticEnabled;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
    _themeStyle = widget.themeStyle;
    _hapticEnabled = widget.hapticEnabled;
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) _themeMode = widget.themeMode;
    if (oldWidget.themeStyle != widget.themeStyle) _themeStyle = widget.themeStyle;
    if (oldWidget.hapticEnabled != widget.hapticEnabled) _hapticEnabled = widget.hapticEnabled;
  }

  void _up(String m, dynamic v) async {
    setState(() {
      switch (m) {
        case 'updateThemeMode':
          _themeMode = v as String;
          break;
        case 'updateThemeStyle':
          _themeStyle = v as String;
          break;
        case 'updateHaptic':
          _hapticEnabled = v as bool;
          break;
      }
    });
    await channel.invokeMethod(m, v);
    widget.onUpdate();
  }

  Future<void> _handleDataOperation(String method, String label) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text('正在$label数据...'),
          ],
        ),
      ),
    );

    try {
      final result = await channel.invokeMethod<bool>(method);
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label成功！'), backgroundColor: Colors.green));
          widget.onUpdate();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已取消$label或$label失败')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label失败: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _t("系统模式", cs),
          _card(
            cs,
            Column(
              children: [
                RadioListTile(
                  title: const Text("跟随系统"),
                  value: "SYSTEM",
                  groupValue: _themeMode,
                  onChanged: (v) => _up('updateThemeMode', v),
                ),
                RadioListTile(
                  title: const Text("日间模式"),
                  value: "LIGHT",
                  groupValue: _themeMode,
                  onChanged: (v) => _up('updateThemeMode', v),
                ),
                RadioListTile(
                  title: const Text("夜间模式"),
                  value: "DARK",
                  groupValue: _themeMode,
                  onChanged: (v) => _up('updateThemeMode', v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _t("视觉风格", cs),
          _card(
            cs,
            Column(
              children: [
                _sTile("智能自适应", Icons.auto_awesome, "AUTO", cs),
                _sTile("经典蓝调", Icons.palette, "CLASSIC", cs),
                _sTile("赛博朋克", Icons.electric_bolt, "CYBERPUNK", cs),
                _sTile("森林氧吧", Icons.forest, "FOREST", cs),
                _sTile("撒哈拉之光", Icons.wb_sunny, "SAHARA", cs),
                _sTile("赤陶朱砂", Icons.local_fire_department, "EMBER", cs),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _t("交互体验", cs),
          _card(
            cs,
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: const Text("开启触感反馈"),
              value: _hapticEnabled,
              onChanged: (v) => _up('updateHaptic', v),
            ),
          ),
          const SizedBox(height: 20),
          _t("数据管理", cs),
          _card(
            cs,
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload),
                  title: const Text("导出足迹备份"),
                  onTap: () => _handleDataOperation('exportData', '导出'),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download),
                  title: const Text("导入历史记录"),
                  onTap: () => _handleDataOperation('importData', '导入'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _t("应用信息", cs),
          _card(
            cs,
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text("当前版本"),
              subtitle: Text(kAppVersionLabel),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _t(String t, ColorScheme cs) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      t,
      style: TextStyle(
        color: cs.primary,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    ),
  );
  Widget _card(ColorScheme cs, Widget child) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    ),
    child: child,
  );
  Widget _sTile(String t, IconData i, String v, ColorScheme cs) => ListTile(
    leading: Icon(i, color: _themeStyle == v ? cs.primary : cs.outline),
    title: Text(
      t,
      style: TextStyle(
        color: _themeStyle == v ? cs.primary : null,
        fontWeight: _themeStyle == v ? FontWeight.bold : null,
      ),
    ),
    trailing: _themeStyle == v
        ? Icon(Icons.check, color: cs.primary)
        : null,
    onTap: () => _up('updateThemeStyle', v),
  );
  void _launchURL(String url) async {
    const channel = MethodChannel('com.footprint/data');
    await channel.invokeMethod('openUrl', url);
  }

  IconData _getAv(String id) {
    switch (id) {
      case "avatar_2":
        return Icons.account_circle;
      case "avatar_3":
        return Icons.smart_toy;
      case "avatar_4":
        return Icons.fingerprint;
      default:
        return Icons.face;
    }
  }
}

class ArtStudioScreen extends StatelessWidget {
  final String nickname;
  final bool isMaintValid;
  const ArtStudioScreen({
    super.key,
    required this.nickname,
    this.isMaintValid = false,
  });
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final todayHint = getEternalTodayBannerText();
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: cs.onSurface,
            title: Text(
              '足迹工坊',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: cs.onSurface,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudioIntroCard(context, nickname),
                  const SizedBox(height: 18),
                  _buildStudioHeroStats(context),
                  const SizedBox(height: 18),
                  _buildCuratorStrip(todayHint),
                  const SizedBox(height: 22),
                  _buildSectionHeader(
                    context,
                    "艺术创作",
                    "把足迹整理成可以分享、打印和反复回看的视觉作品",
                  ),
                  const SizedBox(height: 16),
                  _buildStudioCard(
                    context,
                    "艺术足迹导出",
                    "将您的轨迹转化为精美的极简主义艺术海报",
                    Icons.auto_awesome,
                    const Color(0xFF0D4C78),
                    const Color(0xFF55B7C4),
                    const ['极简海报', '打印感', '高完成度'],
                    () {
                      const MethodChannel('com.footprint/data').invokeMethod('openNativeScreen', {'screen_type': 'art_studio'});
                    }
                  ),
                  const SizedBox(height: 16),
                  _buildStudioCard(
                    context,
                    "时空热力图",
                    "可视化您的活动密集区域",
                    Icons.grid_view,
                    const Color(0xFF24514F),
                    const Color(0xFF9ED3B5),
                    const ['密度分析', '轨迹纹理', '城市节奏'],
                    () {
                      const MethodChannel('com.footprint/data').invokeMethod('openNativeScreen', {'screen_type': 'generative_art'});
                    }
                  ),
                  const SizedBox(height: 18),
                  _buildMiniInspirationGrid(),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    context,
                    "实验室功能",
                    "更具空间感和沉浸感的足迹回放方式",
                  ),
                  const SizedBox(height: 16),
                  _buildStudioCard(
                    context,
                    "3D 足迹漫游",
                    "在 3D 地球上回放您的旅行故事",
                    Icons.view_in_ar,
                    const Color(0xFF5A3827),
                    const Color(0xFFF0B071),
                    const ['空间回放', '地球视角', '故事感'],
                    () {
                      const MethodChannel('com.footprint/data').invokeMethod('openNativeScreen', {'screen_type': 'export_trace'});
                    }
                  ),
                  if (isMaintValid) ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      context,
                      "永恒之境",
                      "更私人的入口，只给特定的人和特定的日子",
                      accent: Colors.pinkAccent,
                    ),
                    const SizedBox(height: 16),
                    _buildStudioCard(
                      context,
                      "Lucas 的时空密室",
                      todayHint ?? "遇见你，是我最美的意外。这里珍藏着属于我们的每一刻。",
                      Icons.favorite,
                      const Color(0xFF6F1D4F),
                      const Color(0xFFFFA7C4),
                      const ['私密彩蛋', '纪念空间', '只对她开放'],
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EternalRealmScreen()));
                      }
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudioIntroCard(BuildContext context, String nickname) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? cs.surfaceContainerHighest : const Color(0xFFECE3D3),
            cs.surface,
            isDark ? const Color(0xFF182523) : const Color(0xFFD7E5E0),
          ],
        ),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(isDark ? 0.12 : 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -18,
            left: -10,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.secondary.withOpacity(isDark ? 0.12 : 0.09),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'FOOTPRINT ATELIER',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$nickname，把轨迹做成值得收藏的作品。',
                style: tt.titleLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '从极简海报到时空热力图，再到 3D 漫游，把日常足迹整理成更有记忆点的表达。',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudioHeroStats(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: cs.outlineVariant),
      ),
      child: const Row(
        children: [
          Expanded(child: _StudioMetric(value: '3', label: '创作入口', icon: Icons.layers_outlined)),
          SizedBox(width: 12),
          Expanded(child: _StudioMetric(value: '∞', label: '回忆延展', icon: Icons.auto_awesome_motion)),
          SizedBox(width: 12),
          Expanded(child: _StudioMetric(value: '1', label: '私密空间', icon: Icons.favorite_border)),
        ],
      ),
    );
  }

  Widget _buildCuratorStrip(String? todayHint) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF183048),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tips_and_updates_outlined, color: Color(0xFFFFD18C)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '今日策展建议',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  todayHint ?? '如果想先做一张最容易出效果的作品，优先试试“艺术足迹导出”，它最适合把一段路线收成纪念海报。',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInspirationGrid() {
    final items = const [
      (
        '适合分享',
        '海报更适合发朋友圈或打印留存',
        Color(0xFFDB6C4B),
        Color(0xFFFFD39C),
        Color(0xFFFFF4E6),
        Icons.auto_awesome,
      ),
      (
        '适合复盘',
        '热力图更适合看一段时间的活动重心',
        Color(0xFF1D5E73),
        Color(0xFF6FD7D3),
        Color(0xFFEAFBFA),
        Icons.insights_outlined,
      ),
    ];
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: item == items.first ? 10 : 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      item.$3,
                      Color.alphaBlend(Colors.white.withOpacity(0.14), item.$3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                  boxShadow: [
                    BoxShadow(
                      color: item.$3.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.16)),
                      ),
                      child: Icon(item.$6, color: item.$4, size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.$1,
                      style: TextStyle(
                        color: item.$5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      style: TextStyle(
                        color: item.$5.withOpacity(0.82),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle, {
    Color accent = const Color(0xFF10355B),
  }) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final effectiveAccent = accent == const Color(0xFF10355B) ? cs.primary : accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: effectiveAccent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildStudioCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color startColor,
    Color accentColor,
    List<String> tags,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              startColor,
              Color.alphaBlend(Colors.white.withOpacity(0.08), startColor),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: startColor.withOpacity(0.22),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        '进入工坊',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: accentColor, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudioMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StudioMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.56),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary, size: 18),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class NativeMapView extends StatelessWidget {
  final Function(int) onCreated;
  const NativeMapView({super.key, required this.onCreated});
  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'com.footprint/amap',
      layoutDirection: TextDirection.ltr,
      creationParams: {"zoom": 15.0},
      onPlatformViewCreated: onCreated,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

class TimeFootprintPlaybackPage extends StatefulWidget {
  const TimeFootprintPlaybackPage({super.key});

  @override
  State<TimeFootprintPlaybackPage> createState() => _TimeFootprintPlaybackPageState();
}

class _TimeFootprintPlaybackPageState extends State<TimeFootprintPlaybackPage> {
  static const dataChannel = MethodChannel('com.footprint/data');
  MethodChannel? _mapChannel;
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  List<dynamic> _allEntries = [];
  List<dynamic> _filteredEntries = [];
  bool _isLoading = true;
  double _totalDistance = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final String jsonStr = await dataChannel.invokeMethod('getAllEntries');
      if (!mounted) return;
      setState(() {
        _allEntries = jsonDecode(jsonStr);
      });
      _filterData();
    } catch (e) {
      debugPrint("Failed to load map entries: $e");
    }
  }

  Future<void> _filterData() async {
    setState(() { _isLoading = true; });
    final startStr = "${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}";
    final endStr = "${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}";
    
    _filteredEntries = _allEntries.where((e) {
      final d = e['happenedOn'] as String?;
      if (d == null) return false;
      return d.compareTo(startStr) >= 0 && d.compareTo(endStr) <= 0;
    }).toList();
    
    _totalDistance = 0.0;
    for (var e in _filteredEntries) {
      _totalDistance += (e['distanceKm'] as num?)?.toDouble() ?? 0.0;
    }

    try {
      final startMs = DateTime(_startDate.year, _startDate.month, _startDate.day).millisecondsSinceEpoch;
      final endMs = DateTime(_endDate.year, _endDate.month, _endDate.day).add(const Duration(days: 1)).millisecondsSinceEpoch;
      final String trackJson = await dataChannel.invokeMethod('getTrackPoints', {'startTime': startMs, 'endTime': endMs});
      final List<dynamic> tracks = jsonDecode(trackJson);
      
      _mapChannel?.invokeMethod('setEntries', _filteredEntries);
      _mapChannel?.invokeMethod('setTrackingPath', tracks.map((t) => {
        'lat': (t['latitude'] as num?)?.toDouble(),
        'lng': (t['longitude'] as num?)?.toDouble(),
        'speed': (t['speed'] as num?)?.toDouble() ?? 0.0,
      }).toList());
      
      // Auto center to the first point of the track or entry
      if (tracks.isNotEmpty) {
        _mapChannel?.invokeMethod('centerLocation', {
          'latitude': (tracks.first['latitude'] as num?)?.toDouble(),
          'longitude': (tracks.first['longitude'] as num?)?.toDouble(),
          'zoom': 13.0
        });
      } else if (_filteredEntries.isNotEmpty) {
        final entry = _filteredEntries.firstWhere((e) => e['latitude'] != null, orElse: () => null);
        if (entry != null) {
          _mapChannel?.invokeMethod('centerLocation', {
            'latitude': (entry['latitude'] as num?)?.toDouble(),
            'longitude': (entry['longitude'] as num?)?.toDouble(),
            'zoom': 13.0
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to load track points: $e");
    }
    
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  void _onMapCreated(int id) {
    _mapChannel = MethodChannel('com.footprint/amap_$id');
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    _mapChannel?.invokeMethod('setTheme', isDark);
    _mapChannel?.invokeMethod('setMapMode', "STANDARD"); // or FOG
    // after map created, apply the filtered data immediately if available
    _mapChannel?.invokeMethod('setEntries', _filteredEntries);
    _filterData(); // trigger re-fetch and apply
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('zh'),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
        if (_startDate.isAfter(_endDate)) {
          _startDate = _endDate;
        }
      });
      _filterData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final df = "${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}";
    final dt = "${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('时光足迹回放', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cs.surface,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Time Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text("起始: $df", style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text("结束: $dt", style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Map View
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  NativeMapView(onCreated: _onMapCreated),
                  if (_isLoading)
                    Container(
                      color: cs.surface.withValues(alpha: 0.5),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("区间总里程", style: TextStyle(color: cs.outline, fontSize: 12)),
                                Text("${_totalDistance.toStringAsFixed(3)} km", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("区间足迹篇数", style: TextStyle(color: cs.outline, fontSize: 12)),
                                Text("${_filteredEntries.length} 篇", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          // Footprint List (BottomSheet-like)
          Expanded(
            flex: 4,
            child: Container(
              color: cs.surface,
              child: ListView.builder(
                itemCount: _filteredEntries.length,
                itemBuilder: (context, index) {
                  final e = _filteredEntries[index];
                  final dist = (e['distanceKm'] as num?)?.toDouble() ?? 0.0;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Icon(Icons.location_on, color: cs.primary, size: 20),
                    ),
                    title: Text(e['title'] ?? '未知记录', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Builder(
                      builder: (context) {
                        String loc = e['location'] ?? '未知地点';
                        final coordRegex = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)');
                        final match = coordRegex.firstMatch(loc);
                        if (match != null) {
                          try {
                            double lat = double.parse(match.group(1)!);
                            double lng = double.parse(match.group(2)!);
                            loc = "${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}";
                          } catch (_) {}
                        }
                        return Text("${e['happenedOn'] ?? ''} · $loc", maxLines: 1, overflow: TextOverflow.ellipsis);
                      }
                    ),
                    trailing: Text("${dist.toStringAsFixed(3)} km", style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
                    onTap: () {
                      if (e['latitude'] != null) {
                         _mapChannel?.invokeMethod('centerLocation', {
                           'latitude': (e['latitude'] as num?)?.toDouble(),
                           'longitude': (e['longitude'] as num?)?.toDouble(),
                           'zoom': 16.0
                         });
                      }
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FootprintDetailPage(entry: e)));
                    }
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
