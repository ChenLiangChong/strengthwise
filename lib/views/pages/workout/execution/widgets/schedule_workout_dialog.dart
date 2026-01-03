import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 安排訓練對話框（Material 3）
/// 
/// 讓用戶選擇訓練日期和時間範圍
class ScheduleWorkoutDialog extends StatefulWidget {
  final String templateName;

  const ScheduleWorkoutDialog({
    super.key,
    required this.templateName,
  });

  @override
  State<ScheduleWorkoutDialog> createState() => _ScheduleWorkoutDialogState();
}

class _ScheduleWorkoutDialogState extends State<ScheduleWorkoutDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    
    // 預設為今天，下午 2:00 - 3:00
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _startTime = const TimeOfDay(hour: 14, minute: 0);
    _endTime = const TimeOfDay(hour: 15, minute: 0);
  }

  /// 選擇日期
  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  /// 選擇開始時間
  Future<void> _selectStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
        
        // 自動調整結束時間（如果開始時間晚於結束時間）
        final startMinutes = _startTime.hour * 60 + _startTime.minute;
        final endMinutes = _endTime.hour * 60 + _endTime.minute;
        
        if (startMinutes >= endMinutes) {
          // 結束時間設為開始時間 +1 小時
          final newEndMinutes = startMinutes + 60;
          _endTime = TimeOfDay(
            hour: (newEndMinutes ~/ 60) % 24,
            minute: newEndMinutes % 60,
          );
        }
      });
    }
  }

  /// 選擇結束時間
  Future<void> _selectEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (pickedTime != null) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  /// 驗證時間範圍
  bool _validateTimeRange() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return endMinutes > startMinutes;
  }

  /// 計算訓練時長
  String _formatDuration() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final durationMinutes = endMinutes - startMinutes;
    
    if (durationMinutes < 60) {
      return '$durationMinutes 分鐘';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      return minutes > 0 ? '$hours 小時 $minutes 分鐘' : '$hours 小時';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isValidTimeRange = _validateTimeRange();

    return AlertDialog(
      title: const Text('安排訓練'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模板名稱
            Text(
              widget.templateName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // 日期選擇
            Text(
              '訓練日期',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('yyyy/MM/dd (E)', 'zh_TW').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 時間範圍
            Text(
              '訓練時間',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                // 開始時間
                Expanded(
                  child: InkWell(
                    onTap: _selectStartTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 20, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            _startTime.format(context),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, color: colorScheme.onSurfaceVariant),
                ),
                
                // 結束時間
                Expanded(
                  child: InkWell(
                    onTap: _selectEndTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isValidTimeRange ? colorScheme.outline : colorScheme.error,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time, 
                            size: 20, 
                            color: isValidTimeRange ? colorScheme.primary : colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _endTime.format(context),
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w500,
                              color: isValidTimeRange ? null : colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // 時長顯示
            const SizedBox(height: 12),
            if (isValidTimeRange)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, size: 16, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      '時長：${_formatDuration()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 16, color: colorScheme.onErrorContainer),
                    const SizedBox(width: 6),
                    Text(
                      '結束時間必須晚於開始時間',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: isValidTimeRange ? () {
            // 組合日期和時間
            final trainingStart = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _startTime.hour,
              _startTime.minute,
            );
            final trainingEnd = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _endTime.hour,
              _endTime.minute,
            );

            Navigator.pop(context, {
              'start': trainingStart,
              'end': trainingEnd,
            });
          } : null,
          child: const Text('確定'),
        ),
      ],
    );
  }
}

