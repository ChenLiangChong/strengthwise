// ✅ 已響應式改造 (Phase 0) - 列表頁，子組件處理
import 'dart:async'; // ⭐ v3.5
import 'package:flutter/material.dart';
import 'package:strengthwise/models/workout_template_model.dart';
import 'package:strengthwise/models/workout_record_model.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_event_bus_controller.dart'; // ⭐ v3.5
import 'package:strengthwise/services/core/app_event_bus.dart'; // ⭐ v3.5
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'template_editor_page.dart';
import 'widgets/template_list_item.dart';
import 'widgets/empty_template_state.dart';
import 'widgets/template_duplicate_dialog.dart';

import 'widgets/schedule_workout_dialog.dart';

class TemplateManagementPage extends StatefulWidget {
  const TemplateManagementPage({super.key});

  @override
  State<TemplateManagementPage> createState() => _TemplateManagementPageState();
}

class _TemplateManagementPageState extends State<TemplateManagementPage> {
  late final IWorkoutController _workoutController;
  late final IAuthController _authController;
  late final ErrorHandlingService _errorService;
  late final IEventBusController _eventBusController; // ⭐ v3.5

  StreamSubscription<AppEvent>? _eventSubscription; // ⭐ v3.5
  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 從服務定位器獲取依賴
    _workoutController = serviceLocator<IWorkoutController>();
    _authController = serviceLocator<IAuthController>();
    _errorService = serviceLocator<ErrorHandlingService>();
    _eventBusController = serviceLocator<IEventBusController>(); // ⭐ v3.5

    // ⭐ v3.5: 訂閱模板相關事件
    _eventSubscription = _eventBusController.templateEvents.listen(_onAppEvent);

    _loadTemplates();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel(); // ⭐ v3.5
    super.dispose();
  }

  /// ⭐ v3.5: 處理模板相關事件
  void _onAppEvent(AppEvent event) {
    if (!mounted) return;
    // 收到模板事件時，重新載入模板列表
    _loadTemplates(forceRefresh: true);
  }

  /// 載入模板列表
  ///
  /// [forceRefresh] 是否強制重新載入，忽略緩存（預設 false）
  Future<void> _loadTemplates({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 使用控制器載模板
      final templates = forceRefresh
          ? await _workoutController.reloadTemplates() // 強制重新載入
          : await _workoutController.loadUserTemplates(); // 可能使用緩存

      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }

  Future<void> _duplicateTemplate(WorkoutTemplate template) async {
    try {
      final newTitle = await showDialog<String>(
        context: context,
        barrierDismissible: false, // 修復：防止點擊外部關閉
        builder: (context) => TemplateDuplicateDialog(
          defaultName: '${template.title} - 副本',
        ),
      );

      if (newTitle == null || newTitle.isEmpty) return;

      // 創建新模板的副本
      final newTemplate = template.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: newTitle,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 使用控制器創建模板
      await _workoutController.createTemplate(newTemplate);
      // ⭐ v3.5: 事件由 Controller 統一發布，View 只處理 UI 回饋

      // 強制重新載入模板列表（忽略緩存）
      await _loadTemplates(forceRefresh: true);

      if (mounted) {
        NotificationUtils.showSuccess(context, '模板複製成功');
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }

  Future<void> _deleteTemplate(String templateId) async {
    try {
      // 使用控制器刪除模板
      final success = await _workoutController.deleteTemplate(templateId);
      // ⭐ v3.5: 事件由 Controller 統一發布，View 只處理 UI 回饋

      if (success) {
        setState(() {
          _templates.removeWhere((template) => template.id == templateId);
        });

        if (mounted) {
          NotificationUtils.showSuccess(context, '模板已刪除');
        }
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }

  // 直接從模板創建訓練記錄
  /// 編輯模板
  Future<void> _editTemplate(WorkoutTemplate template) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TemplateEditorPage(template: template),
      ),
    );

    if (result == true) {
      // 強制重新載入模板列表（忽略緩存）
      await _loadTemplates(forceRefresh: true);

      if (mounted) {
        NotificationUtils.showSuccess(context, '模板已更新');
      }
    }
  }

  Future<void> _createWorkoutRecordFromTemplate(
      WorkoutTemplate template) async {
    try {
      // 顯示日期時間選擇對話框
      final result = await showDialog<Map<String, DateTime>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ScheduleWorkoutDialog(
          templateName: template.title,
        ),
      );

      if (result == null) return;

      final trainingStart = result['start']!;
      final trainingEnd = result['end']!;

      // 獲取當前用戶 ID
      final userId = _authController.user?.uid;
      if (userId == null) {
        throw Exception('未登入');
      }

      debugPrint(
          '[TemplateManagement] 從模板創建訓練: ${template.title}，時間: $trainingStart - $trainingEnd');

      // 從模板創建動作記錄
      final exerciseRecords = template.exercises
          .map((exercise) => ExerciseRecord(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                sets: List.generate(
                  exercise.sets,
                  (index) => SetRecord(
                    setNumber: index + 1,
                    reps: exercise.reps,
                    weight: exercise.weight,
                    restTime: exercise.restTime,
                  ),
                ),
              ))
          .toList();

      // 直接創建完整訓練記錄（包含時間範圍）
      final record = WorkoutRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        workoutPlanId: template.id,
        userId: userId,
        title: template.title,
        date: trainingStart,
        exerciseRecords: exerciseRecords,
        completed: false,
        createdAt: DateTime.now(),
        trainingEndTime: trainingEnd,
      );

      // ⭐ v3.5: 透過 Controller 創建訓練記錄（Controller 會自動發布事件）
      final createdRecord = await _workoutController.createRecord(record);
      debugPrint('[TEMPLATE_MANAGEMENT] ✅ 訓練記錄已創建: ${createdRecord.id}');

      if (mounted) {
        NotificationUtils.showSuccess(
          context,
          '${trainingStart.month}月${trainingStart.day}日的訓練已創建',
        );
      }
    } catch (e) {
      debugPrint('[TemplateManagement] 從模板創建訓練失敗: $e');
      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練計劃模板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TemplateEditorPage(),
                ),
              );

              if (result == true) {
                // 強制重新載入模板列表（忽略緩存）
                await _loadTemplates(forceRefresh: true);

                if (mounted) {
                  // ignore: use_build_context_synchronously - mounted 已檢查
                  NotificationUtils.showSuccess(context, '模板已創建');
                }
              }
            },
            tooltip: '創建模板',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? EmptyTemplateState(
                  onBackPressed: () => Navigator.of(context).pop(),
                )
              : ListView.builder(
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    return TemplateListItem(
                      template: template,
                      onTap: () => Navigator.pop(context, template),
                      onMenuAction: (action) async {
                        switch (action) {
                          case 'create_record':
                            await _createWorkoutRecordFromTemplate(template);
                            break;
                          case 'edit':
                            await _editTemplate(template);
                            break;
                          case 'duplicate':
                            await _duplicateTemplate(template);
                            break;
                          case 'delete':
                            await _deleteTemplate(template.id);
                            break;
                        }
                      },
                    );
                  },
                ),
    );
  }
}
