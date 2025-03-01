import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_cache_service.dart';
import '../models/exercise_model.dart';

class PreloadService {
  static Future<void> preloadCommonData() async {
    try {
      // 預加載所有運動類型 - 直接從Firestore獲取並利用內建緩存
      await FirebaseFirestore.instance.collection('exerciseTypes').get();
      
      // 預加載所有身體部位 - 直接從Firestore獲取並利用內建緩存
      await FirebaseFirestore.instance.collection('bodyParts').get();
      
      // 預加載一些常用的運動數據
      final typesSnapshot = await FirebaseFirestore.instance.collection('exerciseTypes').get();
      final types = typesSnapshot.docs.map((doc) => doc['name'] as String).toList();
      
      // 只加載前3個類型的運動數據
      for (var type in types.take(3)) {
        await FirebaseFirestore.instance
            .collection('exercise')
            .where('type', isEqualTo: type)
            .limit(20)
            .get(); // Firebase會自動緩存這些查詢結果
      }
    } catch (e) {
      print('預加載數據失敗: $e');
    }
  }
} 