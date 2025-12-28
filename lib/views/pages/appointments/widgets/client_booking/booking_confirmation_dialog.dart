import 'package:flutter/material.dart';
import '../../../../../services/interfaces/i_availability_slot_service.dart';

/// 預約確認對話框
class BookingConfirmationDialog extends StatelessWidget {
  final AvailabilitySlotWithBooking slot;
  final String coachName;

  const BookingConfirmationDialog({
    super.key,
    required this.slot,
    required this.coachName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('確認預約'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            Icons.person_outline,
            '教練',
            coachName,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            '日期',
            _formatDate(slot.slot.startTime),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time_outlined,
            '時間',
            slot.slot.displayTimeRange,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.timer_outlined,
            '時長',
            '${slot.slot.durationMinutes} 分鐘',
          ),
          if (slot.slot.notes != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.note_outlined,
              '備註',
              slot.slot.notes!,
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '預約成功後需等待教練確認',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('確認預約'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

