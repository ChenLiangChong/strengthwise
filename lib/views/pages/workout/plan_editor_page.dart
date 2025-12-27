import 'package:flutter/material.dart';
import '../../../models/workout_exercise_model.dart' as exercise_models;
import '../../../models/workout_record_model.dart';
import '../../../models/exercise_model.dart';
import '../../../services/interfaces/i_workout_service.dart';
import '../../../controllers/interfaces/i_auth_controller.dart';
import '../../../services/service_locator.dart';
import '../exercises/exercises_page.dart';
import 'template_management_page.dart';
import '../../../models/workout_template_model.dart';
import '../../../utils/notification_utils.dart';
import 'widgets/plan_date_header.dart';
import 'widgets/plan_basic_info_form.dart';
import 'widgets/plan_exercise_card.dart';
import 'widgets/training_time_picker_dialog.dart';
import 'widgets/set_edit_dialog.dart';

class PlanEditorPage extends StatefulWidget {
  final DateTime selectedDate;
  final String? planId; // 如果是編輯現有計畫，則提供planId
  final String? planType; // 計劃類型: "self" 或 "trainer"

  const PlanEditorPage({
    super.key,
    required this.selectedDate,
    this.planId,
    this.planType,
  });

  @override
  _PlanEditorPageState createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  late final IWorkoutService _workoutService;
  late final IAuthController _authController;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<exercise_models.WorkoutExercise> _exercises = [];
  bool _isLoading = false;
  String? _selectedPlanType;

  // 修改：使用 DateTime 替代 int
  DateTime _trainingTime = DateTime.now()
      .copyWith(hour: 8, minute: 0, second: 0, millisecond: 0, microsecond: 0);

  // 訓練計畫類型（使用 PlanType 枚舉 - 專業健身分類）
  final List<String> _planTypes = [
    '力量訓練', // 💪 1-5RM，提升最大力量
    '增肌訓練', // 🏋️ 6-12RM，增加肌肉量
    '減脂訓練', // 🔥 高強度循環，燃脂塑形
    '有氧訓練', // 🏃 有氧運動，提升心肺
    '全身訓練', // 🎯 全身性訓練，適合新手
    '上半身訓練', // ⬆️ 上半身專項訓練
    '下半身訓練', // ⬇️ 下半身專項訓練
    '核心訓練', // 🎪 核心穩定性訓練
    '伸展恢復', // 🧘 伸展放鬆，促進恢復
    '自定義', // ⚙️ 自訂訓練計劃
  ];

  @override
  void initState() {
    super.initState();

    // 從服務定位器獲取依賴
    _workoutService = serviceLocator<IWorkoutService>();
    _authController = serviceLocator<IAuthController>();

    // 如果提供了計劃類型，設置默認值
    if (widget.planType != null) {
      // 注意: 這裡的 planType 是用於資料庫存儲的值 ("self" 或 "trainer")
      // 而 _selectedPlanType 是界面顯示的訓練類型 (力量訓練, 有氧訓練等)
      // 我們在保存時會保存兩種值
    }

    // 檢查是否是過去的日期
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(widget.selectedDate.year,
        widget.selectedDate.month, widget.selectedDate.day);

    if (selectedDate.isBefore(today)) {
      // 使用 Future.microtask 確保在 initState 之後顯示錯誤提示並返回
      Future.microtask(() {
        NotificationUtils.showError(context, '無法為過去的日期創建訓練計畫');
        Navigator.of(context).pop();
      });
      return;
    }

    if (widget.planId != null) {
      _loadExistingPlan();
    }
  }

  // 載入現有訓練計畫
  Future<void> _loadExistingPlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('[PlanEditor] 載入現有計畫: ${widget.planId}');

      final record = await _workoutService.getRecordById(widget.planId!);

      if (record != null) {
        _titleController.text = record.title;
        _descriptionController.text = record.notes;
        _selectedPlanType = '全身訓練'; // 預設值（適合大多數人）

        // 加載訓練時間
        if (record.trainingTime != null) {
          _trainingTime = record.trainingTime!;
        }

        // 載入訓練動作（從 ExerciseRecord 轉換回 WorkoutExercise）
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

        print('[PlanEditor] 載入成功，動作數量: ${_exercises.length}');
      }
    } catch (e) {
      print('[PlanEditor] 載入失敗: $e');
      NotificationUtils.showError(context, '載入訓練計畫失敗: $e');
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

      print('[PlanEditor] 準備保存訓練計畫，動作數量: ${_exercises.length}');

      // 將 WorkoutExercise 轉換為 ExerciseRecord
      final exerciseRecords = _exercises.map((exercise) {
        return ExerciseRecord(
          exerciseId: exercise.exerciseId, // ← 修復：使用 exerciseId 而不是 id
          exerciseName: exercise.name,
          sets: List.generate(
            exercise.sets,
            (index) => SetRecord(
              setNumber: index + 1,
              reps: exercise.reps,
              weight: exercise.weight,
              restTime: exercise.restTime,
              completed: false,
            ),
          ),
          notes: '',
          completed: false,
        );
      }).toList();

      if (widget.planId != null) {
        // 更新現有記錄
        print('[PlanEditor] 更新現有計畫: ${widget.planId}');

        final existingRecord =
            await _workoutService.getRecordById(widget.planId!);
        if (existingRecord != null) {
          final updatedRecord = WorkoutRecord(
            id: widget.planId!,
            workoutPlanId: existingRecord.workoutPlanId,
            userId: userId,
            title: _titleController.text.isNotEmpty
                ? _titleController.text
                : '訓練記錄',
            date: widget.selectedDate,
            exerciseRecords: exerciseRecords,
            notes: _descriptionController.text,
            completed: existingRecord.completed,
            createdAt: existingRecord.createdAt,
            trainingTime: _trainingTime,
          );

          await _workoutService.updateRecord(updatedRecord);
          print('[PlanEditor] 更新成功');
        }
      } else {
        // 創建新記錄
        print('[PlanEditor] 創建新計畫');

        final newRecord = WorkoutRecord(
          id: '', // 會在 createRecord 中生成
          workoutPlanId: '',
          userId: userId,
          title:
              _titleController.text.isNotEmpty ? _titleController.text : '訓練記錄',
          date: widget.selectedDate,
          exerciseRecords: exerciseRecords,
          notes: _descriptionController.text,
          completed: false,
          createdAt: DateTime.now(),
          trainingTime: _trainingTime,
        );

        await _workoutService.createRecord(newRecord);
        print('[PlanEditor] 創建成功');
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
        Navigator.pop(context, true); // 傳回true表示保存成功
      }
    } catch (e) {
      print('[PlanEditor] 保存失敗: $e');
      if (mounted) {
        NotificationUtils.showError(context, '保存訓練計畫失敗: $e');
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

      print('[PlanEditor] 準備保存為模板: $templateName');

      // 創建模板對象
      final template = WorkoutTemplate(
        id: '', // 會在 createTemplate 中生成
        userId: userId,
        title: templateName,
        description: _descriptionController.text,
        planType: _selectedPlanType ?? '力量訓練',
        exercises: _exercises,
        trainingTime: _trainingTime,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _workoutService.createTemplate(template);
      print('[PlanEditor] 模板已保存: $templateName');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        NotificationUtils.showSuccess(context, '模板保存成功');
      }
    } catch (e, stackTrace) {
      print('[PlanEditor] 保存模板錯誤: $e');
      print('[PlanEditor] 錯誤堆棧: $stackTrace');

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
            // 如果不在列表中，設置為預設值
            _selectedPlanType = '全身訓練';
            print(
                '[PlanEditor] ⚠️ 模板的 planType "${template.planType}" 不在列表中，已設為預設值');
          }

          _exercises = List.from(template.exercises);
          // 如果模板中有訓練時間設置，則使用該設置
          if (template.trainingTime != null) {
            _trainingTime = template.trainingTime!;
          }
        });

        NotificationUtils.showSuccess(context, '已加載模板: ${template.title}');
      }
    } catch (e) {
      print('從模板加載錯誤: $e');
      NotificationUtils.showError(context, '加載模板失敗: $e');
    }
  }

  // 添加訓練動作
  void _addExercise() async {
    final result = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExercisesPage(),
      ),
    );

    if (result != null) {
      setState(() {
        _exercises.add(exercise_models.WorkoutExercise.fromExercise(result));
      });
    }
  }

  // 編輯單組數據
  Future<void> _editSet(int exerciseIndex, int setIndex) async {
    final exercise = _exercises[exerciseIndex];

    // 獲取當前組的數據
    int currentReps;
    double currentWeight;

    if (exercise.setTargets != null && setIndex < exercise.setTargets!.length) {
      final target = exercise.setTargets![setIndex];
      currentReps = target['reps'] as int? ?? exercise.reps;
      currentWeight = (target['weight'] as num?)?.toDouble() ?? exercise.weight;
    } else {
      currentReps = exercise.reps;
      currentWeight = exercise.weight;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SetEditDialog(
        setNumber: setIndex + 1,
        initialReps: currentReps,
        initialWeight: currentWeight,
      ),
    );

    if (result != null) {
      final reps = result['reps'] as int;
      final weight = result['weight'] as double;

      setState(() {
        // 確保 setTargets 存在
        if (exercise.setTargets == null || exercise.setTargets!.isEmpty) {
          final newSetTargets = List.generate(
            exercise.sets,
            (i) => {'reps': exercise.reps, 'weight': exercise.weight},
          );
          _exercises[exerciseIndex] =
              exercise.copyWith(setTargets: newSetTargets);
        }

        // 更新指定組的數據
        final updatedSetTargets = List<Map<String, dynamic>>.from(
            _exercises[exerciseIndex].setTargets!);
        updatedSetTargets[setIndex] = {'reps': reps, 'weight': weight};

        _exercises[exerciseIndex] = _exercises[exerciseIndex].copyWith(
          setTargets: updatedSetTargets,
          reps: updatedSetTargets.first['reps'] as int,
          weight: (updatedSetTargets.first['weight'] as num).toDouble(),
        );
      });
    }
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

  // 批量編輯所有組
  Future<void> _batchEditSets(int exerciseIndex) async {
    final exercise = _exercises[exerciseIndex];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BatchSetEditDialog(
        initialReps: exercise.reps,
        initialWeight: exercise.weight,
      ),
    );

    if (result != null) {
      final reps = result['reps'] as int;
      final weight = result['weight'] as double;

      setState(() {
        final newSetTargets = List.generate(
          exercise.sets,
          (i) => {'reps': reps, 'weight': weight},
        );

        _exercises[exerciseIndex] = exercise.copyWith(
          sets: exercise.sets,
          reps: reps,
          weight: weight,
          setTargets: newSetTargets,
        );
      });
    }
  }

  // 移除訓練動作
  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  // 選擇訓練時間
  Future<void> _selectTrainingTime() async {
    final selectedTime = await showDialog<DateTime>(
      context: context,
      builder: (context) =>
          TrainingTimePickerDialog(initialTime: _trainingTime),
    );

    if (selectedTime != null) {
      setState(() {
        _trainingTime = selectedTime;
      });
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
                    onSelectTime: _selectTrainingTime,
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
                              onBatchEdit: () => _batchEditSets(index),
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
    super.dispose();
  }
}
