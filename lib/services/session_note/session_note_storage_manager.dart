import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';

/// Session Note Storage 管理器（子模組）
///
/// 職責：處理 Supabase Storage 檔案上傳/刪除/簽名 URL
class SessionNoteStorageManager {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;

  SessionNoteStorageManager(this._supabase, this._errorService);

  /// 上傳手繪圖片
  ///
  /// 路徑格式：coach_drawings/{coach_id}/{client_id}/{filename}
  Future<String> uploadDrawing({
    required String coachId,
    required String clientId,
    required File file,
  }) async {
    try {
      return _uploadFile(
        bucket: 'coach_drawings',
        coachId: coachId,
        clientId: clientId,
        file: file,
      );
    } catch (e) {
      _errorService.logError(
        '上傳手繪圖片失敗: $e',
        type: 'SessionNoteStorageError',
      );
      rethrow;
    }
  }

  /// 上傳照片
  ///
  /// 路徑格式：session_photos/{coach_id}/{client_id}/{filename}
  Future<String> uploadPhoto({
    required String coachId,
    required String clientId,
    required File file,
  }) async {
    try {
      return _uploadFile(
        bucket: 'session_photos',
        coachId: coachId,
        clientId: clientId,
        file: file,
      );
    } catch (e) {
      _errorService.logError(
        '上傳照片失敗: $e',
        type: 'SessionNoteStorageError',
      );
      rethrow;
    }
  }

  /// 上傳語音筆記
  ///
  /// 路徑格式：voice_notes/{coach_id}/{client_id}/{filename}
  Future<String> uploadVoiceNote({
    required String coachId,
    required String clientId,
    required File file,
  }) async {
    try {
      return _uploadFile(
        bucket: 'voice_notes',
        coachId: coachId,
        clientId: clientId,
        file: file,
      );
    } catch (e) {
      _errorService.logError(
        '上傳語音筆記失敗: $e',
        type: 'SessionNoteStorageError',
      );
      rethrow;
    }
  }

  /// 通用上傳方法
  Future<String> _uploadFile({
    required String bucket,
    required String coachId,
    required String clientId,
    required File file,
  }) async {
    // 使用 path.basename() 正確提取文件名（跨平台）
    final rawFileName = path.basename(file.path);

    // 清理文件名：移除特殊字符（保留字母、數字、點、破折號、下劃線）
    final cleanFileName = rawFileName.replaceAll(RegExp(r'[^\w\-.]'), '_');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$coachId/$clientId/${timestamp}_$cleanFileName';

    await _supabase.storage.from(bucket).upload(
          storagePath,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

    return storagePath;
  }

  /// 生成 Signed URL（24 小時有效）
  Future<String> generateSignedUrl({
    required String bucket,
    required String path,
  }) async {
    try {
      final signedUrl = await _supabase.storage.from(bucket).createSignedUrl(
            path,
            86400, // 24 小時（秒）
          );

      return signedUrl;
    } catch (e) {
      _errorService.logError(
        '生成簽名 URL 失敗: $e',
        type: 'SessionNoteStorageError',
      );
      rethrow;
    }
  }

  /// 刪除 Storage 檔案
  Future<void> deleteStorageFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      _errorService.logError(
        '刪除檔案失敗: $e',
        type: 'SessionNoteStorageError',
      );
      rethrow;
    }
  }

  /// 批量刪除檔案（用於刪除筆記時清理所有附件）
  Future<void> batchDeleteFiles({
    required String bucket,
    required List<String> paths,
  }) async {
    try {
      if (paths.isEmpty) return;
      await _supabase.storage.from(bucket).remove(paths);
    } catch (e) {
      _errorService.logError(
        '批量刪除檔案失敗: $e',
        type: 'SessionNoteStorageError',
      );
      rethrow;
    }
  }
}
