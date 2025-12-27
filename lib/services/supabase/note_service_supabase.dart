import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/note_model.dart';
import '../interfaces/i_note_service.dart';
import '../core/error_handling_service.dart';
import '../service_locator.dart' show Environment;
import 'note/note_cache_manager.dart';
import 'note/note_operations.dart';

/// 筆記服務的 Supabase 實現
/// 
/// 提供筆記的創建、讀取、更新、刪除等功能（Supabase PostgreSQL 版本）
class NoteServiceSupabase implements INoteService {
  // 依賴注入
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;
  
  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;
  
  // 服務配置
  bool _cacheNotes = true;
  
  // 子模組
  late final NoteCacheManager _cacheManager;
  late final NoteOperations _operations;
  
  /// 創建服務實例
  NoteServiceSupabase({
    required SupabaseClient supabase,
    ErrorHandlingService? errorService,
  }) : 
    _supabase = supabase,
    _errorService = errorService ?? ErrorHandlingService() {
    _cacheManager = NoteCacheManager();
    _operations = NoteOperations(
      supabase: _supabase,
      logDebug: _logDebug,
    );
  }
  
  /// 初始化服務
  Future<void> initialize({Environment environment = Environment.development}) async {
    if (_isInitialized) return;
    
    try {
      configureForEnvironment(environment);
      
      if (_cacheNotes) {
        _cacheManager.setupCacheCleanupTimer();
      }
      
      _isInitialized = true;
      _logDebug('筆記服務初始化完成');
    } catch (e) {
      _logError('筆記服務初始化失敗: $e');
      rethrow;
    }
  }
  
  /// 釋放資源
  Future<void> dispose() async {
    try {
      _cacheManager.dispose();
      _isInitialized = false;
      _logDebug('筆記服務資源已釋放');
    } catch (e) {
      _logError('釋放筆記服務資源時發生錯誤: $e');
    }
  }
  
  /// 根據環境配置服務
  void configureForEnvironment(Environment environment) {
    _environment = environment;
    
    switch (environment) {
      case Environment.development:
        _cacheNotes = true;
        _cacheManager.configure(50);
        _logDebug('筆記服務配置為開發環境');
        break;
      case Environment.testing:
        _cacheNotes = false;
        _cacheManager.configure(10);
        _logDebug('筆記服務配置為測試環境');
        break;
      case Environment.production:
        _cacheNotes = true;
        _cacheManager.configure(30);
        _logDebug('筆記服務配置為生產環境');
        break;
    }
  }
  
  // 獲取當前用戶ID
  String? get currentUserId {
    _ensureInitialized();
    return _supabase.auth.currentUser?.id;
  }
  
  @override
  Future<List<Note>> getUserNotes() async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logDebug('獲取用戶筆記：沒有登入用戶');
      return [];
    }
    
    // 檢查緩存
    if (_cacheNotes && _cacheManager.isListCacheValid()) {
      final cached = _cacheManager.getListCache();
      if (cached != null) {
        _logDebug('從緩存獲取用戶筆記列表 (${cached.length} 個筆記)');
        return List.unmodifiable(cached);
      }
    }
    
    try {
      final notes = await _operations.getUserNotes(currentUserId!);
      
      // 更新緩存
      if (_cacheNotes) {
        _cacheManager.updateListCache(notes);
      }
      
      return notes;
    } catch (e) {
      _logError('獲取筆記失敗: $e');
      
      // 返回可能過期的緩存數據
      if (_cacheNotes) {
        final cached = _cacheManager.getListCache();
        if (cached != null) {
          _logDebug('服務器獲取失敗，返回可能過期的緩存數據');
          return List.unmodifiable(cached);
        }
      }
      
      return [];
    }
  }
  
  @override
  Future<Note?> getNoteById(String noteId) async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logDebug('獲取筆記詳情：沒有登入用戶');
      return null;
    }
    
    // 檢查緩存
    if (_cacheNotes) {
      final cached = _cacheManager.getNoteCache(noteId);
      if (cached != null) {
        _logDebug('從緩存獲取筆記: $noteId');
        return cached;
      }
    }
    
    try {
      final note = await _operations.getNoteById(currentUserId!, noteId);
      
      if (note == null) {
        return null;
      }
      
      // 更新緩存
      if (_cacheNotes) {
        _cacheManager.updateNoteCache(noteId, note);
      }
      
      return note;
    } catch (e) {
      _logError('獲取筆記詳情失敗: $e');
      return null;
    }
  }
  
  @override
  Future<Note> createNote(String title, String textContent, List<DrawingPoint>? drawingPoints) async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logError('創建筆記失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }
    
    try {
      final newNote = await _operations.createNote(
        userId: currentUserId!,
        title: title,
        textContent: textContent,
        drawingPoints: drawingPoints,
      );
      
      // 更新緩存
      if (_cacheNotes) {
        _cacheManager.addNoteToListCache(newNote);
      }
      
      return newNote;
    } catch (e) {
      _logError('創建筆記失敗: $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> updateNote(Note note) async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logError('更新筆記失敗：沒有登入用戶');
      return false;
    }
    
    try {
      final updatedNote = await _operations.updateNote(
        userId: currentUserId!,
        note: note,
      );
      
      // 更新緩存
      if (_cacheNotes) {
        _cacheManager.updateNoteInListCache(updatedNote);
      }
      
      return true;
    } catch (e) {
      _logError('更新筆記失敗: $e');
      return false;
    }
  }
  
  @override
  Future<bool> deleteNote(String noteId) async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logError('刪除筆記失敗：沒有登入用戶');
      return false;
    }
    
    try {
      await _operations.deleteNote(currentUserId!, noteId);
      
      // 更新緩存
      if (_cacheNotes) {
        _cacheManager.removeNoteCache(noteId);
      }
      
      return true;
    } catch (e) {
      _logError('刪除筆記失敗: $e');
      return false;
    }
  }
  
  /// 確保服務已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      _logDebug('警告: 筆記服務在初始化前被調用');
      if (_environment == Environment.development) {
        initialize();
      } else {
        throw StateError('筆記服務未初始化');
      }
    }
  }
  
  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[NOTE] $message');
    }
  }
  
  /// 記錄錯誤信息
  void _logError(String message) {
    if (kDebugMode) {
      print('[NOTE ERROR] $message');
    }
    _errorService.logError(message);
  }
}
