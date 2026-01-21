import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 訓練時段選擇器
///
/// 專為訓練計畫設計的時間範圍選擇器
/// - 快速選擇常用時長（1小時、1.5小時、2小時）
/// - 一次性設定開始和結束時間
/// - 自動計算時長
class TrainingTimeRangePicker extends StatefulWidget {
  final TimeOfDay initialStart;
  final TimeOfDay? initialEnd;
  final DateTime selectedDate; // ⭐ 新增：顯示選定的日期

  const TrainingTimeRangePicker({
    super.key,
    required this.initialStart,
    this.initialEnd,
    required this.selectedDate,
  });

  @override
  State<TrainingTimeRangePicker> createState() =>
      _TrainingTimeRangePickerState();
}

class _TrainingTimeRangePickerState extends State<TrainingTimeRangePicker> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStart;
    _endTime = widget.initialEnd ?? _calculateDefaultEnd(widget.initialStart);
  }

  /// 計算預設結束時間（開始時間 + 1.5 小時）
  TimeOfDay _calculateDefaultEnd(TimeOfDay start) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = startMinutes + 90; // 預設 1.5 小時
    return TimeOfDay(
      hour: (endMinutes ~/ 60) % 24,
      minute: endMinutes % 60,
    );
  }

  /// 設定快速時長
  void _setDuration(int minutes) {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = startMinutes + minutes;

    setState(() {
      _endTime = TimeOfDay(
        hour: (endMinutes ~/ 60) % 24,
        minute: endMinutes % 60,
      );
      _validateTimeRange();
    });

    HapticFeedback.selectionClick();
  }

  /// 驗證時間範圍
  void _validateTimeRange() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      setState(() {
        _errorMessage = '結束時間必須晚於開始時間';
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  /// 格式化時長
  String _formatDuration() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final durationMinutes = endMinutes - startMinutes;

    if (durationMinutes <= 0) return '無效時長';

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours 小時 $minutes 分鐘';
    } else if (hours > 0) {
      return '$hours 小時';
    } else {
      return '$minutes 分鐘';
    }
  }

  /// 選擇開始時間
  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: '選擇開始時間',
      builder: (context, child) {
        // ⭐ 強制使用 Material 3 時間選擇器（統一跨平台樣式）
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              // 使用輸入模式（AM/PM 樣式）
              hourMinuteTextStyle: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: false,  // ⭐ 強制使用 12 小時制
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        _validateTimeRange();
      });
      HapticFeedback.selectionClick();
    }
  }

  /// 選擇結束時間
  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: '選擇結束時間',
      builder: (context, child) {
        // ⭐ 強制使用 Material 3 時間選擇器（統一跨平台樣式）
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              hourMinuteTextStyle: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: false,  // ⭐ 強制使用 12 小時制
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
        _validateTimeRange();
      });
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('設定訓練時段'),
          const SizedBox(height: 4),
          Text(
            DateFormat('yyyy年MM月dd日').format(widget.selectedDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 快速選擇時長
            Text(
              '快速選擇時長',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickDurationChip(
                    label: '1小時',
                    onTap: () => _setDuration(60),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickDurationChip(
                    label: '1.5小時',
                    onTap: () => _setDuration(90),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickDurationChip(
                    label: '2小時',
                    onTap: () => _setDuration(120),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 時間範圍（並排顯示）
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('開始'),
                    subtitle: Text(_startTime.format(context)),
                    onTap: _selectStartTime,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('結束'),
                    subtitle: Text(_endTime.format(context)),
                    onTap: _selectEndTime,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 時長顯示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _errorMessage != null
                    ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _errorMessage != null
                        ? Icons.error_outline
                        : Icons.schedule,
                    size: 20,
                    color: _errorMessage != null
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage ?? '時長：${_formatDuration()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _errorMessage != null
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _errorMessage == null
              ? () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, {
                    'start': _startTime,
                    'end': _endTime,
                  });
                }
              : null,
          child: const Text('確定'),
        ),
      ],
    );
  }
}

/// 快速時長選項按鈕
class _QuickDurationChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickDurationChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// 顯示訓練時段選擇器
///
/// 使用方式：
/// ```dart
/// final result = await showTrainingTimeRangePicker(
///   context: context,
///   initialStart: TimeOfDay.now(),
///   selectedDate: DateTime.now(),
/// );
///
/// if (result != null) {
///   final startTime = result['start'] as TimeOfDay;
///   final endTime = result['end'] as TimeOfDay;
/// }
/// ```
Future<Map<String, TimeOfDay>?> showTrainingTimeRangePicker({
  required BuildContext context,
  required TimeOfDay initialStart,
  TimeOfDay? initialEnd,
  required DateTime selectedDate,
}) async {
  return showDialog<Map<String, TimeOfDay>>(
    context: context,
    barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
    builder: (context) => TrainingTimeRangePicker(
      initialStart: initialStart,
      initialEnd: initialEnd,
      selectedDate: selectedDate,
    ),
  );
}
