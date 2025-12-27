import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/custom_exercise_model.dart';
import '../../../utils/translation_helper.dart';
import 'custom_exercise_id_generator.dart';

/// 自訂動作資料庫操作
class CustomExerciseOperations {
  final SupabaseClient _supabase;
  final Function(String) _logDebug;
  final int _queryTimeout;

  CustomExerciseOperations({
    required SupabaseClient supabase,
    required Function(String) logDebug,
    required int queryTimeout,
  })  : _supabase = supabase,
        _logDebug = logDebug,
        _queryTimeout = queryTimeout;

  /// 創建自訂動作
  Future<CustomExercise> createCustomExercise({
    required String userId,
    required String name,
    required String trainingType,
    required String bodyPart,
    String equipment = '徒手',
    String description = '',
    String notes = '',
  }) async {
    _logDebug('創建新的自定義動作: $name (類型: $trainingType, 部位: $bodyPart, 器材: $equipment)');

    final id = CustomExerciseIdGenerator.generate();
    
    // 自動填充英文欄位
    final trainingTypeEn = TranslationHelper.getTrainingTypeEn(trainingType);
    final bodyPartEn = TranslationHelper.getBodyPartEn(bodyPart);
    final equipmentEn = TranslationHelper.getEquipmentEn(equipment);

    final response = await _supabase
        .from('custom_exercises')
        .insert({
          'id': id,
          'user_id': userId,
          'name': name,
          'training_type': trainingType,
          'training_type_en': trainingTypeEn,
          'body_part': bodyPart,
          'body_part_en': bodyPartEn,
          'equipment': equipment,
          'equipment_en': equipmentEn,
          'description': description,
          'notes': notes,
        })
        .select()
        .single()
        .timeout(
          Duration(seconds: _queryTimeout),
          onTimeout: () => throw TimeoutException('添加自定義動作超時'),
        );

    final newExercise = CustomExercise.fromSupabase(response);
    _logDebug('自定義動作創建成功: ${newExercise.id}');
    return newExercise;
  }

  /// 獲取用戶自訂動作列表
  Future<List<CustomExercise>> getUserCustomExercises(String userId) async {
    _logDebug('從 Supabase 獲取自定義動作');

    final response = await _supabase
        .from('custom_exercises')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .timeout(
          Duration(seconds: _queryTimeout),
          onTimeout: () => throw TimeoutException('獲取自定義動作列表超時'),
        );

    final exercises = (response as List)
        .map((data) => CustomExercise.fromSupabase(data))
        .toList();

    _logDebug('成功獲取 ${exercises.length} 個自定義動作');
    return exercises;
  }

  /// 更新自訂動作
  Future<void> updateCustomExercise({
    required String userId,
    required String exerciseId,
    String? name,
    String? trainingType,
    String? bodyPart,
    String? equipment,
    String? description,
    String? notes,
  }) async {
    _logDebug('更新自定義動作: $exerciseId');

    // 建立更新資料（包含雙語欄位）
    final Map<String, dynamic> updateData = {};
    if (name != null) updateData['name'] = name;
    if (trainingType != null) {
      updateData['training_type'] = trainingType;
      updateData['training_type_en'] = TranslationHelper.getTrainingTypeEn(trainingType);
    }
    if (bodyPart != null) {
      updateData['body_part'] = bodyPart;
      updateData['body_part_en'] = TranslationHelper.getBodyPartEn(bodyPart);
    }
    if (equipment != null) {
      updateData['equipment'] = equipment;
      updateData['equipment_en'] = TranslationHelper.getEquipmentEn(equipment);
    }
    if (description != null) updateData['description'] = description;
    if (notes != null) updateData['notes'] = notes;

    if (updateData.isEmpty) {
      _logDebug('沒有需要更新的欄位');
      return;
    }

    await _supabase
        .from('custom_exercises')
        .update(updateData)
        .eq('id', exerciseId)
        .eq('user_id', userId)
        .timeout(
          Duration(seconds: _queryTimeout),
          onTimeout: () => throw TimeoutException('更新自定義動作超時'),
        );

    _logDebug('自定義動作更新成功');
  }

  /// 刪除自訂動作
  Future<void> deleteCustomExercise(String userId, String exerciseId) async {
    _logDebug('刪除自定義動作: $exerciseId');

    await _supabase
        .from('custom_exercises')
        .delete()
        .eq('id', exerciseId)
        .eq('user_id', userId)
        .timeout(
          Duration(seconds: _queryTimeout),
          onTimeout: () => throw TimeoutException('刪除自定義動作超時'),
        );

    _logDebug('自定義動作刪除成功');
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

