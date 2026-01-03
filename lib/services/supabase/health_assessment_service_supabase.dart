import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/models/health_assessment_models.dart';
import 'package:strengthwise/services/interfaces/i_health_assessment_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/services/health_assessment/health_assessment_query_manager.dart';
import 'package:strengthwise/services/health_assessment/health_assessment_operations_manager.dart';

/// 健康評估服務 Supabase 實作
class HealthAssessmentServiceSupabase implements IHealthAssessmentService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;
  
  late final HealthAssessmentQueryManager _query;
  late final HealthAssessmentOperationsManager _operations;

  HealthAssessmentServiceSupabase(
    this._supabase,
    this._errorService,
  ) {
    _query = HealthAssessmentQueryManager(_supabase);
    _operations = HealthAssessmentOperationsManager(_supabase);
  }

  @override
  Future<HealthAssessmentModel?> getCurrentAssessment(String userId) async {
    try {
      return await _query.queryCurrentAssessment(userId);
    } catch (e) {
      _errorService.logError(
        '取得當前健康評估失敗: $e',
        type: 'HealthAssessmentServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<List<HealthAssessmentModel>> getAssessmentHistory(
    String userId, {
    int limit = 10,
  }) async {
    try {
      return await _query.queryAssessmentHistory(userId, limit: limit);
    } catch (e) {
      _errorService.logError(
        '取得健康評估歷史失敗: $e',
        type: 'HealthAssessmentServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<HealthAssessmentModel> createAssessment(
    HealthAssessmentModel assessment, {
    bool setAsCurrent = true,
  }) async {
    try {
      return await _operations.insert(assessment, setAsCurrent: setAsCurrent);
    } catch (e) {
      _errorService.logError(
        '建立健康評估失敗: $e',
        type: 'HealthAssessmentServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateAssessment(HealthAssessmentModel assessment) async {
    try {
      await _operations.update(assessment);
    } catch (e) {
      _errorService.logError(
        '更新健康評估失敗: $e',
        type: 'HealthAssessmentServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      await _operations.delete(assessmentId);
    } catch (e) {
      _errorService.logError(
        '刪除健康評估失敗: $e',
        type: 'HealthAssessmentServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<void> setAsCurrentAssessment(String assessmentId, String userId) async {
    try {
      await _operations.setAsCurrent(assessmentId, userId);
    } catch (e) {
      _errorService.logError(
        '設定當前評估失敗: $e',
        type: 'HealthAssessmentServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, HealthAssessmentModel?>> batchGetCurrentAssessments(
    List<String> userIds,
  ) async {
    try {
      return await _query.batchQueryCurrentAssessments(userIds);
    } catch (e) {
      _errorService.logError(
        '批次取得健康評估失敗: $e',
        type: 'HealthAssessmentServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<List<HealthAssessmentModel>> getWarningAssessments(
    String coachId,
  ) async {
    try {
      return await _query.queryWarningAssessments(coachId);
    } catch (e) {
      _errorService.logError(
        '取得警示評估失敗: $e',
        type: 'HealthAssessmentServiceError',
      );
      rethrow;
    }
  }

  /// 更新教練備註
  /// 
  /// [assessmentId] 評估 ID
  /// [coachNotes] 教練備註內容
  Future<void> updateCoachNotes(String assessmentId, String coachNotes) async {
    try {
      await _operations.updateCoachNotes(assessmentId, coachNotes);
    } catch (e) {
      _errorService.logError(
        '更新教練備註失敗: $e',
        type: 'HealthAssessmentServiceError',
      );
      rethrow;
    }
  }

  /// 檢查指定學員是否已有當前評估
  /// 
  /// [userId] 學員 ID
  Future<bool> hasCurrentAssessment(String userId) async {
    try {
      return await _query.hasCurrentAssessment(userId);
    } catch (e) {
      _errorService.logError(
        '檢查評估存在失敗: $e',
        type: 'HealthAssessmentServiceError',
      );
      rethrow;
    }
  }
}

