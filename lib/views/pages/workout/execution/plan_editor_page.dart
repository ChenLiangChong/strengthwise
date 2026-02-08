// ✅ 已響應式改造 (Phase 0) - 表單頁，複雜操作不約束
// ✅ v3.2: Coach Mark 引導
// ✅ v3.5: AppEventBus 自動刷新
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:strengthwise/models/workout_exercise_model.dart'
    as exercise_models;
import 'package:strengthwise/models/workout_record_model.dart';
import 'package:strengthwise/models/exercise_model.dart';
import 'package:strengthwise/models/tracking_mode.dart'; // v3.2+
// v3.4+
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_controller.dart'; // ⭐ v3.5: MVVM 重構
import 'package:strengthwise/services/core/onboarding_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/exercises/exercises_page.dart';
import 'package:strengthwise/views/pages/workout/execution/template_management_page.dart';
import 'package:strengthwise/models/workout_template_model.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/widgets/onboarding/coach_mark_helper.dart';
import 'widgets/plan_date_header.dart';
import 'widgets/plan_basic_info_form.dart';
import 'widgets/plan_exercise_card.dart';
import 'widgets/set_edit_dialog.dart';
import 'widgets/exercise_settings_dialog.dart'; // v3.2+ 添加動作設定對話框

class PlanEditorPage extends StatefulWidget {
  final DateTime selectedDate;
  final String? planId; // 如果是編輯現有記錄則提供 planId
  final String? planType; // 計劃類型: "self" 或 "trainer"
  final String? traineeId; // Phase 4C: 教練為學員創建訓練時的學員 ID
  final DateTime? initialStartTime; // 預填開始時間（從學員偏好時段）
  final DateTime? initialEndTime; // 預填結束時間（從學員偏好時段）
  final String? appointmentId; // ⭐ v3.1: Session Mode 關聯的預約 ID
  final WorkoutTemplate? initialTemplate; // ⭐ v3.1: 預填模板資料

  const PlanEditorPage({
    super.key,
    required this.selectedDate,
    this.planId,
    this.planType,
    this.traineeId,
    this.initialStartTime,
    this.initialEndTime,
    this.appointmentId,
    this.initialTemplate,
  });

  @override
  State<PlanEditorPage> createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  // ⭐ v3.6: MVVM 重構 - 移除 Service 直接調用
  late final IAuthController _authController;
  late final IWorkoutController _workoutController;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // v3.2+ 新增動作設定對話框控制器
  final TextEditingController _newExerciseSetsController =
      TextEditingController();
  final TextEditingController _newExerciseRepsController =
      TextEditingController();
  final TextEditingController _newExerciseWeightController =
      TextEditingController();
  final TextEditingController _newExerciseRestController =
      TextEditingController();
  final TextEditingController _newExerciseTimeController =
      TextEditingController();
  final TextEditingController _newExerciseDistanceController =
      TextEditingController();
  final TextEditingController _newExerciseCaloriesController =
      TextEditingController();

  List<exercise_models.WorkoutExercise> _exercises = [];
  bool _isLoading = false;
  String? _selectedPlanType;

  // ⭐ v3.2: Coach Mark 引導
  final GlobalKey _addExerciseButtonKey = GlobalKey();
  bool _coachMarkShown = false;

  // ⭐ v2.1: 訓練時間（開始時為 null，在 initState 中設定）
  late DateTime _trainingTime;

  // ⭐ v2.1: 訓練結束時間
  late DateTime _trainingEndTime;

  // ⭐ v3.4: 使用統一的訓練計畫類型列表
  List<String> get _planTypes => PlanTypeExtension.uiOptions;

  @override
  void initState() {
    super.initState();

    // ⭐ v3.6: MVVM 重構 - 透過 Controller
    _authController = serviceLocator<IAuthController>();
    _workoutController = serviceLocator<IWorkoutController>();

    // ⭐ v2.1: 設定訓練時間
    // 1. 如果調用方提供 initialStartTime（偏好時段）→ 使用該時間
    // 2. 否則使用當前時間設為預設，讓用戶自知需要修改
    final initialStartTime = widget.initialStartTime;
    if (initialStartTime != null) {
      _trainingTime = initialStartTime;
    } else {
      final now = DateTime.now();
      _trainingTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        now.hour,
        now.minute,
      );
    }

    // ⭐ v3.2: 檢查 Coach Mark 引導
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCoachMark();
    });

    // ⭐ v2.1: 設定訓練結束時間
    final initialEndTime = widget.initialEndTime;
    if (initialEndTime != null) {
      _trainingEndTime = initialEndTime;
    } else {
      _trainingEndTime = _trainingTime.add(const Duration(hours: 1));
    }

    // 如果傳入了計劃類型則設置默認值
    if (widget.planType != null) {
      // 注意: 這裡的 planType 是用於資料庫存儲的值 ("self" 或 "trainer")
      // 而 _selectedPlanType 是用於顯示的訓練類型 (力量訓練, 有氧訓練等)
      // 我們在保存時保留兩種值
    }

    // 檢查是否為過去日期
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(widget.selectedDate.year,
        widget.selectedDate.month, widget.selectedDate.day);

    if (selectedDate.isBefore(today)) {
      // 使用 Future.microtask 確保在 initState 之後顯示錯誤提示並返回
      Future.microtask(() {
        if (!mounted) return;
        NotificationUtils.showError(context, '無法在過去的日期創建訓練計畫');
        Navigator.of(context).pop();
      });
      return;
    }

    if (widget.planId != null) {
      _loadExistingPlan();
    } else if (widget.initialTemplate != null) {
      // ⭐ v3.1: 從模板預填資料
      _initializeFromTemplate(widget.initialTemplate!);
    }
  }

  /// 從模板初始化表單 ⭐ v3.1
  void _initializeFromTemplate(WorkoutTemplate template) {
    _titleController.text = template.title;
    _descriptionController.text = template.description;

    // 驗證模板的 planType 是否在列表中
    if (_planTypes.contains(template.planType)) {
      _selectedPlanType = template.planType;
    } else {
      _selectedPlanType = '全身訓練';
    }

    _exercises = List.from(template.exercises);
  }

  // 載入現有訓練計畫
  Future<void> _loadExistingPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('[PlanEditor] 載入現有計畫: ${widget.planId}');

      // ⭐ v3.6: MVVM 重構 - 透過 Controller 查詢
      final record = await _workoutController.getRecordById(widget.planId!);

      if (record != null) {
        _titleController.text = record.title;
        _descriptionController.text = record.notes;
        _selectedPlanType = '全身訓練'; // 預設值，適合大多數人

        // 設定訓練時間
        if (record.trainingTime != null) {
          _trainingTime = record.trainingTime!;
        }

        // 載入訓練動作（從 ExerciseRecord 轉換為 WorkoutExercise）
        _exercises = record.exerciseRecords.map((exerciseRecord) {
          return exercise_models.WorkoutExercise(
            id: exerciseRecord.exerciseId,
            exerciseId: exerciseRecord.exerciseId,
            name: exerciseRecord.exerciseName,
            sets: exerciseRecord.sets.length,
            reps: exerciseRecord.sets.isNotEmpty
                ? exerciseRecord.sets.first.reps
                : 10,
            weight: exerciseRecord.sets.isNotEmpty
                ? exerciseRecord.sets.first.weight
                : 0.0,
            restTime: exerciseRecord.sets.isNotEmpty
                ? exerciseRecord.sets.first.restTime
                : 60,
            equipment: '', // 預設空值
            bodyParts: [], // 預設空陣列
          );
        }).toList();

        debugPrint('[PlanEditor] 載入完成，動作數量: ${_exercises.length}');
      }
    } catch (e) {
      debugPrint('[PlanEditor] 載入失敗: $e');
      if (mounted) {
        NotificationUtils.showError(context, '載入訓練計畫失敗: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 保存訓練計畫
  Future<void> _savePlan() async {
    if (_titleController.text.isEmpty || _selectedPlanType == null) {
      NotificationUtils.showWarning(context, '請填寫計畫名稱和類型');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        throw Exception('未登入');
      }

      debugPrint('[PlanEditor] 準備保存訓練計畫，動作數量: ${_exercises.length}');

      // 從 WorkoutExercise 轉換為 ExerciseRecord
      // v3.2+ 支援多元追蹤模式 + 修復：正確使用 setTargets
      final exerciseRecords = _exercises.map((exercise) {
        return ExerciseRecord(
          exerciseId: exercise.exerciseId, // 修復：使用 exerciseId 而非 id
          exerciseName: exercise.name,
          trackingMode: exercise.trackingMode, // v3.2+
          sets: List.generate(
            exercise.sets,
            (index) {
              // ✅ 優先使用 setTargets 中的個別設定
              final setTargets = exercise.setTargets;
              if (setTargets != null && index < setTargets.length) {
                final target = setTargets[index];
                return SetRecord(
                  setNumber: index + 1,
                  reps: (target['reps'] as num?)?.toInt() ?? exercise.reps,
                  weight:
                      (target['weight'] as num?)?.toDouble() ?? exercise.weight,
                  restTime: (target['restTime'] as num?)?.toInt() ??
                      exercise.restTime,
                  completed: false,
                  // v3.2+ 新增欄位
                  time: (target['time'] as num?)?.toInt() ?? exercise.time,
                  distance: (target['distance'] as num?)?.toDouble() ??
                      exercise.distance,
                  calories: (target['calories'] as num?)?.toDouble() ??
                      exercise.calories,
                );
              }
              // 沒有 setTargets 時使用預設值
              return SetRecord(
                setNumber: index + 1,
                reps: exercise.reps,
                weight: exercise.weight,
                restTime: exercise.restTime,
                completed: false,
                time: exercise.time,
                distance: exercise.distance,
                calories: exercise.calories,
              );
            },
          ),
          notes: '',
          completed: false,
        );
      }).toList();

      if (widget.planId != null) {
        // 更新現有記錄
        debugPrint('[PlanEditor] 更新現有計畫: ${widget.planId}');

        // ⭐ v3.6: MVVM 重構 - 透過 Controller 查詢
        final existingRecord =
            await _workoutController.getRecordById(widget.planId!);
        if (existingRecord != null) {
          final updatedRecord = WorkoutRecord(
            id: widget.planId!,
            workoutPlanId: existingRecord.workoutPlanId,
            userId: userId,
            traineeId: existingRecord.traineeId, // 保留原有的 traineeId
            creatorId: existingRecord.creatorId, // 保留原有的 creatorId
            title: _titleController.text.isNotEmpty
                ? _titleController.text
                : '訓練記錄',
            date: _trainingTime, // ⭐ v2.1: date = 訓練開始時間
            exerciseRecords: exerciseRecords,
            notes: _descriptionController.text,
            completed: existingRecord.completed,
            createdAt: existingRecord.createdAt,
            trainingEndTime: _trainingEndTime, // ⭐ v2.1: 訓練結束時間
          );

          // ⭐ v3.5: 透過 Controller 更新訓練記錄（Controller 會自動發布事件）
          final success = await _workoutController.updateRecord(updatedRecord);
          if (!success) {
            throw Exception(_workoutController.errorMessage ?? '更新失敗');
          }
          debugPrint('[PlanEditor] 更新完成');
        }
      } else {
        // 創建新記錄
        debugPrint('[PlanEditor] 創建新記錄');
        debugPrint(
            '[PlanEditor] appointmentId: ${widget.appointmentId}'); // ⭐ v3.1 調試

        // ⭐ Phase 4C: 正確設置 traineeId 和 creatorId
        final traineeId = widget.traineeId ?? userId; // 如果指定學員則用學員 ID；否則用當前用戶
        final creatorId = userId; // 創建者永遠是當前用戶

        final newRecord = WorkoutRecord(
          id: '', // 將在 createRecord 中生成
          workoutPlanId: '',
          userId: userId,
          traineeId: traineeId, // 受訓者 ID
          creatorId: creatorId, // 創建者 ID
          title:
              _titleController.text.isNotEmpty ? _titleController.text : '訓練記錄',
          date: _trainingTime, // ⭐ v2.1: date = 訓練開始時間
          exerciseRecords: exerciseRecords,
          notes: _descriptionController.text,
          completed: false,
          createdAt: DateTime.now(),
          trainingEndTime: _trainingEndTime, // ⭐ v2.1: 訓練結束時間
          appointmentId: widget.appointmentId, // ⭐ v3.1: Session Mode 關聯預約 ID
          planType: _selectedPlanType, // ⭐ v3.4: 訓練計畫類型
        );

        // ⭐ v3.5: 透過 Controller 創建訓練記錄（Controller 會自動發布事件）
        final createdRecord = await _workoutController.createRecord(newRecord);
        debugPrint('[PlanEditor] 創建完成: ${createdRecord.id}');
      }

      // 顯示成功通知
      if (mounted) {
        final isUpdate = widget.planId != null;
        NotificationUtils.showSuccess(
          context,
          isUpdate ? '訓練計畫更新成功' : '訓練計畫創建成功',
        );
      }

      // 返回行事曆頁面
      if (mounted) {
        Navigator.pop(context, true); // 返回 true 表示保存成功
      }
    } catch (e) {
      debugPrint('[PlanEditor] 保存失敗: $e');

      // ⭐ v2.1: 識別時間衝突錯誤
      if (e.toString().contains('訓練時間衝突')) {
        if (mounted) {
          NotificationUtils.showError(context, '訓練時間衝突：該學員在此時段已有訓練計畫，請選擇其他時間');
          // 返回錯誤訊息給調用方
          Navigator.pop(context, e.toString());
        }
      } else {
        if (mounted) {
          NotificationUtils.showError(context, '保存訓練計畫失敗: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 保存為模板
  // ⭐ v3.5: MVVM 重構 - 透過 Controller 操作，事件由 Controller 自動發布
  Future<void> _saveAsTemplate() async {
    try {
      if (_titleController.text.isEmpty || _selectedPlanType == null) {
        NotificationUtils.showWarning(context, '請填寫計畫名稱和類型');
        return;
      }

      if (_exercises.isEmpty) {
        NotificationUtils.showWarning(context, '請至少添加一個訓練動作');
        return;
      }

      // 顯示模板名稱輸入框
      TextEditingController templateNameController =
          TextEditingController(text: _titleController.text);
      final templateName = await showDialog<String>(
        context: context,
        barrierDismissible: false, // 修復：防止點擊外部關閉
        builder: (context) => AlertDialog(
          title: const Text('保存為模板'),
          content: TextField(
            controller: templateNameController,
            decoration: const InputDecoration(
              labelText: '模板名稱',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, templateNameController.text);
              },
              style: ElevatedButton.styleFrom(),
              child: const Text('保存'),
            ),
          ],
        ),
      );

      if (templateName == null || templateName.isEmpty) return;

      setState(() {
        _isLoading = true;
      });

      final userId = _authController.user?.uid;
      if (userId == null) {
        throw Exception('用戶未登入');
      }

      debugPrint('[PlanEditor] 準備保存為模板: $templateName');

      // 創建模板對象
      final template = WorkoutTemplate(
        id: '', // 將在 createTemplate 中生成
        userId: userId,
        title: templateName,
        description: _descriptionController.text,
        planType: _selectedPlanType ?? '自訂訓練',
        exercises: _exercises,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // ⭐ v3.5: 透過 Controller 創建模板（Controller 會自動發布事件）
      final savedTemplate = await _workoutController.createTemplate(template);
      debugPrint('[PlanEditor] 模板已儲存: $templateName, ID: ${savedTemplate.id}');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        NotificationUtils.showSuccess(context, '模板保存成功');
      }
    } catch (e, stackTrace) {
      debugPrint('[PlanEditor] 保存模板錯誤: $e');
      debugPrint('[PlanEditor] 錯誤堆棧: $stackTrace');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        NotificationUtils.showError(context, '保存模板失敗: $e');
      }
    }
  }

  // 從模板加載
  Future<void> _loadFromTemplate() async {
    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        NotificationUtils.showWarning(context, '請先登入');
        return;
      }

      final template = await Navigator.push<WorkoutTemplate>(
        context,
        MaterialPageRoute(
          builder: (context) => const TemplateManagementPage(),
        ),
      );

      if (template != null && mounted) {
        setState(() {
          _titleController.text = template.title;
          _descriptionController.text = template.description;

          // ⚠️ 驗證模板的 planType 是否在列表中，避免 DropdownButton 錯誤
          if (_planTypes.contains(template.planType)) {
            _selectedPlanType = template.planType;
          } else {
            // 如果不在列表中則設置為預設值
            _selectedPlanType = '全身訓練';
            debugPrint(
                '[PlanEditor] ⚠️ 模板的 planType "${template.planType}" 不在列表中，已設為預設值');
          }

          _exercises = List.from(template.exercises);
        });

        if (mounted) {
          NotificationUtils.showSuccess(context, '已載入模板: ${template.title}');
        }
      }
    } catch (e) {
      debugPrint('從模板加載錯誤: $e');
      if (mounted) {
        NotificationUtils.showError(context, '載入模板失敗: $e');
      }
    }
  }

  // 添加訓練動作
  // v3.2+ 根據 trackingMode 顯示不同的設定對話框
  void _addExercise() async {
    final result = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExercisesPage(),
      ),
    );

    if (result != null) {
      _showExerciseSettingsDialog(result);
    }
  }

  /// v3.2+ 顯示動作設定對話框
  void _showExerciseSettingsDialog(Exercise exercise) async {
    final trackingMode = exercise.trackingMode;

    // 重置控制器預設值
    _newExerciseSetsController.text = '4';
    _newExerciseRepsController.text = '10';
    _newExerciseWeightController.text = '0';
    _newExerciseRestController.text = '90';
    // v3.2+ 新欄位預設值
    _newExerciseTimeController.text = '30';
    _newExerciseDistanceController.text = '0';
    _newExerciseCaloriesController.text = '0';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExerciseSettingsDialog(
        exerciseName: exercise.displayName,
        setsController: _newExerciseSetsController,
        repsController: _newExerciseRepsController,
        weightController: _newExerciseWeightController,
        restController: _newExerciseRestController,
        // v3.2+ 傳遞新參數
        timeController: _newExerciseTimeController,
        distanceController: _newExerciseDistanceController,
        caloriesController: _newExerciseCaloriesController,
        trackingMode: trackingMode,
      ),
    );

    if (result == true && mounted) {
      final sets = int.tryParse(_newExerciseSetsController.text) ?? 4;
      final reps = int.tryParse(_newExerciseRepsController.text) ?? 10;
      final weight = double.tryParse(_newExerciseWeightController.text) ?? 0.0;
      final restTime = int.tryParse(_newExerciseRestController.text) ?? 90;
      // v3.2+ 解析新欄位
      final time = int.tryParse(_newExerciseTimeController.text);
      final distance = double.tryParse(_newExerciseDistanceController.text);
      final calories = double.tryParse(_newExerciseCaloriesController.text);

      setState(() {
        _exercises.add(exercise_models.WorkoutExercise(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          exerciseId: exercise.id,
          name: exercise.displayName,
          actionName: exercise.actionName,
          equipment: exercise.equipment,
          bodyParts: exercise.bodyParts,
          sets: sets,
          reps: reps,
          weight: weight,
          restTime: restTime,
          trackingMode: trackingMode,
          time: time,
          distance: distance,
          calories: calories,
        ));
      });
    }
  }

  // 編輯單組設定
  // v3.2+ 支援多元追蹤模式
  Future<void> _editSet(int exerciseIndex, int setIndex) async {
    final exercise = _exercises[exerciseIndex];
    final trackingMode = exercise.trackingMode;

    // 獲取當前組的目標值
    int currentReps;
    double currentWeight;
    int? currentTime;
    double? currentDistance;
    double? currentCalories;

    final setTargets = exercise.setTargets;
    if (setTargets != null && setIndex < setTargets.length) {
      final target = setTargets[setIndex];
      currentReps = target['reps'] as int? ?? exercise.reps;
      currentWeight = (target['weight'] as num?)?.toDouble() ?? exercise.weight;
      currentTime = target['time'] as int? ?? exercise.time;
      currentDistance =
          (target['distance'] as num?)?.toDouble() ?? exercise.distance;
      currentCalories =
          (target['calories'] as num?)?.toDouble() ?? exercise.calories;
    } else {
      currentReps = exercise.reps;
      currentWeight = exercise.weight;
      currentTime = exercise.time;
      currentDistance = exercise.distance;
      currentCalories = exercise.calories;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false, // 修復：防止點擊外部關閉
      builder: (context) => SetEditDialog(
        setNumber: setIndex + 1,
        initialReps: currentReps,
        initialWeight: currentWeight,
        initialTime: currentTime,
        initialDistance: currentDistance,
        initialCalories: currentCalories,
        trackingMode: trackingMode, // v3.2+
      ),
    );

    if (result != null) {
      setState(() {
        // 確保 setTargets 存在
        if (exercise.setTargets == null || exercise.setTargets!.isEmpty) {
          final newSetTargets = List.generate(
            exercise.sets,
            (i) => _buildSetTarget(exercise),
          );
          _exercises[exerciseIndex] =
              exercise.copyWith(setTargets: newSetTargets);
        }

        // 更新單組目標值
        final updatedSetTargets = List<Map<String, dynamic>>.from(
            _exercises[exerciseIndex].setTargets!);
        updatedSetTargets[setIndex] = result;

        _exercises[exerciseIndex] = _exercises[exerciseIndex].copyWith(
          setTargets: updatedSetTargets,
          reps: result['reps'] as int? ?? exercise.reps,
          weight: (result['weight'] as num?)?.toDouble() ?? exercise.weight,
          time: result['time'] as int?,
          distance: (result['distance'] as num?)?.toDouble(),
          calories: (result['calories'] as num?)?.toDouble(),
        );
      });
    }
  }

  /// v3.2+ 根據 exercise 建立 setTarget
  Map<String, dynamic> _buildSetTarget(
      exercise_models.WorkoutExercise exercise) {
    final target = <String, dynamic>{};
    final mode = exercise.trackingMode;

    if (mode.needsReps) target['reps'] = exercise.reps;
    if (mode.needsWeight) target['weight'] = exercise.weight;
    if (mode.needsTime) target['time'] = exercise.time ?? 0;
    if (mode.needsDistance) target['distance'] = exercise.distance ?? 0.0;
    if (mode.needsCalories) target['calories'] = exercise.calories ?? 0.0;

    return target;
  }

  // 調整組數
  void _adjustSets(int exerciseIndex, int delta) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final newSets = (exercise.sets + delta).clamp(1, 10);

      if (newSets == exercise.sets) return;

      List<Map<String, dynamic>> newSetTargets;

      if (exercise.setTargets != null && exercise.setTargets!.isNotEmpty) {
        newSetTargets = List<Map<String, dynamic>>.from(exercise.setTargets!);

        if (newSets > exercise.sets) {
          // 增加組數，複製最後一組
          final lastSet = newSetTargets.last;
          for (int i = exercise.sets; i < newSets; i++) {
            newSetTargets.add(Map<String, dynamic>.from(lastSet));
          }
        } else {
          // 減少組數
          newSetTargets = newSetTargets.sublist(0, newSets);
        }
      } else {
        // 如果沒有 setTargets，創建新的
        newSetTargets = List.generate(
          newSets,
          (i) => {'reps': exercise.reps, 'weight': exercise.weight},
        );
      }

      _exercises[exerciseIndex] = exercise.copyWith(
        sets: newSets,
        setTargets: newSetTargets,
      );
    });
  }

  /// 處理 inline 編輯更新（來自 PlanExerciseCard）
  /// 支援兩種模式：
  /// - 批量更新（無 setIndex）：更新預設目標並應用到所有組
  /// - 單組更新（有 setIndex）：只更新指定組
  void _handleBatchUpdate(int exerciseIndex, Map<String, dynamic> values) {
    setState(() {
      final exercise = _exercises[exerciseIndex];
      final setIndex = values['setIndex'] as int?;

      if (setIndex != null) {
        // 單組更新模式
        final updatedValues = Map<String, dynamic>.from(values);
        updatedValues.remove('setIndex'); // 移除 setIndex，只保留數據

        // 確保 setTargets 存在
        List<Map<String, dynamic>> newSetTargets;
        if (exercise.setTargets != null && exercise.setTargets!.isNotEmpty) {
          newSetTargets = List<Map<String, dynamic>>.from(exercise.setTargets!);
        } else {
          newSetTargets = List.generate(
            exercise.sets,
            (i) => _buildSetTarget(exercise),
          );
        }

        // 確保 setIndex 在範圍內
        while (newSetTargets.length <= setIndex) {
          newSetTargets.add(_buildSetTarget(exercise));
        }

        // 更新指定組
        newSetTargets[setIndex] = updatedValues;

        _exercises[exerciseIndex] = exercise.copyWith(
          setTargets: newSetTargets,
        );
      } else {
        // 批量更新模式：更新預設值並應用到所有組
        final newSetTargets = List.generate(
          exercise.sets,
          (i) => Map<String, dynamic>.from(values),
        );

        _exercises[exerciseIndex] = exercise.copyWith(
          reps: values['reps'] as int? ?? exercise.reps,
          weight: (values['weight'] as num?)?.toDouble() ?? exercise.weight,
          time: values['time'] as int?,
          distance: (values['distance'] as num?)?.toDouble(),
          calories: (values['calories'] as num?)?.toDouble(),
          setTargets: newSetTargets,
        );
      }
    });
  }

  // 移除訓練動作
  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  // ⭐ v2.1: 統一處理時間範圍變更
  void _onTimeRangeChanged(TimeOfDay start, TimeOfDay end) {
    setState(() {
      _trainingTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        start.hour,
        start.minute,
      );
      _trainingEndTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        end.hour,
        end.minute,
      );
    });
  }

  // ⭐ v3.2: 檢查是否顯示 Coach Mark
  Future<void> _checkCoachMark() async {
    if (_coachMarkShown) return;

    final onboardingService = serviceLocator<OnboardingService>();
    final shouldShow = await onboardingService.shouldShowCoachMark(
      OnboardingService.keyWorkoutPlanCreate,
    );

    if (shouldShow && mounted) {
      // 延遲顯示，確保 UI 已渲染
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showCoachMark();
      });
    }
  }

  // ⭐ v3.2: 顯示 Coach Mark 引導
  void _showCoachMark() {
    if (_coachMarkShown) return;
    _coachMarkShown = true;

    final targets = <TargetFocus>[];

    // 添加動作按鈕引導
    if (_addExerciseButtonKey.currentContext != null) {
      targets.add(
        CoachMarkHelper.createRectTarget(
          key: _addExerciseButtonKey,
          title: '新增訓練動作',
          description: '點擊這裡新增訓練動作\n\n進入動作庫後，找不到動作？\n可以點擊右上角新增自訂動作',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planId != null ? '編輯訓練計畫' : '新增訓練計畫'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: '保存為模板',
            onPressed: _isLoading ? null : _saveAsTemplate,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '從模板創建',
            onPressed: _isLoading ? null : _loadFromTemplate,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _savePlan,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期和時間頭部
                  PlanDateHeader(
                    selectedDate: widget.selectedDate,
                    trainingTime: _trainingTime,
                    trainingEndTime: _trainingEndTime, // ⭐ v2.1: 傳入結束時間
                    onTimeRangeChanged: _onTimeRangeChanged, // ⭐ v2.1: 統一回調
                  ),
                  const SizedBox(height: 16),

                  // 基本信息表單
                  PlanBasicInfoForm(
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    selectedPlanType: _selectedPlanType,
                    planTypes: _planTypes,
                    onPlanTypeChanged: (value) {
                      setState(() {
                        _selectedPlanType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // 訓練動作標題
                  const Text(
                    '訓練動作',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 動作列表
                  _exercises.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('尚未添加訓練動作'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _exercises.length,
                          itemBuilder: (context, index) {
                            return PlanExerciseCard(
                              exercise: _exercises[index],
                              exerciseIndex: index,
                              onBatchUpdate: (values) =>
                                  _handleBatchUpdate(index, values),
                              onDelete: () => _removeExercise(index),
                              onEditSet: (setIndex) =>
                                  _editSet(index, setIndex),
                              onAdjustSets: (delta) =>
                                  _adjustSets(index, delta),
                            );
                          },
                        ),
                  const SizedBox(height: 16),

                  // 添加動作按鈕
                  Center(
                    child: ElevatedButton.icon(
                      key: _addExerciseButtonKey, // ⭐ v3.2: Coach Mark 引導用
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('添加訓練動作'),
                      style: ElevatedButton.styleFrom(),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    // v3.2+ 清理新增動作對話框控制器
    _newExerciseSetsController.dispose();
    _newExerciseRepsController.dispose();
    _newExerciseWeightController.dispose();
    _newExerciseRestController.dispose();
    _newExerciseTimeController.dispose();
    _newExerciseDistanceController.dispose();
    _newExerciseCaloriesController.dispose();
    super.dispose();
  }
}
