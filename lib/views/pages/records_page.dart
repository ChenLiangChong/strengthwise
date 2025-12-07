import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../controllers/interfaces/i_note_controller.dart';
import '../../services/error_handling_service.dart';
import '../../services/service_locator.dart';
import 'note_editor_page.dart';

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
  
  Future<void> _deleteNote(String noteId) async {
    try {
      final success = await _controller.deleteNote(noteId);
      
      if (!mounted) return;
      
      if (success) {
        setState(() {
          _notes.removeWhere((note) => note.id == noteId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('筆記已刪除')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('刪除筆記失敗')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      _errorService.handleError(context, e, customMessage: '刪除筆記失敗');
    }
  }
  
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
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '今天';
    } else if (date.year == now.year) {
      return '${date.month}月${date.day}日';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練記錄'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotes,
              child: _notes.isEmpty
                  ? _buildEmptyState()
                  : _buildNotesList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToNoteEditor(null);
        },
        tooltip: '新建筆記',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '還沒有訓練筆記',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '點擊底部的加號按鈕添加新筆記',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Dismissible(
          key: Key(note.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('確認刪除'),
                content: Text('確定要刪除筆記 "${note.title}" 嗎？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('刪除'),
                  ),
                ],
              ),
            ) ?? false;
          },
          onDismissed: (direction) {
            _deleteNote(note.id);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: InkWell(
              onTap: () {
                _navigateToNoteEditor(note);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(note.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note.textContent,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (note.drawingPoints != null && note.drawingPoints!.isNotEmpty)
                          Icon(
                            Icons.draw,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.text_fields,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 