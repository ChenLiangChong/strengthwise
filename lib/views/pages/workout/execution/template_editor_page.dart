// ✅ 已響應式改造 (Phase 0) - 表單頁，複雜操作不約束
import 'package:flutter/material.dart';
import 'package:strengthwise/common_widgets/time_picker/time_input_field.dart';
import 'package:strengthwise/models/workout_template_model.dart';
import 'package:strengthwise/models/workout_exercise_model.dart'
    as exercise_models;
import 'package:strengthwise/models/exercise_model.dart';
import 'package:strengthwise/models/tracking_mode.dart'; // v3.2+
// v3.4+
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart'; // ⭐ v3.6: MVVM
import 'package:strengthwise/controllers/interfaces/i_workout_controller.dart'; // ⭐ v3.5: MVVM 重構
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

  // ⭐ v3.6: MVVM 重構 - 透過 Controller
  late final IAuthController _authController;
  late final IWorkoutController _workoutController;

  // ⭐ v3.4: 使用統一的訓練計畫類型列表
  List<String> get _planTypes => PlanTypeExtension.uiOptions;

  @override
  void initState() {
    super.initState();
    _authController = serviceLocator<IAuthController>(); // ⭐ v3.6: MVVM
    _workoutController = serviceLocator<IWorkoutController>();
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
      debugPrint('[模板編輯] 警告：模板訓練類型 "${template.planType}" 不在可選列表中，使用預設值');
      _selectedPlanType = _planTypes.first; // 使用第一個選項作為預設值
    }

    _exercises = List.from(template.exercises);
  }

  /// 保存模板
  /// ⭐ v3.5: MVVM 重構 - 透過 Controller 操作，事件由 Controller 自動發布
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
      debugPrint('[模板編輯] 準備保存模板，動作數量: ${_exercises.length}');

      // ⭐ v3.6: MVVM 重構 - 透過 Controller 獲取用戶
      final userId = _authController.user?.uid;
      if (userId == null || userId.isEmpty) {
        throw Exception('用戶未登入');
      }

      if (widget.template != null) {
        // 更新現有模板
        debugPrint('[模板編輯] 更新模板 ID: ${widget.template!.id}');
        final updatedTemplate = widget.template!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          planType: _selectedPlanType!,
          exercises: _exercises,
          updatedAt: DateTime.now(),
        );

        // ⭐ v3.5: 透過 Controller 更新模板（Controller 會自動發布事件）
        final success = await _workoutController.updateTemplate(updatedTemplate);
        if (!success) {
          throw Exception(_workoutController.errorMessage ?? '更新模板失敗');
        }
        debugPrint('[模板編輯] 更新完成');
      } else {
        // 創建新模板
        debugPrint('[模板編輯] 創建新模板');
        final newTemplate = WorkoutTemplate(
          id: '', // Service 會生成
          userId: userId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          planType: _selectedPlanType!,
          exercises: _exercises,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // ⭐ v3.5: 透過 Controller 創建模板（Controller 會自動發布事件）
        final savedTemplate = await _workoutController.createTemplate(newTemplate);
        debugPrint('[模板編輯] 創建完成，ID: ${savedTemplate.id}');
      }

      if (mounted) {
        Navigator.pop(context, true); // 返回 true 表示保存成功
      }
    } catch (e, stackTrace) {
      debugPrint('[模板編輯] 保存失敗: $e');
      debugPrint('[模板編輯] Stack trace: $stackTrace');
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
  /// v3.7+ 使用獨立 Dialog Widget 支援 TimeInputField
  void _editExerciseSettings(int index) async {
    final exercise = _exercises[index];
    
    final result = await showDialog<exercise_models.WorkoutExercise>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TemplateExerciseEditDialog(exercise: exercise),
    );
    
    if (result != null && mounted) {
      setState(() {
        _exercises[index] = result;
      });
    }
  }

  /// 移除訓練動作
  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  /// ⭐ v3.4: 根據 trackingMode 構建動作摘要顯示
  String _buildExerciseSummary(exercise_models.WorkoutExercise exercise) {
    final sets = exercise.sets;
    final trackingMode = exercise.trackingMode;

    switch (trackingMode) {
      case TrackingMode.weightReps:
        return '$sets 組 × ${exercise.reps} 次 @ ${exercise.weight} kg';
      case TrackingMode.weightTime:
        return '$sets 組 × ${exercise.weight} kg × ${exercise.time ?? 30} 秒';
      case TrackingMode.repsOnly:
        return '$sets 組 × ${exercise.reps} 次';
      case TrackingMode.timeOnly:
        return '$sets 組 × ${exercise.time ?? 30} 秒';
      case TrackingMode.repsTime:
        return '$sets 組 × ${exercise.reps} 次 × ${exercise.time ?? 5} 秒';
      case TrackingMode.distanceTime:
        final distance = exercise.distance ?? 0;
        final distanceStr = distance >= 1000 
            ? '${(distance / 1000).toStringAsFixed(1)} km' 
            : '${distance.toInt()} m';
        return '$sets 組 × $distanceStr / ${_formatTime(exercise.time ?? 0)}';
      case TrackingMode.distanceOnly:
        final distance = exercise.distance ?? 0;
        final distanceStr = distance >= 1000 
            ? '${(distance / 1000).toStringAsFixed(1)} km' 
            : '${distance.toStringAsFixed(1)} m';
        return '$sets 組 × $distanceStr';
      case TrackingMode.calories:
        return '$sets 組 × ${exercise.calories?.toInt() ?? 0} 卡';
    }
  }

  /// 格式化時間（秒 → mm:ss）
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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

                  // 訓練計畫類型
                  const Text(
                    '訓練計畫類型 *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPlanType,
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
                              _buildExerciseSummary(exercise),
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

/// ⭐ v3.7+: 模板動作編輯對話框
/// 
/// 獨立的 StatefulWidget，支援 TimeInputField
class _TemplateExerciseEditDialog extends StatefulWidget {
  final exercise_models.WorkoutExercise exercise;

  const _TemplateExerciseEditDialog({required this.exercise});

  @override
  State<_TemplateExerciseEditDialog> createState() => _TemplateExerciseEditDialogState();
}

class _TemplateExerciseEditDialogState extends State<_TemplateExerciseEditDialog> {
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _distanceController;
  late TextEditingController _caloriesController;
  late TextEditingController _notesController;
  int? _timeValue;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(text: widget.exercise.sets.toString());
    _repsController = TextEditingController(text: widget.exercise.reps.toString());
    _weightController = TextEditingController(text: widget.exercise.weight.toString());
    _distanceController = TextEditingController(text: (widget.exercise.distance ?? 0).toString());
    _caloriesController = TextEditingController(text: (widget.exercise.calories ?? 0).toString());
    _notesController = TextEditingController(text: widget.exercise.notes);
    _timeValue = widget.exercise.time;
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _distanceController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackingMode = widget.exercise.trackingMode;
    
    return AlertDialog(
      title: Text('編輯 ${widget.exercise.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _setsController,
              decoration: const InputDecoration(
                labelText: '目標組數',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ..._buildTrackingModeFields(trackingMode),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
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
          onPressed: _onSave,
          child: const Text('保存'),
        ),
      ],
    );
  }

  List<Widget> _buildTrackingModeFields(TrackingMode trackingMode) {
    final fields = <Widget>[];
    
    if (trackingMode.needsWeight) {
      fields.add(TextField(
        controller: _weightController,
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
        controller: _repsController,
        decoration: const InputDecoration(
          labelText: '目標次數',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ));
      fields.add(const SizedBox(height: 10));
    }
    
    if (trackingMode.needsTime) {
      fields.add(TimeInputField(
        value: _timeValue,
        onChanged: (seconds) => setState(() => _timeValue = seconds),
        useOutlineBorder: true,
        labelText: '時間',
      ));
      fields.add(const SizedBox(height: 10));
    }
    
    if (trackingMode.needsDistance) {
      fields.add(TextField(
        controller: _distanceController,
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
        controller: _caloriesController,
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

  void _onSave() {
    final sets = int.tryParse(_setsController.text);
    
    if (sets == null) {
      NotificationUtils.showWarning(context, '請輸入有效的組數');
      return;
    }

    final trackingMode = widget.exercise.trackingMode;
    final reps = trackingMode.needsReps
        ? int.tryParse(_repsController.text) ?? 0
        : 0;
    final weight = trackingMode.needsWeight
        ? double.tryParse(_weightController.text) ?? 0.0
        : 0.0;
    final distance = trackingMode.needsDistance
        ? double.tryParse(_distanceController.text)
        : null;
    final calories = trackingMode.needsCalories
        ? double.tryParse(_caloriesController.text)
        : null;

    final updatedExercise = widget.exercise.copyWith(
      sets: sets,
      reps: reps,
      weight: weight,
      notes: _notesController.text,
      time: _timeValue,
      distance: distance,
      calories: calories,
      setTargets: null, // 模板不儲存詳細的每組設定
    );

    Navigator.pop(context, updatedExercise);
  }
}
