import 'package:flutter/material.dart';
import 'package:strengthwise/models/availability_slot_model.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/controllers/interfaces/i_availability_slot_controller.dart';
import 'package:strengthwise/utils/date_format_utils.dart';

/// 時段編輯對話框
///
/// 用於編輯或新增教練時段
class SlotEditorDialog extends StatefulWidget {
  final String coachId;
  final AvailabilitySlotModel? slot; // null = 新增模式
  final DateTime? selectedDate; // 新增模式時必填

  const SlotEditorDialog({
    super.key,
    required this.coachId,
    this.slot,
    this.selectedDate,
  }) : assert(slot != null || selectedDate != null, '新增模式時必須提供 selectedDate');

  @override
  State<SlotEditorDialog> createState() => _SlotEditorDialogState();
}

class _SlotEditorDialogState extends State<SlotEditorDialog> {
  late final IAvailabilitySlotController _slotController;

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late DateTime _date;
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditMode => widget.slot != null;

  @override
  void initState() {
    super.initState();
    _slotController = serviceLocator<IAvailabilitySlotController>();

    if (_isEditMode) {
      // 編輯模式：載入現有時段資料
      final slot = widget.slot!;
      _date = slot.startTime;
      _startTime = TimeOfDay.fromDateTime(slot.startTime);
      _endTime = TimeOfDay.fromDateTime(slot.endTime);
      _notesController.text = slot.notes ?? '';
    } else {
      // 新增模式：使用選定的日期
      _date = widget.selectedDate!;
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
            alwaysUse24HourFormat: false, // ⭐ 強制使用 12 小時制
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

  /// 儲存時段
  Future<void> _saveSlot() async {
    // 驗證
    final startDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      _showError('結束時間必須晚於開始時間');
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success;

      if (_isEditMode) {
        // 更新現有時段
        final updatedSlot = widget.slot!.copyWith(
          startTime: startDateTime,
          endTime: endDateTime,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );
        success = await _slotController.updateSlot(
          widget.slot!.id,
          updatedSlot,
        );
      } else {
        // 創建新時段
        final newSlot = AvailabilitySlotModel(
          id: '',
          coachId: widget.coachId,
          startTime: startDateTime,
          endTime: endDateTime,
          recurrenceRule: null,
          isOverride: false,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        success = await _slotController.createSlot(newSlot);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pop(context, true);
        } else {
          _showError(_slotController.errorMessage ?? '儲存失敗');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('儲存時段時發生錯誤：$e');
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
    final theme = Theme.of(context);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEditMode ? '編輯時段' : '新增時段'),
          const SizedBox(height: 4),
          Text(
            DateFormatUtils.formatDate(_date),
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

            // 備註
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
              : Text(_isEditMode ? '儲存' : '創建'),
        ),
      ],
    );
  }
}
