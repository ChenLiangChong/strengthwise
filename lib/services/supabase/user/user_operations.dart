import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/user_model.dart';

/// 用戶資料操作模組
/// 
/// 負責用戶資料的 CRUD 操作
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
          .select('nickname, height, weight')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        _logDebug('用戶資料不存在');
        return false;
      }

      // 檢查必填欄位
      final hasNickname = response['nickname'] != null && response['nickname'].toString().isNotEmpty;
      final hasHeight = response['height'] != null;
      final hasWeight = response['weight'] != null;

      final isCompleted = hasNickname && hasHeight && hasWeight;
      _logDebug('用戶資料完整度: $isCompleted');

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
          .select()
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
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updateData) async {
    try {
      if (updateData.isEmpty) {
        _logDebug('沒有需要更新的資料');
        return true;
      }

      _logDebug('更新用戶資料: $userId');

      // 更新時間戳記
      updateData['profile_updated_at'] = DateTime.now().toIso8601String();

      // 執行更新
      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId);

      _logDebug('用戶資料更新成功');
      return true;
    } catch (e) {
      _logDebug('更新用戶資料失敗: $e');
      return false;
    }
  }
  
  /// 切換用戶角色
  Future<bool> toggleUserRole(String userId, bool isCoach) async {
    try {
      _logDebug('切換用戶角色: isCoach=$isCoach');

      await _supabase
          .from('users')
          .update({
            'is_coach': isCoach,
            'is_student': !isCoach,
            'profile_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

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

      await _supabase
          .from('users')
          .update({
            'weight': weight,
            'profile_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      _logDebug('用戶體重更新成功');
      return true;
    } catch (e) {
      _logDebug('更新用戶體重失敗: $e');
      return false;
    }
  }
}

