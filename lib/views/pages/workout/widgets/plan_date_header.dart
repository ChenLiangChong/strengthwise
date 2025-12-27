import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 計劃日期頭部元件
class PlanDateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime trainingTime;
  final VoidCallback onSelectTime;

  const PlanDateHeader({
    super.key,
    required this.selectedDate,
    required this.trainingTime,
    required this.onSelectTime,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy年MM月dd日').format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '日期: $formattedDate',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '訓練時間: ${DateFormat('HH:mm').format(trainingTime)}',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onSelectTime,
              icon: const Icon(Icons.edit_calendar_outlined, size: 16),
              label: const Text('修改時間'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

