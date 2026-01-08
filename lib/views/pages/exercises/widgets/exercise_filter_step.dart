// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 動作篩選步驟 Widget
///
/// 用於顯示訓練類型、身體部位、特定肌群、器材類別、器材子類別的選擇列表
///
/// 響應式設計：
/// - 小螢幕：單欄列表
/// - 平板/桌面：多欄網格
class ExerciseFilterStep extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> items;
  final String? selectedValue;
  final Function(String) onSelect;
  final bool showSkipButton;
  final VoidCallback? onSkip;

  const ExerciseFilterStep({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    this.selectedValue,
    required this.onSelect,
    this.showSkipButton = false,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final padding = context.pagePadding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題區域
        Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle != null) ...[
                Text(
                  subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: context.spacing.sm),
              ],
              Text(
                title,
                style: textTheme.titleLarge,
              ),
            ],
          ),
        ),

        // 選項列表
        if (items.isEmpty)
          _FilterEmptyState()
        else
          _FilterItemGrid(
            items: items,
            selectedValue: selectedValue,
            onSelect: onSelect,
          ),

        // 跳過按鈕
        if (showSkipButton && items.isNotEmpty && onSkip != null)
          Padding(
            padding: padding,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.skip_next),
              label: const Text('跳過此分類，直接查看動作'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: onSkip,
            ),
          ),
      ],
    );
  }
}

/// 空狀態組件
class _FilterEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Center(
        child: Padding(
          padding: context.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: context.isMobileSmall ? 40 : 48,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: context.spacing.md),
              Text(
                '沒有找到符合條件的分類',
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.sm),
              Text(
                '將自動進入下一步',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 選項網格組件
class _FilterItemGrid extends StatelessWidget {
  final List<String> items;
  final String? selectedValue;
  final Function(String) onSelect;

  const _FilterItemGrid({
    required this.items,
    this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final columns = context.listColumns;
    final padding = context.pagePadding;

    // 大螢幕使用網格佈局
    if (columns > 1) {
      return Expanded(
        child: GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: context.spacing.sm,
            mainAxisSpacing: context.spacing.sm,
            childAspectRatio: 3.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildItem(context, items[index]),
        ),
      );
    }

    // 小螢幕使用列表佈局
    return Expanded(
      child: ListView.builder(
        padding: padding,
        itemCount: items.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: context.spacing.sm),
          child: _buildItem(context, items[index]),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, String item) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = item == selectedValue;

    return Card(
      elevation: 0,
      color: isSelected ? colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        title: Text(
          item,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => onSelect(item),
      ),
    );
  }
}
