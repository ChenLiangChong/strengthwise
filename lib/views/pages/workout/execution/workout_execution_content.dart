// ✅ 已響應式改造 (Phase 0) - 訓練執行內容，子組件處理
// ✅ v3.1: 從 WorkoutExecutionPage 抽取的可內嵌訓練執行內容
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strengthwise/models/exercise_model.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_execution_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/realtime/session_realtime_service.dart';
import 'package:strengthwise/themes/app_theme.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/workout/execution/widgets/exercise_card.dart';
import 'package:strengthwise/views/pages/exercises/exercises_page.dart';
import 'widgets/workout_info_card.dart';
import 'widgets/empty_exercise_state.dart';
import 'widgets/exercise_settings_dialog.dart';
import 'widgets/rest_timer_widget.dart';

/// 訓練執行內容 Widget
///
/// 從 WorkoutExecutionPage 抽取的可內嵌組件，包含：
/// - 訓練資訊卡片
/// - 動作卡片列表
/// - 休息計時器
/// - 開始訓練按鈕
///
/// 可用於：
/// - WorkoutExecutionPage（獨立頁面）
/// - SessionExecutionTab（內嵌在 Session Mode）
class WorkoutExecutionContent extends StatefulWidget {
  /// 訓練記錄 ID
  final String workoutRecordId;

  /// 是否在列表底部顯示「新增動作」按鈕
  /// - WorkoutExecutionPage: false（用外部 FAB）
  /// - SessionExecutionTab: true（用內嵌按鈕）
  final bool showInlineAddButton;

  /// 覆蓋「是否可編輯」的判斷（Session Mode 用）
  /// null 時使用 Controller 的判斷
  final bool? overrideCanEdit;

  /// 覆蓋「是否可打勾」的判斷（Session Mode 用）
  /// null 時使用 Controller 的判斷
  final bool? overrideCanMarkSet;

  /// 覆蓋「是否顯示計時器 UI」的判斷（Session Mode 用）
  /// null 時使用 Controller 的判斷
  final bool? overrideShowTimerUI;

  /// 自訂新增動作的回調（用於權限檢查等）
  final VoidCallback? onAddExerciseOverride;

  /// 載入完成的回調
  final VoidCallback? onLoaded;

  /// 資料變更的回調
  final VoidCallback? onDataChanged;

  /// 滾動區域頂部的額外 Widget（會被轉為 SliverToBoxAdapter）
  /// 用於 Session Mode 在頂部顯示 ReadinessCard 等
  final List<Widget>? headerWidgets;

  /// 滾動區域底部的額外 Widget（會被轉為 SliverToBoxAdapter）
  /// 用於 Session Mode 在訓練下方顯示課程筆記等
  final List<Widget>? footerWidgets;

  const WorkoutExecutionContent({
    super.key,
    required this.workoutRecordId,
    this.showInlineAddButton = true,
    this.overrideCanEdit,
    this.overrideCanMarkSet,
    this.overrideShowTimerUI,
    this.onAddExerciseOverride,
    this.onLoaded,
    this.onDataChanged,
    this.headerWidgets,
    this.footerWidgets,
  });

  @override
  State<WorkoutExecutionContent> createState() =>
      WorkoutExecutionContentState();
}

class WorkoutExecutionContentState extends State<WorkoutExecutionContent>
    with WidgetsBindingObserver {
  late final IWorkoutExecutionController _executionController;
  late final SessionRealtimeService _realtimeService;

  // ⭐ v3.1: Realtime 訂閱 ID（用於取消訂閱）
  String? _realtimeSubscriptionId;

  // 新增動作的控制器
  final TextEditingController _newExerciseSetsController =
      TextEditingController(text: '3');
  final TextEditingController _newExerciseRepsController =
      TextEditingController(text: '10');
  final TextEditingController _newExerciseWeightController =
      TextEditingController(text: '0');
  final TextEditingController _newExerciseRestController =
      TextEditingController(text: '60');

  // 訓練備註控制器
  final TextEditingController _workoutNotesController = TextEditingController();

  // 休息計時器狀態
  bool _isRestTimerActive = false;
  int _restSeconds = 90;

  // 是否已載入
  bool _isInitialized = false;

  // ⭐ v3.1: 防止自己觸發的 Realtime 更新導致閃爍
  DateTime? _lastLocalSaveTime;

  /// 暴露控制器給外部（用於 WorkoutExecutionPage 的 AppBar 操作）
  IWorkoutExecutionController get controller => _executionController;

  /// 暴露備註控制器
  TextEditingController get notesController => _workoutNotesController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _executionController = serviceLocator<IWorkoutExecutionController>();
    _realtimeService = serviceLocator<SessionRealtimeService>();
    _loadWorkoutPlan();
    _startTimerLoop();
    // ⭐ v3.1: 延遲訂閱 Realtime，等載入完成後根據條件決定
  }

  /// ⭐ v3.1: 根據條件決定是否訂閱 Realtime
  /// 只有以下情況才需要 Realtime：
  /// 1. Session Mode（上課，需要教練學員同步）
  /// 2. 教練查看學員訓練（traineeId != currentUserId）
  /// 自己訓練自己時不需要 Realtime（避免自己改自己觸發重載）
  void _subscribeToRealtimeIfNeeded() {
    final authController = serviceLocator<IAuthController>();
    final currentUserId = authController.user?.uid;
    final traineeId = _executionController.getTraineeId();
    final isSessionMode = _executionController.isSessionPlan();

    // 判斷是否需要 Realtime
    final isOwnTraining = traineeId == null || traineeId == currentUserId;
    final needsRealtime = isSessionMode || !isOwnTraining;

    debugPrint(
        '[WORKOUT_CONTENT] Realtime 判斷: isSessionMode=$isSessionMode, isOwnTraining=$isOwnTraining, needsRealtime=$needsRealtime');

    if (!needsRealtime) {
      debugPrint('[WORKOUT_CONTENT] 自己訓練，不需要 Realtime');
      return;
    }

    debugPrint('[WORKOUT_CONTENT] 開始訂閱 Realtime: ${widget.workoutRecordId}');
    _realtimeSubscriptionId = _realtimeService.subscribeToWorkoutPlan(
      workoutPlanId: widget.workoutRecordId,
      onUpdate: () {
        // ⭐ v3.1: 忽略自己觸發的 Realtime 更新（2 秒內的本地保存）
        if (_shouldIgnoreRealtimeUpdate()) {
          debugPrint('[WORKOUT_CONTENT] ⏭️ 忽略自己觸發的 Realtime 更新');
          return;
        }
        debugPrint('[WORKOUT_CONTENT] ⚡ 收到 Realtime 更新，重新載入資料');
        _reloadWorkoutPlan();
      },
      onDelete: () {
        // 訓練計畫被刪除
        debugPrint('[WORKOUT_CONTENT] 訓練計畫被刪除');
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
    debugPrint('[WORKOUT_CONTENT] 訂閱 ID: $_realtimeSubscriptionId');
  }

  /// ⭐ v3.1: 判斷是否應該忽略 Realtime 更新
  /// 如果剛剛（2 秒內）做過本地保存，就忽略（避免自己觸發的更新導致閃爍）
  bool _shouldIgnoreRealtimeUpdate() {
    if (_lastLocalSaveTime == null) return false;
    final elapsed = DateTime.now().difference(_lastLocalSaveTime!);
    return elapsed.inSeconds < 2;
  }

  /// ⭐ v3.1: 標記剛剛做了本地保存
  void _markLocalSave() {
    _lastLocalSaveTime = DateTime.now();
  }

  /// ⭐ v3.1: 重新載入訓練計畫（靜默更新，不閃爍）
  Future<void> _reloadWorkoutPlan() async {
    if (!mounted) return;
    // 使用靜默更新，不影響計時和 loading 狀態
    await _executionController.reloadForRealtime(widget.workoutRecordId);
    setState(() {});
    widget.onDataChanged?.call();
  }

  @override
  void didUpdateWidget(WorkoutExecutionContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 workoutRecordId 變了，重新載入（訂閱會在載入完成後處理）
    if (widget.workoutRecordId != oldWidget.workoutRecordId) {
      // 取消舊的訂閱
      if (_realtimeSubscriptionId != null) {
        _realtimeService.unsubscribe(_realtimeSubscriptionId!);
        _realtimeSubscriptionId = null;
      }
      _loadWorkoutPlan();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // ⭐ v3.1: App 進入背景時保存訓練狀態
      if (_executionController.isInProgress) {
        _executionController.pauseTraining();
      }
      // 保存所有未保存的修改
      if (_executionController.isDataChanged) {
        _executionController.saveWorkoutRecord();
      }
      setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  void _startTimerLoop() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (_executionController.isInProgress) {
          _executionController.tickElapsedTime();
          setState(() {});
        }
        _startTimerLoop();
      }
    });
  }

  String _formatElapsedTime() {
    final totalSeconds = _executionController.elapsedSeconds;
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _loadWorkoutPlan() async {
    await _executionController.loadWorkoutPlan(widget.workoutRecordId);

    // ⭐ v3.1: 設置 Session Mode 的權限覆蓋
    // 這讓 Controller 內部的權限檢查尊重 Session Mode 的時間窗口邏輯
    if (widget.overrideCanEdit != null || widget.overrideCanMarkSet != null) {
      debugPrint(
          '[WORKOUT_CONTENT] 設置權限覆蓋: canEdit=${widget.overrideCanEdit}, canMarkSet=${widget.overrideCanMarkSet}');
      _executionController.setPermissionOverride(
        canEdit: widget.overrideCanEdit,
        canMarkSet: widget.overrideCanMarkSet,
      );
    }

    _workoutNotesController.text = _executionController.getNotes();
    _isInitialized = true;
    debugPrint(
        '[WORKOUT_CONTENT] 載入完成，_canEdit=$_canEdit, _canMarkSet=$_canMarkSet');

    // ⭐ v3.1: 載入完成後根據條件決定是否訂閱 Realtime
    _subscribeToRealtimeIfNeeded();

    setState(() {});
    widget.onLoaded?.call();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // ⭐ v3.1: 取消 Realtime 訂閱
    if (_realtimeSubscriptionId != null) {
      _realtimeService.unsubscribe(_realtimeSubscriptionId!);
    }

    // ⭐ v3.1: 離開頁面時保存所有未保存的修改
    if (_executionController.isDataChanged) {
      _executionController.saveWorkoutRecord();
    }

    _newExerciseSetsController.dispose();
    _newExerciseRepsController.dispose();
    _newExerciseWeightController.dispose();
    _newExerciseRestController.dispose();
    _workoutNotesController.dispose();
    super.dispose();
  }

  // ========================================
  // 權限判斷（支援覆蓋）
  // ========================================

  bool get _canEdit => widget.overrideCanEdit ?? _executionController.canEdit();

  bool get _canMarkSet =>
      widget.overrideCanMarkSet ?? _executionController.canToggleCompletion();

  bool get _canDelete =>
      widget.overrideCanEdit ?? _executionController.canDelete();

  bool get _showTimerUI =>
      widget.overrideShowTimerUI ?? _executionController.shouldShowTimerUI();

  // ========================================
  // 提示訊息
  // ========================================

  void _showCannotEditMessage() {
    if (_executionController.isPastDate()) {
      NotificationUtils.showWarning(context, '無法編輯過去的訓練記錄');
    } else {
      NotificationUtils.showWarning(context, '無法編輯此訓練計畫');
    }
  }

  void _showCannotToggleCompletionMessage() {
    if (_executionController.isCoachViewingTrainee()) {
      NotificationUtils.showWarning(context, '教練無法幫學員勾選動作，請由學員自行完成訓練');
    } else if (_executionController.isPastDate()) {
      NotificationUtils.showWarning(context, '無法修改過去的訓練記錄');
    } else if (_executionController.isFutureDate()) {
      NotificationUtils.showWarning(context, '未來的訓練無法勾選完成，請在訓練當天標記');
    } else if (_executionController.isPaused) {
      NotificationUtils.showWarning(context, '請先點擊「繼續訓練」按鈕後再勾選');
    } else if (_executionController.isPending) {
      NotificationUtils.showWarning(context, '請先點擊「開始訓練」按鈕後再勾選');
    }
  }

  void _showCannotDeleteMessage() {
    if (_executionController.isPastDate()) {
      NotificationUtils.showWarning(context, '無法刪除過去的訓練記錄');
    } else if (_executionController.isViewingOthersCreatedPlan()) {
      NotificationUtils.showWarning(context, '無法刪除教練安排的動作，如需調整請聯繫教練');
    }
  }

  // ========================================
  // 休息計時器
  // ========================================

  void _showRestTimerDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    final options = [
      (60, '1:00'),
      (90, '1:30'),
      (120, '2:00'),
      (150, '2:30'),
      (180, '3:00'),
      (210, '3:30'),
      (240, '4:00'),
      (270, '4:30'),
      (300, '5:00'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '選擇休息時間',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...options.map((option) => ActionChip(
                          label: Text(option.$2),
                          onPressed: () {
                            Navigator.pop(context);
                            _startRestTimer(option.$1);
                          },
                        )),
                    ActionChip(
                      avatar: const Icon(Icons.edit, size: 18),
                      label: const Text('自訂'),
                      onPressed: () {
                        Navigator.pop(context);
                        _showCustomRestTimeDialog();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomRestTimeDialog() {
    final controller = TextEditingController(text: '90');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('自訂休息時間'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '秒數',
              suffixText: '秒',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final seconds = int.tryParse(controller.text) ?? 90;
                Navigator.pop(context);
                _startRestTimer(seconds);
              },
              child: const Text('開始'),
            ),
          ],
        );
      },
    );
  }

  void _startRestTimer(int seconds) {
    HapticFeedback.mediumImpact();
    setState(() {
      _restSeconds = seconds;
      _isRestTimerActive = true;
    });
  }

  void _onRestTimerComplete() {
    setState(() {
      _isRestTimerActive = false;
    });
    if (mounted) {
      NotificationUtils.showInfo(context, '休息時間結束，繼續訓練吧！💪');
    }
  }

  void _onRestTimerSkip() {
    setState(() {
      _isRestTimerActive = false;
    });
  }

  // ========================================
  // 訓練操作
  // ========================================

  /// 開始訓練（公開方法，供外部調用）
  Future<void> startTraining() async {
    HapticFeedback.mediumImpact();
    await _executionController.startTraining();
    setState(() {});
    if (mounted) {
      NotificationUtils.showSuccess(context, '訓練開始！加油！💪');
    }
  }

  /// 恢復訓練（公開方法）
  Future<void> resumeTraining() async {
    await _executionController.resumeTraining();
    setState(() {});
    if (mounted) {
      NotificationUtils.showInfo(context, '訓練已恢復，計時繼續');
    }
  }

  /// 完成訓練（公開方法）
  Future<bool> completeTraining() async {
    return await _executionController.completeTraining(context: context);
  }

  /// 暫停訓練（公開方法）
  Future<void> pauseTraining() async {
    await _executionController.pauseTraining();
    setState(() {});
  }

  /// 保存訓練記錄（公開方法）
  Future<void> saveWorkoutRecord() async {
    await _executionController.saveWorkoutRecord(context: context);
  }

  /// 新增動作（公開方法）
  void addNewExercise() async {
    if (widget.onAddExerciseOverride != null) {
      widget.onAddExerciseOverride!();
      return;
    }

    if (!_canEdit) {
      _showCannotEditMessage();
      return;
    }

    final result = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExercisesPage(),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      _showExerciseSettingsDialog(result);
    }
  }

  void _showExerciseSettingsDialog(Exercise exercise) async {
    _newExerciseSetsController.text = '3';
    _newExerciseRepsController.text = '10';
    _newExerciseWeightController.text = '0';
    _newExerciseRestController.text = '60';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExerciseSettingsDialog(
        exerciseName: exercise.name,
        setsController: _newExerciseSetsController,
        repsController: _newExerciseRepsController,
        weightController: _newExerciseWeightController,
        restController: _newExerciseRestController,
      ),
    );

    if (result == true && mounted) {
      final sets = int.tryParse(_newExerciseSetsController.text) ?? 3;
      final reps = int.tryParse(_newExerciseRepsController.text) ?? 10;
      final weight = double.tryParse(_newExerciseWeightController.text) ?? 0.0;
      final restTime = int.tryParse(_newExerciseRestController.text) ?? 60;

      _markLocalSave(); // ⭐ 防止 Realtime 閃爍
      await _executionController.addNewExercise(
        exercise,
        sets,
        reps,
        weight,
        restTime,
        context: context,
      );

      setState(() {});
      widget.onDataChanged?.call();
    }
  }

  void _deleteExercise(int exerciseIndex) async {
    if (!_canDelete) {
      _showCannotDeleteMessage();
      return;
    }

    final exerciseRecords = _executionController.getExerciseRecords();
    if (exerciseIndex >= exerciseRecords.length) return;

    final exercise = exerciseRecords[exerciseIndex];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除「${exercise.exerciseName}」嗎？此操作不能撤銷。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _markLocalSave(); // ⭐ 防止 Realtime 閃爍
              await _executionController.deleteExercise(exerciseIndex,
                  context: context);
              setState(() {});
              widget.onDataChanged?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  // ========================================
  // UI 構建
  // ========================================

  ExerciseCardData _convertToCardData(int index) {
    final exerciseRecords = _executionController.getExerciseRecords();
    final exercise = exerciseRecords[index];

    final sets = exercise.sets.map((set) {
      return SetData(
        setNumber: set.setNumber,
        weight: set.weight,
        reps: set.reps,
        isCompleted: set.completed,
        previousData: null,
      );
    }).toList();

    return ExerciseCardData(
      exerciseId: exercise.exerciseId,
      exerciseName: exercise.exerciseName,
      sets: sets,
      targetSets: exercise.sets.length,
      targetReps: null,
      targetWeight: null,
    );
  }

  Widget _buildExerciseCard(int index) {
    final exerciseRecords = _executionController.getExerciseRecords();
    if (index >= exerciseRecords.length) return const SizedBox.shrink();

    final exercise = exerciseRecords[index];
    final isCurrentExercise =
        index == _executionController.getCurrentExerciseIndex();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCurrentExercise)
            Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingXs,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius:
                    BorderRadius.circular(AppTheme.buttonBorderRadius),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '進行中',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ExerciseCard(
            data: _convertToCardData(index),
            isEditable: _canEdit,
            activeSetNumber: null,
            onSetUpdate: (setNumber, weight, reps) {
              if (!_canEdit) {
                _showCannotEditMessage();
                return;
              }
              final setIndex = exercise.sets.indexWhere(
                (s) => s.setNumber == setNumber,
              );
              if (setIndex != -1) {
                _markLocalSave(); // ⭐ 防止 Realtime 閃爍
                _executionController.updateSetData(
                  index,
                  setIndex,
                  reps ?? 0,
                  weight ?? 0.0,
                  context: context,
                );
                widget.onDataChanged?.call();
              }
            },
            onSetComplete: (setNumber) {
              HapticFeedback.lightImpact();

              if (!_canMarkSet) {
                _showCannotToggleCompletionMessage();
                return;
              }

              final setIndex = exercise.sets.indexWhere(
                (s) => s.setNumber == setNumber,
              );
              if (setIndex != -1) {
                final wasCompleted = exercise.sets[setIndex].completed;

                _markLocalSave(); // ⭐ 防止 Realtime 閃爍
                _executionController.toggleSetCompletion(
                  index,
                  setIndex,
                  context: context,
                );
                setState(() {});
                widget.onDataChanged?.call();

                if (!wasCompleted &&
                    !_executionController.allExercisesCompleted() &&
                    _showTimerUI) {
                  _showRestTimerDialog();
                }
              }
            },
            onAddSet: () {
              if (!_canEdit) {
                _showCannotEditMessage();
                return;
              }
              HapticFeedback.lightImpact();
              _markLocalSave(); // ⭐ 防止 Realtime 閃爍
              _executionController.addSetToExercise(index, context: context);
              setState(() {});
              widget.onDataChanged?.call();
            },
            onRemoveSet: _canDelete
                ? () {
                    HapticFeedback.lightImpact();
                    _markLocalSave(); // ⭐ 防止 Realtime 閃爍
                    _executionController.removeSetFromExercise(index,
                        context: context);
                    setState(() {});
                    widget.onDataChanged?.call();
                  }
                : null,
            onDelete: _canDelete ? () => _deleteExercise(index) : null,
            canDelete: _canDelete,
            note: exercise.notes.isNotEmpty ? exercise.notes : null,
            onNoteChanged: _canEdit
                ? (newNote) {
                    _executionController.addExerciseNote(index, newNote,
                        context: context);
                    setState(() {});
                    widget.onDataChanged?.call();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingModeCard() {
    final exerciseRecords = _executionController.getExerciseRecords();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '準備訓練',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${exerciseRecords.length} 個動作，共 ${_executionController.calculateTotalSets()} 組',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '你可以在下方預覽和調整訓練內容',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartTrainingButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: startTraining,
          icon: const Icon(Icons.play_arrow, size: 28),
          label: const Text(
            '開始訓練',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineAddButton() {
    if (!_canEdit) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: OutlinedButton.icon(
        onPressed: addNewExercise,
        icon: const Icon(Icons.add),
        label: const Text('新增動作'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _executionController.isLoading;
    final isSaving = _executionController.isSaving;

    if (!_isInitialized || isLoading || isSaving) {
      return const Center(child: CircularProgressIndicator());
    }

    final exerciseRecords = _executionController.getExerciseRecords();
    final isPending = _executionController.isPending;
    final isPaused = _executionController.isPaused;
    final isCompleted = _executionController.isCompleted;
    final showTimerUI = _showTimerUI;

    return Column(
      children: [
        // 休息計時器
        if (showTimerUI && _isRestTimerActive)
          RestTimerWidget(
            restSeconds: _restSeconds,
            isActive: _isRestTimerActive,
            onComplete: _onRestTimerComplete,
            onSkip: _onRestTimerSkip,
          ),

        // 主要內容區
        Expanded(
          child: CustomScrollView(
            slivers: [
              // 頂部額外 Widget（如 ReadinessCard）
              if (widget.headerWidgets != null)
                ...widget.headerWidgets!.map(
                  (w) => SliverToBoxAdapter(child: w),
                ),

              // 訓練資訊卡片
              SliverToBoxAdapter(
                child: (showTimerUI && isPending && !isCompleted)
                    ? _buildPendingModeCard()
                    : WorkoutInfoCard(
                        planType: _executionController.getPlanType(),
                        // ⭐ v3.1: 學員也可以看到運動時長（只是不能操作計時器）
                        elapsedTime: _formatElapsedTime(),
                        exerciseCount: exerciseRecords.length,
                        totalSets: _executionController.calculateTotalSets(),
                        totalVolume:
                            _executionController.calculateTotalVolume(),
                        notesController: _workoutNotesController,
                        onNotesChanged: (value) {
                          _executionController.setNotes(value);
                          widget.onDataChanged?.call();
                        },
                        // ⭐ v3.1: 只有可操作計時器時才顯示暫停狀態和繼續按鈕
                        isPaused: showTimerUI && isPaused,
                        onResume:
                            (showTimerUI && isPaused) ? resumeTraining : null,
                        isCompleted: isCompleted,
                      ),
              ),

              // 訓練動作列表
              if (exerciseRecords.isEmpty)
                SliverFillRemaining(
                  child: EmptyExerciseState(onAddExercise: addNewExercise),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildExerciseCard(index),
                    childCount: exerciseRecords.length,
                  ),
                ),

              // 內嵌新增按鈕
              if (widget.showInlineAddButton && exerciseRecords.isNotEmpty)
                SliverToBoxAdapter(child: _buildInlineAddButton()),

              // 底部額外 Widget（如課程筆記）
              if (widget.footerWidgets != null)
                ...widget.footerWidgets!.map(
                  (w) => SliverToBoxAdapter(child: w),
                ),

              // 底部留白
              const SliverToBoxAdapter(
                child: SizedBox(height: 96),
              ),
            ],
          ),
        ),

        // 開始訓練按鈕
        if (showTimerUI &&
            isPending &&
            !isCompleted &&
            exerciseRecords.isNotEmpty)
          _buildStartTrainingButton(),
      ],
    );
  }
}
