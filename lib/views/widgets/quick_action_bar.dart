// ✅ Phase 3.1-B: 快捷操作按鈕列
import 'package:flutter/material.dart';

/// 單個快捷操作按鈕的資料
class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });
}

/// 快捷操作按鈕列 Widget
///
/// 橫向排列快捷操作按鈕，超過螢幕寬度時可橫向滾動。
///
/// UX 設計原則：
/// - Touch Target: 72x72px（符合最小 44x44px）
/// - Touch Spacing: 12px 間距（符合最小 8px）
/// - 圖標 + 文字標籤，提高可理解性
class QuickActionBar extends StatelessWidget {
  /// 快捷操作列表
  final List<QuickAction> actions;

  /// 是否顯示標題
  final bool showTitle;

  /// 標題文字
  final String title;

  const QuickActionBar({
    super.key,
    required this.actions,
    this.showTitle = true,
    this.title = '快捷操作',
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

        // 按鈕列（橫向滾動）
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: actions
                .map((action) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _QuickActionButton(action: action),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// 單個快捷操作按鈕
class _QuickActionButton extends StatelessWidget {
  final QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = action.backgroundColor ?? colorScheme.primaryContainer;
    final iconColor = action.iconColor ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action.icon,
                size: 28,
                color: iconColor,
              ),
              const SizedBox(height: 4),
              Text(
                action.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

