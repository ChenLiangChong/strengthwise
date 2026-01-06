// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 動作列表頭部 Widget
///
/// 顯示選擇路徑和動作數量
///
/// 響應式設計：
/// - 使用 Theme 文字樣式
/// - 響應式間距
class ExerciseListHeader extends StatelessWidget {
  final String selectionPath;
  final int exerciseCount;

  const ExerciseListHeader({
    super.key,
    required this.selectionPath,
    required this.exerciseCount,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: context.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectionPath,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            '符合條件的訓練動作 ($exerciseCount):',
            style: textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

