import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'views/splash_screen.dart';
import 'services/service_locator.dart';
import 'services/supabase_service.dart';
import 'services/theme_service.dart';
import 'controllers/theme_controller.dart';
import 'themes/app_theme.dart';

/// 應用程式入口
void main() {
  // 在統一的 Zone 內運行應用，捕獲全局錯誤
  runZonedGuarded(() async {
    // 確保Flutter引擎初始化
    WidgetsFlutterBinding.ensureInitialized();

    // 初始化日期格式化
    await initializeDateFormatting('zh_TW', null);
    await initializeDateFormatting('en_US', null);
    Intl.defaultLocale = 'zh_TW';
    print('日期格式化初始化成功');

    try {
      // 嘗試初始化 Firebase，使用 try-catch 來捕獲重複初始化錯誤
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase 初始化成功');
      } catch (e) {
        // 忽略已存在的 Firebase 應用實例錯誤
        if (e.toString().contains('core/duplicate-app')) {
          print('Firebase 已經初始化，繼續執行');
        } else {
          // 其他錯誤則重新拋出
          rethrow;
        }
      }

      // 初始化 Supabase（用於動作庫等靜態資料）
      try {
        await SupabaseService.initialize();
        print('Supabase 初始化成功');
      } catch (e) {
        print('Supabase 初始化失敗: $e');
        // Supabase 初始化失敗不阻止應用啟動（可以繼續使用 Firebase）
      }

      // 設置環境和初始化服務定位器
      setEnvironment(Environment.development);
      await setupServiceLocator();

      // 啟動應用
      runApp(const MyApp());
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
          // 等待主題載入完成
          if (!themeController.isInitialized) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'StrengthWise',
            debugShowCheckedModeBanner: false,

            // ========================================
            // Kinetic 設計系統主題
            // ========================================
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeController.themeMode,

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
