import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'session_note_storage_manager.dart';

/// Session Note 操作管理器（子模組）
/// 
/// 職責：處理筆記的 CRUD 操作
class SessionNoteOperations {
  final SupabaseClient _supabase;
  final SessionNoteStorageManager _storage;

  SessionNoteOperations(this._supabase, this._storage);

  /// 創建筆記
  Future<SessionNoteModel> createNote(SessionNoteModel note) async {
    final data = note.toSupabase(includeId: false);

    final response = await _supabase
        .from('session_notes')
        .insert(data)
        .select()
        .single();

    return SessionNoteModel.fromSupabase(response);
  }

  /// 更新筆記
  Future<SessionNoteModel> updateNote(SessionNoteModel note) async {
    final data = note.toSupabase(includeId: false);

    final response = await _supabase
        .from('session_notes')
        .update(data)
        .eq('id', note.id)
        .select()
        .single();

    return SessionNoteModel.fromSupabase(response);
  }

  /// 刪除筆記
  /// 
  /// 會同時刪除：
  /// 1. Storage 中的所有照片
  /// 2. 資料庫中的筆記記錄
  Future<void> deleteNote(String noteId) async {
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
  }

  /// 切換筆記可見性（private <-> shared）
  Future<SessionNoteModel> toggleVisibility(String noteId) async {
    // 先取得當前筆記
    final currentNote = await _supabase
        .from('session_notes')
        .select('visibility')
        .eq('id', noteId)
        .single();

    final currentVisibility = currentNote['visibility'] as String;
    final newVisibility = currentVisibility == 'private' ? 'shared' : 'private';

    // 更新可見性
    final response = await _supabase
        .from('session_notes')
        .update({'visibility': newVisibility})
        .eq('id', noteId)
        .select()
        .single();

    return SessionNoteModel.fromSupabase(response);
  }
}

