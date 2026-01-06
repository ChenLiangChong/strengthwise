// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 空狀態提示組件
///
/// 用於顯示無數據時的友善提示
///
/// 響應式設計：
/// - 使用 Theme 文字樣式
/// - 響應式間距與圖標大小
class EmptyStateWidget extends StatelessWidget {
  /// 圖標
  final IconData icon;

  /// 主標題
  final String title;

  /// 副標題（說明文字）
  final String? subtitle;

  /// 圖標大小（基準值，會根據螢幕縮放）
  final double iconSize;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconSize = 64.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final effectiveIconSize = context.isMobileSmall ? iconSize * 0.75 : iconSize;

    return Center(
      child: Padding(
        padding: context.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: effectiveIconSize,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: context.spacing.sm),
              Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

