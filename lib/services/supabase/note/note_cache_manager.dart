import 'dart:async';
import '../../../models/note_model.dart';

/// 筆記快取管理器
class NoteCacheManager {
  // 筆記緩存
  final Map<String, Note> _noteCache = {};
  List<Note>? _userNotesCache;
  DateTime? _userNotesCacheTime;
  
  // 配置
  int _noteCacheLimit = 30;
  Timer? _cacheClearTimer;

  void configure(int limit) {
    _noteCacheLimit = limit;
  }

  /// 檢查列表緩存是否有效
  bool isListCacheValid() {
    if (_userNotesCache == null || _userNotesCacheTime == null) return false;
    final cacheAge = DateTime.now().difference(_userNotesCacheTime!);
    return cacheAge.inMinutes < 10; // 10 分鐘有效
  }

  /// 取得列表緩存
  List<Note>? getListCache() => _userNotesCache;

  /// 更新列表緩存
  void updateListCache(List<Note> notes) {
    _userNotesCache = notes;
    _userNotesCacheTime = DateTime.now();
    
    // 同時更新單個筆記緩存
    for (final note in notes) {
      _noteCache[note.id] = note;
    }
    _manageCache();
  }

  /// 取得單個筆記緩存
  Note? getNoteCache(String noteId) => _noteCache[noteId];

  /// 更新單個筆記緩存
  void updateNoteCache(String noteId, Note note) {
    _noteCache[noteId] = note;
    _manageCache();
  }

  /// 移除筆記緩存
  void removeNoteCache(String noteId) {
    _noteCache.remove(noteId);
    
    if (_userNotesCache != null) {
      _userNotesCache = _userNotesCache!.where((note) => note.id != noteId).toList();
      _userNotesCacheTime = DateTime.now();
    }
  }

  /// 新增筆記到列表緩存
  void addNoteToListCache(Note note) {
    if (_userNotesCache != null) {
      _userNotesCache = [note, ..._userNotesCache!];
      _userNotesCacheTime = DateTime.now();
    }
    
    _noteCache[note.id] = note;
    _manageCache();
  }

  /// 更新列表中的筆記
  void updateNoteInListCache(Note updatedNote) {
    _noteCache[updatedNote.id] = updatedNote;
    
    if (_userNotesCache != null) {
      _userNotesCache = _userNotesCache!
          .map((n) => n.id == updatedNote.id ? updatedNote : n)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        
      _userNotesCacheTime = DateTime.now();
    }
  }

  /// 管理緩存大小
  void _manageCache() {
    if (_noteCache.length > _noteCacheLimit) {
      _noteCache.clear();
    }
  }

  /// 清除所有緩存
  void clearAll() {
    _noteCache.clear();
    _userNotesCache = null;
    _userNotesCacheTime = null;
  }

  /// 設置緩存清理計時器
  void setupCacheCleanupTimer() {
    _cacheClearTimer?.cancel();
    _cacheClearTimer = Timer.periodic(const Duration(hours: 2), (_) {
      clearAll();
    });
  }

  /// 釋放資源
  void dispose() {
    _cacheClearTimer?.cancel();
    _cacheClearTimer = null;
    clearAll();
  }
}

