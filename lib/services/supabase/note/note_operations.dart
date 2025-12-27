import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/note_model.dart';
import '../../../utils/firestore_id_generator.dart';
import 'note_data_parser.dart';

/// 筆記資料庫操作
class NoteOperations {
  final SupabaseClient _supabase;
  final Function(String) _logDebug;

  NoteOperations({
    required SupabaseClient supabase,
    required Function(String) logDebug,
  })  : _supabase = supabase,
        _logDebug = logDebug;

  /// 獲取用戶筆記列表
  Future<List<Note>> getUserNotes(String userId) async {
    _logDebug('從 Supabase 獲取用戶筆記');
    final response = await _supabase
        .from('notes')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    
    final notesData = response as List<dynamic>;
    final notes = notesData
        .map((data) => NoteDataParser.parseFromSupabase(data as Map<String, dynamic>))
        .toList();
    
    _logDebug('成功獲取 ${notes.length} 個筆記');
    return notes;
  }

  /// 獲取單個筆記
  Future<Note?> getNoteById(String userId, String noteId) async {
    _logDebug('從 Supabase 獲取筆記: $noteId');
    final response = await _supabase
        .from('notes')
        .select()
        .eq('id', noteId)
        .eq('user_id', userId)
        .maybeSingle();
    
    if (response == null) {
      _logDebug('筆記不存在: $noteId');
      return null;
    }
    
    final note = NoteDataParser.parseFromSupabase(response);
    _logDebug('成功獲取筆記詳情: ${note.title}');
    return note;
  }

  /// 創建筆記
  Future<Note> createNote({
    required String userId,
    required String title,
    required String textContent,
    List<DrawingPoint>? drawingPoints,
  }) async {
    _logDebug('創建新筆記: $title');
    final now = DateTime.now();
    final noteId = generateFirestoreId();
    
    final noteData = {
      'id': noteId,
      'user_id': userId,
      'title': title,
      'text_content': textContent,
      'drawing_points': drawingPoints?.map((p) => p.toMap()).toList(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
    
    await _supabase.from('notes').insert(noteData);
    
    final newNote = Note(
      id: noteId,
      title: title,
      textContent: textContent,
      drawingPoints: drawingPoints,
      createdAt: now,
      updatedAt: now,
    );
    
    _logDebug('筆記創建成功: ${newNote.id}');
    return newNote;
  }

  /// 更新筆記
  Future<Note> updateNote({
    required String userId,
    required Note note,
  }) async {
    _logDebug('更新筆記: ${note.id} - ${note.title}');
    final now = DateTime.now();
    
    await _supabase
        .from('notes')
        .update({
          'title': note.title,
          'text_content': note.textContent,
          'drawing_points': note.drawingPoints?.map((p) => p.toMap()).toList(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', note.id)
        .eq('user_id', userId);
    
    final updatedNote = Note(
      id: note.id,
      title: note.title,
      textContent: note.textContent,
      drawingPoints: note.drawingPoints,
      createdAt: note.createdAt,
      updatedAt: now,
    );
    
    _logDebug('筆記更新成功');
    return updatedNote;
  }

  /// 刪除筆記
  Future<void> deleteNote(String userId, String noteId) async {
    _logDebug('刪除筆記: $noteId');
    
    await _supabase
        .from('notes')
        .delete()
        .eq('id', noteId)
        .eq('user_id', userId);
    
    _logDebug('筆記刪除成功');
  }
}

