import 'package:flutter/foundation.dart';
import '../../models/session_note/session_note_model.dart';

/// SessionNoteStateManager - 筆記狀態管理器
/// 
/// 管理筆記相關的所有狀態（列表、載入狀態、篩選條件等）
class SessionNoteStateManager extends ChangeNotifier {
  // ==================== 狀態 ====================
  
  bool _isLoading = false;
  String? _errorMessage;
  List<SessionNoteModel> _notes = [];
  SessionNoteModel? _selectedNote;
  
  // 篩選條件
  String? _filterClientId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  List<String>? _filterTags;
  String? _filterVisibility;
  
  // 統計資料
  int _totalCount = 0;
  int _sharedCount = 0;
  int _privateCount = 0;
  
  // ==================== Getters ====================
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SessionNoteModel> get notes => List.unmodifiable(_notes);
  SessionNoteModel? get selectedNote => _selectedNote;
  
  // 篩選條件
  String? get filterClientId => _filterClientId;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  List<String>? get filterTags => _filterTags;
  String? get filterVisibility => _filterVisibility;
  
  // 統計資料
  int get totalCount => _totalCount;
  int get sharedCount => _sharedCount;
  int get privateCount => _privateCount;
  
  // 衍生狀態
  bool get hasNotes => _notes.isNotEmpty;
  bool get hasError => _errorMessage != null;
  
  /// 取得已分享的筆記
  List<SessionNoteModel> get sharedNotes {
    return _notes.where((note) => note.visibility == 'shared').toList();
  }
  
  /// 取得私人筆記
  List<SessionNoteModel> get privateNotes {
    return _notes.where((note) => note.visibility == 'private').toList();
  }
  
  /// 根據學員 ID 篩選筆記
  List<SessionNoteModel> getNotesForClient(String clientId) {
    return _notes.where((note) => note.clientId == clientId).toList();
  }
  
  // ==================== 狀態更新方法 ====================
  
  /// 設定載入狀態
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 設定錯誤訊息
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  /// 清除錯誤
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// 更新筆記列表
  void setNotes(List<SessionNoteModel> notes) {
    _notes = notes;
    notifyListeners();
  }
  
  /// 新增筆記到列表頂部
  void addNote(SessionNoteModel note) {
    _notes.insert(0, note);
    _totalCount++;
    if (note.visibility == 'shared') {
      _sharedCount++;
    } else {
      _privateCount++;
    }
    notifyListeners();
  }
  
  /// 更新列表中的筆記
  void updateNote(SessionNoteModel updatedNote) {
    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      final oldNote = _notes[index];
      _notes[index] = updatedNote;
      
      // 更新統計（如果可見性改變）
      if (oldNote.visibility != updatedNote.visibility) {
        if (updatedNote.visibility == 'shared') {
          _sharedCount++;
          _privateCount--;
        } else {
          _sharedCount--;
          _privateCount++;
        }
      }
      
      // 如果是選中的筆記，同步更新
      if (_selectedNote?.id == updatedNote.id) {
        _selectedNote = updatedNote;
      }
      
      notifyListeners();
    }
  }
  
  /// 從列表中移除筆記
  void removeNote(String noteId) {
    final index = _notes.indexWhere((note) => note.id == noteId);
    if (index != -1) {
      final removedNote = _notes.removeAt(index);
      _totalCount--;
      if (removedNote.visibility == 'shared') {
        _sharedCount--;
      } else {
        _privateCount--;
      }
      
      // 如果是選中的筆記，清除選中狀態
      if (_selectedNote?.id == noteId) {
        _selectedNote = null;
      }
      
      notifyListeners();
    }
  }
  
  /// 設定選中的筆記
  void setSelectedNote(SessionNoteModel? note) {
    _selectedNote = note;
    notifyListeners();
  }
  
  /// 清除選中的筆記
  void clearSelectedNote() {
    _selectedNote = null;
    notifyListeners();
  }
  
  // ==================== 篩選條件更新 ====================
  
  /// 設定學員篩選
  void setClientFilter(String? clientId) {
    _filterClientId = clientId;
    notifyListeners();
  }
  
  /// 設定日期範圍篩選
  void setDateRangeFilter(DateTime? startDate, DateTime? endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    notifyListeners();
  }
  
  /// 設定標籤篩選
  void setTagsFilter(List<String>? tags) {
    _filterTags = tags;
    notifyListeners();
  }
  
  /// 設定可見性篩選
  void setVisibilityFilter(String? visibility) {
    _filterVisibility = visibility;
    notifyListeners();
  }
  
  /// 清除所有篩選條件
  void clearFilters() {
    _filterClientId = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _filterTags = null;
    _filterVisibility = null;
    notifyListeners();
  }
  
  // ==================== 統計資料更新 ====================
  
  /// 更新統計資料
  void updateStats({
    required int total,
    required int shared,
    required int private,
  }) {
    _totalCount = total;
    _sharedCount = shared;
    _privateCount = private;
    notifyListeners();
  }
  
  /// 重新計算統計資料（從當前列表）
  void recalculateStats() {
    _totalCount = _notes.length;
    _sharedCount = _notes.where((n) => n.visibility == 'shared').length;
    _privateCount = _notes.where((n) => n.visibility == 'private').length;
    notifyListeners();
  }
  
  /// 重置所有狀態
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _notes = [];
    _selectedNote = null;
    _filterClientId = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _filterTags = null;
    _filterVisibility = null;
    _totalCount = 0;
    _sharedCount = 0;
    _privateCount = 0;
    notifyListeners();
  }
}

