import 'package:flutter/material.dart';
import 'package:strengthwise/models/exercise/exercise_labels.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import '../../../../models/exercise_model.dart';

/// 動作列表項 Widget
///
/// 顯示動作名稱、v5.0 分類標籤（PPL + 器材 + 難度）。
class ExerciseListItem extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onSelect;

  const ExerciseListItem({
    super.key,
    required this.exercise,
    required this.onTap,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = exercise.displayName;
    final infoParts = _buildInfoParts();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: context.spacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: context.cardPadding,
          child: Row(
            children: [
              // 左側：動作名稱和資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 動作名稱
                    Text(
                      displayName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // 底部資訊（PPL + 器材 + 難度）
                    if (infoParts.isNotEmpty) ...[
                      SizedBox(height: context.spacing.xs),
                      Text(
                        infoParts.join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // 右側：操作按鈕
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: colorScheme.secondary,
                    ),
                    tooltip: '選擇此動作',
                    onPressed: onSelect,
                  ),
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 構建 v5.0 分類標籤
  List<String> _buildInfoParts() {
    final infoParts = <String>[];

    // PPL 標籤
    if (exercise.pplTags.isNotEmpty) {
      infoParts.add(
        ExerciseLabels.resolve(ExerciseLabels.ppl, exercise.pplTags.first),
      );
    }

    // 器材
    if (exercise.equipment.isNotEmpty) {
      infoParts.add(
        ExerciseLabels.resolve(ExerciseLabels.equipment, exercise.equipment),
      );
    } else {
      infoParts.add('徒手');
    }

    // 難度
    infoParts.add(
      ExerciseLabels.resolve(ExerciseLabels.difficulty, exercise.difficultyLevel),
    );

    return infoParts;
  }
}
