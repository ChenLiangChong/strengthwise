import '../../models/note_model.dart';

/// 筆記緩存管理器
class NoteCacheManager {
  // 數據緩存
  List<Note>? _cachedNotes;
  final Map<String, Note> _noteDetailsCache = {};
  DateTime? _lastNotesRefreshTime;

  /// 緩存的筆記
  List<Note> get cachedNotes => _cachedNotes ?? [];

  /// 檢查是否需要刷新緩存
  /// 
  /// 默認5分鐘後需要刷新
  bool shouldRefresh() {
    if (_lastNotesRefreshTime == null || _cachedNotes == null) {
      return true;
    }
    
    final now = DateTime.now();
    return now.difference(_lastNotesRefreshTime!).inMinutes > 5;
  }

  /// 更新筆記列表緩存
  void updateNotesCache(List<Note> notes) {
    _cachedNotes = notes;
    _lastNotesRefreshTime = DateTime.now();
  }

  /// 檢查筆記詳情緩存
  bool hasNoteDetails(String noteId) {
    return _noteDetailsCache.containsKey(noteId);
  }

  /// 獲取筆記詳情
  Note? getNoteDetails(String noteId) {
    return _noteDetailsCache[noteId];
  }

  /// 設置筆記詳情緩存
  void setNoteDetails(String noteId, Note note) {
    _noteDetailsCache[noteId] = note;
  }

  /// 從列表緩存中查找筆記
  Note? findNoteInListCache(String noteId) {
    if (_cachedNotes == null) return null;
    
    return _cachedNotes!
        .where((note) => note.id == noteId)
        .firstOrNull;
  }

  /// 添加筆記到緩存
  void addNoteToCache(Note note) {
    if (_cachedNotes != null) {
      _cachedNotes = [..._cachedNotes!, note];
    }
  }

  /// 更新緩存中的筆記
  void updateNoteInCache(Note note) {
    _noteDetailsCache[note.id] = note;
    
    if (_cachedNotes != null) {
      _cachedNotes = _cachedNotes!.map((n) => 
        n.id == note.id ? note : n
      ).toList();
    }
  }

  /// 從緩存中移除筆記
  void removeNoteFromCache(String noteId) {
    _noteDetailsCache.remove(noteId);
    
    if (_cachedNotes != null) {
      _cachedNotes = _cachedNotes!
          .where((note) => note.id != noteId)
          .toList();
    }
  }

  /// 清除緩存
  void clearCache() {
    _cachedNotes = null;
    _noteDetailsCache.clear();
    _lastNotesRefreshTime = null;
  }
}

