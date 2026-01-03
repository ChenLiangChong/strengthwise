import 'package:flutter/material.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/firestore_id_generator.dart';
import 'package:intl/intl.dart';

/// 時段編輯對話框
/// 
/// 功能：
/// - 創建或編輯可用時段
/// - 設定時間範圍
/// - 設定優先級
class AvailabilitySlotEditorDialog extends StatefulWidget {
  final ClientAvailabilityModel? slot;
  final DateTime selectedDate; // ⭐ 改為必填（來自行事曆點擊）

  const AvailabilitySlotEditorDialog({
    Key? key,
    this.slot,
    required this.selectedDate, // ⭐ 必填
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
      // 創建模式：使用選定的日期
      _startTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        9,
        0,
      );
      _endTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        10,
        0,
      );
      _priority = AvailabilityPriority.available;
    }
  }

  /// 選擇開始時間
  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
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
    
    // ⭐ v2.1: 確保時間是本地時區（formatToTstzRange 會自動轉 UTC）
    final slot = ClientAvailabilityModel(
      id: widget.slot?.id ?? generateFirestoreId(),
      clientId: currentUser.uid,
      startTime: _startTime,  // 本地時間
      endTime: _endTime,      // 本地時間
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.slot != null ? '編輯時段' : '新增時段'),
          const SizedBox(height: 4),
          Text(
            DateFormat('yyyy年MM月dd日').format(_startTime),
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
                    subtitle: Text(TimeOfDay.fromDateTime(_startTime).format(context)),
                    onTap: _selectStartTime,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    title: const Text('結束'),
                    subtitle: Text(TimeOfDay.fromDateTime(_endTime).format(context)),
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
              maxLength: 100,
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
}

