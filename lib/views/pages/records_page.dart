import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import 'note_editor_page.dart';
import 'dart:math';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  _RecordsPageState createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  // 暫時使用本地數據，後期可替換為數據庫
  List<Note> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // 模擬從數據庫加載數據
    _loadNotes();
  }

  void _loadNotes() async {
    // 暫時使用模擬數據
    await Future.delayed(const Duration(milliseconds: 800));
    
    final mockNotes = List.generate(
      5,
      (index) => Note(
        id: 'note_${index + 1}',
        title: '訓練筆記 ${index + 1}',
        textContent: '這是訓練筆記的內容，記錄了一些重要的訓練心得...',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now().subtract(Duration(days: index, hours: Random().nextInt(5))),
      ),
    );
    
    if (mounted) {
      setState(() {
        notes = mockNotes;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練記錄'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? _buildEmptyState()
              : _buildNotesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToNoteEditor(null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
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
                      if (note.drawingPoints != null)
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
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  void _navigateToNoteEditor(Note? note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(
          note: note,
          onSave: (savedNote) {
            _handleNoteSaved(savedNote);
          },
        ),
      ),
    );
  }

  void _handleNoteSaved(Note savedNote) {
    setState(() {
      // 查找是否已有此筆記
      final existingIndex = notes.indexWhere((note) => note.id == savedNote.id);
      if (existingIndex >= 0) {
        // 更新現有筆記
        notes[existingIndex] = savedNote;
      } else {
        // 添加新筆記
        notes.add(savedNote);
      }
      // 按更新時間排序
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }
} 