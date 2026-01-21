// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/workout_template_model.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'template_info_chip.dart';

/// 模板卡片元件
///
/// 響應式設計：
/// - 使用 Theme 文字樣式
/// - 使用 Theme 顏色
/// - 響應式間距
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: context.spacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: context.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TemplateCardHeader(
                template: template,
                onMoreMenu: onMoreMenu,
              ),
              SizedBox(height: context.spacing.sm),
              _TemplateCardInfoChips(
                template: template,
                exerciseCount: exerciseCount,
              ),
              SizedBox(height: context.spacing.sm),
              _TemplateCardActions(
                onCreateToday: onCreateToday,
                onCreateScheduled: onCreateScheduled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 卡片頭部（圖標、標題、描述、更多按鈕）
class _TemplateCardHeader extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback onMoreMenu;

  const _TemplateCardHeader({
    required this.template,
    required this.onMoreMenu,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        // 圖標
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.fitness_center,
            color: colorScheme.onPrimaryContainer,
            size: 28,
          ),
        ),
        SizedBox(width: context.spacing.sm),
        // 標題和描述
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (template.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  template.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
}

/// 信息標籤（訓練類型、動作數量）
class _TemplateCardInfoChips extends StatelessWidget {
  final WorkoutTemplate template;
  final int exerciseCount;

  const _TemplateCardInfoChips({
    required this.template,
    required this.exerciseCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: context.spacing.sm,
      runSpacing: context.spacing.xs,
      children: [
        TemplateInfoChip(
          icon: Icons.category,
          label: template.planType,
          color: colorScheme.secondary,
        ),
        TemplateInfoChip(
          icon: Icons.format_list_numbered,
          label: '$exerciseCount 個動作',
          color: colorScheme.primary,
        ),
      ],
    );
  }
}

/// 快速操作按鈕
class _TemplateCardActions extends StatelessWidget {
  final VoidCallback onCreateToday;
  final VoidCallback onCreateScheduled;

  const _TemplateCardActions({
    required this.onCreateToday,
    required this.onCreateScheduled,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobileSmall = context.isMobileSmall;

    // 小螢幕使用垂直排列
    if (isMobileSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onCreateToday,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('今日訓練'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
            ),
          ),
          SizedBox(height: context.spacing.xs),
          OutlinedButton.icon(
            onPressed: onCreateScheduled,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('選擇日期'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.secondary,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCreateToday,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('今日訓練'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
            ),
          ),
        ),
        SizedBox(width: context.spacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCreateScheduled,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('選擇日期'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
