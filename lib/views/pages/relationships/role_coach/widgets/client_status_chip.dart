// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 學員狀態標籤組件
class ClientStatusChip extends StatelessWidget {
  final String status;

  const ClientStatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 根據狀態決定顏色和文字
    Color backgroundColor;
    Color textColor;
    String displayText;
    IconData icon;

    switch (status) {
      case 'active':
        backgroundColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        displayText = '活躍';
        icon = Icons.check_circle;
        break;
      case 'pending':
        backgroundColor = colorScheme.secondaryContainer;
        textColor = colorScheme.onSecondaryContainer;
        displayText = '待接受';
        icon = Icons.pending;
        break;
      case 'archived':
        backgroundColor = colorScheme.surfaceVariant;
        textColor = colorScheme.onSurfaceVariant;
        displayText = '已歸檔';
        icon = Icons.archive;
        break;
      case 'rejected':
        backgroundColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        displayText = '已拒絕';
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = colorScheme.surfaceVariant;
        textColor = colorScheme.onSurfaceVariant;
        displayText = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md, // ⭐ 響應式內距
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.scaled(context), // ⭐ 響應式圖標
            color: textColor,
          ),
          SizedBox(width: context.spacing.xs), // ⭐ 響應式間距
          Text(
            displayText,
            style: context.responsive.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ), // ⭐ 響應式文字
          ),
        ],
      ),
    );
  }
}

