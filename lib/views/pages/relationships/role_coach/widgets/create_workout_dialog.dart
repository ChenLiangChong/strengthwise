import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/client_management_controller.dart';
import 'package:strengthwise/models/workout_template/workout_template.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/workout/execution/plan_editor_page.dart';

/// 創建訓練計畫 Dialog（教練端）
///
/// 功能：
/// 1. 快速創建空白訓練
/// 2. 從模板創建
/// 3. 自訂訓練
class CreateWorkoutDialog extends StatefulWidget {
  final String coachId;
  final String clientId;
  final String clientName;
  final DateTime scheduledDate;
  final DateTime? startTime;  // ⭐ 新增：預填時段開始時間
  final DateTime? endTime;    // ⭐ 新增：預填時段結束時間

  const CreateWorkoutDialog({
    super.key,
    required this.coachId,
    required this.clientId,
    required this.clientName,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
  });

  @override
  State<CreateWorkoutDialog> createState() => _CreateWorkoutDialogState();
}

class _CreateWorkoutDialogState extends State<CreateWorkoutDialog> {
  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  /// 載入訓練模板
  Future<void> _loadTemplates() async {
    try {
      // TODO: 後續可以直接透過 IWorkoutService 查詢模板
      _templates = [];
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 創建空白訓練
  Future<void> _createBlankWorkout() async {
    Navigator.pop(context);
    
    // 導航到訓練編輯頁面
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanEditorPage(
          selectedDate: widget.scheduledDate,
          planType: 'trainer',
          traineeId: widget.clientId, // 指派給學員
          initialStartTime: widget.startTime,  // ⭐ 傳入偏好時段開始時間
          initialEndTime: widget.endTime,      // ⭐ 傳入偏好時段結束時間
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  /// 從模板創建
  Future<void> _createFromTemplate(WorkoutTemplate template) async {
    final controller = context.read<ClientManagementController>();

    try {
      final success = await controller.createWorkoutForClient(
        coachId: widget.coachId,
        clientId: widget.clientId,
        scheduledDate: widget.scheduledDate,
        title: template.title,
        notes: template.description,
        exercises: template.exercises
            .map((e) => e.toJson())
            .toList(),
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          NotificationUtils.showError(context, '創建失敗');
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, '創建失敗: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('新增訓練計畫'),
          const SizedBox(height: 8),
          Text(
            '學員：${widget.clientName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            '日期：${_formatDate(widget.scheduledDate)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 選項 1：空白訓練
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.add, color: colorScheme.primary),
                    ),
                    title: const Text('空白訓練'),
                    subtitle: const Text('從頭開始建立訓練計畫'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _createBlankWorkout,
                  ),

                  const Divider(),

                  // 選項 2：從模板創建
                  if (_templates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        '尚無訓練模板',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else ...[
                    const ListTile(
                      title: Text(
                        '從模板創建',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _templates.length,
                        itemBuilder: (context, index) {
                          final template = _templates[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.secondaryContainer,
                              child: Icon(Icons.bookmark,
                                  color: colorScheme.secondary),
                            ),
                            title: Text(template.title),
                            subtitle: Text(
                              '${template.exercises.length} 個動作',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _createFromTemplate(template),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

