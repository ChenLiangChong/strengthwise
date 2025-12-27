import 'package:flutter/material.dart';
import '../../../../models/note_model.dart';
import 'note_card.dart';

/// 筆記列表元件
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          note: note,
          onTap: () => onNavigateToEditor(note),
          onDelete: () => onDeleteNote(note.id),
        );
      },
    );
  }
}

