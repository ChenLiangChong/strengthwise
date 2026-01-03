import 'package:flutter/material.dart';
import 'package:strengthwise/models/appointment_model.dart';

/// 預約卡片組件
class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isCoachMode;
  final VoidCallback onTap;
  final Function(String) onQuickAction;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.isCoachMode,
    required this.onTap,
    required this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題列（日期 + 狀態）
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDate(appointment.startTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),

              const SizedBox(height: 12),

              // 時間範圍
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimeRange(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${appointment.durationMinutes} 分鐘',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // 備註（如果有）
              if (appointment.notes != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.notes!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // 快速操作按鈕
              if (_shouldShowQuickActions()) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _buildQuickActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final color = _getStatusColor();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        appointment.status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  bool _shouldShowQuickActions() {
    if (isCoachMode) {
      // 教練：待確認時顯示確認/拒絕按鈕，已確認時顯示取消按鈕
      return appointment.status == AppointmentStatus.requested ||
          appointment.status == AppointmentStatus.confirmed;
    } else {
      // 學員：待確認或已確認時顯示取消按鈕
      return appointment.status == AppointmentStatus.requested ||
          appointment.status == AppointmentStatus.confirmed;
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    if (isCoachMode && appointment.status == AppointmentStatus.requested) {
      // 教練：待確認時 - 確認/拒絕
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: TextButton.icon(
              onPressed: () => onQuickAction('reject'),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('拒絕'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FilledButton.icon(
              onPressed: () => onQuickAction('confirm'),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('確認'),
            ),
          ),
        ],
      );
    } else if (isCoachMode && appointment.status == AppointmentStatus.confirmed) {
      // 教練：已確認時 - 取消
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: TextButton.icon(
              onPressed: () => onQuickAction('cancel'),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('取消預約'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      );
    } else {
      // 學員：取消
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: TextButton.icon(
              onPressed: () => onQuickAction('cancel'),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('取消預約'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      );
    }
  }

  Color _getStatusColor() {
    switch (appointment.status) {
      case AppointmentStatus.requested:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final weekday = _getWeekdayName(date.weekday);
    return '$year-$month-$day ($weekday)';
  }

  String _formatTimeRange() {
    final start = _formatTime(appointment.startTime);
    final end = _formatTime(appointment.endTime);
    return '$start - $end';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return '週一';
      case 2:
        return '週二';
      case 3:
        return '週三';
      case 4:
        return '週四';
      case 5:
        return '週五';
      case 6:
        return '週六';
      case 7:
        return '週日';
      default:
        return '';
    }
  }
}

