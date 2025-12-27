import 'package:flutter/material.dart';
import '../../../models/note_model.dart';
import '../../../controllers/interfaces/i_note_controller.dart';
import '../../../services/core/error_handling_service.dart';
import '../../../services/service_locator.dart';
import '../../../utils/notification_utils.dart';
import '../notes/note_editor_page.dart';
import '../statistics/statistics_page_v2.dart';
import 'widgets/empty_records_state.dart';
import 'widgets/notes_list.dart';

/// 訓練記錄頁面
class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  _RecordsPageState createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  late final INoteController _controller;
  late final ErrorHandlingService _errorService;
  
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // 從服務定位器獲取依賴
    _controller = serviceLocator<INoteController>();
    _errorService = serviceLocator<ErrorHandlingService>();
    
    _loadNotes();
  }

  /// 載入筆記列表
  Future<void> _loadNotes() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final notes = await _controller.loadUserNotes();
      
      if (!mounted) return;
      
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      _errorService.handleLoadingError(context, e);
    }
  }
  
  /// 刪除筆記
  Future<void> _deleteNote(String noteId) async {
    try {
      final success = await _controller.deleteNote(noteId);
      
      if (!mounted) return;
      
      if (success) {
        setState(() {
          _notes.removeWhere((note) => note.id == noteId);
        });
        
        NotificationUtils.showSuccess(context, '筆記已刪除');
      } else {
        NotificationUtils.showError(context, '刪除筆記失敗');
      }
    } catch (e) {
      if (!mounted) return;
      
      _errorService.handleError(context, e, customMessage: '刪除筆記失敗');
    }
  }
  
  /// 導航到筆記編輯頁面
  void _navigateToNoteEditor(Note? note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(note: note),
      ),
    );
    
    if (result == true) {
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練記錄'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _navigateToStatistics,
            tooltip: '訓練統計',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNoteEditor(null),
        tooltip: '新建筆記',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 建構頁面主體
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: _notes.isEmpty
          ? const EmptyRecordsState()
          : NotesList(
              notes: _notes,
              onNavigateToEditor: _navigateToNoteEditor,
              onDeleteNote: _deleteNote,
            ),
    );
  }

  /// 導航到統計頁面
  void _navigateToStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StatisticsPageV2(),
      ),
    );
  }
} 