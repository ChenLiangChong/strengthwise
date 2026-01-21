import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/session_note/session_note_model.dart';

/// 課程筆記控制器接口
///
/// 管理課程筆記的創建、查詢、更新、刪除以及 Storage 檔案上傳
abstract class ISessionNoteController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 載入中狀態
  bool get isLoading;

  /// 錯誤訊息
  String? get errorMessage;

  /// 筆記列表
  List<SessionNoteModel> get notes;

  /// 當前選中的筆記
  SessionNoteModel? get selectedNote;

  /// 是否有筆記
  bool get hasNotes;

  /// 是否有錯誤
  bool get hasError;

  // 篩選條件
  String? get filterClientId;
  DateTime? get filterStartDate;
  DateTime? get filterEndDate;
  List<String>? get filterTags;
  String? get filterVisibility;

  // 統計資料
  int get totalCount;
  int get sharedCount;
  int get privateCount;

  // 衍生狀態
  List<SessionNoteModel> get sharedNotes;
  List<SessionNoteModel> get privateNotes;
  List<SessionNoteModel> getNotesForClient(String clientId);

  // ==================== 查詢功能 ====================

  /// 載入教練的所有筆記
  Future<void> loadCoachNotes({
    required String coachId,
    String? clientId,
    String? clientName,
    int limit = 20,
    String? lastNoteId,
    bool append = false,
  });

  /// 載入學員可見的筆記（僅 shared）
  Future<void> loadClientNotes({
    required String clientId,
    String? coachId,
    String? coachName,
    int limit = 20,
    String? lastNoteId,
    bool append = false,
  });

  /// 載入單筆筆記詳情
  Future<SessionNoteModel?> loadNoteById(String noteId);

  /// 載入與預約關聯的筆記
  Future<void> loadNotesByAppointment({required String appointmentId});

  /// 載入與訓練記錄關聯的筆記
  Future<void> loadNotesByWorkoutLog({required String workoutLogId});

  /// 搜尋筆記（依標籤或關鍵字）
  Future<void> searchNotes({
    required String coachId,
    String? keyword,
    List<String>? tags,
    int limit = 20,
  });

  // ==================== CRUD 功能 ====================

  /// 創建新筆記
  Future<SessionNoteModel?> createNote(SessionNoteModel note);

  /// 更新筆記內容
  Future<SessionNoteModel?> updateNote(SessionNoteModel note);

  /// 切換筆記可見性（private <-> shared）
  Future<SessionNoteModel?> toggleVisibility(String noteId);

  /// 刪除筆記
  Future<bool> deleteNote(String noteId);

  /// 隱藏筆記（教練或學員）
  Future<bool> hideNote({required String noteId, required bool isCoach});

  /// 批次分享筆記
  Future<List<SessionNoteModel>> batchShare(List<String> noteIds);

  /// 批次刪除筆記
  Future<bool> batchDelete(List<String> noteIds);

  // ==================== Storage 功能 ====================

  /// 上傳手繪圖片
  Future<String?> uploadDrawing({
    required String coachId,
    required String clientId,
    required File file,
  });

  /// 上傳照片
  Future<String?> uploadPhoto({
    required String coachId,
    required String clientId,
    required File file,
  });

  /// 上傳語音筆記
  Future<String?> uploadVoiceNote({
    required String coachId,
    required String clientId,
    required File file,
  });

  /// 根據元素類型自動上傳
  Future<String?> uploadByElementType({
    required String elementType,
    required String coachId,
    required String clientId,
    required File file,
  });

  /// 生成 Signed URL（24 小時有效）
  Future<String?> generateSignedUrl({required String bucket, required String path});

  /// 根據元素類型生成 Signed URL
  Future<String?> generateSignedUrlByElementType({
    required String elementType,
    required String path,
  });

  /// 刪除 Storage 檔案
  Future<bool> deleteFile({required String bucket, required String path});

  /// 根據元素類型刪除檔案
  Future<bool> deleteFileByElementType({
    required String elementType,
    required String path,
  });

  // ==================== 篩選條件管理 ====================

  void setClientFilter(String? clientId);
  void setDateRangeFilter(DateTime? startDate, DateTime? endDate);
  void setTagsFilter(List<String>? tags);
  void setVisibilityFilter(String? visibility);
  void clearFilters();

  // ==================== 狀態管理 ====================

  void setSelectedNote(SessionNoteModel? note);
  void clearSelectedNote();
  void clearError();
  void reset();

  // ==================== MVVM 查詢方法 ====================

  /// 查詢與預約關聯的筆記（直接返回結果）
  Future<List<SessionNoteModel>> getNotesByAppointment({required String appointmentId});
}
