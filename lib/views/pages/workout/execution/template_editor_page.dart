// ✅ 已響應式改造 (Phase 0) - 表單頁，複雜操作不約束
import 'package:flutter/material.dart';
import 'package:strengthwise/models/workout_template_model.dart';
import 'package:strengthwise/models/workout_exercise_model.dart'
    as exercise_models;
import 'package:strengthwise/models/exercise_model.dart';
import 'package:strengthwise/models/tracking_mode.dart'; // v3.2+
import 'package:strengthwise/services/interfaces/i_workout_service.dart';
import 'package:strengthwise/services/interfaces/i_auth_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/exercises/exercises_page.dart';
import 'widgets/exercise_settings_dialog.dart'; // v3.2+ 添加動作設定對話框

/// 訓練模板編輯頁面
///
/// 用於創建新模板或編輯現有模板（簡化版，只需要基本設定）
class TemplateEditorPage extends StatefulWidget {
  final WorkoutTemplate? template; // 如果是 null 則創建新模板

  const TemplateEditorPage({
    super.key,
    this.template,
  });

  @override
  State<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<TemplateEditorPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPlanType;
  List<exercise_models.WorkoutExercise> _exercises = [];
  bool _isLoading = false;
  
  // v3.2+ 新增動作設定對話框控制器
  final _newExerciseSetsController = TextEditingController();
  final _newExerciseRepsController = TextEditingController();
  final _newExerciseWeightController = TextEditingController();
  final _newExerciseRestController = TextEditingController();
  final _newExerciseTimeController = TextEditingController();
  final _newExerciseDistanceController = TextEditingController();
  final _newExerciseCaloriesController = TextEditingController();

  // Service 層
  late final IWorkoutService _workoutService;
  late final IAuthService _authService;

  // 共用訓練類型列舉（PlanType 列舉一致 - 專業健身分類）
  final List<String> _planTypes = [
    '力量訓練', // 🏋️ 1-5RM，提升最大力量
    '增肌訓練', // 💪 6-12RM，提升肌肉量
    '減脂訓練', // 🔥 高強度循環訓練，塑形
    '有氧訓練', // ❤️ 有氧運動，提升心肺
    '全身訓練', // 🌟 全身協調練習，多關節
    '上半身', // ⬆️ 上半身專項訓練
    '下半身', // ⬇️ 下半身專項訓練
    '核心訓練', // 🎯 核心穩定性訓練
    '伸展恢復', // 🧘 伸展運動，促進恢復
    '自訂', // 📝 自訂訓練計劃
  ];

  @override
  void initState() {
    super.initState();
    _workoutService = serviceLocator<IWorkoutService>();
    _authService = serviceLocator<IAuthService>();
    if (widget.template != null) {
      _loadTemplateData();
    }
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

  /// 載入模板資料
  void _loadTemplateData() {
    final template = widget.template!;
    _titleController.text = template.title;
    _descriptionController.text = template.description;

    // 防護：確保 planType 在列表中，否則使用預設值
    if (_planTypes.contains(template.planType)) {
      _selectedPlanType = template.planType;
    } else {
      print('[模板編輯] 警告：模板訓練類型 "${template.planType}" 不在可選列表中，使用預設值');
      _selectedPlanType = _planTypes.first; // 使用第一個選項作為預設值
    }

    _exercises = List.from(template.exercises);
  }

  /// 保存模板
  Future<void> _saveTemplate() async {
    if (_titleController.text.isEmpty || _selectedPlanType == null) {
      NotificationUtils.showWarning(context, '請填寫模板名稱和類型');
      return;
    }

    if (_exercises.isEmpty) {
      NotificationUtils.showWarning(context, '請至少添加一個動作');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('[模板編輯] 準備保存模板，動作數量: ${_exercises.length}');

      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('用戶未登入');
      }

      if (widget.template != null) {
        // 更新現有模板
        print('[模板編輯] 更新模板 ID: ${widget.template!.id}');
        final updatedTemplate = widget.template!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          planType: _selectedPlanType!,
          exercises: _exercises,
          updatedAt: DateTime.now(),
        );

        await _workoutService.updateTemplate(updatedTemplate);
        print('[模板編輯] 更新完成');
      } else {
        // 創建新模板
        print('[模板編輯] 創建新模板');
        final newTemplate = WorkoutTemplate(
          id: '', // Service 會生成
          userId: currentUser['uid'] ?? '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          planType: _selectedPlanType!,
          exercises: _exercises,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final savedTemplate = await _workoutService.createTemplate(newTemplate);
        print('[模板編輯] 創建完成，ID: ${savedTemplate.id}');
      }

      if (mounted) {
        Navigator.pop(context, true); // 返回 true 表示保存成功
      }
    } catch (e, stackTrace) {
      print('[模板編輯] 保存失敗: $e');
      print('[模板編輯] Stack trace: $stackTrace');
      if (mounted) {
        NotificationUtils.showError(
          context,
          '保存模板失敗: $e',
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 添加訓練動作
  /// v3.2+ 根據 trackingMode 顯示不同的設定對話框
  Future<void> _addExercise() async {
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
        exerciseName: exercise.name,
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
          name: exercise.name,
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

  /// 編輯訓練動作設置（簡化設定）
  /// v3.2+ 根據 trackingMode 顯示不同欄位
  void _editExerciseSettings(int index) {
    final exercise = _exercises[index];
    final trackingMode = exercise.trackingMode;

    final setsController =
        TextEditingController(text: exercise.sets.toString());
    final repsController =
        TextEditingController(text: exercise.reps.toString());
    final weightController =
        TextEditingController(text: exercise.weight.toString());
    final restTimeController =
        TextEditingController(text: exercise.restTime.toString());
    final notesController = TextEditingController(text: exercise.notes);
    // v3.2+ 新增控制器
    final timeController =
        TextEditingController(text: (exercise.time ?? 0).toString());
    final distanceController =
        TextEditingController(text: (exercise.distance ?? 0).toString());
    final caloriesController =
        TextEditingController(text: (exercise.calories ?? 0).toString());

    showDialog(
      context: context,
      barrierDismissible: false, // 修復：防止點擊外部關閉
      builder: (context) => AlertDialog(
        title: Text('編輯 ${exercise.name}'), // 使用完整 name
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 組數（所有模式都需要）
              TextField(
                controller: setsController,
                decoration: const InputDecoration(
                  labelText: '目標組數',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              // v3.2+ 根據 trackingMode 顯示對應欄位
              ..._buildTrackingModeFields(
                trackingMode,
                repsController,
                weightController,
                timeController,
                distanceController,
                caloriesController,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: restTimeController,
                decoration: const InputDecoration(
                  labelText: '休息時間 (秒)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: '備註',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final sets = int.tryParse(setsController.text);
              final restTime = int.tryParse(restTimeController.text);

              if (sets == null || restTime == null) {
                NotificationUtils.showWarning(context, '請輸入有效的數值');
                return;
              }

              // v3.2+ 根據 trackingMode 解析欄位
              final reps = trackingMode.needsReps
                  ? int.tryParse(repsController.text) ?? 0
                  : 0;
              final weight = trackingMode.needsWeight
                  ? double.tryParse(weightController.text) ?? 0.0
                  : 0.0;
              final time = trackingMode.needsTime
                  ? int.tryParse(timeController.text)
                  : null;
              final distance = trackingMode.needsDistance
                  ? double.tryParse(distanceController.text)
                  : null;
              final calories = trackingMode.needsCalories
                  ? double.tryParse(caloriesController.text)
                  : null;

              setState(() {
                _exercises[index] = exercise.copyWith(
                  sets: sets,
                  reps: reps,
                  weight: weight,
                  restTime: restTime,
                  notes: notesController.text,
                  time: time,
                  distance: distance,
                  calories: calories,
                  setTargets: null, // 模板不儲存詳細的每組設定
                );
              });

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// v3.2+ 根據追蹤模式構建輸入欄位
  List<Widget> _buildTrackingModeFields(
    TrackingMode trackingMode,
    TextEditingController repsController,
    TextEditingController weightController,
    TextEditingController timeController,
    TextEditingController distanceController,
    TextEditingController caloriesController,
  ) {
    final fields = <Widget>[];
    
    if (trackingMode.needsWeight) {
      fields.add(TextField(
        controller: weightController,
        decoration: const InputDecoration(
          labelText: '建議重量 (kg)',
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ));
      fields.add(const SizedBox(height: 10));
    }
    
    if (trackingMode.needsReps) {
      fields.add(TextField(
        controller: repsController,
        decoration: const InputDecoration(
          labelText: '目標次數',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ));
      fields.add(const SizedBox(height: 10));
    }
    
    if (trackingMode.needsTime) {
      fields.add(TextField(
        controller: timeController,
        decoration: const InputDecoration(
          labelText: '時間 (秒)',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ));
      fields.add(const SizedBox(height: 10));
    }
    
    if (trackingMode.needsDistance) {
      fields.add(TextField(
        controller: distanceController,
        decoration: const InputDecoration(
          labelText: '距離 (公尺)',
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ));
      fields.add(const SizedBox(height: 10));
    }
    
    if (trackingMode.needsCalories) {
      fields.add(TextField(
        controller: caloriesController,
        decoration: const InputDecoration(
          labelText: '卡路里 (kcal)',
          border: OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ));
      fields.add(const SizedBox(height: 10));
    }
    
    return fields;
  }

  /// 移除訓練動作
  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  /// 重新排序訓練動作
  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template != null ? '編輯模板' : '創建模板'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveTemplate,
              tooltip: '保存模板',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 模板名稱
                  const Text(
                    '模板名稱 *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '例如：推拉 A',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 訓練類型
                  const Text(
                    '訓練類型 *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedPlanType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _planTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPlanType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // 描述
                  const Text(
                    '描述',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '適合不需要器材的快速全身訓練方案',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // 動作列表標題
                  const Text(
                    '訓練動作',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 動作列表
                  if (_exercises.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.fitness_center,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              '還沒有添加任何動作',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _exercises.length,
                      onReorder: _reorderExercises,
                      itemBuilder: (context, index) {
                        final exercise = _exercises[index];
                        return Card(
                          key: ValueKey(exercise.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.drag_handle),
                            title: Text(
                              exercise.name, // 使用完整 name
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${exercise.sets} 組 × ${exercise.reps} 次 @ ${exercise.weight} kg | 休息 ${exercise.restTime}s',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _editExerciseSettings(index),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () => _removeExercise(index),
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),

                  // 添加動作按鈕（移到列表下方）
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('添加動作'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 96), // 底部留白，避免被導航欄遮擋
                ],
              ),
            ),
    );
  }
}
