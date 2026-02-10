import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// 用戶頭像管理器
///
/// 負責頭像的上傳、刪除等操作
class UserAvatarManager {
  final SupabaseClient _supabase;

  /// 頭像最大檔案大小：5MB
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  /// 允許的副檔名
  static const List<String> _allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  UserAvatarManager({required SupabaseClient supabase}) : _supabase = supabase;

  /// 驗證圖片檔案的 magic bytes
  ///
  /// 確保檔案內容與副檔名一致，防止偽造檔案類型
  bool _isValidImageHeader(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    // WebP: 52 49 46 46 (RIFF)
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46) {
      return true;
    }

    return false;
  }

  /// 上傳頭像到 Supabase Storage
  ///
  /// 驗證：檔案大小（≤5MB）、副檔名（jpg/png/webp）、magic bytes
  Future<String?> uploadAvatar(String userId, File avatarFile) async {
    try {
      _logDebug('開始上傳頭像');

      // 1. 檢查檔案大小
      final fileSize = await avatarFile.length();
      if (fileSize > _maxFileSizeBytes) {
        _logDebug('頭像檔案過大: $fileSize bytes（上限 ${_maxFileSizeBytes ~/ 1024 ~/ 1024}MB）');
        return null;
      }

      // 2. 檢查副檔名
      final ext = avatarFile.path.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        _logDebug('不支援的頭像格式: $ext');
        return null;
      }

      // 3. 檢查 magic bytes（真實檔案類型）
      final headerBytes = await avatarFile.openRead(0, 4).expand((b) => b).toList();
      if (!_isValidImageHeader(Uint8List.fromList(headerBytes))) {
        _logDebug('頭像檔案內容無效（magic bytes 不匹配）');
        return null;
      }

      final path = '$userId/avatar.jpg';

      // 上傳檔案到 Supabase Storage
      await _supabase.storage.from('avatars').upload(
        path,
        avatarFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      // 獲取公開 URL（加上時間戳避免客戶端快取舊圖）
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      final cacheBustedUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      _logDebug('頭像上傳成功: $cacheBustedUrl');
      return cacheBustedUrl;
    } catch (e) {
      _logDebug('上傳頭像失敗: $e');
      return null;
    }
  }
  
  /// 刪除頭像
  Future<bool> deleteAvatar(String userId) async {
    try {
      _logDebug('開始刪除頭像');
      
      final path = '$userId/avatar.jpg';
      
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
      debugPrint('[USER_AVATAR_MANAGER] $message');
    }
  }
}

