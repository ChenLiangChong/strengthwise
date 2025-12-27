import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../interfaces/i_user_service.dart';
import '../core/error_handling_service.dart';
import 'user/user_cache_manager.dart';
import 'user/user_operations.dart';
import 'user/user_avatar_manager.dart';

/// 用戶服務的 Supabase 實現
///
/// 提供用戶資料的 CRUD 操作
class UserServiceSupabase implements IUserService {
  final SupabaseClient _supabase;
  final ErrorHandlingService? _errorService;
  
  // 子模組
  late final UserCacheManager _cacheManager;
  late final UserOperations _operations;
  late final UserAvatarManager _avatarManager;

  UserServiceSupabase({
    SupabaseClient? supabase,
    ErrorHandlingService? errorService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _errorService = errorService {
    _cacheManager = UserCacheManager();
    _operations = UserOperations(
      supabase: _supabase,
      logDebug: _logDebug,
    );
    _avatarManager = UserAvatarManager(supabase: _supabase);
    
    // 配置快取管理器（5 分鐘有效期）
    _cacheManager.configure(5);
  }

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

      return await _operations.isProfileCompleted(userId);
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

      // ⚡ 檢查快取
      final cached = _cacheManager.getCachedProfile(userId);
      if (cached != null) {
        return cached;
      }

      // 從資料庫獲取
      final user = await _operations.getUserProfile(userId);
      
      if (user != null) {
        // ⚡ 更新快取
        _cacheManager.updateCache(userId, user);
      }

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
        final avatarUrl = await _avatarManager.uploadAvatar(userId, avatarFile);
        if (avatarUrl != null) {
          updateData['photo_url'] = avatarUrl;
        }
      }

      // 執行更新
      final success = await _operations.updateUserProfile(userId, updateData);

      if (success) {
        // ⚡ 清除快取，下次會重新載入
        _cacheManager.clearCache();
      }

      return success;
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

      final success = await _operations.toggleUserRole(userId, isCoach);
      
      if (success) {
        // ⚡ 清除快取
        _cacheManager.clearCache();
      }
      
      return success;
    } catch (e) {
      _logError('切換用戶角色失敗: $e');
      _errorService?.logError('切換用戶角色失敗: $e', type: 'UserServiceError');
      return false;
    }
  }

  @override
  Future<bool> updateUserWeight(String userId, double weight) async {
    try {
      final success = await _operations.updateUserWeight(userId, weight);
      
      if (success) {
        // ⚡ 清除快取
        _cacheManager.clearCache();
      }
      
      return success;
    } catch (e) {
      _logError('更新用戶體重失敗: $e');
      _errorService?.logError('更新用戶體重失敗: $e', type: 'UserServiceError');
      return false;
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

