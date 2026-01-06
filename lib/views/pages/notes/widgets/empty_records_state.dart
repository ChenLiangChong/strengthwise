// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 空狀態顯示元件
///
/// 響應式設計：
/// - 使用 Theme 文字樣式
/// - 響應式間距與圖標大小
class EmptyRecordsState extends StatelessWidget {
  const EmptyRecordsState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconSize = context.isMobileSmall ? 64.0 : 80.0;

    return ListView(
      children: [
        SizedBox(
          height: context.screenHeight * 0.7,
          child: Center(
            child: Padding(
              padding: context.pagePadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: iconSize,
                    color: colorScheme.outline,
                  ),
                  SizedBox(height: context.spacing.md),
                  Text(
                    '還沒有訓練筆記',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.spacing.sm),
                  Text(
                    '點擊底部的加號按鈕添加新筆記',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

