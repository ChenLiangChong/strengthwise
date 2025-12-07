import 'package:flutter/material.dart';
import 'dart:async';
import '../models/note_model.dart';
import '../services/interfaces/i_note_service.dart';
import '../services/error_handling_service.dart';
import '../services/service_locator.dart' show serviceLocator;
import 'interfaces/i_note_controller.dart';

/// 筆記控制器實現
/// 
/// 管理用戶筆記的業務邏輯，提供數據驗證，錯誤處理和狀態管理功能
class NoteController extends ChangeNotifier implements INoteController {
  // 依賴注入
  final INoteService _noteService;
  final ErrorHandlingService _errorService;
  
  // 狀態管理
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  
  // 數據緩存
  List<Note>? _cachedNotes;
  final Map<String, Note> _noteDetailsCache = {};
  DateTime? _lastNotesRefreshTime;
  
  /// 正在載入數據
  bool get isLoading => _isLoading;
  
  /// 錯誤訊息
  String? get errorMessage => _errorMessage;
  
  /// 緩存的筆記
  List<Note> get cachedNotes => _cachedNotes ?? [];
  
  /// 構造函數，支持依賴注入
  NoteController({
    INoteService? noteService,
    ErrorHandlingService? errorService,
  }) : 
    _noteService = noteService ?? serviceLocator<INoteService>(),
    _errorService = errorService ?? serviceLocator<ErrorHandlingService>() {
    _initialize();
  }
  
  /// 初始化控制器
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      
      // 確保服務已初始化
      if (_noteService.runtimeType.toString().contains('NoteService')) {
        await Future.microtask(() async {
          // 可能的初始化代碼，取決於服務實現
        });
      }
      
      _isInitialized = true;
      _setLoading(false);
    } catch (e) {
      _handleError('初始化筆記控制器失敗', e);
    }
  }
  
  /// 設置載入狀態
  void _setLoading(bool isLoading) {
    if (_isLoading != isLoading) {
      _isLoading = isLoading;
      notifyListeners();
    }
  }
  
  /// 處理錯誤
  void _handleError(String message, [dynamic error]) {
    _errorMessage = message;
    _errorService.logError('$message: $error', type: 'NoteControllerError');
    _setLoading(false);
    notifyListeners();
  }
  
  /// 清除錯誤消息
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  /// 清除緩存
  void clearCache() {
    _cachedNotes = null;
    _noteDetailsCache.clear();
    _lastNotesRefreshTime = null;
  }
  
  /// 釋放資源
  @override
  void dispose() {
    _isInitialized = false;
    clearCache();
    super.dispose();
  }
  
  @override
  Future<List<Note>> loadUserNotes() async {
    if (!_isInitialized) await _initialize();
    
    try {
      // 檢查是否需要重新載入 (5分鐘過期)
      final now = DateTime.now();
      final shouldRefresh = _lastNotesRefreshTime == null || 
          now.difference(_lastNotesRefreshTime!).inMinutes > 5;
      
      if (shouldRefresh || _cachedNotes == null) {
        _setLoading(true);
        clearError();
        
        _cachedNotes = await _noteService.getUserNotes();
        _lastNotesRefreshTime = now;
        
        _setLoading(false);
      }
      
      return _cachedNotes ?? [];
    } catch (e) {
      _handleError('載入筆記失敗', e);
      return _cachedNotes ?? [];
    }
  }
  
  /// 強制重新載入筆記，忽略緩存
  Future<List<Note>> reloadNotes() async {
    _cachedNotes = null;
    return loadUserNotes();
  }
  
  @override
  Future<Note?> getNoteById(String noteId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      // 從緩存中查找
      if (_noteDetailsCache.containsKey(noteId)) {
        return _noteDetailsCache[noteId];
      }
      
      // 從列表緩存中查找
      if (_cachedNotes != null) {
        final cachedNote = _cachedNotes!
            .where((note) => note.id == noteId)
            .firstOrNull;
        
        if (cachedNote != null) {
          _noteDetailsCache[noteId] = cachedNote;
          return cachedNote;
        }
      }
      
      // 從服務獲取
      _setLoading(true);
      clearError();
      
      final note = await _noteService.getNoteById(noteId);
      
      if (note != null) {
        _noteDetailsCache[noteId] = note;
      }
      
      _setLoading(false);
      return note;
    } catch (e) {
      _handleError('獲取筆記詳情失敗', e);
      return null;
    }
  }
  
  @override
  Future<Note> createNote(String title, String textContent, List<DrawingPoint>? drawingPoints) async {
    if (!_isInitialized) await _initialize();
    
    // 輸入驗證
    if (title.trim().isEmpty) {
      _handleError('筆記標題不能為空');
      throw ArgumentError('筆記標題不能為空');
    }
    
    try {
      _setLoading(true);
      clearError();
      
      final note = await _noteService.createNote(title, textContent, drawingPoints);
      
      // 更新緩存
      if (_cachedNotes != null) {
        _cachedNotes = [..._cachedNotes!, note];
      }
      
      _setLoading(false);
      return note;
    } catch (e) {
      _handleError('創建筆記失敗', e);
      rethrow;
    }
  }
  
  @override
  Future<bool> updateNote(Note note) async {
    if (!_isInitialized) await _initialize();
    
    // 輸入驗證
    if (note.title.trim().isEmpty) {
      _handleError('筆記標題不能為空');
      throw ArgumentError('筆記標題不能為空');
    }
    
    try {
      _setLoading(true);
      clearError();
      
      // 更新筆記前更新其修改時間
      final updatedNote = Note(
        id: note.id,
        title: note.title,
        textContent: note.textContent,
        drawingPoints: note.drawingPoints,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
      );
      
      final success = await _noteService.updateNote(updatedNote);
      
      // 更新緩存
      if (success) {
        _noteDetailsCache[note.id] = updatedNote;
        
        if (_cachedNotes != null) {
          _cachedNotes = _cachedNotes!.map((n) => 
            n.id == note.id ? updatedNote : n
          ).toList();
        }
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _handleError('更新筆記失敗', e);
      return false;
    }
  }
  
  @override
  Future<bool> deleteNote(String noteId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      final success = await _noteService.deleteNote(noteId);
      
      // 更新緩存
      if (success) {
        _noteDetailsCache.remove(noteId);
        
        if (_cachedNotes != null) {
          _cachedNotes = _cachedNotes!
              .where((note) => note.id != noteId)
              .toList();
        }
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _handleError('刪除筆記失敗', e);
      return false;
    }
  }
} 