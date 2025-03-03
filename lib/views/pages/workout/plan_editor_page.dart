import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/workout_exercise_model.dart' as exercise_models;
import '../../../models/exercise_model.dart';
import '../exercises_page.dart';
import 'template_management_page.dart';

class PlanEditorPage extends StatefulWidget {
  final DateTime selectedDate;
  final String? planId; // 如果是編輯現有計畫，則提供planId

  const PlanEditorPage({
    super.key,
    required this.selectedDate,
    this.planId,
  });

  @override
  _PlanEditorPageState createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  List<exercise_models.WorkoutExercise> _exercises = [];
  bool _isLoading = false;
  String? _selectedPlanType;
  
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

        // 載入訓練動作
        final exercisesData = data['exercises'] as List<dynamic>? ?? [];
        _exercises = exercisesData
            .map((e) => exercise_models.WorkoutExercise.fromFirestore(e as Map<String, dynamic>))
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

      // 創建訓練記錄數據
      final recordData = {
        'userId': userId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'planType': _selectedPlanType,
        'date': Timestamp.fromDate(widget.selectedDate),
        'exercises': _exercises.map((e) => {
          'exerciseId': e.id,
          'exerciseName': e.name,
          'actionName': e.actionName,
          'sets': e.sets,
          'reps': e.reps,
          'weight': e.weight,
          'restTime': e.restTime,
          'notes': e.notes,
          'completed': false,
        }).toList(),
        'totalSets': _exercises.fold(0, (sum, exercise) => sum + exercise.sets),
        'totalExercises': _exercises.length,
        'completed': false,
        'note': '',
        'startTime': null,
        'endTime': null,
        'duration': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.planId != null) {
        // 更新現有記錄
        await FirebaseFirestore.instance
            .collection('workoutRecords')
            .doc(widget.planId)
            .update({
          ...recordData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 創建新記錄
        await FirebaseFirestore.instance.collection('workoutRecords').add(recordData);
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
      TextEditingController templateNameController = TextEditingController(text: _titleController.text);
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

      // 創建模板數據 (直接存儲在 workoutPlans 集合中)
      final templateData = {
        'userId': userId,
        'title': templateName,
        'description': _descriptionController.text,
        'planType': _selectedPlanType,
        'exercises': _exercises.map((e) => e.toJson()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('準備保存模板: $templateName');
      await FirebaseFirestore.instance
          .collection('workoutPlans')
          .add(templateData);
      print('模板已保存: $templateName');

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

  // 編輯訓練動作設置
  void _editExerciseSettings(int index) {
    final exercise = _exercises[index];
    
    // 創建臨時控制器
    final setsController = TextEditingController(text: exercise.sets.toString());
    final repsController = TextEditingController(text: exercise.reps.toString());
    final weightController = TextEditingController(text: exercise.weight.toString());
    final restTimeController = TextEditingController(text: exercise.restTime.toString());
    final notesController = TextEditingController(text: exercise.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('設置 ${exercise.actionName ?? exercise.name}'),
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
              // 解析輸入值
              int? sets = int.tryParse(setsController.text);
              int? reps = int.tryParse(repsController.text);
              double? weight = double.tryParse(weightController.text);
              int? restTime = int.tryParse(restTimeController.text);

              // 驗證輸入
              if (sets == null || reps == null || weight == null || restTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('請輸入有效的數值')),
                );
                return;
              }

              // 更新動作設置
              setState(() {
                _exercises[index] = exercise.copyWith(
                  sets: sets,
                  reps: reps,
                  weight: weight,
                  restTime: restTime,
                  notes: notesController.text,
                );
              });

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('保存'),
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

  // 重新排序訓練動作
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
                    value: _selectedPlanType,
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
                      : ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _exercises.length,
                          onReorder: _reorderExercises,
                          itemBuilder: (context, index) {
                            final exercise = _exercises[index];
                            return Card(
                              key: Key(exercise.id),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.drag_handle),
                                title: Text(
                                  exercise.actionName ?? exercise.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${exercise.sets}組 x ${exercise.reps}次 | ${exercise.weight}kg'),
                                    Text('休息: ${exercise.restTime}秒'),
                                    if (exercise.notes.isNotEmpty) 
                                      Text('備註: ${exercise.notes}', 
                                        style: const TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editExerciseSettings(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeExercise(index),
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