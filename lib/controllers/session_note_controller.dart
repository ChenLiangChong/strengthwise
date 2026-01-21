import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/interfaces/i_session_note_service.dart';
import '../services/core/error_handling_service.dart';
import '../models/session_note/session_note_model.dart';
import 'session_note/session_note_state_manager.dart';
import 'session_note/session_note_query_manager.dart';
import 'session_note/session_note_crud_operations.dart';
import 'session_note/session_note_storage_operations.dart';
import 'interfaces/i_event_bus_controller.dart'; // ⭐ v3.9: EventBus
import 'interfaces/i_session_note_controller.dart';

/// SessionNoteController - Phase 3 課程筆記控制器
///
/// 管理課程筆記的創建、查詢、更新、刪除以及 Storage 檔案上傳
/// 遵循完全解耦架構（透過 Interface 注入依賴）+ 子模組化設計
/// ⭐ v3.9: 統一發布筆記事件（Controller 層負責事件發布）
class SessionNoteController extends ChangeNotifier implements ISessionNoteController {
  final ISessionNoteService _noteService;
  final ErrorHandlingService _errorService;
  final IEventBusController _eventBusController; // ⭐ v3.9: EventBus

  // 子模組
  late final SessionNoteStateManager _state;
  late final SessionNoteQueryManager _query;
  late final SessionNoteCrudOperations _crud;
  late final SessionNoteStorageOperations _storage;

  SessionNoteController(
    this._noteService,
    this._errorService,
    this._eventBusController, // ⭐ v3.9: EventBus
  ) {
    _state = SessionNoteStateManager();
    _query = SessionNoteQueryManager(_noteService, _state);
    _crud = SessionNoteCrudOperations(_noteService, _state);
    _storage = SessionNoteStorageOperations(_noteService);

    // 監聽狀態變化並通知 UI
    _state.addListener(notifyListeners);
  }

  // ============================================================================
  // 狀態訪問（委託給 StateManager）
  // ============================================================================

  @override
  bool get isLoading => _state.isLoading;
  @override
  String? get errorMessage => _state.errorMessage;
  @override
  List<SessionNoteModel> get notes => _state.notes;
  @override
  SessionNoteModel? get selectedNote => _state.selectedNote;
  @override
  bool get hasNotes => _state.hasNotes;
  @override
  bool get hasError => _state.hasError;
  
  // 篩選條件
  @override
  String? get filterClientId => _state.filterClientId;
  @override
  DateTime? get filterStartDate => _state.filterStartDate;
  @override
  DateTime? get filterEndDate => _state.filterEndDate;
  @override
  List<String>? get filterTags => _state.filterTags;
  @override
  String? get filterVisibility => _state.filterVisibility;
  
  // 統計資料
  @override
  int get totalCount => _state.totalCount;
  @override
  int get sharedCount => _state.sharedCount;
  @override
  int get privateCount => _state.privateCount;
  
  // 衍生狀態
  @override
  List<SessionNoteModel> get sharedNotes => _state.sharedNotes;
  @override
  List<SessionNoteModel> get privateNotes => _state.privateNotes;
  @override
  List<SessionNoteModel> getNotesForClient(String clientId) =>
      _state.getNotesForClient(clientId);

  // ============================================================================
  // 查詢功能（委託給 QueryManager）
  // ============================================================================

  /// 載入教練的所有筆記
  @override
  Future<void> loadCoachNotes({
    required String coachId,
    String? clientId,
    String? clientName, // ⭐ 新增：用於查詢已刪除學員的筆記
    int limit = 20,
    String? lastNoteId,
    bool append = false,
  }) async {
    await _executeOperation(() async {
      await _query.loadCoachNotes(
        coachId: coachId,
        clientId: clientId,
        clientName: clientName, // ⭐ 傳遞參數
        limit: limit,
        lastNoteId: lastNoteId,
        append: append,
      );
      
      // 載入統計資料
      if (!append) {
        await _query.loadCoachStats(coachId: coachId, clientId: clientId);
      }
    }, '載入筆記列表失敗');
  }

  /// 載入學員可見的筆記（僅 shared）
  @override
  Future<void> loadClientNotes({
    required String clientId,
    String? coachId, // ⭐ 新增：用於教練篩選
    String? coachName, // ⭐ 新增：用於查詢已刪除教練的筆記
    int limit = 20,
    String? lastNoteId,
    bool append = false,
  }) async {
    await _executeOperation(() async {
      await _query.loadClientNotes(
        clientId: clientId,
        coachId: coachId, // ⭐ 傳遞參數
        coachName: coachName, // ⭐ 傳遞參數
        limit: limit,
        lastNoteId: lastNoteId,
        append: append,
      );
      
      // 載入統計資料
      if (!append) {
        await _query.loadClientStats(clientId: clientId);
      }
    }, '載入筆記列表失敗');
  }

  /// 載入單筆筆記詳情
  @override
  Future<SessionNoteModel?> loadNoteById(String noteId) async {
    SessionNoteModel? note;
    
    await _executeOperation(() async {
      note = await _query.loadNoteById(noteId);
    }, '載入筆記詳情失敗');
    
    return note;
  }

  /// 載入與預約關聯的筆記
  @override
  Future<void> loadNotesByAppointment({
    required String appointmentId,
  }) async {
    await _executeOperation(() async {
      await _query.loadNotesByAppointment(appointmentId: appointmentId);
    }, '載入相關筆記失敗');
  }

  /// 載入與訓練記錄關聯的筆記
  @override
  Future<void> loadNotesByWorkoutLog({
    required String workoutLogId,
  }) async {
    await _executeOperation(() async {
      await _query.loadNotesByWorkoutLog(workoutLogId: workoutLogId);
    }, '載入相關筆記失敗');
  }

  /// 搜尋筆記（依標籤或關鍵字）
  @override
  Future<void> searchNotes({
    required String coachId,
    String? keyword,
    List<String>? tags,
    int limit = 20,
  }) async {
    await _executeOperation(() async {
      await _query.searchNotes(
        coachId: coachId,
        keyword: keyword,
        tags: tags,
        limit: limit,
      );
    }, '搜尋筆記失敗');
  }

  // ============================================================================
  // CRUD 功能（委託給 CrudOperations）
  // ============================================================================

  /// 創建新筆記
  /// ⭐ v3.9: 操作成功後自動發布事件
  @override
  Future<SessionNoteModel?> createNote(SessionNoteModel note) async {
    SessionNoteModel? createdNote;
    
    await _executeOperation(() async {
      createdNote = await _crud.createNote(note);
    }, '創建筆記失敗');

    // ⭐ v3.9: 發布筆記更新事件
    final created = createdNote;
    final coachId = created?.coachId;
    final clientId = created?.clientId;
    if (created != null && coachId != null && clientId != null) {
      _eventBusController.publishSessionNoteUpdated(
        noteId: created.id,
        coachId: coachId,
        clientId: clientId,
      );
    }

    return createdNote;
  }

  /// 更新筆記內容
  /// ⭐ v3.9: 操作成功後自動發布事件
  @override
  Future<SessionNoteModel?> updateNote(SessionNoteModel note) async {
    SessionNoteModel? updatedNote;

    await _executeOperation(() async {
      updatedNote = await _crud.updateNote(note);
    }, '更新筆記失敗');

    // ⭐ v3.9: 發布筆記更新事件
    final updated = updatedNote;
    final coachId = updated?.coachId;
    final clientId = updated?.clientId;
    if (updated != null && coachId != null && clientId != null) {
      _eventBusController.publishSessionNoteUpdated(
        noteId: updated.id,
        coachId: coachId,
        clientId: clientId,
      );
    }

    return updatedNote;
  }

  /// 切換筆記可見性（private <-> shared）
  @override
  Future<SessionNoteModel?> toggleVisibility(String noteId) async {
    SessionNoteModel? updatedNote;
    
    await _executeOperation(() async {
      updatedNote = await _crud.toggleVisibility(noteId);
    }, '切換分享狀態失敗');
    
    return updatedNote;
  }

  /// 刪除筆記
  /// ⭐ v3.9: 操作成功後自動發布事件
  @override
  Future<bool> deleteNote(String noteId) async {
    bool success = false;

    // 先從現有筆記中獲取資訊用於事件發布
    SessionNoteModel? note;
    try {
      note = _state.notes.firstWhere((n) => n.id == noteId);
    } catch (_) {
      // 如果找不到，note 保持 null
    }
    
    await _executeOperation(() async {
      await _crud.deleteNote(noteId);
      success = true;
    }, '刪除筆記失敗');

    // ⭐ v3.9: 發布筆記更新事件
    final coachId = note?.coachId;
    final clientId = note?.clientId;
    if (success && coachId != null && coachId.isNotEmpty && clientId != null) {
      _eventBusController.publishSessionNoteUpdated(
        noteId: noteId,
        coachId: coachId,
        clientId: clientId,
      );
    }
    
    return success;
  }

  /// 隱藏筆記（教練或學員）⭐ 新增
  /// 
  /// 當關係為 archived 時，雙方可以選擇「移除」共享筆記，
  /// 實際上是 UPDATE hidden_by_client/hidden_by_coach = true。
  /// 
  /// [noteId] 筆記 ID
  /// [isCoach] true = 教練隱藏，false = 學員隱藏
  @override
  Future<bool> hideNote({
    required String noteId,
    required bool isCoach,
  }) async {
    bool success = false;
    
    await _executeOperation(() async {
      await _noteService.hideNote(noteId: noteId, isCoach: isCoach);
      success = true;
    }, '隱藏筆記失敗');
    
    return success;
  }

  /// 批次分享筆記
  @override
  Future<List<SessionNoteModel>> batchShare(List<String> noteIds) async {
    List<SessionNoteModel> updatedNotes = [];
    
    await _executeOperation(() async {
      updatedNotes = await _crud.batchShare(noteIds);
    }, '批次分享失敗');
    
    return updatedNotes;
  }

  /// 批次刪除筆記
  @override
  Future<bool> batchDelete(List<String> noteIds) async {
    bool success = false;
    
    await _executeOperation(() async {
      await _crud.batchDelete(noteIds);
      success = true;
    }, '批次刪除失敗');
    
    return success;
  }

  // ============================================================================
  // Storage 功能（委託給 StorageOperations）
  // ============================================================================

  /// 上傳手繪圖片
  @override
  Future<String?> uploadDrawing({
    required String coachId,
    required String clientId,
    required File file,
  }) async {
    String? storagePath;
    
    await _executeOperation(() async {
      // 驗證檔案
      if (!_storage.validateFileSize(
        file: file,
        elementType: SessionNoteStorageOperations.typeDrawing,
      )) {
        throw Exception('檔案大小超過限制（10MB）');
      }
      
      if (!_storage.validateFileFormat(
        file: file,
        elementType: SessionNoteStorageOperations.typeDrawing,
      )) {
        throw Exception('不支援的檔案格式');
      }
      
      storagePath = await _storage.uploadDrawing(
        coachId: coachId,
        clientId: clientId,
        file: file,
      );
    }, '上傳手繪圖片失敗');
    
    return storagePath;
  }

  /// 上傳照片
  @override
  Future<String?> uploadPhoto({
    required String coachId,
    required String clientId,
    required File file,
  }) async {
    String? storagePath;
    
    await _executeOperation(() async {
      // 驗證檔案
      if (!_storage.validateFileSize(
        file: file,
        elementType: SessionNoteStorageOperations.typePhoto,
      )) {
        throw Exception('檔案大小超過限制（10MB）');
      }
      
      if (!_storage.validateFileFormat(
        file: file,
        elementType: SessionNoteStorageOperations.typePhoto,
      )) {
        throw Exception('不支援的檔案格式');
      }
      
      storagePath = await _storage.uploadPhoto(
        coachId: coachId,
        clientId: clientId,
        file: file,
      );
    }, '上傳照片失敗');
    
    return storagePath;
  }

  /// 上傳語音筆記
  @override
  Future<String?> uploadVoiceNote({
    required String coachId,
    required String clientId,
    required File file,
  }) async {
    String? storagePath;
    
    await _executeOperation(() async {
      // 驗證檔案
      if (!_storage.validateFileSize(
        file: file,
        elementType: SessionNoteStorageOperations.typeVoice,
      )) {
        throw Exception('檔案大小超過限制（50MB）');
      }
      
      if (!_storage.validateFileFormat(
        file: file,
        elementType: SessionNoteStorageOperations.typeVoice,
      )) {
        throw Exception('不支援的檔案格式');
      }
      
      storagePath = await _storage.uploadVoiceNote(
        coachId: coachId,
        clientId: clientId,
        file: file,
      );
    }, '上傳語音筆記失敗');
    
    return storagePath;
  }

  /// 根據元素類型自動上傳
  @override
  Future<String?> uploadByElementType({
    required String elementType,
    required String coachId,
    required String clientId,
    required File file,
  }) async {
    String? storagePath;
    
    await _executeOperation(() async {
      storagePath = await _storage.uploadByElementType(
        elementType: elementType,
        coachId: coachId,
        clientId: clientId,
        file: file,
      );
    }, '上傳檔案失敗');
    
    return storagePath;
  }

  /// 生成 Signed URL（24 小時有效）
  /// ⭐ v3.7: 不使用 _executeOperation，避免在 build 過程中觸發 notifyListeners
  @override
  Future<String?> generateSignedUrl({
    required String bucket,
    required String path,
  }) async {
    try {
      return await _storage.generateSignedUrl(
        bucket: bucket,
        path: path,
      );
    } catch (e) {
      _errorService.logError(
        '生成存取網址失敗: $e',
        type: 'SessionNoteControllerError',
      );
      return null;
    }
  }

  /// 根據元素類型生成 Signed URL
  /// ⭐ v3.7: 不使用 _executeOperation，避免在 build 過程中觸發 notifyListeners
  @override
  Future<String?> generateSignedUrlByElementType({
    required String elementType,
    required String path,
  }) async {
    try {
      return await _storage.generateSignedUrlByElementType(
        elementType: elementType,
        path: path,
      );
    } catch (e) {
      _errorService.logError(
        '生成存取網址失敗: $e',
        type: 'SessionNoteControllerError',
      );
      return null;
    }
  }

  /// 刪除 Storage 檔案
  @override
  Future<bool> deleteFile({
    required String bucket,
    required String path,
  }) async {
    bool success = false;
    
    await _executeOperation(() async {
      await _storage.deleteFile(bucket: bucket, path: path);
      success = true;
    }, '刪除檔案失敗');
    
    return success;
  }

  /// 根據元素類型刪除檔案
  @override
  Future<bool> deleteFileByElementType({
    required String elementType,
    required String path,
  }) async {
    bool success = false;
    
    await _executeOperation(() async {
      await _storage.deleteFileByElementType(
        elementType: elementType,
        path: path,
      );
      success = true;
    }, '刪除檔案失敗');
    
    return success;
  }

  // ============================================================================
  // 篩選條件管理
  // ============================================================================

  /// 設定學員篩選
  @override
  void setClientFilter(String? clientId) {
    _state.setClientFilter(clientId);
  }

  /// 設定日期範圍篩選
  @override
  void setDateRangeFilter(DateTime? startDate, DateTime? endDate) {
    _state.setDateRangeFilter(startDate, endDate);
  }

  /// 設定標籤篩選
  @override
  void setTagsFilter(List<String>? tags) {
    _state.setTagsFilter(tags);
  }

  /// 設定可見性篩選
  @override
  void setVisibilityFilter(String? visibility) {
    _state.setVisibilityFilter(visibility);
  }

  /// 清除所有篩選條件
  @override
  void clearFilters() {
    _state.clearFilters();
  }

  // ============================================================================
  // 狀態管理
  // ============================================================================

  /// 設定選中的筆記
  @override
  void setSelectedNote(SessionNoteModel? note) {
    _state.setSelectedNote(note);
  }

  /// 清除選中的筆記
  @override
  void clearSelectedNote() {
    _state.clearSelectedNote();
  }

  /// 清除錯誤訊息
  @override
  void clearError() {
    _state.clearError();
  }

  /// 重置所有狀態
  @override
  void reset() {
    _state.reset();
  }

  // ============================================================================
  // 內部輔助方法
  // ============================================================================

  /// 執行操作（統一錯誤處理）
  Future<void> _executeOperation(
    Future<void> Function() operation,
    String errorMessage,
  ) async {
    try {
      _state.setLoading(true);
      _state.clearError();
      
      await operation();
      
    } catch (e) {
      final error = '$errorMessage: $e';
      _state.setError(error);
      _errorService.logError(error, type: 'SessionNoteControllerError');
      
      if (kDebugMode) {
        debugPrint('❌ [SessionNoteController] $error');
      }
      
      rethrow;
      
    } finally {
      _state.setLoading(false);
    }
  }

  // ============================================================================
  // ⭐ MVVM 重構：直接查詢方法（返回結果，不更新 Controller 狀態）
  // ============================================================================

  /// 查詢與預約關聯的筆記（直接返回結果）
  /// ⭐ v3.6 MVVM 重構
  ///
  /// 用於課程紀錄頁面等需要直接獲取數據的場景
  @override
  Future<List<SessionNoteModel>> getNotesByAppointment({
    required String appointmentId,
  }) async {
    try {
      return await _noteService.getNotesByAppointment(
        appointmentId: appointmentId,
      );
    } catch (e) {
      _errorService.logError(
        '查詢預約筆記失敗: $e',
        type: 'SessionNoteControllerError',
      );
      return [];
    }
  }

  @override
  void dispose() {
    _state.removeListener(notifyListeners);
    _state.dispose();
    super.dispose();
  }
}

