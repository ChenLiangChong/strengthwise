import 'dart:io';
import '../../services/interfaces/i_session_note_service.dart';

/// SessionNoteStorageOperations - 筆記 Storage 操作管理器
/// 
/// 負責檔案上傳、下載、刪除等 Storage 相關操作
class SessionNoteStorageOperations {
  final ISessionNoteService _service;
  
  SessionNoteStorageOperations(this._service);
  
  // 元素類型常量
  static const String typeDrawing = 'drawing';
  static const String typePhoto = 'photo';
  static const String typeVoice = 'voice_note';
  static const String typeText = 'text';
  
  // ==================== 上傳操作 ====================
  
  /// 上傳手繪圖片
  /// 
  /// 返回：Storage 路徑
  Future<String> uploadDrawing({
    required String coachId,
    required String clientId,
    required File file,
  }) async {
    return await _service.uploadDrawing(
      coachId: coachId,
      clientId: clientId,
      file: file,
    );
  }
  
  /// 上傳照片
  /// 
  /// 返回：Storage 路徑
  Future<String> uploadPhoto({
    required String coachId,
    required String clientId,
    required File file,
  }) async {
    return await _service.uploadPhoto(
      coachId: coachId,
      clientId: clientId,
      file: file,
    );
  }
  
  /// 上傳語音筆記
  /// 
  /// 返回：Storage 路徑
  Future<String> uploadVoiceNote({
    required String coachId,
    required String clientId,
    required File file,
  }) async {
    return await _service.uploadVoiceNote(
      coachId: coachId,
      clientId: clientId,
      file: file,
    );
  }
  
  /// 根據元素類型自動選擇上傳方法
  /// 
  /// 返回：Storage 路徑
  Future<String> uploadByElementType({
    required String elementType,
    required String coachId,
    required String clientId,
    required File file,
  }) async {
    switch (elementType) {
      case typeDrawing:
        return await uploadDrawing(
          coachId: coachId,
          clientId: clientId,
          file: file,
        );
      case typePhoto:
        return await uploadPhoto(
          coachId: coachId,
          clientId: clientId,
          file: file,
        );
      case typeVoice:
        return await uploadVoiceNote(
          coachId: coachId,
          clientId: clientId,
          file: file,
        );
      case typeText:
        throw ArgumentError('Text elements do not require file upload');
      default:
        throw ArgumentError('Unknown element type: $elementType');
    }
  }
  
  // ==================== Signed URL 生成 ====================
  
  /// 生成 Signed URL（24 小時有效）
  /// 
  /// [bucket] Storage Bucket 名稱（coach-drawings / coach-photos / coach-voice-notes）
  /// [path] 檔案路徑
  /// 
  /// 返回：臨時存取網址
  Future<String> generateSignedUrl({
    required String bucket,
    required String path,
  }) async {
    return await _service.generateSignedUrl(
      bucket: bucket,
      path: path,
    );
  }
  
  /// 根據元素類型生成 Signed URL
  Future<String> generateSignedUrlByElementType({
    required String elementType,
    required String path,
  }) async {
    final bucket = _getBucketByElementType(elementType);
    return await generateSignedUrl(bucket: bucket, path: path);
  }
  
  // ==================== 刪除操作 ====================
  
  /// 刪除 Storage 檔案
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await _service.deleteStorageFile(
      bucket: bucket,
      path: path,
    );
  }
  
  /// 根據元素類型刪除檔案
  Future<void> deleteFileByElementType({
    required String elementType,
    required String path,
  }) async {
    final bucket = _getBucketByElementType(elementType);
    await deleteFile(bucket: bucket, path: path);
  }
  
  // ==================== 輔助方法 ====================
  
  /// 根據元素類型取得對應的 Bucket 名稱
  String _getBucketByElementType(String elementType) {
    switch (elementType) {
      case typeDrawing:
        return 'coach-drawings';
      case typePhoto:
        return 'coach-photos';
      case typeVoice:
        return 'coach-voice-notes';
      case typeText:
        throw ArgumentError('Text elements do not have a storage bucket');
      default:
        throw ArgumentError('Unknown element type: $elementType');
    }
  }
  
  /// 驗證檔案大小
  bool validateFileSize({
    required File file,
    required String elementType,
  }) {
    final sizeInBytes = file.lengthSync();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    
    // 根據類型限制大小
    switch (elementType) {
      case typeDrawing:
      case typePhoto:
        return sizeInMB <= 10; // 10MB
      case typeVoice:
        return sizeInMB <= 50; // 50MB
      case typeText:
        return true; // 無限制
      default:
        return false;
    }
  }
  
  /// 驗證檔案格式
  bool validateFileFormat({
    required File file,
    required String elementType,
  }) {
    final extension = file.path.split('.').last.toLowerCase();
    
    switch (elementType) {
      case typeDrawing:
      case typePhoto:
        return ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
      case typeVoice:
        return ['mp3', 'wav', 'm4a', 'ogg'].contains(extension);
      case typeText:
        return true;
      default:
        return false;
    }
  }
}
