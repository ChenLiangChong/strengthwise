import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// 創建測試模板的腳本
/// 運行方式：dart run scripts/create_test_template.dart
Future<void> main() async {
  print('初始化 Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  // ⚠️ 請替換為你的實際 userId
  const userId = 'UmtFu02WQ4QUoTV3x6AFRbd1ov52';
  
  print('創建測試模板...');
  
  final templateData = {
    'userId': userId,
    'title': '測試模板 - 增肌計畫',
    'description': '這是一個測試模板，包含基本的增肌訓練動作',
    'planType': '力量訓練',
    'exercises': [
      {
        'exerciseId': 'squat',
        'exerciseName': '深蹲',
        'sets': [
          {'setNumber': 1, 'reps': 10, 'weight': 60.0, 'restTime': 90},
          {'setNumber': 2, 'reps': 10, 'weight': 60.0, 'restTime': 90},
          {'setNumber': 3, 'reps': 10, 'weight': 60.0, 'restTime': 90},
        ],
      },
      {
        'exerciseId': 'bench_press',
        'exerciseName': '臥推',
        'sets': [
          {'setNumber': 1, 'reps': 10, 'weight': 40.0, 'restTime': 90},
          {'setNumber': 2, 'reps': 10, 'weight': 40.0, 'restTime': 90},
          {'setNumber': 3, 'reps': 10, 'weight': 40.0, 'restTime': 90},
        ],
      },
    ],
    'trainingTime': Timestamp.fromDate(DateTime(2024, 12, 22, 10, 0)),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  try {
    final docRef = await firestore.collection('workoutTemplates').add(templateData);
    print('✅ 測試模板創建成功！');
    print('   文檔 ID: ${docRef.id}');
    print('   用戶 ID: $userId');
    print('   模板名稱: ${templateData['title']}');
    print('\n現在你可以在 Firebase Console 看到 workoutTemplates 集合了！');
  } catch (e) {
    print('❌ 創建失敗: $e');
  }
}

