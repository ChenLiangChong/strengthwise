import 'package:flutter/material.dart';
import '../../../../models/workout_template_model.dart';

/// 模板列表項
class TemplateListItem extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback onTap;
  final Function(String action) onMenuAction;

  const TemplateListItem({
    super.key,
    required this.template,
    required this.onTap,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(template.title),
        subtitle: Text('${template.planType} - ${template.exercises.length} 個動作'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'create_record',
              child: Row(
                children: [
                  Icon(Icons.fitness_center, color: Colors.green),
                  SizedBox(width: 8),
                  Text('安排訓練'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('編輯'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy),
                  SizedBox(width: 8),
                  Text('複製'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('刪除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) => onMenuAction(value),
        ),
        onTap: onTap,
      ),
    );
  }
}

