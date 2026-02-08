import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 階層瀏覽卡片組件
///
/// 用於各導航層級：訓練類型、瀏覽模式、肌群分區、動作模式等。
/// 每張卡片含 icon、標題、副標題、數量標記。
class ExerciseBrowseCards extends StatelessWidget {
  /// 卡片資料
  final List<BrowseCardItem> items;

  /// 頂部標題
  final String? title;

  /// 麵包屑路徑
  final String? breadcrumb;

  /// 選擇回調
  final ValueChanged<BrowseCardItem> onSelect;

  const ExerciseBrowseCards({
    super.key,
    required this.items,
    this.title,
    this.breadcrumb,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final columns = context.listColumns;
    final padding = context.pagePadding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 麵包屑 + 標題
        if (breadcrumb != null || title != null)
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (breadcrumb != null)
                  Text(
                    breadcrumb!,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (breadcrumb != null) SizedBox(height: context.spacing.sm),
                if (title != null)
                  Text(title!, style: textTheme.titleLarge),
              ],
            ),
          ),
        SizedBox(height: context.spacing.sm),

        // 卡片列表
        Expanded(
          child: columns > 1
              ? GridView.builder(
                  padding: padding,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: context.spacing.sm,
                    mainAxisSpacing: context.spacing.sm,
                    childAspectRatio: 3.0,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _BrowseCard(item: items[index], onTap: onSelect),
                )
              : ListView.builder(
                  padding: padding,
                  itemCount: items.length,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.only(bottom: context.spacing.sm),
                    child: _BrowseCard(
                      item: items[index],
                      onTap: onSelect,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// 單張瀏覽卡片
class _BrowseCard extends StatelessWidget {
  final BrowseCardItem item;
  final ValueChanged<BrowseCardItem> onTap;

  const _BrowseCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => onTap(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // icon
              if (item.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    item.icon,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                ),
              // 文字
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.subtitle!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // 箭頭
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 瀏覽卡片資料模型
class BrowseCardItem {
  /// 卡片 ID（用於邏輯判斷）
  final String id;

  /// 顯示標題
  final String title;

  /// 副標題（可選）
  final String? subtitle;

  /// 圖標（可選）
  final IconData? icon;

  const BrowseCardItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
  });
}
