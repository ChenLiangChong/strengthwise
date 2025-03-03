import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/workout_exercise_model.dart' as exercise_models;

class WorkoutTemplate {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String planType;
  final List<exercise_models.WorkoutExercise> exercises;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkoutTemplate({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.planType,
    required this.exercises,
    this.createdAt,
    this.updatedAt,
  });

  // 從 Firestore 文檔創建模板對象
  factory WorkoutTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final exercisesData = (data['exercises'] as List<dynamic>?) ?? [];
    final exercises = exercisesData
        .map((e) => exercise_models.WorkoutExercise.fromFirestore(e as Map<String, dynamic>))
        .toList();
    
    return WorkoutTemplate(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      planType: data['planType'] ?? '',
      exercises: exercises,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class TemplateManagementPage extends StatefulWidget {
  const TemplateManagementPage({super.key});

  @override
  State<TemplateManagementPage> createState() => _TemplateManagementPageState();
}

class _TemplateManagementPageState extends State<TemplateManagementPage> {
  List<WorkoutTemplate> _templates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('用戶未登入');
      }

      print('正在加載用戶 $userId 的模板...');

      // 從 workoutPlans 中查詢用戶的所有模板
      final querySnapshot = await FirebaseFirestore.instance
          .collection('workoutPlans')
          .where('userId', isEqualTo: userId)
          .get();

      print('找到 ${querySnapshot.docs.length} 個模板');
      
      // 在本地排序結果
      final templates = querySnapshot.docs
          .map((doc) => WorkoutTemplate.fromFirestore(doc))
          .toList();
          
      // 在本地進行排序（按創建時間）
      templates.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        } else if (a.createdAt == null && b.createdAt != null) {
          return 1;
        } else if (a.createdAt != null && b.createdAt == null) {
          return -1;
        }
        return 0;
      });

      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      print('加載模板失敗: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加載模板失敗: $e')),
        );
      }
    }
  }

  Future<void> _duplicateTemplate(WorkoutTemplate template) async {
    try {
      // 顯示輸入對話框讓用戶修改新模板的名稱
      TextEditingController titleController = TextEditingController(text: '${template.title} - 副本');
      final newTitle = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('複製模板'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: '新模板名稱',
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
                Navigator.pop(context, titleController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('確定'),
            ),
          ],
        ),
      );

      if (newTitle == null || newTitle.isEmpty) return;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('用戶未登入');
      }

      // 創建新的模板文檔
      final newTemplateData = {
        'userId': userId,
        'title': newTitle,
        'description': template.description,
        'planType': template.planType,
        'exercises': template.exercises.map((e) => e.toJson()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('workoutPlans')
          .add(newTemplateData);

      // 重新加載模板列表
      await _loadTemplates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板複製成功')),
        );
      }
    } catch (e) {
      print('複製模板失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('複製模板失敗: $e')),
        );
      }
    }
  }

  Future<void> _deleteTemplate(String templateId) async {
    try {
      await FirebaseFirestore.instance
          .collection('workoutPlans')
          .doc(templateId)
          .delete();

      setState(() {
        _templates.removeWhere((template) => template.id == templateId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('模板已刪除')),
        );
      }
    } catch (e) {
      print('刪除模板失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除模板失敗: $e')),
        );
      }
    }
  }

  // 直接從模板創建訓練記錄
  Future<void> _createWorkoutRecordFromTemplate(WorkoutTemplate template) async {
    try {
      // 顯示日期選擇器
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 7)),
        lastDate: DateTime.now().add(const Duration(days: 30)),
      );
      
      if (selectedDate == null) return;
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('用戶未登入');
      }
      
      // 創建訓練記錄
      final workoutRecordData = {
        'userId': userId,
        'title': template.title,
        'description': template.description,
        'planType': template.planType,
        'date': Timestamp.fromDate(selectedDate),
        'completed': false,
        'exercises': template.exercises.map((exercise) => {
          'exerciseId': exercise.id,
          'exerciseName': exercise.name,
          'actionName': exercise.actionName,
          'sets': exercise.sets,
          'reps': exercise.reps,
          'weight': exercise.weight,
          'restTime': exercise.restTime,
          'notes': exercise.notes,
          'completed': false,
        }).toList(),
        'totalSets': template.exercises.fold(0, (sum, exercise) => sum + exercise.sets),
        'totalExercises': template.exercises.length,
        'note': '',
        'startTime': null,
        'endTime': null,
        'duration': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await FirebaseFirestore.instance
          .collection('workoutRecords')
          .add(workoutRecordData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedDate.month}月${selectedDate.day}日的訓練已安排')),
        );
      }
    } catch (e) {
      print('創建訓練記錄失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('創建訓練記錄失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練計劃模板'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.note_alt_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '還沒有保存的模板',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // 返回上一頁
                          Navigator.of(context).pop();
                        },
                        child: const Text('返回'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(template.title),
                        subtitle: Text(
                          '${template.planType} - ${template.exercises.length} 個動作',
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'create_record',
                              child: Row(
                                children: [
                                  Icon(Icons.fitness_center, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('安排訓練'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  Icon(Icons.copy),
                                  SizedBox(width: 8),
                                  Text('複製'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('刪除', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            switch (value) {
                              case 'create_record':
                                await _createWorkoutRecordFromTemplate(template);
                                break;
                              case 'duplicate':
                                await _duplicateTemplate(template);
                                break;
                              case 'delete':
                                await _deleteTemplate(template.id);
                                break;
                            }
                          },
                        ),
                        onTap: () {
                          // 返回選擇的模板
                          Navigator.pop(context, template);
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 