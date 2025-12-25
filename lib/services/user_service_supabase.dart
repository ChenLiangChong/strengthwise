import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'interfaces/i_user_service.dart';
import 'error_handling_service.dart';

/// 用戶服務的 Supabase 實現
///
/// 提供用戶資料的 CRUD 操作
class UserServiceSupabase implements IUserService {
  final SupabaseClient _supabase;
  final ErrorHandlingService? _errorService;

  UserServiceSupabase({
    SupabaseClient? supabase,
    ErrorHandlingService? errorService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _errorService = errorService;

  /// 獲取當前用戶 ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  @override
  Future<bool> isProfileCompleted() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        _logDebug('用戶未登入');
        return false;
      }

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
      _logError('檢查用戶資料完整度失敗: $e');
      return false;
    }
  }

  @override
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        _logDebug('用戶未登入');
        return null;
      }

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
      _logError('獲取用戶資料失敗: $e');
      _errorService?.logError('獲取用戶資料失敗: $e', type: 'UserServiceError');
      return null;
    }
  }

  @override
  Future<bool> updateUserProfile({
    String? displayName,
    String? nickname,
    String? gender,
    double? height,
    double? weight,
    int? age,
    DateTime? birthDate,
    bool? isCoach,
    bool? isStudent,
    String? bio,
    String? unitSystem,
    File? avatarFile,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        _logError('用戶未登入');
        return false;
      }

      _logDebug('更新用戶資料: $userId');

      // 準備更新數據
      final Map<String, dynamic> updateData = {};

      if (displayName != null) updateData['display_name'] = displayName;
      if (nickname != null) updateData['nickname'] = nickname;
      if (gender != null) updateData['gender'] = gender;
      if (height != null) updateData['height'] = height;
      if (weight != null) updateData['weight'] = weight;
      if (age != null) updateData['age'] = age;
      if (birthDate != null) updateData['birth_date'] = birthDate.toIso8601String();
      if (isCoach != null) updateData['is_coach'] = isCoach;
      if (isStudent != null) updateData['is_student'] = isStudent;
      if (bio != null) updateData['bio'] = bio;
      if (unitSystem != null) updateData['unit_system'] = unitSystem;

      // 處理頭像上傳
      if (avatarFile != null) {
        final avatarUrl = await _uploadAvatar(userId, avatarFile);
        if (avatarUrl != null) {
          updateData['photo_url'] = avatarUrl;
        }
      }

      if (updateData.isEmpty) {
        _logDebug('沒有需要更新的資料');
        return true;
      }

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
      _logError('更新用戶資料失敗: $e');
      _errorService?.logError('更新用戶資料失敗: $e', type: 'UserServiceError');
      return false;
    }
  }

  @override
  Future<bool> toggleUserRole(bool isCoach) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        _logError('用戶未登入');
        return false;
      }

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
      _logError('切換用戶角色失敗: $e');
      _errorService?.logError('切換用戶角色失敗: $e', type: 'UserServiceError');
      return false;
    }
  }

  @override
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
      _logError('更新用戶體重失敗: $e');
      _errorService?.logError('更新用戶體重失敗: $e', type: 'UserServiceError');
      return false;
    }
  }

  /// 上傳頭像到 Supabase Storage
  Future<String?> _uploadAvatar(String userId, File avatarFile) async {
    try {
      _logDebug('開始上傳頭像');

      final fileName = 'avatar_$userId.jpg';
      final path = 'avatars/$fileName';

      // 上傳檔案到 Supabase Storage
      await _supabase.storage.from('avatars').upload(
        path,
        avatarFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      // 獲取公開 URL
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);

      _logDebug('頭像上傳成功: $publicUrl');
      return publicUrl;
    } catch (e) {
      _logError('上傳頭像失敗: $e');
      return null;
    }
  }

  /// 偵錯日誌
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[USER_SERVICE_SUPABASE] $message');
    }
  }

  /// 錯誤日誌
  void _logError(String message) {
    if (kDebugMode) {
      print('[USER_SERVICE_SUPABASE ERROR] $message');
    }
    _errorService?.logError(message, type: 'UserServiceError');
  }
}

