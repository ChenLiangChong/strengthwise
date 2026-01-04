import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/health_assessment_models.dart';
import '../../../utils/datetime_utils.dart';

/// 健康評估操作管理器
/// 
/// 負責所有資料庫寫入操作（INSERT、UPDATE、DELETE）
class HealthAssessmentOperationsManager {
  final SupabaseClient _supabase;

  HealthAssessmentOperationsManager(this._supabase);

  /// 插入新評估
  /// 
  /// [assessment] 健康評估模型
  /// [setAsCurrent] 是否設為當前有效
  /// 
  /// 返回插入後的完整評估（包含自動生成的 id）
  Future<HealthAssessmentModel> insert(
    HealthAssessmentModel assessment, {
    bool setAsCurrent = true,
  }) async {
    // 如果要設為當前，先將舊的標記為非當前
    if (setAsCurrent) {
      await _markOthersAsNotCurrent(assessment.userId);
    }

    final data = assessment.toSupabase();
    data['is_current'] = setAsCurrent; // 確保正確設定

    final response = await _supabase
        .from('health_assessments')
        .insert(data)
        .select()
        .single();

    return HealthAssessmentModel.fromSupabase(response);
  }

  /// 更新評估
  /// 
  /// [assessment] 健康評估模型（必須包含 id）
  Future<void> update(HealthAssessmentModel assessment) async {
    final data = assessment.toSupabase();
    data['updated_at'] = DateTimeUtils.formatToUtcIso(DateTime.now());

    await _supabase
        .from('health_assessments')
        .update(data)
        .eq('id', assessment.id);
  }

  /// 刪除評估
  /// 
  /// [assessmentId] 評估 ID
  Future<void> delete(String assessmentId) async {
    await _supabase
        .from('health_assessments')
        .delete()
        .eq('id', assessmentId);
  }

  /// 將指定評估設為當前有效
  /// 
  /// [assessmentId] 評估 ID
  /// [userId] 學員 ID
  Future<void> setAsCurrent(String assessmentId, String userId) async {
    // 1. 將該學員的所有評估標記為非當前
    await _markOthersAsNotCurrent(userId);

    // 2. 將指定評估設為當前
    await _supabase
        .from('health_assessments')
        .update({
          'is_current': true,
          'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
        })
        .eq('id', assessmentId)
        .eq('user_id', userId); // 額外驗證學員 ID
  }

  /// 將指定學員的所有評估標記為非當前
  /// 
  /// [userId] 學員 ID
  Future<void> _markOthersAsNotCurrent(String userId) async {
    await _supabase
        .from('health_assessments')
        .update({
          'is_current': false,
          'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
        })
        .eq('user_id', userId)
        .eq('is_current', true); // 只更新當前為 true 的記錄
  }

  /// 批次更新評估的 is_current 狀態
  /// 
  /// [updates] Map<評估ID, 是否為當前>
  Future<void> batchUpdateCurrentStatus(Map<String, bool> updates) async {
    for (final entry in updates.entries) {
      await _supabase
          .from('health_assessments')
          .update({
            'is_current': entry.value,
            'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
          })
          .eq('id', entry.key);
    }
  }
}

