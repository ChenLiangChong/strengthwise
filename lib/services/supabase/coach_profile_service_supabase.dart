import 'package:strengthwise/models/coach_profile/coach_profile_model.dart';
import 'package:strengthwise/services/interfaces/i_coach_profile_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 教練公開檔案服務 Supabase 實作
class CoachProfileServiceSupabase implements ICoachProfileService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;

  CoachProfileServiceSupabase({
    required SupabaseClient supabase,
    required ErrorHandlingService errorService,
  })  : _supabase = supabase,
        _errorService = errorService;

  @override
  Future<CoachProfileModel?> getProfile(String coachId) async {
    try {
      final response = await _supabase
          .from('coaches')
          .select('''
            id,
            display_name,
            headline,
            bio,
            specialties,
            certifications,
            years_experience,
            languages,
            service_types,
            hourly_rate_min,
            hourly_rate_max,
            currency,
            offers_free_consultation,
            verified_status,
            slug,
            created_at,
            updated_at
          ''')
          .eq('id', coachId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return CoachProfileModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '取得教練檔案失敗: $e',
        type: 'CoachProfileServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<CoachProfileModel> createProfile(CoachProfileModel profile) async {
    try {
      final response = await _supabase
          .from('coaches')
          .insert(profile.toMap())
          .select()
          .single();

      return CoachProfileModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '建立教練檔案失敗: $e',
        type: 'CoachProfileServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<CoachProfileModel> updateProfile(CoachProfileModel profile) async {
    try {
      final response = await _supabase
          .from('coaches')
          .update(profile.toUpdateMap())
          .eq('id', profile.id)
          .select()
          .single();

      return CoachProfileModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '更新教練檔案失敗: $e',
        type: 'CoachProfileServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<CoachProfileModel> upsertProfile(CoachProfileModel profile) async {
    try {
      // 使用 upsert，以 id 為衝突鍵
      final response = await _supabase
          .from('coaches')
          .upsert(
            profile.toMap(),
            onConflict: 'id',
          )
          .select()
          .single();

      return CoachProfileModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '建立或更新教練檔案失敗: $e',
        type: 'CoachProfileServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<bool> hasProfile(String coachId) async {
    try {
      final response = await _supabase
          .from('coaches')
          .select('id')
          .eq('id', coachId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      _errorService.logError(
        '檢查教練檔案存在失敗: $e',
        type: 'CoachProfileServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteProfile(String coachId) async {
    try {
      await _supabase
          .from('coaches')
          .delete()
          .eq('id', coachId);
    } catch (e) {
      _errorService.logError(
        '刪除教練檔案失敗: $e',
        type: 'CoachProfileServiceError',
      );
      rethrow;
    }
  }
}

