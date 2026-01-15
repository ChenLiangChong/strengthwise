import 'package:flutter/material.dart';
import 'dart:async';
import '../models/note_model.dart';
import '../services/interfaces/i_note_service.dart';
import '../services/core/error_handling_service.dart';
import '../services/service_locator.dart' show serviceLocator;
import 'interfaces/i_note_controller.dart';
import 'note/note_validator.dart';

/// 筆記控制器實現
/// 
/// 管理用戶筆記的業務邏輯，提供數據驗證，錯誤處理和狀態管理功能
/// ⭐ v3.7: 快取統一到 Service 層
class NoteController extends ChangeNotifier implements INoteController {
  // 依賴注入
  final INoteService _noteService;
  final ErrorHandlingService _errorService;
  
  // 狀態管理
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  
  /// 正在載入數據
  bool get isLoading => _isLoading;
  
  /// 錯誤訊息
  String? get errorMessage => _errorMessage;
  
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
  
  /// 釋放資源
  @override
  void dispose() {
    _isInitialized = false;
    super.dispose();
  }
  
  @override
  Future<List<Note>> loadUserNotes() async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      // ⭐ v3.7: 快取統一到 Service 層
      final notes = await _noteService.getUserNotes();
      
      _setLoading(false);
      return notes;
    } catch (e) {
      _handleError('載入筆記失敗', e);
      return [];
    }
  }
  
  /// 強制重新載入筆記
  Future<List<Note>> reloadNotes() async {
    return loadUserNotes();
  }
  
  @override
  Future<Note?> getNoteById(String noteId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      // ⭐ v3.7: 快取統一到 Service 層
      return await _noteService.getNoteById(noteId);
    } catch (e) {
      _handleError('獲取筆記詳情失敗', e);
      return null;
    }
  }
  
  @override
  Future<Note> createNote(String title, String textContent, List<DrawingPoint>? drawingPoints) async {
    if (!_isInitialized) await _initialize();
    
    // 使用驗證器進行輸入驗證
    try {
      NoteValidator.validateCreateParams(title);
    } catch (e) {
      _handleError(e.toString());
      rethrow;
    }
    
    try {
      _setLoading(true);
      clearError();
      
      // ⭐ v3.7: Service 層會自動更新快取
      final note = await _noteService.createNote(title, textContent, drawingPoints);
      
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
    
    // 使用驗證器進行輸入驗證
    try {
      NoteValidator.validateUpdateParams(note);
    } catch (e) {
      _handleError(e.toString());
      rethrow;
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
      
      // ⭐ v3.7: Service 層會自動更新快取
      final success = await _noteService.updateNote(updatedNote);
      
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
      
      // ⭐ v3.7: Service 層會自動更新快取
      final success = await _noteService.deleteNote(noteId);
      
      _setLoading(false);
      return success;
    } catch (e) {
      _handleError('刪除筆記失敗', e);
      return false;
    }
  }
} 