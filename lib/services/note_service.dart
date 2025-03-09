import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/note_model.dart';
import 'interfaces/i_note_service.dart';
import 'error_handling_service.dart';
import 'service_locator.dart' show Environment;

/// 筆記服務的Firebase實現
/// 
/// 提供筆記的創建、讀取、更新、刪除等功能
/// 支持環境配置，緩存機制和統一錯誤處理
class NoteService implements INoteService {
  // 依賴注入
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ErrorHandlingService _errorService;
  
  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;
  
  // 服務配置
  bool _cacheNotes = true;
  int _queryTimeout = 10; // 秒
  int _noteCacheLimit = 30;
  
  // 筆記緩存
  final Map<String, Note> _noteCache = {};
  List<Note>? _userNotesCache;
  DateTime? _userNotesCacheTime;
  Timer? _cacheClearTimer;
  
  /// 創建服務實例
  /// 
  /// 允許注入自定義的Firestore和Auth實例，便於測試
  NoteService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ErrorHandlingService? errorService,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance,
    _errorService = errorService ?? ErrorHandlingService();
  
  /// 初始化服務
  /// 
  /// 設置環境配置並初始化緩存系統
  Future<void> initialize({Environment environment = Environment.development}) async {
    if (_isInitialized) return;
    
    try {
      // 設置環境
      configureForEnvironment(environment);
      
      // 設置緩存清理計時器（每兩小時）
      if (_cacheNotes) {
        _setupCacheCleanupTimer();
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
      // 取消緩存清理計時器
      _cacheClearTimer?.cancel();
      _cacheClearTimer = null;
      
      // 清空緩存
      _noteCache.clear();
      _userNotesCache = null;
      _userNotesCacheTime = null;
      
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
        // 開發環境設置
        _cacheNotes = true;
        _queryTimeout = 15; // 較長的超時時間，便於調試
        _noteCacheLimit = 50; // 較大的緩存上限，便於開發
        _logDebug('筆記服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設置
        _cacheNotes = false; // 測試需要實時數據，不使用緩存
        _queryTimeout = 8;
        _noteCacheLimit = 10;
        _logDebug('筆記服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設置
        _cacheNotes = true;
        _queryTimeout = 10;
        _noteCacheLimit = 30;
        _logDebug('筆記服務配置為生產環境');
        break;
    }
  }
  
  /// 設置緩存清理計時器
  void _setupCacheCleanupTimer() {
    _cacheClearTimer?.cancel();
    // 每兩小時清理一次緩存
    _cacheClearTimer = Timer.periodic(const Duration(hours: 2), (_) {
      _clearCache();
    });
  }
  
  /// 清除緩存
  void _clearCache() {
    _logDebug('清理筆記緩存');
    _noteCache.clear();
    _userNotesCache = null;
    _userNotesCacheTime = null;
  }
  
  /// 管理筆記緩存大小
  void _manageNoteCache() {
    if (_noteCache.length > _noteCacheLimit) {
      _logDebug('筆記緩存超出限制 (${_noteCache.length}/${_noteCacheLimit})，進行清理');
      
      // 簡單策略：直接清空緩存
      _noteCache.clear();
      _logDebug('筆記緩存已清空');
    }
  }
  
  // 獲取當前用戶ID
  String? get currentUserId {
    _ensureInitialized();
    return _auth.currentUser?.uid;
  }
  
  // 獲取筆記集合引用
  CollectionReference get _notesRef => _firestore.collection('notes');
  
  @override
  Future<List<Note>> getUserNotes() async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logDebug('獲取用戶筆記：沒有登入用戶');
      return [];
    }
    
    // 檢查緩存是否有效（如果啟用）
    if (_cacheNotes && _userNotesCache != null && _userNotesCacheTime != null) {
      final cacheAge = DateTime.now().difference(_userNotesCacheTime!);
      // 緩存有效期為10分鐘
      if (cacheAge.inMinutes < 10) {
        _logDebug('從緩存獲取用戶筆記列表 (${_userNotesCache!.length} 個筆記)');
        return List.unmodifiable(_userNotesCache!);
      }
    }
    
    try {
      _logDebug('從Firestore獲取用戶筆記');
      final querySnapshot = await _notesRef
          .where('userId', isEqualTo: currentUserId)
          .orderBy('updatedAt', descending: true)
          .get()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取筆記列表超時'),
          );
      
      final notes = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // 確保id存在
            data['id'] = doc.id;
            return Note.fromMap(data);
          })
          .toList();
      
      // 更新緩存
      if (_cacheNotes) {
        _userNotesCache = notes;
        _userNotesCacheTime = DateTime.now();
        
        // 同時更新單個筆記緩存
        for (final note in notes) {
          _noteCache[note.id] = note;
        }
        _manageNoteCache();
      }
      
      _logDebug('成功獲取 ${notes.length} 個筆記');
      return notes;
    } catch (e) {
      _logError('獲取筆記失敗: $e');
      
      // 如果緩存可用但可能已過期，在發生錯誤時仍返回緩存數據
      if (_cacheNotes && _userNotesCache != null) {
        _logDebug('服務器獲取失敗，返回可能過期的緩存數據');
        return List.unmodifiable(_userNotesCache!);
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
    if (_cacheNotes && _noteCache.containsKey(noteId)) {
      _logDebug('從緩存獲取筆記: $noteId');
      return _noteCache[noteId];
    }
    
    try {
      _logDebug('從Firestore獲取筆記: $noteId');
      final docSnapshot = await _notesRef.doc(noteId).get()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取筆記詳情超時'),
          );
          
      if (!docSnapshot.exists) {
        _logDebug('筆記不存在: $noteId');
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      if (data['userId'] != currentUserId) {
        _logError('無權訪問此筆記: $noteId');
        throw Exception('無權訪問此筆記');
      }
      
      // 確保id存在
      data['id'] = docSnapshot.id;
      final note = Note.fromMap(data);
      
      // 更新緩存
      if (_cacheNotes) {
        _noteCache[noteId] = note;
        _manageNoteCache();
      }
      
      _logDebug('成功獲取筆記詳情: ${note.title}');
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
      _logDebug('創建新筆記: $title');
      final now = DateTime.now();
      final noteData = {
        'userId': currentUserId,
        'title': title,
        'textContent': textContent,
        'drawingPoints': drawingPoints?.map((p) => p.toMap()).toList(),
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      };
      
      final docRef = await _notesRef.add(noteData)
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('創建筆記超時'),
          );
      
      final newNote = Note(
        id: docRef.id,
        title: title,
        textContent: textContent,
        drawingPoints: drawingPoints,
        createdAt: now,
        updatedAt: now,
      );
      
      // 更新緩存
      if (_cacheNotes) {
        _noteCache[newNote.id] = newNote;
        
        // 更新筆記列表緩存，將新筆記插入到最前面
        if (_userNotesCache != null) {
          _userNotesCache = [newNote, ..._userNotesCache!];
          _userNotesCacheTime = now;
        }
        
        _manageNoteCache();
      }
      
      _logDebug('筆記創建成功: ${newNote.id}');
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
      _logDebug('更新筆記: ${note.id} - ${note.title}');
      final now = DateTime.now();
      await _notesRef.doc(note.id).update({
        'title': note.title,
        'textContent': note.textContent,
        'drawingPoints': note.drawingPoints?.map((p) => p.toMap()).toList(),
        'updatedAt': now.millisecondsSinceEpoch,
      }).timeout(
        Duration(seconds: _queryTimeout),
        onTimeout: () => throw TimeoutException('更新筆記超時'),
      );
      
      // 更新緩存，設置新的時間戳
      final updatedNote = Note(
        id: note.id,
        title: note.title,
        textContent: note.textContent,
        drawingPoints: note.drawingPoints,
        createdAt: note.createdAt,
        updatedAt: now,
      );
      
      if (_cacheNotes) {
        _noteCache[note.id] = updatedNote;
        
        // 更新筆記列表緩存
        if (_userNotesCache != null) {
          _userNotesCache = _userNotesCache!
              .map((n) => n.id == note.id ? updatedNote : n)
              .toList()
            ..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!)); // 重新按更新時間排序
            
          _userNotesCacheTime = now;
        }
      }
      
      _logDebug('筆記更新成功');
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
      _logDebug('刪除筆記: $noteId');
      
      // 檢查權限
      final doc = await _notesRef.doc(noteId).get();
      if (!doc.exists) {
        _logDebug('筆記不存在: $noteId');
        return false;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != currentUserId) {
        _logError('無權刪除此筆記: $noteId');
        throw Exception('無權刪除此筆記');
      }
      
      await _notesRef.doc(noteId).delete()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('刪除筆記超時'),
          );
      
      // 更新緩存
      if (_cacheNotes) {
        _noteCache.remove(noteId);
        
        // 更新筆記列表緩存
        if (_userNotesCache != null) {
          _userNotesCache = _userNotesCache!.where((note) => note.id != noteId).toList();
          _userNotesCacheTime = DateTime.now();
        }
      }
      
      _logDebug('筆記刪除成功');
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
      // 在開發環境中自動初始化，但在其他環境拋出錯誤
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