import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'training_time_range_picker.dart';

/// 計劃日期頭部元件 ⭐ v2.1: 支援時間範圍
class PlanDateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime trainingTime;
  final DateTime? trainingEndTime; // ⭐ v2.1: 結束時間
  final Function(TimeOfDay start, TimeOfDay end) onTimeRangeChanged; // ⭐ 改為統一回調

  const PlanDateHeader({
    super.key,
    required this.selectedDate,
    required this.trainingTime,
    this.trainingEndTime,
    required this.onTimeRangeChanged,
  });

  /// 顯示時間範圍選擇器
  Future<void> _showTimeRangePicker(BuildContext context) async {
    final result = await showTrainingTimeRangePicker(
      context: context,
      initialStart: TimeOfDay.fromDateTime(trainingTime),
      initialEnd: trainingEndTime != null
          ? TimeOfDay.fromDateTime(trainingEndTime!)
          : null,
      selectedDate: selectedDate, // ⭐ 傳入選定的日期
    );

    if (result != null) {
      onTimeRangeChanged(result['start']!, result['end']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy年MM月dd日').format(selectedDate);
    final colorScheme = Theme.of(context).colorScheme;

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
        const SizedBox(height: 12),

        // ⭐ v2.1: 統一的時間範圍選擇（一次點擊）
        InkWell(
          onTap: () => _showTimeRangePicker(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 開始時間
                      Row(
                        children: [
                          Text(
                            '開始: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(trainingTime),
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrains Mono', // 等寬字體
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 結束時間
                      Row(
                        children: [
                          Text(
                            '結束: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            trainingEndTime != null
                                ? DateFormat('HH:mm').format(trainingEndTime!)
                                : "未設定",
                            style: TextStyle(
                              fontSize: 16,
                              color: trainingEndTime != null
                                  ? colorScheme.primary
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JetBrains Mono', // 等寬字體
                            ),
                          ),
                        ],
                      ),
                      // 顯示時長
                      if (trainingEndTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '時長: ${_formatDuration(trainingEndTime!.difference(trainingTime))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.edit_calendar_outlined,
                  size: 20,
                  color: colorScheme.primary.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 格式化時長
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '$hours 小時 $minutes 分鐘';
    } else if (hours > 0) {
      return '$hours 小時';
    } else {
      return '$minutes 分鐘';
    }
  }
}
