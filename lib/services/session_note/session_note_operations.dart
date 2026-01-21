import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'session_note_storage_manager.dart';

/// Session Note 操作管理器（子模組）
///
/// 職責：處理筆記的 CRUD 操作
class SessionNoteOperations {
  final SupabaseClient _supabase;
  final SessionNoteStorageManager _storage;
  final ErrorHandlingService _errorService;

  SessionNoteOperations(this._supabase, this._storage, this._errorService);

  /// 創建筆記
  Future<SessionNoteModel> createNote(SessionNoteModel note) async {
    try {
      final data = note.toSupabase(includeId: false);

      final response =
          await _supabase.from('session_notes').insert(data).select().single();

      return SessionNoteModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '創建筆記失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }

  /// 更新筆記
  Future<SessionNoteModel> updateNote(SessionNoteModel note) async {
    try {
      final data = note.toSupabase(includeId: false);

      final response = await _supabase
          .from('session_notes')
          .update(data)
          .eq('id', note.id)
          .select()
          .single();

      return SessionNoteModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '更新筆記失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }

  /// 刪除筆記
  ///
  /// 會同時刪除：
  /// 1. Storage 中的所有照片
  /// 2. 資料庫中的筆記記錄
  Future<void> deleteNote(String noteId) async {
    try {
      // 1. 先查詢筆記內容，取得照片列表
      final noteData = await _supabase
          .from('session_notes')
          .select('content')
          .eq('id', noteId)
          .maybeSingle();

      if (noteData != null) {
        // 2. 提取照片路徑（從 JSONB content 欄位）
        final content = noteData['content'] as Map<String, dynamic>?;
        if (content != null) {
          final visualElements = content['visual_elements'] as List<dynamic>?;
          if (visualElements != null && visualElements.isNotEmpty) {
            final photoPaths = visualElements
                .where((element) => element['type'] == 'photo')
                .map((element) => element['storage_path'] as String)
                .toList();

            // 3. 批量刪除 Storage 照片
            if (photoPaths.isNotEmpty) {
              await _storage.batchDeleteFiles(
                bucket: 'session_photos',
                paths: photoPaths,
              );
            }
          }
        }
      }

      // 4. 刪除資料庫記錄
      await _supabase.from('session_notes').delete().eq('id', noteId);
    } catch (e) {
      _errorService.logError(
        '刪除筆記失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }

  /// 切換筆記可見性（private <-> shared）
  Future<SessionNoteModel> toggleVisibility(String noteId) async {
    try {
      // 先取得當前筆記
      final currentNote = await _supabase
          .from('session_notes')
          .select('visibility')
          .eq('id', noteId)
          .single();

      final currentVisibility = currentNote['visibility'] as String;
      final newVisibility =
          currentVisibility == 'private' ? 'shared' : 'private';

      // 更新可見性
      final response = await _supabase
          .from('session_notes')
          .update({'visibility': newVisibility})
          .eq('id', noteId)
          .select()
          .single();

      return SessionNoteModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '切換筆記可見性失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }

  /// 隱藏筆記（教練或學員）⭐ 新增
  ///
  /// 當關係為 archived 時，雙方可以選擇「移除」共享筆記，
  /// 實際上是 UPDATE hidden_by_client/hidden_by_coach = true。
  ///
  /// **自動清理邏輯**：
  /// 如果更新後雙方都已隱藏（hidden_by_client = true AND hidden_by_coach = true），
  /// 則自動呼叫 deleteNote() 真正刪除記錄（包含 Storage 檔案清理）。
  ///
  /// [noteId] 筆記 ID
  /// [isCoach] true = 教練隱藏（更新 hidden_by_coach），false = 學員隱藏（更新 hidden_by_client）
  Future<void> hideNote({
    required String noteId,
    required bool isCoach,
  }) async {
    try {
      // 1. 先查詢當前狀態
      final currentNote = await _supabase
          .from('session_notes')
          .select('hidden_by_client, hidden_by_coach')
          .eq('id', noteId)
          .maybeSingle();

      if (currentNote == null) {
        throw Exception('筆記不存在');
      }

      final currentHiddenByClient =
          currentNote['hidden_by_client'] as bool? ?? false;
      final currentHiddenByCoach =
          currentNote['hidden_by_coach'] as bool? ?? false;

      // 2. 更新隱藏狀態
      final updateData =
          isCoach ? {'hidden_by_coach': true} : {'hidden_by_client': true};

      await _supabase.from('session_notes').update(updateData).eq('id', noteId);

      // 3. 檢查是否雙方都已隱藏（包含本次更新）
      final bothHidden = isCoach
          ? (currentHiddenByClient && true) // 教練隱藏 + 學員已隱藏
          : (true && currentHiddenByCoach); // 學員隱藏 + 教練已隱藏

      // 4. 如果雙方都隱藏，真正刪除記錄（包含 Storage 清理）
      if (bothHidden) {
        await deleteNote(noteId);
      }
    } catch (e) {
      _errorService.logError(
        '隱藏筆記失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }
}
