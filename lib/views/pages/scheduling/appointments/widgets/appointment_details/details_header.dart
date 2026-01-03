import 'package:flutter/material.dart';
import 'package:strengthwise/models/appointment_model.dart';

/// 詳情頭部組件
class DetailsHeader extends StatelessWidget {
  final AppointmentModel appointment;

  const DetailsHeader({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: _getStatusColor().withValues(alpha: 0.1),
      child: Column(
        children: [
          // 狀態標籤
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              appointment.status.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 日期
          Text(
            _formatDate(appointment.startTime),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),

          const SizedBox(height: 8),

          // 時間範圍
          Text(
            _formatTimeRange(),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 4),

          // 時長
          Text(
            '時長 ${appointment.durationMinutes} 分鐘',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
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
    return '$year年$month月$day日 ($weekday)';
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

