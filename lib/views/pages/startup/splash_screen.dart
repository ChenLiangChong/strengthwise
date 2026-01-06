import 'package:flutter/material.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/auth/login_page.dart';
import 'package:strengthwise/views/pages/home/main_home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final IAuthController _authController;

  @override
  void initState() {
    super.initState();

    // ⚡ 超級優化：立即嘗試導航，不等待 3 秒
    _navigateToNextScreen();
  }

  /// ⚡ 立即導航到下一個畫面（等待服務就緒）
  Future<void> _navigateToNextScreen() async {
    // 等待一幀渲染（確保 Splash 畫面顯示）
    await Future.delayed(const Duration(milliseconds: 100));

    // ⚡ 等待服務定位器初始化（最多 2 秒）
    int retries = 0;
    while (retries < 20) {
      try {
        _authController = serviceLocator<IAuthController>();
        break;
      } catch (e) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }
    }

    if (!mounted) return;

    // 檢查登入狀態並導航
    try {
      if (_authController.isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainHomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      // 最終失敗，預設進入登入頁
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 根據系統主題決定背景色（符合 UI/UX 規範）
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? const Color(0xFF0F172A) // 深色模式：Deep Slate
        : const Color(0xFFF1F5F9); // 淺色模式：Slate 50

    return Scaffold(
      backgroundColor: backgroundColor,
      body: const SizedBox.shrink(), // 空白，讓原生 Splash 保持顯示
    );
  }
}
