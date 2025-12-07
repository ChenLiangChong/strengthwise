import 'package:flutter/material.dart';
import 'dart:async';
import '../controllers/interfaces/i_auth_controller.dart';
import '../services/service_locator.dart';
import 'login_page.dart';
import 'main_home_page.dart';

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
    
    // 從服務定位器獲取 AuthController
    _authController = serviceLocator<IAuthController>();
    
    // 延遲3秒後檢查登入狀態並跳轉
    Timer(const Duration(seconds: 3), () {
      if (_authController.isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainHomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 您可以使用自己的Logo图片
            FlutterLogo(size: 100),
            SizedBox(height: 30),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('歡迎使用', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
} 