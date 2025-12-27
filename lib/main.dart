import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/splash_screen.dart';
import 'services/service_locator.dart';
import 'services/core/supabase_service.dart';
import 'services/core/theme_service.dart';
import 'controllers/theme_controller.dart';
import 'themes/app_theme.dart';

/// 應用程式入口
void main() {
  // 在統一的 Zone 內運行應用，捕獲全局錯誤
  runZonedGuarded(() async {
    // 確保Flutter引擎初始化
    WidgetsFlutterBinding.ensureInitialized();

    // ⚡ 優化：將耗時操作移到後台，避免阻塞主線程
    try {
      // 1. 快速初始化：只做關鍵操作（Supabase + 服務註冊）
      await _quickInitialization();

      // 2. 啟動應用（先顯示 UI）
      runApp(const MyApp());

      // 3. 背景初始化：耗時服務在背景載入
      _backgroundInitialization();
    } catch (e) {
      print('初始化失敗: $e');
      // 顯示錯誤並退出
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text('應用初始化失敗',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(e.toString(),
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }, (error, stack) {
    // 處理異步錯誤
    print('未捕獲的異常: $error');
    print('堆疊: $stack');
  });
}

/// ⚡ 快速初始化（<100ms）
///
/// 只初始化啟動應用必需的服務
Future<void> _quickInitialization() async {
  // 日期格式化（同步，很快）
  await initializeDateFormatting('zh_TW', null);
  await initializeDateFormatting('en_US', null);
  Intl.defaultLocale = 'zh_TW';

  // ⚡ Supabase 必須在這裡初始化（AuthService 依賴它）
  await SupabaseService.initialize();

  // 設置環境（同步）
  setEnvironment(Environment.development);

  // ⚡ 只註冊服務（不初始化，延遲到實際使用時）
  await setupServiceLocator(lazyInit: true);
}

/// ⚡ 背景初始化（不阻塞 UI）
///
/// 在應用啟動後背景載入耗時服務
void _backgroundInitialization() {
  // 使用 Future.microtask 確保在下一個事件循環執行
  Future.microtask(() async {
    try {
      // 背景載入認證、預約、運動服務
      await setupServiceLocator(lazyInit: false);
      print('[MAIN] ✅ 背景服務初始化完成');
    } catch (e) {
      print('[MAIN] ⚠️ 背景服務初始化失敗: $e');
    }
  });
}

/// 應用主類
///
/// 使用 ChangeNotifierProvider 管理主題狀態
/// 整合 Kinetic 設計系統（Titanium Blue 配色方案）
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeController(ThemeService()),
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          // ⚡ 優化：不等待主題載入，使用默認主題先渲染 UI
          // 主題載入完成後會自動更新
          return MaterialApp(
            title: 'StrengthWise',
            debugShowCheckedModeBanner: false,

            // ========================================
            // Kinetic 設計系統主題
            // ========================================
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeController.isInitialized
                ? themeController.themeMode
                : ThemeMode.light, // 默認使用淺色主題

            // ========================================
            // 首頁
            // ========================================
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  /// 構建淺色主題
  ///
  /// 整合 Google Fonts（Inter）與 Kinetic 設計系統
  ThemeData _buildLightTheme() {
    final baseTheme = AppTheme.lightTheme;

    return baseTheme.copyWith(
      // 應用 Inter 字體到整個主題
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        // Display Large - 用於總訓練量、PR 慶祝
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
          color: baseTheme.colorScheme.onSurface,
        ),
        // Headline Medium - 用於頁面標題
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: baseTheme.colorScheme.onSurface,
        ),
        // Title Medium - 用於動作名稱卡片標題
        titleMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: baseTheme.colorScheme.onSurface,
        ),
        // Body Large - 用於一般說明文字
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: baseTheme.colorScheme.onSurface,
        ),
        // Body Medium - 用於列表次要資訊
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: baseTheme.colorScheme.onSurface,
        ),
        // Label Large - 用於按鈕文字
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
          color: baseTheme.colorScheme.onSurface,
        ),
      ),
    );
  }

  /// 構建深色主題
  ///
  /// 整合 Google Fonts（Inter）與 Kinetic 設計系統
  ThemeData _buildDarkTheme() {
    final baseTheme = AppTheme.darkTheme;

    return baseTheme.copyWith(
      // 應用 Inter 字體到整個主題
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        // Display Large
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
          color: baseTheme.colorScheme.onSurface,
        ),
        // Headline Medium
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: baseTheme.colorScheme.onSurface,
        ),
        // Title Medium
        titleMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: baseTheme.colorScheme.onSurface,
        ),
        // Body Large
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: baseTheme.colorScheme.onSurface,
        ),
        // Body Medium
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: baseTheme.colorScheme.onSurface,
        ),
        // Label Large
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.25,
          color: baseTheme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
