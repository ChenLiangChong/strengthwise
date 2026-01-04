import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strengthwise/models/exercise_model.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_execution_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/themes/app_theme.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/workout/execution/widgets/exercise_card.dart';
import 'package:strengthwise/views/pages/exercises/exercises_page.dart';
import 'widgets/workout_info_card.dart';
import 'widgets/empty_exercise_state.dart';
import 'widgets/exercise_settings_dialog.dart';
import 'widgets/rest_timer_widget.dart';

class WorkoutExecutionPage extends StatefulWidget {
  final String workoutRecordId;

  const WorkoutExecutionPage({
    super.key,
    required this.workoutRecordId,
  });

  @override
  _WorkoutExecutionPageState createState() => _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends State<WorkoutExecutionPage>
    with WidgetsBindingObserver {
  late final IWorkoutExecutionController _executionController;

  // 新增運動的控制器
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

  // ⭐ v2.9.1: 休息計時器狀態
  bool _isRestTimerActive = false;
  int _restSeconds = 90; // 預設 1:30

  @override
  void initState() {
    super.initState();

    // 監聽 App 生命週期（離開時暫停）
    WidgetsBinding.instance.addObserver(this);

    // 從服務定位器獲取依賴
    _executionController = serviceLocator<IWorkoutExecutionController>();

    _loadWorkoutPlan();
    // ⭐ v2.9.1: 計時器由 Controller 狀態驅動
    _startTimer();
  }

  // ⭐ v2.9.1: 監聯 App 生命週期
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // ⚠️ 只有 paused（切換 App）時才暫停，inactive（螢幕暗掉）不暫停
    // 這樣用戶運動時螢幕變暗，計時仍會繼續
    if (state == AppLifecycleState.paused) {
      if (_executionController.isInProgress) {
        _executionController.pauseTraining();
        setState(() {}); // 更新 UI
      }
    } else if (state == AppLifecycleState.resumed) {
      // 回到 App 時更新 UI（如果之前是暫停狀態）
      setState(() {});
    }
  }

  // ⭐ v2.9.1: 定期更新計時器顯示（由 Controller 提供時間）
  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // 只有進行中時才更新 UI
        if (_executionController.isInProgress) {
          _executionController.tickElapsedTime();
          setState(() {}); // 觸發重新構建
        }
        _startTimer(); // 遞迴調用以繼續計時
      }
    });
  }

  /// ⭐ v2.9.1: 格式化經過時間
  String _formatElapsedTime() {
    final totalSeconds = _executionController.elapsedSeconds;
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // 加載訓練計畫
  Future<void> _loadWorkoutPlan() async {
    await _executionController.loadWorkoutPlan(widget.workoutRecordId);

    // 載入備註到控制器
    _workoutNotesController.text = _executionController.getNotes();

    setState(() {}); // 觸發重新構建
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _newExerciseSetsController.dispose();
    _newExerciseRepsController.dispose();
    _newExerciseWeightController.dispose();
    _newExerciseRestController.dispose();
    _workoutNotesController.dispose();
    super.dispose();
  }

  // 顯示無法修改的提示消息
  void _showCannotEditMessage() {
    if (_executionController.isPastDate()) {
      NotificationUtils.showWarning(context, '無法編輯過去的訓練記錄');
    }
  }

  // 顯示無法勾選完成的提示消息
  void _showCannotToggleCompletionMessage() {
    // ⭐ v2.9.1: 根據不同情況顯示不同提示
    if (_executionController.isCoachViewingTrainee()) {
      NotificationUtils.showWarning(context, '教練無法幫學員勾選完成，請由學員自行完成訓練');
    } else if (_executionController.isPastDate()) {
      NotificationUtils.showWarning(context, '無法修改過去的訓練記錄');
    } else if (_executionController.isFutureDate()) {
      NotificationUtils.showWarning(context, '未來的訓練無法勾選完成，請在訓練當天標記');
    } else if (_executionController.isPaused) {
      NotificationUtils.showWarning(context, '請先點擊「繼續訓練」再進行打勾');
    } else if (_executionController.isPending) {
      NotificationUtils.showWarning(context, '請先點擊「開始訓練」再進行打勾');
    }
  }

  // ⭐ v2.9: 顯示無法刪除的提示消息
  void _showCannotDeleteMessage() {
    if (_executionController.isPastDate()) {
      NotificationUtils.showWarning(context, '無法刪除過去的訓練記錄');
    } else if (_executionController.isViewingOthersCreatedPlan()) {
      NotificationUtils.showWarning(context, '無法刪除教練安排的動作，如需調整請聯繫教練');
    }
  }

  // ⭐ v2.9.1: 完成訓練（使用新的狀態機）
  Future<void> _completeTraining() async {
    final success =
        await _executionController.completeTraining(context: context);
    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  // ⭐ v2.9.1: 顯示休息時間選擇對話框
  void _showRestTimerDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    // 預設選項（秒）
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
                // 標題
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

                // 時間選項網格
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...options.map((option) => _buildRestTimeChip(
                          seconds: option.$1,
                          label: option.$2,
                        )),
                    // 自訂選項
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

  // 構建時間選項 Chip
  Widget _buildRestTimeChip({required int seconds, required String label}) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        Navigator.pop(context);
        _startRestTimer(seconds);
      },
    );
  }

  // 自訂休息時間對話框
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

  // 開始休息計時器
  void _startRestTimer(int seconds) {
    HapticFeedback.mediumImpact();
    setState(() {
      _restSeconds = seconds;
      _isRestTimerActive = true;
    });
  }

  // 休息計時器完成
  void _onRestTimerComplete() {
    setState(() {
      _isRestTimerActive = false;
    });
    if (mounted) {
      NotificationUtils.showInfo(context, '休息時間結束，繼續訓練！💪');
    }
  }

  // 跳過休息
  void _onRestTimerSkip() {
    setState(() {
      _isRestTimerActive = false;
    });
  }

  // 新增：添加新的訓練動作
  void _addNewExercise() async {
    // 檢查是否可以編輯（過去的訓練不能編輯）
    if (!_executionController.canEdit()) {
      _showCannotEditMessage();
      return;
    }

    // 導航到運動選擇頁面
    final result = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExercisesPage(),
        fullscreenDialog: true, // 使用全屏對話框風格打開頁面
      ),
    );

    // 如果用戶選擇了運動，添加到列表中
    if (result != null) {
      // 顯示設置對話框
      _showExerciseSettingsDialog(result);
    }
  }

  // 顯示運動設置對話框
  void _showExerciseSettingsDialog(Exercise exercise) async {
    // 重置控制器值為默認值
    _newExerciseSetsController.text = '3';
    _newExerciseRepsController.text = '10';
    _newExerciseWeightController.text = '0';
    _newExerciseRestController.text = '60';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => ExerciseSettingsDialog(
        exerciseName: exercise.name,
        setsController: _newExerciseSetsController,
        repsController: _newExerciseRepsController,
        weightController: _newExerciseWeightController,
        restController: _newExerciseRestController,
      ),
    );

    if (result == true && mounted) {
      // 解析設置
      final sets = int.tryParse(_newExerciseSetsController.text) ?? 3;
      final reps = int.tryParse(_newExerciseRepsController.text) ?? 10;
      final weight = double.tryParse(_newExerciseWeightController.text) ?? 0.0;
      final restTime = int.tryParse(_newExerciseRestController.text) ?? 60;

      // 使用控制器添加新動作
      await _executionController.addNewExercise(
        exercise,
        sets,
        reps,
        weight,
        restTime,
        context: context,
      );

      setState(() {}); // 觸發重新構建
    }
  }

  // 添加刪除運動的方法
  void _deleteExercise(int exerciseIndex) async {
    // ⭐ v2.9: 檢查是否可以刪除（只有創建者可以刪除）
    if (!_executionController.canDelete()) {
      _showCannotDeleteMessage();
      return;
    }

    final exerciseRecords = _executionController.getExerciseRecords();
    if (exerciseIndex >= exerciseRecords.length) return;

    final exercise = exerciseRecords[exerciseIndex];

    // 顯示確認對話框
    showDialog(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
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
              // 先關閉對話框
              Navigator.pop(context);

              // 使用控制器刪除運動
              await _executionController.deleteExercise(exerciseIndex,
                  context: context);

              setState(() {}); // 觸發重新構建
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  // 將 ExerciseRecord 轉換為 ExerciseCardData
  ExerciseCardData _convertToCardData(int index) {
    final exerciseRecords = _executionController.getExerciseRecords();
    final exercise = exerciseRecords[index];

    // 轉換組數據
    final sets = exercise.sets.map((set) {
      return SetData(
        setNumber: set.setNumber,
        weight: set.weight,
        reps: set.reps,
        isCompleted: set.completed,
        previousData: null, // TODO: 未來可以加入歷史數據參考
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

  // 構建運動詳情卡片（使用新的卡片式設計）
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
          // ⭐ v2.9.1: 簡化 - 只保留「進行中」狀態標示
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
                    .withOpacity(0.3),
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

          // 動作卡片（備註已整合到卡片內）
          ExerciseCard(
            data: _convertToCardData(index),
            isEditable: _executionController.canEdit(),
            activeSetNumber: null, // 可以根據需要設置活動組
            onSetUpdate: (setNumber, weight, reps) {
              // 找到對應的組
              final setIndex = exercise.sets.indexWhere(
                (s) => s.setNumber == setNumber,
              );
              if (setIndex != -1) {
                // 更新組數據
                _executionController.updateSetData(
                  index,
                  setIndex,
                  reps ?? 0,
                  weight ?? 0.0,
                  context: context,
                );
              }
            },
            onSetComplete: (setNumber) {
              HapticFeedback.lightImpact(); // 觸覺回饋

              // 檢查是否可以勾選完成
              if (!_executionController.canToggleCompletion()) {
                _showCannotToggleCompletionMessage();
                return;
              }

              // 找到對應的組
              final setIndex = exercise.sets.indexWhere(
                (s) => s.setNumber == setNumber,
              );
              if (setIndex != -1) {
                // ⭐ v2.9.1: 檢查是否是「勾選完成」（之前未完成）
                final wasCompleted = exercise.sets[setIndex].completed;

                _executionController.toggleSetCompletion(
                  index,
                  setIndex,
                  context: context,
                );
                setState(() {}); // 觸發重新構建

                // ⭐ v2.9.1: 勾選完成時直接彈出休息時間選擇
                // 只有「勾選完成」且訓練尚未全部完成 且顯示計時 UI 時
                if (!wasCompleted &&
                    !_executionController.allExercisesCompleted() &&
                    _executionController.shouldShowTimerUI()) {
                  _showRestTimerDialog();
                }
              }
            },
            onAddSet: () {
              HapticFeedback.lightImpact(); // 觸覺回饋
              _executionController.addSetToExercise(index, context: context);
              setState(() {}); // 觸發重新構建
            },
            // ⭐ v2.9.1: 新增參數
            onRemoveSet: _executionController.canDelete()
                ? () {
                    HapticFeedback.lightImpact();
                    _executionController.removeSetFromExercise(index,
                        context: context);
                    setState(() {});
                  }
                : null,
            onDelete: _executionController.canDelete()
                ? () {
                    _deleteExercise(index);
                  }
                : null,
            canDelete: _executionController.canDelete(),
            note: exercise.notes.isNotEmpty ? exercise.notes : null,
            onNoteChanged: (newNote) {
              _executionController.addExerciseNote(index, newNote,
                  context: context);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  // ⭐ v2.9.1: 菜單功能已整合到卡片
  // ⭐ v2.9.1 TRN-6: 移除無意義的時鐘功能（_setTrainingHour）
  // ⭐ v2.9.1: 備註功能已整合到 ExerciseCard 內的輸入框

  // ⭐ v2.9.1: 準備模式的頂部卡片
  Widget _buildPendingModeCard() {
    final exerciseRecords = _executionController.getExerciseRecords();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題行
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

          // 訓練資訊
          Text(
            '${exerciseRecords.length} 個動作，共 ${_executionController.calculateTotalSets()} 組',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),

          // 提示文字
          Text(
            '您可以在開始前預覽和調整訓練內容',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  // ⭐ v2.9.1: 開始訓練按鈕
  Widget _buildStartTrainingButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            await _executionController.startTraining();
            setState(() {});
            if (mounted) {
              NotificationUtils.showSuccess(context, '訓練開始！加油！💪');
            }
          },
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

  @override
  Widget build(BuildContext context) {
    final isLoading = _executionController.isLoading;
    final isSaving = _executionController.isSaving;
    final exerciseRecords = _executionController.getExerciseRecords();

    // ⭐ v2.9.1: 根據訓練狀態決定顯示模式
    final isPending = _executionController.isPending;
    final isInProgress = _executionController.isInProgress;
    final isPaused = _executionController.isPaused;
    final isCompleted = _executionController.isCompleted;

    // ⭐ v2.9.1: 是否顯示計時器 UI（只有今天 + 非教練查看學員）
    final showTimerUI = _executionController.shouldShowTimerUI();

    return PopScope(
      canPop: false, // 攔截返回
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // ⭐ v2.9.1: 如果正在進行中且顯示計時 UI，暫停訓練並提示
        if (showTimerUI && isInProgress) {
          await _executionController.pauseTraining();
          if (context.mounted) {
            NotificationUtils.showInfo(
              context,
              '訓練已暫停，計時將保存。可隨時返回繼續訓練。',
            );
          }
        }
        // 如果有未保存的變更且可以編輯，自動保存
        else if (_executionController.isDataChanged &&
            _executionController.canEdit()) {
          await _executionController.saveWorkoutRecord(context: context);
        }

        // 返回上一頁
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_executionController.getPlanTitle()),
          actions: [
            // ⭐ v2.9.1: 根據狀態顯示不同按鈕
            // 非計時模式或非準備模式時顯示
            if (!showTimerUI || !isPending) ...[
              // ⭐ v2.9.1 TRN-6: 移除無意義的時鐘按鈕
              // 保存按鈕（保存並離開）
              IconButton(
                icon: Icon(isCompleted ? Icons.check : Icons.save),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _completeTraining();
                },
                tooltip: isCompleted ? '離開' : '保存並離開',
              ),
            ],
          ],
        ),
        body: isLoading || isSaving
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // ⭐ v2.9.1: 休息計時器（固定在頂部，只有顯示計時 UI 時才顯示）
                  if (showTimerUI && _isRestTimerActive)
                    RestTimerWidget(
                      restSeconds: _restSeconds,
                      isActive: _isRestTimerActive,
                      onComplete: _onRestTimerComplete,
                      onSkip: _onRestTimerSkip,
                    ),

                  // 主要內容區域
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        // 訓練資訊卡片（可滾動）
                        SliverToBoxAdapter(
                          child: (showTimerUI && isPending && !isCompleted)
                              ? _buildPendingModeCard()
                              : WorkoutInfoCard(
                                  planType: _executionController.getPlanType(),
                                  // ⭐ v2.9.1: 只有顯示計時 UI 時才顯示時長
                                  elapsedTime:
                                      showTimerUI ? _formatElapsedTime() : null,
                                  exerciseCount: exerciseRecords.length,
                                  totalSets:
                                      _executionController.calculateTotalSets(),
                                  totalVolume: _executionController
                                      .calculateTotalVolume(),
                                  notesController: _workoutNotesController,
                                  onNotesChanged: (value) {
                                    _executionController.setNotes(value);
                                  },
                                  // ⭐ v2.9.1: 只有顯示計時 UI 時才顯示暫停/繼續
                                  isPaused: showTimerUI && isPaused,
                                  onResume: (showTimerUI && isPaused)
                                      ? () async {
                                          await _executionController
                                              .resumeTraining();
                                          setState(() {});
                                          if (mounted) {
                                            NotificationUtils.showInfo(
                                                context, '訓練已恢復，計時繼續');
                                          }
                                        }
                                      : null,
                                  isCompleted: isCompleted,
                                ),
                        ),

                        // 訓練動作列表
                        if (exerciseRecords.isEmpty)
                          SliverFillRemaining(
                            child: EmptyExerciseState(
                                onAddExercise: _addNewExercise),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.only(bottom: 96),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildExerciseCard(index),
                                childCount: exerciseRecords.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ⭐ v2.9.1: 準備模式下顯示「開始訓練」按鈕（只有今天 + 非教練查看）
                  if (showTimerUI &&
                      isPending &&
                      !isCompleted &&
                      exerciseRecords.isNotEmpty)
                    _buildStartTrainingButton(),
                ],
              ),
        // 添加運動的浮動按鈕
        // ⭐ v2.9.1: 不顯示計時 UI 時（教練/過去/未來），不受 isPending 限制
        floatingActionButton: _executionController.canEdit() &&
                exerciseRecords.isNotEmpty &&
                (!showTimerUI || !isPending) // 不顯示計時 UI 時可直接新增
            ? FloatingActionButton(
                onPressed: _addNewExercise,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}
