import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_template_model.dart';
import '../models/workout_exercise_model.dart';

/// 默認訓練模板服務
/// 
/// 為新用戶自動創建一周專業訓練模板
class DefaultTemplatesService {
  final FirebaseFirestore _firestore;
  
  DefaultTemplatesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// 為新用戶創建默認訓練模板
  Future<void> createDefaultTemplatesForUser(String userId) async {
    try {
      _logDebug('開始為用戶創建默認模板: $userId');
      
      // 檢查用戶是否已有模板
      final existingTemplates = await _firestore
          .collection('workoutTemplates')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (existingTemplates.docs.isNotEmpty) {
        _logDebug('用戶已有模板，跳過創建');
        return;
      }
      
      // 創建一周訓練模板
      final templates = _generateWeeklyTemplates(userId);
      
      // 批量寫入 Firestore
      final batch = _firestore.batch();
      
      for (var template in templates) {
        final docRef = _firestore.collection('workoutTemplates').doc();
        batch.set(docRef, template.toFirestore());
      }
      
      await batch.commit();
      
      _logDebug('成功創建 ${templates.length} 個默認模板');
    } catch (e) {
      _logError('創建默認模板失敗: $e');
      // 不拋出錯誤，避免影響用戶註冊流程
    }
  }
  
  /// 生成一周訓練模板（週一到週五）
  List<WorkoutTemplate> _generateWeeklyTemplates(String userId) {
    return [
      _createChestTricepsTemplate(userId),  // Day 1: 胸 + 三頭
      _createBackBicepsTemplate(userId),    // Day 2: 背 + 二頭  
      _createLegsSquatTemplate(userId),     // Day 3: 腿部（深蹲）
      _createShouldersTemplate(userId),     // Day 4: 肩部
      _createLegsDeadliftTemplate(userId),  // Day 5: 腿部（硬舉）
    ];
  }
  
  /// Day 1: 胸部 + 三頭肌
  WorkoutTemplate _createChestTricepsTemplate(String userId) {
    return WorkoutTemplate(
      id: '',
      userId: userId,
      title: '胸部 + 三頭肌訓練',
      description: '使用槓鈴、啞鈴和機械進行胸部與三頭肌訓練',
      planType: '力量訓練',
      exercises: [
        WorkoutExercise(
          id: 'ex_1',
          exerciseId: '3zsvNeYy7QC4NNbfB8Cf',
          name: '推／胸推／地板臥推／槓鈴，推舉',
          actionName: '槓鈴臥推',
          equipment: '槓鈴',
          bodyParts: ['胸部', '三頭肌', '肩部'],
          sets: 4,
          reps: 10,
          weight: 60.0,
          restTime: 90,
          notes: '主要胸部訓練，注意肩胛骨後收',
        ),
        WorkoutExercise(
          id: 'ex_2',
          exerciseId: '5yNv0j7fdFEEpuLpA1x5',
          name: '推／胸推／地板臥推／啞鈴，交替推舉',
          actionName: '上斜啞鈴推舉',
          equipment: '啞鈴',
          bodyParts: ['胸部上側', '三頭肌', '肩部'],
          sets: 4,
          reps: 10,
          weight: 22.0,
          restTime: 90,
          notes: '重點訓練上胸',
        ),
        WorkoutExercise(
          id: 'ex_3',
          exerciseId: '6hvpsp4UIyWptRYJYL2l',
          name: '推／肩推／直立式，彈力繩／單手',
          actionName: '肩推',
          equipment: '彈力繩',
          bodyParts: ['肩部', '三頭肌'],
          sets: 3,
          reps: 12,
          weight: 18.0,
          restTime: 60,
          notes: '輔助動作',
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Day 2: 背部 + 二頭肌
  WorkoutTemplate _createBackBicepsTemplate(String userId) {
    return WorkoutTemplate(
      id: '',
      userId: userId,
      title: '背部 + 二頭肌訓練',
      description: '使用槓鈴、啞鈴進行背部與二頭肌訓練',
      planType: '力量訓練',
      exercises: [
        WorkoutExercise(
          id: 'ex_1',
          exerciseId: 'Eh6KPbv5fzn1kVlnmIVl',
          name: 'TRX/引體向上',
          actionName: '引體向上',
          equipment: 'TRX/單槓',
          bodyParts: ['背闊肌', '二頭肌'],
          sets: 4,
          reps: 8,
          weight: 0.0,
          restTime: 120,
          notes: '主要背部訓練，使用助力帶如有需要',
        ),
        WorkoutExercise(
          id: 'ex_2',
          exerciseId: '0K1ohnKBkP3CBriDuwpx',
          name: '拉／划船系列／單足立／啞鈴划船，單臂／同側，寬距',
          actionName: '槓鈴划船',
          equipment: '啞鈴',
          bodyParts: ['背部', '斜方肌'],
          sets: 4,
          reps: 10,
          weight: 55.0,
          restTime: 90,
          notes: '保持背部挺直',
        ),
        WorkoutExercise(
          id: 'ex_3',
          exerciseId: '8WkB8x58YqYWHYorHJvE',
          name: '拉／二頭彎舉／肩前肘固定，半固定器材／單手',
          actionName: '二頭彎舉',
          equipment: '啞鈴',
          bodyParts: ['二頭肌'],
          sets: 3,
          reps: 12,
          weight: 20.0,
          restTime: 60,
          notes: '專注肌肉收縮',
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Day 3: 腿部訓練（深蹲日）
  WorkoutTemplate _createLegsSquatTemplate(String userId) {
    return WorkoutTemplate(
      id: '',
      userId: userId,
      title: '腿部訓練（深蹲日）',
      description: '以深蹲為主的下肢力量訓練',
      planType: '力量訓練',
      exercises: [
        WorkoutExercise(
          id: 'ex_1',
          exerciseId: '0cHIY1SKk1d4OYaQrA1t',
          name: '下肢／深蹲系列／單腳蹲／啞鈴，前舉，單側蹲',
          actionName: '深蹲',
          equipment: '啞鈴',
          bodyParts: ['股四頭肌', '臀部', '核心'],
          sets: 4,
          reps: 10,
          weight: 75.0,
          restTime: 120,
          notes: '主要腿部訓練，注意蹲至大腿平行地面',
        ),
        WorkoutExercise(
          id: 'ex_2',
          exerciseId: '37HfmVRA1CLMcLN8JrNh',
          name: '下肢／深蹲系列／跨側蹲／槓鈴，垂放，單側蹲',
          actionName: '腿推',
          equipment: '槓鈴',
          bodyParts: ['股四頭肌', '臀部'],
          sets: 3,
          reps: 12,
          weight: 110.0,
          restTime: 90,
          notes: '輔助訓練',
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Day 4: 肩部訓練
  WorkoutTemplate _createShouldersTemplate(String userId) {
    return WorkoutTemplate(
      id: '',
      userId: userId,
      title: '肩部專項訓練',
      description: '使用啞鈴和槓鈴進行肩部全面訓練',
      planType: '力量訓練',
      exercises: [
        WorkoutExercise(
          id: 'ex_1',
          exerciseId: '6hvpsp4UIyWptRYJYL2l',
          name: '推／肩推／直立式，彈力繩／單手',
          actionName: '肩推',
          equipment: '彈力繩',
          bodyParts: ['肩部', '三頭肌'],
          sets: 4,
          reps: 10,
          weight: 20.0,
          restTime: 90,
          notes: '主要肩部訓練',
        ),
        WorkoutExercise(
          id: 'ex_2',
          exerciseId: '6mMd1EMonuwNpujwiqlr',
          name: '推／肩推／倒立式',
          actionName: '側平舉',
          equipment: '啞鈴',
          bodyParts: ['肩部側面'],
          sets: 4,
          reps: 12,
          weight: 10.0,
          restTime: 60,
          notes: '雕塑肩部線條',
        ),
        WorkoutExercise(
          id: 'ex_3',
          exerciseId: '3zsvNeYy7QC4NNbfB8Cf',
          name: '推／胸推／地板臥推／槓鈴，推舉',
          actionName: '槓鈴臥推（輕重量）',
          equipment: '槓鈴',
          bodyParts: ['胸部', '三頭肌', '肩部'],
          sets: 3,
          reps: 12,
          weight: 50.0,
          restTime: 90,
          notes: '輔助訓練，使用較輕重量',
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Day 5: 腿部訓練（硬舉日）
  WorkoutTemplate _createLegsDeadliftTemplate(String userId) {
    return WorkoutTemplate(
      id: '',
      userId: userId,
      title: '腿部訓練（硬舉日）',
      description: '以硬舉為主的後鏈力量訓練',
      planType: '力量訓練',
      exercises: [
        WorkoutExercise(
          id: 'ex_1',
          exerciseId: '2DeZfox55TfdzMzO4TX2',
          name: '下肢／硬舉系列／直膝挺髖／雙腳／啞鈴，前舉',
          actionName: '硬舉',
          equipment: '啞鈴',
          bodyParts: ['背部', '腿部', '臀部'],
          sets: 4,
          reps: 8,
          weight: 90.0,
          restTime: 120,
          notes: '主要後鏈訓練，注意保持背部平直',
        ),
        WorkoutExercise(
          id: 'ex_2',
          exerciseId: '37HfmVRA1CLMcLN8JrNh',
          name: '下肢／深蹲系列／跨側蹲／槓鈴，垂放，單側蹲',
          actionName: '腿推',
          equipment: '槓鈴',
          bodyParts: ['股四頭肌', '臀部'],
          sets: 3,
          reps: 12,
          weight: 110.0,
          restTime: 90,
          notes: '輔助訓練',
        ),
        WorkoutExercise(
          id: 'ex_3',
          exerciseId: '8WkB8x58YqYWHYorHJvE',
          name: '拉／二頭彎舉／肩前肘固定，半固定器材／單手',
          actionName: '二頭彎舉',
          equipment: '啞鈴',
          bodyParts: ['二頭肌'],
          sets: 3,
          reps: 12,
          weight: 20.0,
          restTime: 60,
          notes: '手臂訓練',
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[DEFAULT_TEMPLATES] $message');
    }
  }
  
  /// 記錄錯誤信息
  void _logError(String message) {
    if (kDebugMode) {
      print('[DEFAULT_TEMPLATES ERROR] $message');
    }
  }
}

