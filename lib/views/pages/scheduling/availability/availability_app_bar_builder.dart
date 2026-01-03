import 'package:flutter/material.dart';

/// 時段管理頁面的 AppBar 建構器
/// 
/// 統一學員時間偏好和教練時段管理的 AppBar 功能
class AvailabilityAppBarBuilder {
  /// 建構 AppBar
  /// 
  /// [title] AppBar 標題
  /// [onCopyWeek] 複製週時段回調
  /// [onRefresh] 重新載入回調
  /// [showCopyButton] 是否顯示複製週時段按鈕（查看模式不顯示）
  /// [filterOptions] 篩選選項（可選）
  /// [onFilterChanged] 篩選變更回調（可選）
  static AppBar build({
    required String title,
    required VoidCallback? onCopyWeek,
    required VoidCallback onRefresh,
    bool showCopyButton = true,
    List<FilterOption>? filterOptions,
    Function(String)? onFilterChanged,
  }) {
    return AppBar(
      title: Text(title),
      actions: [
        // 複製週時段按鈕（只在允許時顯示）
        if (showCopyButton && onCopyWeek != null)
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: '複製週時段',
            onPressed: onCopyWeek,
          ),
        // 更多選單
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: '更多選項',
          onSelected: (value) {
            if (value == 'refresh') {
              onRefresh();
            } else if (onFilterChanged != null) {
              onFilterChanged(value);
            }
          },
          itemBuilder: (context) => [
            // 重新載入
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('重新載入'),
                ],
              ),
            ),
            // 篩選選項（如果提供）
            if (filterOptions != null && filterOptions.isNotEmpty) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text(
                  '篩選',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              ...filterOptions.map((option) => PopupMenuItem(
                    value: option.value,
                    child: option.icon != null
                        ? Row(
                            children: [
                              Icon(option.icon, color: option.iconColor, size: 16),
                              const SizedBox(width: 8),
                              Text(option.label),
                            ],
                          )
                        : Text(option.label),
                  )),
            ],
          ],
        ),
      ],
    );
  }
}

/// 篩選選項模型
class FilterOption {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const FilterOption({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });
}

