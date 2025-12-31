import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/session_note_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/notes/widgets/session_note_card.dart';
import 'package:strengthwise/views/pages/notes/widgets/empty_notes_state.dart';
import 'package:strengthwise/views/pages/notes/widgets/notes_filter_chip.dart';
import 'package:strengthwise/views/pages/notes/widgets/client_selector_dialog.dart';
import 'package:strengthwise/views/pages/notes/session_note_editor_page.dart';
import 'package:strengthwise/views/pages/notes/session_note_detail_page.dart';

/// 課程筆記列表頁面
/// 
/// 功能：
/// - 教練模式：顯示教練的所有課程筆記（可新增）
/// - 學員模式：顯示學員的共享筆記（只讀）
/// - 支援篩選（全部/私人/共享）
/// - 下拉刷新
/// - 點擊進入詳情頁面
class SessionNotesListPage extends StatefulWidget {
  /// 是否為學員模式（true = 學員查看筆記，false = 教練管理筆記）
  final bool isClientMode;
  
  const SessionNotesListPage({
    Key? key,
    this.isClientMode = false,
  }) : super(key: key);

  @override
  State<SessionNotesListPage> createState() => _SessionNotesListPageState();
}

class _SessionNotesListPageState extends State<SessionNotesListPage> {
  late final SessionNoteController _controller;
  late final IAuthController _authController;
  String _currentFilter = 'all'; // 'all', 'private', 'shared'

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<SessionNoteController>();
    _authController = serviceLocator<IAuthController>();
    _loadNotes();
  }

  /// 載入筆記列表
  Future<void> _loadNotes() async {
    final currentUser = _authController.user;
    if (currentUser == null) return;
    
    if (widget.isClientMode) {
      // 學員模式：載入學員的共享筆記
      await _controller.loadClientNotes(
        clientId: currentUser.uid,
      );
    } else {
      // 教練模式：載入教練的所有筆記
      await _controller.loadCoachNotes(
        coachId: currentUser.uid,
      );
    }
  }

  /// 根據篩選條件過濾筆記
  List<SessionNoteModel> _getFilteredNotes(List<SessionNoteModel> notes) {
    switch (_currentFilter) {
      case 'private':
        return notes.where((note) => note.isPrivate).toList();
      case 'shared':
        return notes.where((note) => note.isShared).toList();
      default:
        return notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isClientMode ? '我的筆記' : '課程筆記'),
          elevation: 0,
          actions: [
            // 新增筆記按鈕（僅教練模式）
            if (!widget.isClientMode)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  // 顯示學員選擇對話框
                  final clientId = await showDialog<String>(
                    context: context,
                    builder: (context) => const ClientSelectorDialog(),
                  );
                  
                  if (clientId != null && mounted) {
                    // 導航到新增筆記頁面
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionNoteEditorPage(
                          clientId: clientId,
                        ),
                      ),
                    );
                    
                    // 如果有修改，重新載入列表
                    if (result == true) {
                      _loadNotes();
                    }
                  }
                },
                tooltip: '新增筆記',
              ),
          ],
        ),
        body: Consumer<SessionNoteController>(
          builder: (context, controller, child) {
            // 載入中狀態
            if (controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // 錯誤狀態
            if (controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadNotes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新載入'),
                    ),
                  ],
                ),
              );
            }

            // 過濾筆記
            final filteredNotes = _getFilteredNotes(controller.notes);

            // 空狀態
            if (filteredNotes.isEmpty) {
              return EmptyNotesState(
                filter: _currentFilter,
                onCreateNote: () async {
                  // 顯示學員選擇對話框
                  final clientId = await showDialog<String>(
                    context: context,
                    builder: (context) => const ClientSelectorDialog(),
                  );
                  
                  if (clientId != null && mounted) {
                    // 導航到新增筆記頁面
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionNoteEditorPage(
                          clientId: clientId,
                        ),
                      ),
                    );

                    if (result == true) {
                      _loadNotes();
                    }
                  }
                },
              );
            }

            // 筆記列表
            return RefreshIndicator(
              onRefresh: _loadNotes,
              child: Column(
                children: [
                  // 篩選器
                  _buildFilterBar(),
                  
                  // 筆記列表
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return SessionNoteCard(
                          note: note,
                          onTap: () => _navigateToNoteDetail(note),
                          onDelete: () => _deleteNote(note),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 篩選器列
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          NotesFilterChip(
            label: '全部',
            isSelected: _currentFilter == 'all',
            onSelected: () => setState(() => _currentFilter = 'all'),
          ),
          const SizedBox(width: 8),
          NotesFilterChip(
            label: '私人',
            isSelected: _currentFilter == 'private',
            onSelected: () => setState(() => _currentFilter = 'private'),
          ),
          const SizedBox(width: 8),
          NotesFilterChip(
            label: '共享',
            isSelected: _currentFilter == 'shared',
            onSelected: () => setState(() => _currentFilter = 'shared'),
          ),
        ],
      ),
    );
  }

  /// 導航到筆記詳情頁面
  Future<void> _navigateToNoteDetail(SessionNoteModel note) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SessionNoteDetailPage(noteId: note.id),
      ),
    );
    
    // 如果有修改，重新載入列表
    if (result == true) {
      _loadNotes();
    }
  }

  /// 刪除筆記
  Future<void> _deleteNote(SessionNoteModel note) async {
    // 顯示確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除筆記'),
        content: const Text('確定要刪除此筆記嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.deleteNote(note.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('筆記已刪除')),
        );
      }
    }
  }
}


