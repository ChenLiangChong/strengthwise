import 'package:flutter/material.dart';

/// 統一的時段卡片組件
/// 
/// 遵循 Material Design 3 規範和 UI/UX Guidelines
/// - 16dp 圓角
/// - 12dp 底部間距
/// - 圓形圖標背景（統一視覺語言）
/// - 48dp 最小觸控目標
class UnifiedSlotCard extends StatelessWidget {
  /// 時間範圍文字（例如：「09:00 - 10:00」）
  final String timeRange;
  
  /// 圖標
  final IconData icon;
  
  /// 圖標顏色
  final Color iconColor;
  
  /// 圖標背景色（可選，默認為 iconColor.withOpacity(0.15)）
  final Color? iconBackgroundColor;
  
  /// 副標題（可選，例如：備註）
  final String? subtitle;
  
  /// 附加資訊（可選，例如：週期性描述）
  final String? additionalInfo;
  
  /// 點擊回調
  final VoidCallback? onTap;
  
  /// 刪除回調
  final VoidCallback? onDelete;
  
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
    this.onTap,
    this.onDelete,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconBackgroundColor ?? iconColor.withOpacity(0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(timeRange),
        subtitle: (additionalInfo != null || subtitle != null)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (additionalInfo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      additionalInfo!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              )
            : null,
        trailing: showChevron
            ? const Icon(Icons.chevron_right)
            : (onDelete != null
                ? IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                    ),
                    onPressed: onDelete,
                    tooltip: '刪除時段',
                  )
                : null),
        onTap: onTap,
      ),
    );
  }
}
