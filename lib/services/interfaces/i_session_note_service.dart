import 'dart:io';
import 'package:strengthwise/models/session_note/session_note_model.dart';

/// Session Note Service Interface
/// 
/// Phase 3: 視覺化筆記系統
/// 定義課程筆記相關操作的接口
abstract class ISessionNoteService {
  // ==================== 查詢方法 ====================

  /// 取得教練的所有筆記（依學員篩選）
  Future<List<SessionNoteModel>> getCoachNotes({
    required String coachId,
    String? clientId,
    int limit = 20,
    String? lastNoteId,
  });

  /// 取得學員可見的筆記（僅 shared）
  Future<List<SessionNoteModel>> getClientNotes({
    required String clientId,
    int limit = 20,
    String? lastNoteId,
  });

  /// 取得單筆筆記
  Future<SessionNoteModel?> getNoteById(String noteId);

  /// 取得與預約關聯的筆記
  Future<List<SessionNoteModel>> getNotesByAppointment({
    required String appointmentId,
  });

  /// 取得與訓練記錄關聯的筆記
  Future<List<SessionNoteModel>> getNotesByWorkoutLog({
    required String workoutLogId,
  });

  /// 搜尋筆記（依標籤或關鍵字）
  Future<List<SessionNoteModel>> searchNotes({
    required String coachId,
    String? keyword,
    List<String>? tags,
    int limit = 20,
  });

  // ==================== CRUD 操作 ====================

  /// 創建筆記
  Future<SessionNoteModel> createNote(SessionNoteModel note);

  /// 更新筆記
  Future<SessionNoteModel> updateNote(SessionNoteModel note);

  /// 刪除筆記
  Future<void> deleteNote(String noteId);

  /// 切換筆記可見性（private <-> shared）
  Future<SessionNoteModel> toggleVisibility(String noteId);

  // ==================== Storage 操作 ====================

  /// 上傳手繪圖片
  /// 
  /// [coachId] 教練 ID
  /// [clientId] 學員 ID（用於分類）
  /// [file] 圖片檔案
  /// 
  /// 返回 Storage 路徑
  Future<String> uploadDrawing({
    required String coachId,
    required String clientId,
    required File file,
  });

  /// 上傳照片
  Future<String> uploadPhoto({
    required String coachId,
    required String clientId,
    required File file,
  });

  /// 上傳語音筆記
  Future<String> uploadVoiceNote({
    required String coachId,
    required String clientId,
    required File file,
  });

  /// 生成 Signed URL（24 小時有效）
  /// 
  /// [bucket] Storage Bucket 名稱
  /// [path] 檔案路徑
  /// 
  /// 返回臨時存取網址
  Future<String> generateSignedUrl({
    required String bucket,
    required String path,
  });

  /// 刪除 Storage 檔案
  Future<void> deleteStorageFile({
    required String bucket,
    required String path,
  });

  // ==================== 統計方法 ====================

  /// 取得教練的筆記統計
  /// 
  /// 返回：{ 'total': 總數, 'shared': 已分享數, 'private': 私人數 }
  Future<Map<String, int>> getCoachNoteStats({
    required String coachId,
    String? clientId,
  });

  /// 取得學員的筆記統計
  /// 
  /// 返回：{ 'total': 總數, 'shared': 可見數 }
  Future<Map<String, int>> getClientNoteStats({
    required String clientId,
  });
}

