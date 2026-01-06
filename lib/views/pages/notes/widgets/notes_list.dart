// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/note_model.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'note_card.dart';

/// 筆記列表元件
///
/// 響應式設計：
/// - 小螢幕：單欄列表
/// - 平板/桌面：雙欄網格
class NotesList extends StatelessWidget {
  final List<Note> notes;
  final Function(Note?) onNavigateToEditor;
  final Function(String) onDeleteNote;

  const NotesList({
    super.key,
    required this.notes,
    required this.onNavigateToEditor,
    required this.onDeleteNote,
  });

  @override
  Widget build(BuildContext context) {
    final columns = context.listColumns;
    final padding = context.pagePadding;

    // 大螢幕使用網格佈局
    if (columns > 1) {
      return GridView.builder(
        padding: padding.copyWith(bottom: 96),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: context.spacing.md,
          mainAxisSpacing: context.spacing.md,
          childAspectRatio: 2.0, // 卡片寬高比
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) => _buildCard(notes[index]),
      );
    }

    // 小螢幕使用列表佈局
    return ListView.builder(
      padding: padding.copyWith(bottom: 96),
      itemCount: notes.length,
      itemBuilder: (context, index) => _buildCard(notes[index]),
    );
  }

  Widget _buildCard(Note note) {
    return NoteCard(
      note: note,
      onTap: () => onNavigateToEditor(note),
      onDelete: () => onDeleteNote(note.id),
    );
  }
}
