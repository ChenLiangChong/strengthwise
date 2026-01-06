// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 空狀態 Widget
///
/// 當沒有找到符合條件的動作時顯示
///
/// 響應式設計：
/// - 使用 Theme 文字樣式
/// - 響應式間距與圖標大小
class EmptyExerciseState extends StatelessWidget {
  const EmptyExerciseState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final iconSize = context.isMobileSmall ? 48.0 : 64.0;

    return Center(
      child: Padding(
        padding: context.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: iconSize,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              '沒有找到符合條件的訓練動作',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.sm),
            Text(
              '請嘗試調整篩選條件',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

