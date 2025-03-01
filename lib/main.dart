import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/main_home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// 檢查是否有應用實例需要刪除
Future<void> _checkAndDeleteFirebaseApp() async {
  try {
    final List<FirebaseApp> apps = Firebase.apps;
    for (var app in apps) {
      await app.delete();
      print('已刪除 Firebase 應用: ${app.name}');
    }
  } catch (e) {
    print('刪除應用失敗: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 先刪除所有現有的 Firebase 應用實例
  await _checkAndDeleteFirebaseApp();
  
  // 清理後再重新初始化 Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase 初始化成功');
    
    // 配置 Firestore 緩存
    FirebaseFirestore.instance.settings = 
      const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
  } catch (e) {
    print('Firebase 初始化失敗: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Strengthwise',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainHomePage(),
    );
  }
}