import 'package:flutter/material.dart';

/// 模板複製對話框
class TemplateDuplicateDialog extends StatelessWidget {
  final String defaultName;

  const TemplateDuplicateDialog({
    super.key,
    required this.defaultName,
  });

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController(text: defaultName);

    return AlertDialog(
      title: const Text('複製模板'),
      content: TextField(
        controller: titleController,
        decoration: const InputDecoration(
          labelText: '新模板名稱',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, titleController.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('確定'),
        ),
      ],
    );
  }
}

