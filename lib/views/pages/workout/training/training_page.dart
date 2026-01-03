import 'package:flutter/material.dart';
import 'package:strengthwise/models/workout_template_model.dart';
import 'package:strengthwise/models/workout_record_model.dart';
import 'package:strengthwise/models/workout_record/exercise_record.dart';
import 'package:strengthwise/models/workout_record/set_record.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/interfaces/i_workout_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/workout/execution/template_editor_page.dart';
import 'package:strengthwise/views/pages/workout/execution/widgets/schedule_workout_dialog.dart';
import 'package:strengthwise/views/pages/workout/execution/widgets/select_time_dialog.dart';
import 'widgets/empty_templates_state.dart';
import 'widgets/template_list.dart';
import 'widgets/template_menu_sheet.dart';

/// 訓練模板管理中心
///
/// 功能：
/// - 顯示所有已保存的訓練模板
/// - 快速從模板創建訓練計劃
/// - 編輯和刪除模板
class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  late final IWorkoutController _workoutController;
  late final IWorkoutService _workoutService;
  late final IAuthController _authController;
  late final ErrorHandlingService _errorService;

  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _workoutController = serviceLocator<IWorkoutController>();
    _workoutService = serviceLocator<IWorkoutService>();
    _authController = serviceLocator<IAuthController>();
    _errorService = serviceLocator<ErrorHandlingService>();
    _loadTemplates();
  }

  /// 載入模板列表
  ///
  /// [forceRefresh] 是否強制重新載入，忽略緩存（預設 false）
  Future<void> _loadTemplates({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 使用控制器加載模板
      final templates = forceRefresh
          ? await _workoutController.reloadTemplates() // 強制重新載入
          : await _workoutController.loadUserTemplates(); // 可能使用緩存

      if (mounted) {
        setState(() {
          _templates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _errorService.handleError(context, e);
      }
    }
  }

  /// 從模板快速創建今日訓練
  Future<void> _createTodayPlanFromTemplate(WorkoutTemplate template) async {
    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        throw Exception('未登入');
      }

      // 顯示時間選擇對話框
      final result = await showDialog<Map<String, DateTime>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SelectTimeDialog(
          templateName: template.title,
        ),
      );

      if (result == null) return;

      final trainingStart = result['start']!;
      final trainingEnd = result['end']!;

      print(
          '[TrainingPage] 從模板創建今日訓練: ${template.title}，時間: $trainingStart - $trainingEnd');

      // 從模板創建動作列表
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

      // 直接創建完整的記錄（包含正確的時間）
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

      await _workoutService.createRecord(record);

      if (mounted) {
        // 使用統一的成功通知（浮動，不會完全遮擋底部內容）
        NotificationUtils.showSuccess(
          context,
          '已創建今日訓練：${template.title}',
          onAction: () {
            // 切換到行事曆頁面
            DefaultTabController.of(context).animateTo(1); // 假設行事曆是第2個 tab
          },
          actionLabel: '查看',
        );

        // 可選：短暫延遲後自動跳轉到行事曆
        // 取消註解以啟用自動跳轉
        // Future.delayed(const Duration(milliseconds: 1500), () {
        //   if (mounted) {
        //     DefaultTabController.of(context).animateTo(1);
        //   }
        // });
      }
    } catch (e) {
      print('[TrainingPage] 創建今日訓練失敗: $e');
      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }

  /// 從模板創建自訂日期的訓練
  Future<void> _createScheduledPlanFromTemplate(
      WorkoutTemplate template) async {
    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        throw Exception('未登入');
      }

      // 顯示日期和時間選擇對話框
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

      print(
          '[TrainingPage] 從模板創建訓練: ${template.title}，時間: $trainingStart - $trainingEnd');

      // 從模板創建動作列表
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

      // 直接創建完整的記錄（包含正確的時間）
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

      await _workoutService.createRecord(record);

      if (mounted) {
        NotificationUtils.showSuccess(
          context,
          '已安排 ${trainingStart.month}/${trainingStart.day} 的訓練：${template.title}',
        );
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e);
      }
    }
  }

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

  /// 刪除模板
  Future<void> _deleteTemplate(WorkoutTemplate template) async {
    final confirmed = await _showDeleteConfirmation(template);
    if (!confirmed) return;

    try {
      final success = await _workoutController.deleteTemplate(template.id);

      if (success) {
        setState(() {
          _templates.removeWhere((t) => t.id == template.id);
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

  /// 顯示模板操作選單
  void _showTemplateMenu(WorkoutTemplate template) {
    TemplateMenuSheet.show(
      context,
      template: template,
      onCreateToday: () => _createTodayPlanFromTemplate(template),
      onCreateScheduled: () => _createScheduledPlanFromTemplate(template),
      onEdit: () => _editTemplate(template),
      onDelete: () => _deleteTemplate(template),
    );
  }

  /// 顯示刪除確認對話框
  Future<bool> _showDeleteConfirmation(WorkoutTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => AlertDialog(
        title: const Text('刪除模板'),
        content: Text('確定要刪除「${template.title}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// 創建新模板
  Future<void> _createNewTemplate() async {
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
        NotificationUtils.showSuccess(context, '模板已創建');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練模板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTemplates,
            tooltip: '重新載入',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTemplate,
        tooltip: '新模板',
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 建構頁面主體
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_templates.isEmpty) {
      return EmptyTemplatesState(onCreateTemplate: _createNewTemplate);
    }

    return RefreshIndicator(
      onRefresh: _loadTemplates,
      child: TemplateList(
        templates: _templates,
        onTemplateTap: _showTemplateMenu,
        onMoreMenu: _showTemplateMenu,
        onCreateToday: _createTodayPlanFromTemplate,
        onCreateScheduled: _createScheduledPlanFromTemplate,
      ),
    );
  }
}
