import 'package:flutter/material.dart';
import '../../../../models/workout_template_model.dart';

/// 模板操作選單底部彈窗
class TemplateMenuSheet extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback onCreateToday;
  final VoidCallback onCreateScheduled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TemplateMenuSheet({
    super.key,
    required this.template,
    required this.onCreateToday,
    required this.onCreateScheduled,
    required this.onEdit,
    required this.onDelete,
  });

  /// 顯示模板選單
  static void show(
    BuildContext context, {
    required WorkoutTemplate template,
    required VoidCallback onCreateToday,
    required VoidCallback onCreateScheduled,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => TemplateMenuSheet(
        template: template,
        onCreateToday: onCreateToday,
        onCreateScheduled: onCreateScheduled,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.today, color: Colors.green),
            title: const Text('創建今日訓練'),
            onTap: () {
              Navigator.pop(context);
              onCreateToday();
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.blue),
            title: const Text('選擇日期創建'),
            onTap: () {
              Navigator.pop(context);
              onCreateScheduled();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('編輯模板'),
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('刪除模板'),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}

