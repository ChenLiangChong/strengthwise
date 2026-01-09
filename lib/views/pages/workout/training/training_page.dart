// ✅ 已響應式改造 (Phase 0)
// ✅ v3.2: Coach Mark 引導
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:strengthwise/models/workout_template_model.dart';
import 'package:strengthwise/models/workout_record_model.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/interfaces/i_workout_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/services/core/onboarding_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/workout/execution/template_editor_page.dart';
import 'package:strengthwise/views/pages/workout/execution/widgets/schedule_workout_dialog.dart';
import 'package:strengthwise/views/pages/workout/execution/widgets/select_time_dialog.dart';
import 'package:strengthwise/views/widgets/onboarding/coach_mark_helper.dart';
import 'package:strengthwise/views/widgets/current_page_provider.dart';
import 'widgets/empty_templates_state.dart';
import 'widgets/template_list.dart';
import 'widgets/template_menu_sheet.dart';

/// 訓練模板管理中心
///
/// 響應式設計：子組件已適配多尺寸螢幕
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
  
  // ⭐ v3.2: Coach Mark 引導
  final GlobalKey _fabKey = GlobalKey();
  bool _coachMarkShown = false;

  @override
  void initState() {
    super.initState();
    _workoutController = serviceLocator<IWorkoutController>();
    _workoutService = serviceLocator<IWorkoutService>();
    _authController = serviceLocator<IAuthController>();
    _errorService = serviceLocator<ErrorHandlingService>();
    _loadTemplates();
  }
  
  // ⭐ v3.2: 當頁面變為可見時檢查 Coach Mark
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 當頁面變為當前頁面時，檢查 Coach Mark
    if (CurrentPageProvider.isCurrentPage(context, 2) && !_coachMarkShown) {
      _checkCoachMark();
    }
  }
  
  // ⭐ v3.2: 檢查是否顯示 Coach Mark
  Future<void> _checkCoachMark() async {
    if (_coachMarkShown) return;
    
    // ⭐ 檢查是否是當前頁面（TrainingPage 是 index 2）
    if (!CurrentPageProvider.isCurrentPage(context, 2)) return;
    
    final onboardingService = serviceLocator<OnboardingService>();
    final shouldShow = await onboardingService.shouldShowCoachMark(
      OnboardingService.keyTrainingPage,
    );
    
    if (shouldShow && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && CurrentPageProvider.isCurrentPage(context, 2)) {
          _showCoachMark();
        }
      });
    }
  }
  
  // ⭐ v3.2: 顯示 Coach Mark 引導
  void _showCoachMark() {
    if (_coachMarkShown) return;
    _coachMarkShown = true;
    
    final targets = <TargetFocus>[];
    
    // FAB 引導
    if (_fabKey.currentContext != null) {
      targets.add(
        CoachMarkHelper.createTarget(
          key: _fabKey,
          title: '訓練模板',
          description: '這裡顯示你的訓練模板\n點擊「+」建立新的訓練模板',
          contentAlign: ContentAlign.top,
        ),
      );
    }
    
    if (targets.isNotEmpty) {
      CoachMarkHelper.show(
        context: context,
        targets: targets,
      );
    }
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
        
        // ⭐ v3.2: 檢查 Coach Mark 引導
        _checkCoachMark();
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
        key: _fabKey, // ⭐ v3.2: Coach Mark 引導用
        heroTag: 'training_page_fab', // ⭐ 防止 Hero tag 衝突
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
