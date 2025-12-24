import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/workout_exercise_model.dart' as exercise_models;
import '../../../models/exercise_model.dart';
import '../../../controllers/interfaces/i_workout_controller.dart';
import '../../../services/error_handling_service.dart';
import '../../../services/service_locator.dart';
import '../exercises_page.dart';
import 'template_management_page.dart' hide WorkoutTemplate;
import '../../../models/workout_template_model.dart';

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
  late final IWorkoutController _workoutController;
  late final ErrorHandlingService _errorService;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<exercise_models.WorkoutExercise> _exercises = [];
  bool _isLoading = false;
  String? _selectedPlanType;

  // 修改：使用 DateTime 替代 int
  DateTime _trainingTime = DateTime.now()
      .copyWith(hour: 8, minute: 0, second: 0, millisecond: 0, microsecond: 0);

  // 訓練計畫類型
  final List<String> _planTypes = [
    '力量訓練',
    '有氧訓練',
    '肌肉塑形',
    '核心訓練',
    '全身訓練',
    '恢復訓練'
  ];

  @override
  void initState() {
    super.initState();

    // 從服務定位器獲取依賴
    _workoutController = serviceLocator<IWorkoutController>();
    _errorService = serviceLocator<ErrorHandlingService>();

    // 如果提供了計劃類型，設置默認值
    if (widget.planType != null) {
      // 注意: 這裡的 planType 是用於 Firebase 存儲的值 ("self" 或 "trainer")
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('無法為過去的日期創建訓練計畫'),
            backgroundColor: Colors.red,
          ),
        );
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
      final doc = await FirebaseFirestore.instance
          .collection('workoutPlans')
          .doc(widget.planId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _selectedPlanType = data['planType'];

        // 加載訓練時間，如果存在
        if (data['trainingTime'] != null) {
          _trainingTime = (data['trainingTime'] as Timestamp).toDate();
        } else if (data['trainingHour'] != null) {
          // 兼容舊數據
          final hour = data['trainingHour'] as int;
          final date = widget.selectedDate;
          _trainingTime = DateTime(date.year, date.month, date.day, hour, 0);
        }

        // 載入訓練動作
        final exercisesData = data['exercises'] as List<dynamic>? ?? [];
        _exercises = exercisesData
            .map((e) => exercise_models.WorkoutExercise.fromFirestore(
                e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('載入訓練計畫失敗: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 保存訓練計畫
  Future<void> _savePlan() async {
    if (_titleController.text.isEmpty || _selectedPlanType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫計畫名稱和類型')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('未登入');
      }

      // 將現有的訓練界面類型 (力量訓練等) 映射到系統標記類型 (self/trainer)
      final actualPlanType = widget.planType ?? 'self'; // 預設為自主訓練

      // 創建訓練計畫數據
      final recordData = {
        // 根據新的集合結構添加字段
        'userId': userId, // 向後相容，同時添加 userId
        'creatorId': userId, // 創建者就是當前用戶
        'traineeId': userId, // 預設情況下，訓練計劃是給自己的
        'title': _titleController.text,
        'description': _descriptionController.text,
        'uiPlanType': _selectedPlanType, // 界面顯示的訓練類型 (力量訓練等)
        'planType': actualPlanType, // 系統標記的計劃類型 (self/trainer)
        'scheduledDate':
            Timestamp.fromDate(widget.selectedDate), // 改用 scheduledDate
        'exercises': _exercises.map((e) => e.toJson()).toList(),
        'completed': false,
        'trainingTime': Timestamp.fromDate(_trainingTime),
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };

      if (widget.planId != null) {
        // 更新現有記錄
        await FirebaseFirestore.instance
            .collection('workoutPlans') // 改用 workoutPlans 集合
            .doc(widget.planId)
            .update({
          ...recordData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 創建新記錄
        await FirebaseFirestore.instance
            .collection('workoutPlans')
            .add(recordData); // 改用 workoutPlans 集合
      }

      // 返回行事曆頁面
      if (mounted) {
        Navigator.pop(context, true); // 傳回true表示保存成功
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存訓練計畫失敗: $e')),
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

  // 保存為模板
  Future<void> _saveAsTemplate() async {
    try {
      if (_titleController.text.isEmpty || _selectedPlanType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請填寫計畫名稱和類型')),
        );
        return;
      }

      if (_exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請至少添加一個訓練動作')),
        );
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      );

      if (templateName == null || templateName.isEmpty) return;

      setState(() {
        _isLoading = true;
      });

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('用戶未登入');
      }

      // 創建模板數據 (存儲在 workoutTemplates 集合中)
      final templateData = {
        'userId': userId,
        'title': templateName,
        'description': _descriptionController.text,
        'planType': _selectedPlanType,
        'exercises': _exercises.map((e) => e.toJson()).toList(),
        'trainingTime': Timestamp.fromDate(_trainingTime),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('準備保存模板: $templateName');
      await FirebaseFirestore.instance
          .collection('workoutTemplates')
          .add(templateData);
      print('模板已保存到 workoutTemplates 集合: $templateName');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板保存成功')),
        );
      }
    } catch (e, stackTrace) {
      print('保存模板錯誤: $e');
      print('錯誤堆棧: $stackTrace');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存模板失敗: $e')),
        );
      }
    }
  }

  // 從模板加載
  Future<void> _loadFromTemplate() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先登入')),
        );
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
          _selectedPlanType = template.planType;
          _exercises = List.from(template.exercises);
          // 如果模板中有訓練時間設置，則使用該設置
          if (template.trainingTime != null) {
            _trainingTime = template.trainingTime!;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已加載模板: ${template.title}')),
        );
      }
    } catch (e) {
      print('從模板加載錯誤: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加載模板失敗: $e')),
      );
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
  void _editSet(int exerciseIndex, int setIndex) {
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
    
    final repsController = TextEditingController(text: currentReps.toString());
    final weightController = TextEditingController(text: currentWeight.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('編輯第 ${setIndex + 1} 組'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: repsController,
              decoration: const InputDecoration(
                labelText: '次數',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(
                labelText: '重量 (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final reps = int.tryParse(repsController.text);
              final weight = double.tryParse(weightController.text);
              
              if (reps == null || weight == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('請輸入有效的數值')),
                );
                return;
              }
              
              setState(() {
                // 確保 setTargets 存在
                if (exercise.setTargets == null || exercise.setTargets!.isEmpty) {
                  // 創建新的 setTargets
                  final newSetTargets = List.generate(
                    exercise.sets,
                    (i) => {'reps': exercise.reps, 'weight': exercise.weight},
                  );
                  _exercises[exerciseIndex] = exercise.copyWith(setTargets: newSetTargets);
                }
                
                // 更新指定組的數據
                final updatedSetTargets = List<Map<String, dynamic>>.from(_exercises[exerciseIndex].setTargets!);
                updatedSetTargets[setIndex] = {'reps': reps, 'weight': weight};
                
                _exercises[exerciseIndex] = _exercises[exerciseIndex].copyWith(
                  setTargets: updatedSetTargets,
                  reps: updatedSetTargets.first['reps'] as int,
                  weight: (updatedSetTargets.first['weight'] as num).toDouble(),
                );
              });
              
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('確定'),
          ),
        ],
      ),
    );
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
  void _batchEditSets(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    
    final repsController = TextEditingController(text: exercise.reps.toString());
    final weightController = TextEditingController(text: exercise.weight.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量編輯所有組'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '這將應用到所有組',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: repsController,
              decoration: const InputDecoration(
                labelText: '次數',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(
                labelText: '重量 (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final reps = int.tryParse(repsController.text);
              final weight = double.tryParse(weightController.text);
              
              if (reps == null || weight == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('請輸入有效的數值')),
                );
                return;
              }
              
              setState(() {
                // 創建所有組的相同設定
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
              
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  // 移除訓練動作
  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  // 添加選擇訓練時間的方法 - 更新為類似鬧鐘的界面
  void _selectTrainingTime() {
    // 獲取當前選中的小時和分鐘
    int selectedHour = _trainingTime.hour;
    int selectedMinute = _trainingTime.minute;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('選擇訓練時間'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('請選擇訓練時間', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),

                  // 顯示當前選擇的時間
                  Text(
                    '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 時間選擇區
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 小時選擇
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('小時',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListWheelScrollView(
                                itemExtent: 40,
                                diameterRatio: 1.5,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedHour = index;
                                  });
                                },
                                controller: FixedExtentScrollController(
                                    initialItem: selectedHour),
                                children: List.generate(24, (index) {
                                  return Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: selectedHour == index
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.transparent,
                                    ),
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: selectedHour == index
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // 分鐘選擇（只有0和30兩個選項）
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('分鐘',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedMinute = 0;
                                      });
                                    },
                                    child: Container(
                                      height: 80,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selectedMinute == 0
                                            ? Colors.blue.withOpacity(0.1)
                                            : Colors.transparent,
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                      ),
                                      child: Text(
                                        '00',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: selectedMinute == 0
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedMinute = 30;
                                      });
                                    },
                                    child: Container(
                                      height: 80,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: selectedMinute == 30
                                            ? Colors.blue.withOpacity(0.1)
                                            : Colors.transparent,
                                      ),
                                      child: Text(
                                        '30',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: selectedMinute == 30
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
              // 更新選中的訓練時間
              final now = DateTime.now();
              _trainingTime = DateTime(
                  now.year, now.month, now.day, selectedHour, selectedMinute);
              setState(() {}); // 更新外部狀態
              Navigator.pop(context);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy年MM月dd日').format(widget.selectedDate);

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
                  // 日期顯示
                  Text(
                    '日期: $formattedDate',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 添加訓練時間選擇
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '訓練時間: ${DateFormat('HH:mm').format(_trainingTime)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _selectTrainingTime, // 更新方法名
                        icon:
                            const Icon(Icons.edit_calendar_outlined, size: 16),
                        label: const Text('修改時間'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 訓練計畫基本信息
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '計畫名稱',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 訓練類型選擇
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '訓練類型',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedPlanType,
                    items: _planTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPlanType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 計畫描述
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '計畫描述（可選）',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // 訓練動作列表
                  const Text(
                    '訓練動作',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

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
                            final exercise = _exercises[index];
                            return Card(
                              key: Key(exercise.id),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              color: Colors.green.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 動作標題和操作按鈕
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                exercise.actionName ?? exercise.name,
                                                style: const TextStyle(
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '${exercise.equipment} | ${exercise.bodyParts.join(", ")}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.copy, size: 20),
                                              color: Colors.blue,
                                              onPressed: () => _batchEditSets(index),
                                              tooltip: '批量編輯',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 20),
                                              color: Colors.red,
                                              onPressed: () => _removeExercise(index),
                                              tooltip: '刪除動作',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    // 組數調整
                                    Row(
                                      children: [
                                        const Text(
                                          '訓練組數',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline),
                                          color: exercise.sets > 1 ? Colors.red : Colors.grey,
                                          onPressed: exercise.sets > 1
                                              ? () => _adjustSets(index, -1)
                                              : null,
                                        ),
                                        Text(
                                          '${exercise.sets} 組',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline),
                                          color: exercise.sets < 10 ? Colors.green : Colors.grey,
                                          onPressed: exercise.sets < 10
                                              ? () => _adjustSets(index, 1)
                                              : null,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // 每組詳情
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: exercise.sets,
                                      itemBuilder: (context, setIndex) {
                                        // 獲取這一組的目標
                                        int targetReps;
                                        double targetWeight;
                                        
                                        if (exercise.setTargets != null && setIndex < exercise.setTargets!.length) {
                                          final target = exercise.setTargets![setIndex];
                                          targetReps = target['reps'] as int? ?? exercise.reps;
                                          targetWeight = (target['weight'] as num?)?.toDouble() ?? exercise.weight;
                                        } else {
                                          targetReps = exercise.reps;
                                          targetWeight = exercise.weight;
                                        }
                                        
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            child: Text('${setIndex + 1}'),
                                          ),
                                          title: Text('第 ${setIndex + 1} 組'),
                                          subtitle: Text('$targetReps 次 × $targetWeight kg'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.edit),
                                            color: Colors.blue,
                                            onPressed: () => _editSet(index, setIndex),
                                            tooltip: '編輯',
                                          ),
                                        );
                                      },
                                    ),
                                    // 休息時間和備註
                                    if (exercise.restTime != 90 || exercise.notes.isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Divider(),
                                          if (exercise.restTime != 90)
                                            Text(
                                              '休息: ${exercise.restTime}秒',
                                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                            ),
                                          if (exercise.notes.isNotEmpty)
                                            Text(
                                              '備註: ${exercise.notes}',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
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
