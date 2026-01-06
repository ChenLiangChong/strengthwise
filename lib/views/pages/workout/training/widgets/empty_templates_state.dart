// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 空模板狀態元件
///
/// 響應式設計：
/// - 使用 Theme 文字樣式
/// - 響應式間距與圖標大小
class EmptyTemplatesState extends StatelessWidget {
  final VoidCallback onCreateTemplate;

  const EmptyTemplatesState({
    super.key,
    required this.onCreateTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconSize = context.isMobileSmall ? 64.0 : 80.0;

    return Center(
      child: Padding(
        padding: context.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: iconSize,
              color: colorScheme.outline,
            ),
            SizedBox(height: context.spacing.lg),
            Text(
              '還沒有訓練模板',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.sm),
            Text(
              '創建模板後可以快速安排訓練',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.xl),
            ElevatedButton.icon(
              onPressed: onCreateTemplate,
              icon: const Icon(Icons.add),
              label: const Text('創建第一個模板'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.lg,
                  vertical: context.spacing.sm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

