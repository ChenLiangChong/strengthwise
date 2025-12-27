import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// 用戶頭像管理器
/// 
/// 負責頭像的上傳、刪除等操作
class UserAvatarManager {
  final SupabaseClient _supabase;
  
  UserAvatarManager({required SupabaseClient supabase}) : _supabase = supabase;
  
  /// 上傳頭像到 Supabase Storage
  Future<String?> uploadAvatar(String userId, File avatarFile) async {
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
      _logDebug('上傳頭像失敗: $e');
      return null;
    }
  }
  
  /// 刪除頭像
  Future<bool> deleteAvatar(String userId) async {
    try {
      _logDebug('開始刪除頭像');
      
      final fileName = 'avatar_$userId.jpg';
      final path = 'avatars/$fileName';
      
      await _supabase.storage.from('avatars').remove([path]);
      
      _logDebug('頭像刪除成功');
      return true;
    } catch (e) {
      _logDebug('刪除頭像失敗: $e');
      return false;
    }
  }
  
  /// 偵錯日誌
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[USER_AVATAR_MANAGER] $message');
    }
  }
}

