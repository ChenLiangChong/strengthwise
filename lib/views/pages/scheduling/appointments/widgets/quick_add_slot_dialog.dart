import 'package:flutter/material.dart';
import 'package:strengthwise/models/availability_slot_model.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/controllers/interfaces/i_availability_slot_controller.dart';
import 'package:strengthwise/utils/date_format_utils.dart';

/// 快速添加/編輯時段對話框
///
/// 點擊日曆日期後彈出，快速創建或編輯單次時段
/// ⭐ v3.9: 支持編輯模式
class QuickAddSlotDialog extends StatefulWidget {
  final String coachId;
  final DateTime selectedDate;
  /// 傳入現有時段則為編輯模式
  final AvailabilitySlotModel? existingSlot;

  const QuickAddSlotDialog({
    super.key,
    required this.coachId,
    required this.selectedDate,
    this.existingSlot,
  });

  /// 是否為編輯模式
  bool get isEditMode => existingSlot != null;

  @override
  State<QuickAddSlotDialog> createState() => _QuickAddSlotDialogState();
}

class _QuickAddSlotDialogState extends State<QuickAddSlotDialog> {
  late final IAvailabilitySlotController _slotController;

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _slotController = serviceLocator<IAvailabilitySlotController>();

    // ⭐ v3.9: 編輯模式預填數據
    final existingSlot = widget.existingSlot;
    if (existingSlot != null) {
      _startTime = TimeOfDay(hour: existingSlot.startTime.hour, minute: existingSlot.startTime.minute);
      _endTime = TimeOfDay(hour: existingSlot.endTime.hour, minute: existingSlot.endTime.minute);
      _notesController.text = existingSlot.notes ?? '';
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 0);
    }
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
        // ⭐ 強制使用 Material 3 時間選擇器（統一跨平台樣式）
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,  // ⭐ 強制使用 12 小時制
          ),
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

  /// 創建或更新時段
  Future<void> _saveSlot() async {
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
      bool success;

      final existingSlot = widget.existingSlot;
      if (widget.isEditMode && existingSlot != null) {
        // ⭐ v3.9: 編輯模式 - 更新時段
        final updatedSlot = AvailabilitySlotModel(
          id: existingSlot.id,
          coachId: widget.coachId,
          startTime: startDateTime,
          endTime: endDateTime,
          recurrenceRule: existingSlot.recurrenceRule,
          isOverride: existingSlot.isOverride,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: existingSlot.createdAt,
          updatedAt: DateTime.now(),
        );
        success = await _slotController.updateSlot(existingSlot.id, updatedSlot);
      } else {
        // 創建單次時段
        final slot = AvailabilitySlotModel(
          id: '',
          coachId: widget.coachId,
          startTime: startDateTime,
          endTime: endDateTime,
          recurrenceRule: null,
          isOverride: false,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        success = await _slotController.createSlot(slot);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pop(context, true);
        } else {
          _showError(_slotController.errorMessage ?? (widget.isEditMode ? '更新失敗' : '創建失敗'));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('${widget.isEditMode ? '更新' : '創建'}時段時發生錯誤：$e');
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
          Text(widget.isEditMode ? '編輯時段' : '新增時段'),
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
            // 時間範圍（並排顯示）
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('開始'),
                    subtitle: Text(_startTime.format(context)),
                    onTap: () => _selectTime(context, true),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('結束'),
                    subtitle: Text(_endTime.format(context)),
                    onTap: () => _selectTime(context, false),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
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

            // 提示（僅新增模式顯示）
            if (!widget.isEditMode)
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
          onPressed: _isLoading ? null : _saveSlot,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEditMode ? '儲存' : '創建'),
        ),
      ],
    );
  }
}

