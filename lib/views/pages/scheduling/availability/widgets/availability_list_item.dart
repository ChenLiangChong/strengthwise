import 'package:flutter/material.dart';
import 'package:strengthwise/models/client_availability_model.dart';

/// 可用時段列表項目
class AvailabilityListItem extends StatelessWidget {
  final ClientAvailabilityModel slot;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AvailabilityListItem({
    Key? key,
    required this.slot,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 優先級圖示
              _getPriorityIcon(slot.priority),
              
              const SizedBox(width: 16),
              
              // 時間資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(slot.startTime),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (slot.notes != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        slot.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // 刪除按鈕（查看模式下隱藏）
              if (onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getPriorityIcon(AvailabilityPriority priority) {
    switch (priority) {
      case AvailabilityPriority.preferred:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.star, color: Colors.amber),
        );
      case AvailabilityPriority.avoid:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.cancel, color: Colors.red),
        );
      case AvailabilityPriority.available:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check_circle, color: Colors.green),
        );
    }
  }

  String _formatDate(DateTime date) {
    // ⭐ date 已經是本地時間（來自 ClientAvailabilityModel）
    return '${date.year}/${date.month}/${date.day}';
  }

  String _formatTime(DateTime time) {
    // ⭐ time 已經是本地時間（來自 ClientAvailabilityModel）
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

