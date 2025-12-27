import 'package:flutter/material.dart';

/// 筆記文本編輯器元件
class NoteTextEditor extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const NoteTextEditor({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: '內容',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        enabled: enabled,
      ),
    );
  }
}

