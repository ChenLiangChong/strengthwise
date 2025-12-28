import 'package:flutter/material.dart';
import '../../../../models/availability_slot_model.dart';
import '../../../../services/service_locator.dart';
import '../../../../controllers/availability_slot_controller.dart';
import '../../../../utils/date_format_utils.dart';

/// 快速添加時段對話框
///
/// 點擊日曆日期後彈出，快速創建單次時段
class QuickAddSlotDialog extends StatefulWidget {
  final String coachId;
  final DateTime selectedDate;

  const QuickAddSlotDialog({
    super.key,
    required this.coachId,
    required this.selectedDate,
  });

  @override
  State<QuickAddSlotDialog> createState() => _QuickAddSlotDialogState();
}

class _QuickAddSlotDialogState extends State<QuickAddSlotDialog> {
  late final AvailabilitySlotController _slotController;

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _slotController = serviceLocator<AvailabilitySlotController>();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// 選擇時間
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // 自動調整結束時間（+1 小時）
          final endHour = (picked.hour + 1) % 24;
          _endTime = TimeOfDay(hour: endHour, minute: picked.minute);
        } else {
          _endTime = picked;
        }
      });
    }
  }

  /// 創建時段
  Future<void> _createSlot() async {
    // 驗證
    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      _showError('結束時間必須晚於開始時間');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final slot = AvailabilitySlotModel(
        id: '',
        coachId: widget.coachId,
        startTime: startDateTime,
        endTime: endDateTime,
        recurrenceRule: null, // 單次時段，無週期規則
        isOverride: false,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await _slotController.createSlot(slot);

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pop(context, true);
        } else {
          _showError(_slotController.errorMessage ?? '創建失敗');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('創建時段時發生錯誤：$e');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('快速添加時段'),
          const SizedBox(height: 4),
          Text(
            DateFormatUtils.formatDate(widget.selectedDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            // 開始時間
            _buildTimeRow(
              label: '開始時間',
              time: _startTime,
              onTap: () => _selectTime(context, true),
            ),

            const SizedBox(height: 16),

            // 結束時間
            _buildTimeRow(
              label: '結束時間',
              time: _endTime,
              onTap: () => _selectTime(context, false),
            ),

            const SizedBox(height: 16),

            // 備註（選填）
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '備註（選填）',
                hintText: '例如：線上課程、小班制',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              maxLength: 100,
            ),

            const SizedBox(height: 8),

            // 提示
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '創建單次時段，學員可預約此時段',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createSlot,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('創建'),
        ),
      ],
    );
  }

  /// 建立時間選擇行
  Widget _buildTimeRow({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[700]),
            const SizedBox(width: 12),
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
                    time.format(context),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

