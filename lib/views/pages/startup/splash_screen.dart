import 'package:flutter/material.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/themes/app_theme.dart';
import 'package:strengthwise/views/pages/auth/login_page.dart';
import 'package:strengthwise/views/pages/home/main_home_page.dart';
import 'package:strengthwise/views/pages/profile/profile_settings_page.dart'; // ⭐ v3.4

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // ⚡ v3.1.1 超級優化：立即嘗試導航
    _navigateToNextScreen();
  }

  /// ⚡ v3.1.1: 積極導航策略
  ///
  /// 1. 立即嘗試取得 AuthController（通常已註冊）
  /// 2. 如果成功，立即跳轉（不等待其他服務）
  /// 3. 如果失敗，等待服務就緒後重試（最多 1.5 秒）
  Future<void> _navigateToNextScreen() async {
    // 等待一幀渲染（確保原生 Splash 過渡自然）
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    // ⚡ 第一次嘗試：立即導航（如果 Auth 已就緒）
    if (await _tryNavigate()) {
      debugPrint('[SPLASH] ⚡ 立即導航成功');
      return;
    }

    // ⚡ 效能優化：延長超時到 3 秒，避免網路慢時導航失敗
    debugPrint('[SPLASH] ⏳ 等待服務就緒...');
    try {
      await waitForServiceReady().timeout(
        const Duration(milliseconds: 3000),
        onTimeout: () {
          debugPrint('[SPLASH] ⚠️ 服務就緒超時，嘗試繼續');
        },
      );
    } catch (e) {
      debugPrint('[SPLASH] ⚠️ 等待服務就緒失敗: $e');
    }

    if (!mounted) return;

    // ⚡ 第二次嘗試：服務應該已就緒
    if (await _tryNavigate()) {
      debugPrint('[SPLASH] ✅ 服務就緒後導航成功');
      return;
    }

    if (!mounted) return;

    // 最終失敗，預設進入登入頁
    debugPrint('[SPLASH] ⚠️ 導航失敗，預設進入登入頁');
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// 嘗試導航到下一個畫面
  ///
  /// 返回 true 表示成功導航，false 表示需要重試
  /// ⭐ v3.4: 改為異步，加入 isProfileCompleted 檢查（修復 Web 首次登入跳過設定問題）
  Future<bool> _tryNavigate() async {
    try {
      final authController = serviceLocator<IAuthController>();
      
      Widget targetPage;
      
      if (authController.isLoggedIn) {
        // ⭐ v3.6: MVVM 重構 - 透過 Controller 檢查
        final isProfileCompleted = await authController.isProfileCompleted();
        
        if (!isProfileCompleted) {
          // 首次登入，跳轉到個人資料設定頁面
          targetPage = const ProfileSettingsPage(isFirstTimeSetup: true);
          debugPrint('[SPLASH] 📝 首次登入，導向個人資料設定');
        } else {
          targetPage = const MainHomePage();
        }
      } else {
        targetPage = const LoginPage();
      }

      if (!mounted) return false;

      // ⚡ v3.1.1: 使用淡入淡出動畫，避免卡頓感
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetPage,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[SPLASH] ⚠️ 取得 AuthController 失敗: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根據系統主題決定背景色（符合 UI/UX 規範）
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? AppTheme.slate900 // 深色模式：Deep Slate
        : AppTheme.slate100; // 淺色模式：Slate 100

    return Scaffold(
      backgroundColor: backgroundColor,
      body: const SizedBox.shrink(), // 空白，讓原生 Splash 保持顯示
    );
  }
}
