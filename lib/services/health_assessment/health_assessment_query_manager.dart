import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/health_assessment_models.dart';

/// 健康評估查詢管理器
/// 
/// 負責所有資料庫查詢操作
class HealthAssessmentQueryManager {
  final SupabaseClient _supabase;

  HealthAssessmentQueryManager(this._supabase);

  /// 查詢欄位（完整）
  static const String _selectFields = '''
    id,
    user_id,
    assessed_by,
    assessment_date,
    heart_disease,
    heart_disease_note,
    chest_pain_exercise,
    chest_pain_rest,
    dizziness,
    bone_joint_problem,
    bone_joint_note,
    medication,
    medication_note,
    other_reason,
    other_reason_note,
    is_cleared,
    cardiovascular_details,
    musculoskeletal_details,
    metabolic_details,
    respiratory_details,
    training_experience,
    training_years,
    occupation_activity,
    equipment_access,
    weekly_sessions,
    sleep_hours,
    training_goals,
    version,
    is_current,
    emergency_contact,
    created_at,
    updated_at
  ''';

  /// 查詢指定學員的當前評估
  Future<HealthAssessmentModel?> queryCurrentAssessment(String userId) async {
    final response = await _supabase
        .from('health_assessments')
        .select(_selectFields)
        .eq('user_id', userId)
        .eq('is_current', true)
        .maybeSingle();

    if (response == null) return null;

    return HealthAssessmentModel.fromSupabase(response);
  }

  /// 查詢指定學員的所有評估記錄
  Future<List<HealthAssessmentModel>> queryAssessmentHistory(
    String userId, {
    int limit = 10,
  }) async {
    final response = await _supabase
        .from('health_assessments')
        .select(_selectFields)
        .eq('user_id', userId)
        .order('assessment_date', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => HealthAssessmentModel.fromSupabase(json))
        .toList();
  }

  /// 根據 ID 查詢單筆評估
  Future<HealthAssessmentModel?> queryById(String assessmentId) async {
    final response = await _supabase
        .from('health_assessments')
        .select(_selectFields)
        .eq('id', assessmentId)
        .maybeSingle();

    if (response == null) return null;

    return HealthAssessmentModel.fromSupabase(response);
  }

  /// 批次查詢多位學員的當前評估
  Future<Map<String, HealthAssessmentModel?>> batchQueryCurrentAssessments(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    final response = await _supabase
        .from('health_assessments')
        .select(_selectFields)
        .inFilter('user_id', userIds)
        .eq('is_current', true);

    final assessments = (response as List)
        .map((json) => HealthAssessmentModel.fromSupabase(json))
        .toList();

    // 轉換為 Map
    final result = <String, HealthAssessmentModel?>{};
    for (final userId in userIds) {
      result[userId] = assessments.cast<HealthAssessmentModel?>().firstWhere(
        (a) => a?.userId == userId,
        orElse: () => null,
      );
    }

    return result;
  }

  /// 查詢指定教練的學員中，有警示的評估
  /// 
  /// 透過 coaching_relationships 關聯查詢
  Future<List<HealthAssessmentModel>> queryWarningAssessments(
    String coachId,
  ) async {
    // 1. 先取得教練的所有 active 學員
    final relationshipsResponse = await _supabase
        .from('coaching_relationships')
        .select('client_id')
        .eq('coach_id', coachId)
        .eq('status', 'active');

    final clientIds = (relationshipsResponse as List)
        .map((json) => json['client_id'] as String)
        .toList();

    if (clientIds.isEmpty) return [];

    // 2. 查詢這些學員的當前評估，且未通過篩檢
    final response = await _supabase
        .from('health_assessments')
        .select(_selectFields)
        .inFilter('user_id', clientIds)
        .eq('is_current', true)
        .eq('is_cleared', false) // 未通過安全篩檢
        .order('assessment_date', ascending: false);

    return (response as List)
        .map((json) => HealthAssessmentModel.fromSupabase(json))
        .toList();
  }

  /// 檢查指定學員是否已有當前評估
  Future<bool> hasCurrentAssessment(String userId) async {
    final response = await _supabase
        .from('health_assessments')
        .select('id')
        .eq('user_id', userId)
        .eq('is_current', true)
        .maybeSingle();

    return response != null;
  }
}

