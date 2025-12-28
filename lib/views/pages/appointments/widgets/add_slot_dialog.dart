import 'package:flutter/material.dart';
import '../../../../controllers/availability_slot_controller.dart';
import '../../../../services/service_locator.dart';

/// 新增時段對話框
///
/// 支援創建單次時段和週期性時段
class AddSlotDialog extends StatefulWidget {
  final String coachId;
  final DateTime? initialDate;

  const AddSlotDialog({
    super.key,
    required this.coachId,
    this.initialDate,
  });

  @override
  State<AddSlotDialog> createState() => _AddSlotDialogState();
}

class _AddSlotDialogState extends State<AddSlotDialog> {
  final _formKey = GlobalKey<FormState>();
  late final AvailabilitySlotController _controller;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isRecurring = false;
  String _recurrenceType = 'weekly'; // weekly, daily
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ✅ 透過 serviceLocator 獲取 Controller
    _controller = serviceLocator<AvailabilitySlotController>();

    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// 選擇日期
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// 選擇開始時間
  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        // 自動設定結束時間為開始時間 + 1小時
        final endHour = (picked.hour + 1) % 24;
        _endTime = TimeOfDay(hour: endHour, minute: picked.minute);
      });
    }
  }

  /// 選擇結束時間
  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  /// 創建時段
  Future<void> _createSlot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ✅ 簡化：只傳遞 UI 收集的原始數據，讓 Controller 處理業務邏輯
    bool success;

    if (_isRecurring) {
      // 創建週期性時段（Controller 層會處理 RRULE 生成）
      success = await _controller.createRecurringSlotFromUI(
        coachId: widget.coachId,
        date: _selectedDate,
        startTime: _startTime,
        endTime: _endTime,
        recurrenceType: _recurrenceType, // 'weekly' or 'daily'
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    } else {
      // 創建單次時段（Controller 層會組合日期時間）
      success = await _controller.createSingleSlotFromUI(
        coachId: widget.coachId,
        date: _selectedDate,
        startTime: _startTime,
        endTime: _endTime,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
      } else if (_controller.errorMessage != null) {
        _showError(_controller.errorMessage!);
      }
    }
  }

  /// 顯示錯誤訊息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題
                const Text(
                  '新增時段',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // 日期選擇
                _buildDateField(),
                const SizedBox(height: 16),

                // 時間選擇
                Row(
                  children: [
                    Expanded(
                        child: _buildTimeField(
                            '開始時間', _startTime, _selectStartTime)),
                    const SizedBox(width: 16),
                    Expanded(
                        child:
                            _buildTimeField('結束時間', _endTime, _selectEndTime)),
                  ],
                ),
                const SizedBox(height: 16),

                // 週期性開關
                SwitchListTile(
                  title: const Text('週期性時段'),
                  subtitle: Text(_isRecurring ? '每週重複' : '單次時段'),
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                    });
                  },
                ),

                // 週期類型選擇（僅當啟用週期性時顯示）
                if (_isRecurring) ...[
                  const SizedBox(height: 8),
                  _buildRecurrenceTypeSelector(),
                ],

                const SizedBox(height: 16),

                // 備註
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: '備註（選填）',
                    hintText: '例如：瑜伽課程、重訓指導',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // 按鈕
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: ElevatedButton(
                        onPressed: _createSlot,
                        child: const Text('創建'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 建立日期選擇欄位
  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '日期',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  /// 建立時間選擇欄位
  Widget _buildTimeField(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          time.format(context),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  /// 建立週期類型選擇器
  Widget _buildRecurrenceTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<String>(
              title: const Text('每週'),
              value: 'weekly',
              groupValue: _recurrenceType,
              onChanged: (value) {
                setState(() {
                  _recurrenceType = value!;
                });
              },
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: const Text('每天'),
              value: 'daily',
              groupValue: _recurrenceType,
              onChanged: (value) {
                setState(() {
                  _recurrenceType = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
