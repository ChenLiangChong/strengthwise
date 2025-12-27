import 'package:flutter/material.dart';
import '../../../models/workout_template_model.dart';
import '../../../models/workout_exercise_model.dart' as exercise_models;
import '../../../models/exercise_model.dart';
import '../../../services/interfaces/i_workout_service.dart';
import '../../../services/interfaces/i_auth_service.dart';
import '../../../services/service_locator.dart';
import '../../../utils/notification_utils.dart';
import '../exercises/exercises_page.dart';

/// 訓練模板編輯頁面
/// 
/// 用於創建新模板或編輯現有模板（簡化版，只需要基本設定）
class TemplateEditorPage extends StatefulWidget {
  final WorkoutTemplate? template; // 如果為 null 則創建新模板
  
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
  DateTime _trainingTime = DateTime.now().copyWith(hour: 18, minute: 0);

  // Service 層
  late final IWorkoutService _workoutService;
  late final IAuthService _authService;

  // 可用的訓練類型（與 PlanType 枚舉一致 - 專業健身分類）
  final List<String> _planTypes = [
    '力量訓練',      // 💪 1-5RM，提升最大力量
    '增肌訓練',      // 🏋️ 6-12RM，增加肌肉量
    '減脂訓練',      // 🔥 高強度循環，燃脂塑形
    '有氧訓練',      // 🏃 有氧運動，提升心肺
    '全身訓練',      // 🎯 全身性訓練，適合新手
    '上半身訓練',    // ⬆️ 上半身專項訓練
    '下半身訓練',    // ⬇️ 下半身專項訓練
    '核心訓練',      // 🎪 核心穩定性訓練
    '伸展恢復',      // 🧘 伸展放鬆，促進恢復
    '自定義',        // ⚙️ 自訂訓練計劃
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
    super.dispose();
  }

  /// 載入模板數據
  void _loadTemplateData() {
    final template = widget.template!;
    _titleController.text = template.title;
    _descriptionController.text = template.description;
    
    // ⚡ 防護：確保 planType 在列表中，否則使用預設值
    if (_planTypes.contains(template.planType)) {
      _selectedPlanType = template.planType;
    } else {
      print('[模板編輯] 警告：模板訓練類型 "${template.planType}" 不在可選列表中，使用預設值');
      _selectedPlanType = _planTypes.first; // 使用第一個選項作為預設值
    }
    
    _exercises = List.from(template.exercises);
    if (template.trainingTime != null) {
      _trainingTime = template.trainingTime!;
    }
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
          trainingTime: _trainingTime,
          updatedAt: DateTime.now(),
        );
        
        await _workoutService.updateTemplate(updatedTemplate);
        print('[模板編輯] 更新成功');
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
          trainingTime: _trainingTime,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final savedTemplate = await _workoutService.createTemplate(newTemplate);
        print('[模板編輯] 創建成功，ID: ${savedTemplate.id}');
      }

      if (mounted) {
        Navigator.pop(context, true); // 傳回 true 表示保存成功
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
  Future<void> _addExercise() async {
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

  /// 編輯訓練動作設置（簡單設定）
  void _editExerciseSettings(int index) {
    final exercise = _exercises[index];

    final setsController = TextEditingController(text: exercise.sets.toString());
    final repsController = TextEditingController(text: exercise.reps.toString());
    final weightController = TextEditingController(text: exercise.weight.toString());
    final restTimeController = TextEditingController(text: exercise.restTime.toString());
    final notesController = TextEditingController(text: exercise.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('編輯 ${exercise.name}'),  // 使用完整 name
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: setsController,
                decoration: const InputDecoration(
                  labelText: '目標組數',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(
                  labelText: '目標次數',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: '建議重量 (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              final reps = int.tryParse(repsController.text);
              final weight = double.tryParse(weightController.text);
              final restTime = int.tryParse(restTimeController.text);

              if (sets == null || reps == null || weight == null || restTime == null) {
                NotificationUtils.showWarning(context, '請輸入有效的數值');
                return;
              }

              setState(() {
                _exercises[index] = exercise.copyWith(
                  sets: sets,
                  reps: reps,
                  weight: weight,
                  restTime: restTime,
                  notes: notesController.text,
                  setTargets: null, // 模板不保存詳細的每組設定
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

  /// 選擇訓練時間
  void _selectTrainingTime() {
    int selectedHour = _trainingTime.hour;
    int selectedMinute = _trainingTime.minute;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇預設訓練時間'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('設定從模板創建計劃時的預設訓練時間'),
                  const SizedBox(height: 20),
                  Text(
                    '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 小時選擇
                      Expanded(
                        child: Column(
                          children: [
                            const Text('小時', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListWheelScrollView.useDelegate(
                                itemExtent: 40,
                                diameterRatio: 1.5,
                                onSelectedItemChanged: (index) {
                                  setDialogState(() {
                                    selectedHour = index;
                                  });
                                },
                                controller: FixedExtentScrollController(initialItem: selectedHour),
                                childDelegate: ListWheelChildBuilderDelegate(
                                  builder: (context, index) {
                                    return Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selectedHour == index ? Colors.blue.withOpacity(0.1) : null,
                                      ),
                                      child: Text(
                                        index.toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: selectedHour == index ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 分鐘選擇
                      Expanded(
                        child: Column(
                          children: [
                            const Text('分鐘', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [0, 30].map((minute) {
                                  return GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedMinute = minute;
                                      });
                                    },
                                    child: Container(
                                      height: 70,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selectedMinute == minute ? Colors.blue.withOpacity(0.1) : null,
                                      ),
                                      child: Text(
                                        minute.toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: selectedMinute == minute ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _trainingTime = DateTime.now().copyWith(hour: selectedHour, minute: selectedMinute);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template != null ? '編輯模板' : '新建模板'),
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
                      hintText: '例如：推日 A',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      hintText: '時間不夠時的快速全身訓練方案',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // 預設訓練時間
                  const Text(
                    '預設訓練時間',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectTrainingTime,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Text(
                            '${_trainingTime.hour.toString().padLeft(2, '0')}:${_trainingTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ],
                      ),
                    ),
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
                            Icon(Icons.fitness_center, size: 64, color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 16),
                            Text(
                              '還沒有添加任何動作',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                              exercise.name,  // 使用完整 name
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
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

