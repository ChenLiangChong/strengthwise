import 'package:flutter/material.dart';

/// 備註區域組件
class NotesSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isEditing;
  final bool isCoachMode;
  final VoidCallback onEditToggle;
  final VoidCallback onSave;

  const NotesSection({
    super.key,
    required this.controller,
    required this.isEditing,
    required this.isCoachMode,
    required this.onEditToggle,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列
          Row(
            children: [
              Expanded(
                child: Text(
                  isCoachMode ? '教練備註（學員不可見）' : '我的備註',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (!isEditing)
                IconButton(
                  onPressed: onEditToggle,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '編輯備註',
                ),
            ],
          ),

          const SizedBox(height: 12),

          // 備註內容/編輯框
          if (isEditing)
            Column(
              children: [
                TextField(
                  controller: controller,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: '輸入備註內容...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onEditToggle,
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('儲存'),
                    ),
                  ],
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                controller.text.isEmpty ? '無備註' : controller.text,
                style: TextStyle(
                  fontSize: 14,
                  color: controller.text.isEmpty
                      ? Colors.grey[500]
                      : Colors.grey[800],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

