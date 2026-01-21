import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/services/interfaces/i_session_note_service.dart';
import 'package:strengthwise/services/session_note/session_note_query_manager.dart';
import 'package:strengthwise/services/session_note/session_note_operations.dart';
import 'package:strengthwise/services/session_note/session_note_storage_manager.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';

/// Session Note Service Supabase 實現
///
/// Phase 3: 視覺化筆記系統
/// 完全解耦合設計 + 子模組化
class SessionNoteServiceSupabase implements ISessionNoteService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;

  // 子模組
  late final SessionNoteQueryManager _queryManager;
  late final SessionNoteOperations _operations;
  late final SessionNoteStorageManager _storageManager;

  SessionNoteServiceSupabase(this._supabase, this._errorService) {
    _storageManager = SessionNoteStorageManager(_supabase, _errorService);
    _queryManager = SessionNoteQueryManager(_supabase, _errorService);
    _operations = SessionNoteOperations(_supabase, _storageManager, _errorService);
  }

  // ==================== 查詢方法（委派給 QueryManager）====================

  @override
  Future<List<SessionNoteModel>> getCoachNotes({
    required String coachId,
    String? clientId,
    String? clientName, // ⭐ 新增：用於查詢已刪除學員的筆記
    int limit = 20,
    String? lastNoteId,
  }) {
    return _queryManager.getCoachNotes(
      coachId: coachId,
      clientId: clientId,
      clientName: clientName, // ⭐ 傳遞參數
      limit: limit,
      lastNoteId: lastNoteId,
    );
  }

  @override
  Future<List<SessionNoteModel>> getClientNotes({
    required String clientId,
    String? coachId, // ⭐ 新增：用於教練篩選
    String? coachName, // ⭐ 新增：用於查詢已刪除教練的筆記
    int limit = 20,
    String? lastNoteId,
  }) {
    return _queryManager.getClientNotes(
      clientId: clientId,
      coachId: coachId, // ⭐ 傳遞參數
      coachName: coachName, // ⭐ 傳遞參數
      limit: limit,
      lastNoteId: lastNoteId,
    );
  }

  @override
  Future<SessionNoteModel?> getNoteById(String noteId) {
    return _queryManager.getNoteById(noteId);
  }

  @override
  Future<List<SessionNoteModel>> getNotesByAppointment({
    required String appointmentId,
  }) {
    return _queryManager.getNotesByAppointment(
      appointmentId: appointmentId,
    );
  }

  @override
  Future<List<SessionNoteModel>> getNotesByWorkoutLog({
    required String workoutLogId,
  }) {
    return _queryManager.getNotesByWorkoutLog(workoutLogId: workoutLogId);
  }

  @override
  Future<List<SessionNoteModel>> searchNotes({
    required String coachId,
    String? keyword,
    List<String>? tags,
    int limit = 20,
  }) {
    return _queryManager.searchNotes(
      coachId: coachId,
      keyword: keyword,
      tags: tags,
      limit: limit,
    );
  }

  // ==================== CRUD 操作（委派給 Operations）====================

  @override
  Future<SessionNoteModel> createNote(SessionNoteModel note) {
    return _operations.createNote(note);
  }

  @override
  Future<SessionNoteModel> updateNote(SessionNoteModel note) {
    return _operations.updateNote(note);
  }

  @override
  Future<void> deleteNote(String noteId) {
    return _operations.deleteNote(noteId);
  }

  @override
  Future<SessionNoteModel> toggleVisibility(String noteId) {
    return _operations.toggleVisibility(noteId);
  }

  @override
  Future<void> hideNote({
    required String noteId,
    required bool isCoach,
  }) {
    return _operations.hideNote(noteId: noteId, isCoach: isCoach);
  }

  // ==================== Storage 操作（委派給 StorageManager）====================

  @override
  Future<String> uploadDrawing({
    required String coachId,
    required String clientId,
    required File file,
  }) {
    return _storageManager.uploadDrawing(
      coachId: coachId,
      clientId: clientId,
      file: file,
    );
  }

  @override
  Future<String> uploadPhoto({
    required String coachId,
    required String clientId,
    required File file,
  }) {
    return _storageManager.uploadPhoto(
      coachId: coachId,
      clientId: clientId,
      file: file,
    );
  }

  @override
  Future<String> uploadVoiceNote({
    required String coachId,
    required String clientId,
    required File file,
  }) {
    return _storageManager.uploadVoiceNote(
      coachId: coachId,
      clientId: clientId,
      file: file,
    );
  }

  @override
  Future<String> generateSignedUrl({
    required String bucket,
    required String path,
  }) {
    return _storageManager.generateSignedUrl(bucket: bucket, path: path);
  }

  @override
  Future<void> deleteStorageFile({
    required String bucket,
    required String path,
  }) {
    return _storageManager.deleteStorageFile(bucket: bucket, path: path);
  }

  // ==================== 統計方法（委派給 QueryManager）====================

  @override
  Future<Map<String, int>> getCoachNoteStats({
    required String coachId,
    String? clientId,
  }) {
    return _queryManager.getCoachNoteStats(
      coachId: coachId,
      clientId: clientId,
    );
  }

  @override
  Future<Map<String, int>> getClientNoteStats({
    required String clientId,
  }) {
    return _queryManager.getClientNoteStats(clientId: clientId);
  }
}

