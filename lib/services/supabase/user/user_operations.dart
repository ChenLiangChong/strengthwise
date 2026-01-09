import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/utils/datetime_utils.dart';
import '../../../models/user_model.dart';

/// 用戶資料操作模組
///
/// 負責用戶資料的 CRUD 操作

/// ⭐ 定義 users 表的標準查詢欄位（避免 SELECT *）
const String _kUserSelectFields = '''
  id, email, display_name, nickname, photo_url, gender, 
  height, weight, birth_date, is_coach, is_student, 
  profile_created_at, profile_updated_at
''';

class UserOperations {
  final SupabaseClient _supabase;
  final void Function(String) _logDebug;

  UserOperations({
    required SupabaseClient supabase,
    required void Function(String) logDebug,
  })  : _supabase = supabase,
        _logDebug = logDebug;

  /// 檢查用戶資料是否完整
  Future<bool> isProfileCompleted(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('display_name, nickname, gender, height, weight, birth_date')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        _logDebug('用戶資料不存在');
        return false;
      }

      // ✅ 檢查所有必填欄位
      final hasDisplayName = response['display_name'] != null &&
          response['display_name'].toString().isNotEmpty;
      final hasNickname = response['nickname'] != null &&
          response['nickname'].toString().isNotEmpty;
      final hasGender = response['gender'] != null &&
          response['gender'].toString().isNotEmpty;
      final hasHeight = response['height'] != null;
      final hasWeight = response['weight'] != null;
      final hasBirthDate = response['birth_date'] != null;

      final isCompleted = hasDisplayName &&
          hasNickname &&
          hasGender &&
          hasHeight &&
          hasWeight &&
          hasBirthDate;
      _logDebug(
          '用戶資料完整度: $isCompleted (display_name: $hasDisplayName, nickname: $hasNickname, gender: $hasGender, height: $hasHeight, weight: $hasWeight, birth_date: $hasBirthDate)');

      return isCompleted;
    } catch (e) {
      _logDebug('檢查用戶資料完整度失敗: $e');
      return false;
    }
  }

  /// 獲取用戶資料
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      _logDebug('獲取用戶資料: $userId');

      final response = await _supabase
          .from('users')
          .select(_kUserSelectFields)
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        _logDebug('用戶資料不存在，可能是新用戶');
        return null;
      }

      final user = UserModel.fromSupabase(response);
      _logDebug('成功獲取用戶資料: ${user.email}');

      return user;
    } catch (e) {
      _logDebug('獲取用戶資料失敗: $e');
      return null;
    }
  }

  /// 更新用戶資料
  Future<bool> updateUserProfile(
      String userId, Map<String, dynamic> updateData) async {
    try {
      if (updateData.isEmpty) {
        _logDebug('沒有需要更新的資料');
        return true;
      }

      _logDebug('更新用戶資料: $userId');

      // 更新時間戳記
      updateData['profile_updated_at'] =
          DateTimeUtils.formatToUtcIso(DateTime.now());

      // 執行更新
      await _supabase.from('users').update(updateData).eq('id', userId);

      _logDebug('用戶資料更新成功');
      return true;
    } catch (e) {
      _logDebug('更新用戶資料失敗: $e');
      return false;
    }
  }

  /// 切換用戶角色
  ///
  /// ⭐ 注意：is_coach 和 is_student 不互斥
  /// 用戶可以同時是教練和學員（例如：A 的教練，B 的學員）
  Future<bool> toggleUserRole(String userId, bool isCoach) async {
    try {
      _logDebug('切換用戶角色: isCoach=$isCoach');

      // ⭐ 修正：啟用教練身份時，同時保留學員身份
      // 只有當用戶明確選擇「只當教練」時才設為 false（目前 UI 沒有這個選項）
      final updateData = <String, dynamic>{
        'is_coach': isCoach,
        'profile_updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
      };

      // 如果啟用教練身份，確保學員身份也是 true（可同時擁有兩種身份）
      if (isCoach) {
        updateData['is_student'] = true;
      }

      await _supabase.from('users').update(updateData).eq('id', userId);

      _logDebug('用戶角色切換成功');
      return true;
    } catch (e) {
      _logDebug('切換用戶角色失敗: $e');
      return false;
    }
  }

  /// 更新用戶體重
  Future<bool> updateUserWeight(String userId, double weight) async {
    try {
      _logDebug('更新用戶體重: userId=$userId, weight=$weight');

      await _supabase.from('users').update({
        'weight': weight,
        'profile_updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
      }).eq('id', userId);

      _logDebug('用戶體重更新成功');
      return true;
    } catch (e) {
      _logDebug('更新用戶體重失敗: $e');
      return false;
    }
  }
}
