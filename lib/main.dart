import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'views/splash_screen.dart';
import 'services/service_locator.dart';
import 'controllers/workout_execution_controller.dart';
import 'controllers/interfaces/i_workout_execution_controller.dart';

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
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text('應用初始化失敗',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(e.toString(),
                        style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
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
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strength Wise',
      theme: ThemeData(
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}