import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

