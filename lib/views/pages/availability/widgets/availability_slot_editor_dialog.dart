import 'package:flutter/material.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/firestore_id_generator.dart';

/// 時段編輯對話框
/// 
/// 功能：
/// - 創建或編輯可用時段
/// - 設定時間範圍
/// - 設定優先級
/// - 設定重複規則（TODO: 未來實作）
class AvailabilitySlotEditorDialog extends StatefulWidget {
  final ClientAvailabilityModel? slot;

  const AvailabilitySlotEditorDialog({
    Key? key,
    this.slot,
  }) : super(key: key);

  @override
  State<AvailabilitySlotEditorDialog> createState() =>
      _AvailabilitySlotEditorDialogState();
}

class _AvailabilitySlotEditorDialogState
    extends State<AvailabilitySlotEditorDialog> {
  late DateTime _startTime;
  late DateTime _endTime;
  late AvailabilityPriority _priority;
  String? _notes;

  @override
  void initState() {
    super.initState();
    
    if (widget.slot != null) {
      // 編輯模式
      _startTime = widget.slot!.startTime;
      _endTime = widget.slot!.endTime;
      _priority = widget.slot!.priority;
      _notes = widget.slot!.notes;
    } else {
      // 創建模式：預設為明天 09:00-10:00
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _startTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      _endTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);
      _priority = AvailabilityPriority.available;
    }
  }

  /// 選擇日期
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _startTime.hour,
          _startTime.minute,
        );
        _endTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _endTime.hour,
          _endTime.minute,
        );
      });
    }
  }

  /// 選擇開始時間
  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );

    if (picked != null) {
      setState(() {
        _startTime = DateTime(
          _startTime.year,
          _startTime.month,
          _startTime.day,
          picked.hour,
          picked.minute,
        );
        
        // 確保結束時間在開始時間之後
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      });
    }
  }

  /// 選擇結束時間
  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
    );

    if (picked != null) {
      final newEndTime = DateTime(
        _endTime.year,
        _endTime.month,
        _endTime.day,
        picked.hour,
        picked.minute,
      );
      
      if (newEndTime.isAfter(_startTime)) {
        setState(() => _endTime = newEndTime);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('結束時間必須在開始時間之後')),
        );
      }
    }
  }

  /// 儲存時段
  void _save() async {
    final authController = serviceLocator<IAuthController>();
    final currentUser = authController.user;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入')),
      );
      return;
    }
    
    final slot = ClientAvailabilityModel(
      id: widget.slot?.id ?? generateFirestoreId(),
      clientId: currentUser.uid,
      startTime: _startTime,
      endTime: _endTime,
      priority: _priority,
      notes: _notes,
      createdAt: widget.slot?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    Navigator.pop(context, slot);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(widget.slot != null ? '編輯時段' : '新增時段'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期選擇
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('日期'),
              subtitle: Text(_formatDate(_startTime)),
              onTap: _selectDate,
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 8),
            
            // 時間範圍
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('開始'),
                    subtitle: Text(_formatTime(_startTime)),
                    onTap: _selectStartTime,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('結束'),
                    subtitle: Text(_formatTime(_endTime)),
                    onTap: _selectEndTime,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 優先級
            Text('優先級', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<AvailabilityPriority>(
              segments: const [
                ButtonSegment(
                  value: AvailabilityPriority.preferred,
                  label: Text('首選'),
                  icon: Icon(Icons.star, size: 16),
                ),
                ButtonSegment(
                  value: AvailabilityPriority.available,
                  label: Text('可訓練'),
                  icon: Icon(Icons.check_circle, size: 16),
                ),
                ButtonSegment(
                  value: AvailabilityPriority.avoid,
                  label: Text('避免'),
                  icon: Icon(Icons.cancel, size: 16),
                ),
              ],
              selected: {_priority},
              onSelectionChanged: (Set<AvailabilityPriority> newSelection) {
                setState(() => _priority = newSelection.first);
              },
            ),
            
            const SizedBox(height: 16),
            
            // 備註
            TextField(
              decoration: const InputDecoration(
                labelText: '備註（選填）',
                hintText: '例如：這段時間精神最好',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => _notes = value.isEmpty ? null : value,
              controller: TextEditingController(text: _notes),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('儲存'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

