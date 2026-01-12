import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/coach_display_preferences_model.dart';
import '../interfaces/i_coach_display_preferences_service.dart';
import '../core/error_handling_service.dart';

/// 教練顯示偏好服務 Supabase 實作

/// ⭐ 定義 coach_display_preferences 表的標準查詢欄位
const String _kDisplayPrefsSelectFields = '''
  coach_id, health_assessment_fields,
  client_list_sort_by, client_list_sort_order,
  updated_at
''';

class CoachDisplayPreferencesServiceSupabase
    implements ICoachDisplayPreferencesService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;

  CoachDisplayPreferencesServiceSupabase({
    required SupabaseClient supabase,
    required ErrorHandlingService errorService,
  })  : _supabase = supabase,
        _errorService = errorService;

  @override
  Future<CoachDisplayPreferencesModel> getPreferences(String coachId) async {
    try {
      final response = await _supabase
          .from('coach_display_preferences')
          .select(_kDisplayPrefsSelectFields)
          .eq('coach_id', coachId)
          .maybeSingle();

      if (response == null) {
        // 若不存在，返回預設偏好
        return CoachDisplayPreferencesModel.createDefault(coachId);
      }

      return CoachDisplayPreferencesModel.fromSupabase(response);
    } catch (e, stackTrace) {
      _errorService.logError(
        '取得教練顯示偏好失敗: $e',
        type: 'CoachDisplayPreferencesService',
        stackTrace: stackTrace,
      );
      // 失敗時返回預設偏好
      return CoachDisplayPreferencesModel.createDefault(coachId);
    }
  }

  @override
  Future<void> updatePreferences(
      CoachDisplayPreferencesModel preferences) async {
    try {
      // 使用 UPSERT 操作
      await _supabase.from('coach_display_preferences').upsert(
            preferences.toSupabase(),
            onConflict: 'coach_id',
          );
    } catch (e, stackTrace) {
      _errorService.logError(
        '更新教練顯示偏好失敗: $e',
        type: 'CoachDisplayPreferencesService',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> resetToDefault(String coachId) async {
    try {
      final defaultPreferences =
          CoachDisplayPreferencesModel.createDefault(coachId);
      await updatePreferences(defaultPreferences);
    } catch (e, stackTrace) {
      _errorService.logError(
        '重置教練顯示偏好失敗: $e',
        type: 'CoachDisplayPreferencesService',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
