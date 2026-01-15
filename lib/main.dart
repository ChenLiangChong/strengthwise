import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'views/pages/startup/splash_screen.dart';
import 'services/service_locator.dart';
import 'services/core/supabase_service.dart';
import 'services/core/deep_link_service.dart';
import 'services/core/theme_service.dart';
import 'services/core/network_status_service.dart';
import 'views/widgets/offline_banner.dart';
import 'services/interfaces/i_notification_service.dart'; // 基礎設施服務，保留
import 'controllers/interfaces/i_auth_controller.dart'; // ⭐ v3.6: MVVM
import 'controllers/interfaces/i_statistics_controller.dart'; // ⭐ v3.6: MVVM
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

  // ⚡ 並行初始化 Supabase + Hive（兩者互不依賴）
  await Future.wait([
    SupabaseService.initialize(),
    _initializeHive(),
  ]);

  // ⚡ 初始化 Deep Link 服務（處理 Email 確認連結）
  await DeepLinkService.instance.initialize();

  // 設置環境（同步）
  setEnvironment(Environment.development);

  // ⚡ 只註冊服務（不初始化，延遲到實際使用時）
  await setupServiceLocator(lazyInit: true);
}

/// ⚡ 初始化 Hive 並提前打開所有 Box
///
/// 讓 LocalCacheService 首次訪問時 Box 已經開啟，不需等待
Future<void> _initializeHive() async {
  try {
    final startTime = DateTime.now();

    // 初始化 Hive
    await Hive.initFlutter();

    // ⚡ 並行打開所有 Box（只開不讀，極快）
    await Future.wait([
      Hive.openBox('user_cache'),
      Hive.openBox('relationship_cache'),
      Hive.openBox('statistics_cache'),
      Hive.openBox('workout_plan_cache'),
      Hive.openBox('exercise_cache'),
      Hive.openBox('onboarding_status'), // ⭐ v3.2: Onboarding 狀態
    ]);

    final duration = DateTime.now().difference(startTime);
    if (kDebugMode) {
      print('[MAIN] ✅ Hive 初始化完成（${duration.inMilliseconds}ms）');
    }
  } catch (e) {
    if (kDebugMode) {
      print('[MAIN] ⚠️ Hive 初始化失敗: $e');
    }
    // Hive 失敗不影響 App 啟動，降級為無本地快取模式
  }
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

      // ⚡ 標記服務就緒（通知 SplashScreen）
      markServiceReady();

      // ⚡ 提前預熱統計快取（不阻塞，背景執行）
      _warmupStatisticsCache();

      // ⚡ 預熱 GoogleFonts（避免首次使用時下載延遲）
      _warmupGoogleFonts();

      // ⚡ FCM 推播初始化（v3.0-C）
      await _initializeFCM();

      // ⚡ v3.1.1: 網路狀態服務初始化
      await NetworkStatusService().initialize();
    } catch (e) {
      print('[MAIN] ⚠️ 背景服務初始化失敗: $e');
      // 即使初始化失敗，也標記就緒讓 App 繼續（降級模式）
      markServiceReady();
    }
  });
}

/// ⚡ 預熱 GoogleFonts
///
/// 在背景預載入 Inter 字體，避免首次渲染時閃爍
void _warmupGoogleFonts() {
  try {
    // 預熱 Inter 字體（App 主字體）
    GoogleFonts.pendingFonts([
      GoogleFonts.inter(),
    ]);

    if (kDebugMode) {
      print('[MAIN] ✅ GoogleFonts 預熱完成');
    }
  } catch (e) {
    if (kDebugMode) {
      print('[MAIN] ⚠️ GoogleFonts 預熱失敗: $e');
    }
  }
}

/// ⚡ 提前預熱統計快取
///
/// 從 Hive 載入統計數據到記憶體
/// 讓用戶進入統計頁面時不需等待
/// ⭐ v3.6: MVVM 重構 - 透過 Controller
void _warmupStatisticsCache() {
  // 不 await，讓它在背景執行
  Future.microtask(() async {
    try {
      final authController = serviceLocator<IAuthController>();
      if (!authController.isLoggedIn) {
        if (kDebugMode) {
          print('[MAIN] ⏭️ 統計預熱跳過（用戶未登入）');
        }
        return;
      }

      final userId = authController.user?.uid;
      if (userId == null) return;

      final statisticsController = serviceLocator<IStatisticsController>();
      await statisticsController.warmupFromLocalCache(userId);

      if (kDebugMode) {
        print('[MAIN] ✅ 統計快取預熱完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[MAIN] ⚠️ 統計快取預熱失敗: $e');
      }
    }
  });
}

/// ⚡ 初始化 FCM 推播通知（v3.0-C）
///
/// 1. 初始化 NotificationService
/// 2. 如果用戶已登入，自動保存 FCM Token
/// 3. 設置 Token 變化監聽
Future<void> _initializeFCM() async {
  try {
    // 只在 Android/iOS 上初始化
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (kDebugMode) {
        print('[MAIN] ⏭️ FCM 跳過（非 Android/iOS 平台）');
      }
      return;
    }

    final notificationService = serviceLocator<INotificationService>();
    await notificationService.initialize();

    // ⭐ v3.6: MVVM 重構 - 透過 Controller 檢查登入狀態
    final authController = serviceLocator<IAuthController>();
    final isLoggedIn = authController.isLoggedIn;

    if (kDebugMode) {
      print('[MAIN] 🔍 FCM 檢查：isLoggedIn=$isLoggedIn');
    }

    if (isLoggedIn) {
      final userId = authController.user?.uid;

      if (kDebugMode) {
        print('[MAIN] 🔍 FCM 用戶：userId=$userId');
      }

      if (userId != null) {
        final token = await notificationService.getToken();

        if (kDebugMode) {
          print('[MAIN] 🔍 FCM Token：${token?.substring(0, 20)}...');
        }

        if (token != null) {
          final platform = Platform.isAndroid ? 'android' : 'ios';
          await notificationService.saveTokenToDatabase(
            userId,
            token,
            platform: platform,
          );
          notificationService.listenForTokenChanges(userId);

          if (kDebugMode) {
            print('[MAIN] ✅ FCM Token 已保存 (user: $userId)');
          }
        } else {
          if (kDebugMode) {
            print('[MAIN] ⚠️ FCM Token 為 null');
          }
        }
      } else {
        if (kDebugMode) {
          print('[MAIN] ⚠️ userId 為 null');
        }
      }
    } else {
      if (kDebugMode) {
        print('[MAIN] ⏭️ FCM Token 跳過（用戶未登入）');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('[MAIN] ⚠️ FCM 初始化失敗: $e');
    }
  }
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

          // 獲取系統亮度以支援 system 模式
          final platformBrightness = MediaQuery.platformBrightnessOf(context);

          // 根據 AppThemeMode 獲取對應的 ThemeData
          final currentTheme = themeController.isInitialized
              ? themeController.getThemeData(platformBrightness)
              : _buildLightTheme();

          return MaterialApp(
            title: 'StrengthWise',
            debugShowCheckedModeBanner: false,

            // ========================================
            // Kinetic 設計系統主題（支援粉色主題 🌸）
            // ========================================
            // 使用單一 theme 屬性，由 ThemeController 決定主題
            theme: _applyGoogleFonts(currentTheme),
            // 不使用 themeMode，因為我們有自訂的 AppThemeMode

            // ========================================
            // 無障礙字體縮放限制 + 全局離線提示
            // ========================================
            // 限制系統字體縮放範圍（0.85x - 1.35x）
            // 既尊重無障礙需求，又防止極端縮放破壞佈局
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final clampedTextScaler = mediaQuery.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.35,
              );
              return MediaQuery(
                data: mediaQuery.copyWith(textScaler: clampedTextScaler),
                // ⚡ v3.1.1: 全局離線提示 Banner
                child: OfflineBanner(child: child!),
              );
            },

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

  /// 應用 Google Fonts 到任意主題
  ///
  /// 通用方法，可用於 Light、Dark、Rose 等任何主題
  ThemeData _applyGoogleFonts(ThemeData baseTheme) {
    return baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
          color: baseTheme.colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: baseTheme.colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: baseTheme.colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: baseTheme.colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: baseTheme.colorScheme.onSurface,
        ),
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
