import 'package:flutter/material.dart';
import '../../../../models/workout_template_model.dart';
import 'template_info_chip.dart';

/// 模板卡片元件
class TemplateCard extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback onTap;
  final VoidCallback onMoreMenu;
  final VoidCallback onCreateToday;
  final VoidCallback onCreateScheduled;

  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
    required this.onMoreMenu,
    required this.onCreateToday,
    required this.onCreateScheduled,
  });

  @override
  Widget build(BuildContext context) {
    final exerciseCount = template.exercises.length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildInfoChips(context, exerciseCount),
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// 建構卡片頭部（圖標、標題、描述、更多按鈕）
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // 圖標
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.fitness_center,
            color: Colors.green,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        // 標題和描述
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (template.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  template.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        // 更多按鈕
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onMoreMenu,
        ),
      ],
    );
  }

  /// 建構信息標籤（訓練類型、動作數量）
  Widget _buildInfoChips(BuildContext context, int exerciseCount) {
    return Row(
      children: [
        TemplateInfoChip(
          icon: Icons.category,
          label: template.planType,
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        TemplateInfoChip(
          icon: Icons.format_list_numbered,
          label: '$exerciseCount 個動作',
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  /// 建構快速操作按鈕
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCreateToday,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('今日訓練'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCreateScheduled,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('選擇日期'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

