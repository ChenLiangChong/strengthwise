import 'package:flutter/material.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/interfaces/i_coaching_relationship_service.dart';
import 'package:strengthwise/services/interfaces/i_appointment_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';

/// 臨時課程建立對話框
///
/// 教練可直接建立 confirmed 狀態的課程，不經過預約流程。
/// 適用於臨時加課或現場上課的情況。
class AdHocSessionDialog extends StatefulWidget {
  /// 教練 ID
  final String coachId;

  const AdHocSessionDialog({
    super.key,
    required this.coachId,
  });

  /// 顯示對話框並返回是否成功創建
  static Future<bool?> show(BuildContext context, String coachId) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AdHocSessionDialog(coachId: coachId),
    );
  }

  @override
  State<AdHocSessionDialog> createState() => _AdHocSessionDialogState();
}

class _AdHocSessionDialogState extends State<AdHocSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  late final ICoachingRelationshipService _relationshipService;
  late final IAppointmentService _appointmentService;
  late final ErrorHandlingService _errorService;

  List<UserModel> _clients = [];
  UserModel? _selectedClient;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationMinutes = 60;

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _relationshipService = serviceLocator<ICoachingRelationshipService>();
    _appointmentService = serviceLocator<IAppointmentService>();
    _errorService = serviceLocator<ErrorHandlingService>();
    _loadClients();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await _relationshipService.getCoachClientsWithDetails(
        widget.coachId,
        status: 'active',
      );
      if (mounted) {
        setState(() {
          _clients = clients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _errorService.handleError(context, e, customMessage: '載入學員列表失敗');
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇學員')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final endTime = startTime.add(Duration(minutes: _durationMinutes));

      await _appointmentService.createAdHocSession(
        coachId: widget.coachId,
        clientId: _selectedClient!.uid,
        startTime: startTime,
        endTime: endTime,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('臨時課程已建立'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _errorService.handleError(context, e, customMessage: '建立臨時課程失敗');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.flash_on, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('建立臨時課程'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 說明文字
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '直接建立已確認的課程，適用於臨時加課',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 選擇學員
                    DropdownButtonFormField<UserModel>(
                      value: _selectedClient,
                      decoration: const InputDecoration(
                        labelText: '選擇學員',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      items: _clients.map((client) {
                        return DropdownMenuItem<UserModel>(
                          value: client,
                          child: Text(client.displayName ?? client.email),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedClient = value);
                      },
                      validator: (value) {
                        if (value == null) return '請選擇學員';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // 日期選擇
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('日期'),
                      subtitle: Text(_formatDate(_selectedDate)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectDate,
                    ),

                    // 時間選擇
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('開始時間'),
                      subtitle: Text(_formatTime(_selectedTime)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectTime,
                    ),

                    const SizedBox(height: 8),

                    // 課程時長
                    DropdownButtonFormField<int>(
                      value: _durationMinutes,
                      decoration: const InputDecoration(
                        labelText: '課程時長',
                        prefixIcon: Icon(Icons.timer),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 分鐘')),
                        DropdownMenuItem(value: 45, child: Text('45 分鐘')),
                        DropdownMenuItem(value: 60, child: Text('60 分鐘')),
                        DropdownMenuItem(value: 90, child: Text('90 分鐘')),
                        DropdownMenuItem(value: 120, child: Text('120 分鐘')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _durationMinutes = value);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // 備註
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: '備註（選填）',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                        hintText: '例如：臨時加課、補課',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_isSubmitting ? '建立中...' : '建立課程'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    return '${date.year}/${date.month}/${date.day} ($weekday)';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getWeekdayName(int weekday) {
    const names = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
    return names[weekday - 1];
  }
}

