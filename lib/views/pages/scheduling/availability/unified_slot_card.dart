import 'package:flutter/material.dart';

/// 統一的時段卡片組件
/// 
/// ⭐ v3.1.1: 更新為 booking page 風格
/// - 左側顏色指示器
/// - 方形圖標背景
/// - 標籤式附加資訊
/// - 右側操作按鈕
class UnifiedSlotCard extends StatelessWidget {
  /// 時間範圍文字（例如：「09:00 - 10:00」）
  final String timeRange;
  
  /// 圖標
  final IconData icon;
  
  /// 圖標顏色（也用於指示器和背景）
  final Color iconColor;
  
  /// 圖標背景色（可選，默認為 iconColor.withOpacity(0.15)）
  final Color? iconBackgroundColor;
  
  /// 副標題（可選，例如：備註）
  final String? subtitle;
  
  /// 附加資訊（可選，例如：週期性描述）
  final String? additionalInfo;
  
  /// 標籤文字（可選，例如：「首選」「可訓練」）
  final String? label;
  
  /// 點擊回調
  final VoidCallback? onTap;
  
  /// 刪除回調
  final VoidCallback? onDelete;
  
  /// 主要操作按鈕文字（可選，例如：「預約」「編輯」）
  final String? actionLabel;
  
  /// 主要操作回調
  final VoidCallback? onAction;
  
  /// 是否顯示箭頭而非刪除按鈕（用於可點擊但不可刪除的場景）
  final bool showChevron;

  const UnifiedSlotCard({
    super.key,
    required this.timeRange,
    required this.icon,
    required this.iconColor,
    this.iconBackgroundColor,
    this.subtitle,
    this.additionalInfo,
    this.label,
    this.onTap,
    this.onDelete,
    this.actionLabel,
    this.onAction,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: iconColor.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 左側顏色指示器
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // 圖標（方形背景）
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              // 內容區域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一行：時間 + 標籤
                    Row(
                      children: [
                        Text(
                          timeRange,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (label != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              label!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // 第二行：附加資訊
                    if (additionalInfo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        additionalInfo!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // 第三行：副標題/備註
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // 右側操作區域
              if (actionLabel != null && onAction != null)
                FilledButton.tonal(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: Text(actionLabel!),
                )
              else if (showChevron)
                const Icon(Icons.chevron_right)
              else if (onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorScheme.error,
                  ),
                  onPressed: onDelete,
                  tooltip: '刪除時段',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
