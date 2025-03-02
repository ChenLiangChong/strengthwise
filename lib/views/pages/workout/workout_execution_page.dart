import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/workout_record_model.dart';

class WorkoutExecutionPage extends StatefulWidget {
  final String workoutPlanId;
  
  const WorkoutExecutionPage({
    super.key,
    required this.workoutPlanId,
  });
  
  @override
  _WorkoutExecutionPageState createState() => _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends State<WorkoutExecutionPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _workoutPlan;
  String _planTitle = '';
  String _planType = '';
  List<ExerciseRecord> _exerciseRecords = [];
  final TextEditingController _notesController = TextEditingController();
  
  // 計時器相關變數
  DateTime? _workoutStartTime;
  DateTime? _workoutEndTime;
  String _elapsedTime = '00:00:00';
  
  // 當前正在進行的運動索引
  int _currentExerciseIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlan();
    // 開始計時
    _workoutStartTime = DateTime.now();
    // 啟動計時器更新
    _startTimer();
  }

  // 定期更新計時器顯示
  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          final now = DateTime.now();
          final difference = now.difference(_workoutStartTime!);
          final hours = difference.inHours.toString().padLeft(2, '0');
          final minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
          final seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
          _elapsedTime = '$hours:$minutes:$seconds';
        });
        _startTimer(); // 遞迴調用以繼續更新
      }
    });
  }
  
  // 加載訓練計畫
  Future<void> _loadWorkoutPlan() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('用戶未登入');
      }
      
      // 獲取訓練計畫詳情
      final doc = await FirebaseFirestore.instance
          .collection('workoutPlans')
          .doc(widget.workoutPlanId)
          .get();
          
      if (!doc.exists) {
        throw Exception('找不到訓練計畫');
      }
      
      final planData = doc.data()!;
      
      // 檢查是否為當前用戶的訓練計畫
      if (planData['userId'] != userId) {
        throw Exception('無權訪問此訓練計畫');
      }
      
      // 創建訓練記錄
      final workoutRecord = WorkoutRecord.fromWorkoutPlan(
        userId,
        widget.workoutPlanId,
        planData,
      );
      
      setState(() {
        _workoutPlan = planData;
        _planTitle = planData['title'] ?? '未命名訓練';
        _planType = planData['planType'] ?? '';
        _exerciseRecords = workoutRecord.exerciseRecords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加載訓練計畫失敗: $e')),
        );
      }
    }
  }
  
  // 保存訓練記錄
  Future<void> _saveWorkoutRecord() async {
    try {
      setState(() {
        _isSaving = true;
      });
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('用戶未登入');
      }
      
      // 記錄訓練結束時間
      _workoutEndTime = DateTime.now();
      
      // 創建完整的訓練記錄
      final workoutRecord = WorkoutRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        workoutPlanId: widget.workoutPlanId,
        userId: userId,
        date: DateTime.now(),
        exerciseRecords: _exerciseRecords,
        notes: _notesController.text,
        isCompleted: true,
        createdAt: DateTime.now(),
      );
      
      // 保存到 Firestore
      await FirebaseFirestore.instance
          .collection('workoutRecords')
          .doc(workoutRecord.id)
          .set(workoutRecord.toJson());
      
      // 更新訓練計畫狀態為已完成
      await FirebaseFirestore.instance
          .collection('workoutPlans')
          .doc(widget.workoutPlanId)
          .update({
        'completed': true,
        'lastExecutedAt': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('訓練記錄已保存')),
        );
        
        // 返回上一頁
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存訓練記錄失敗: $e')),
        );
      }
    }
  }
  
  // 標記一組訓練完成
  void _toggleSetCompletion(int exerciseIndex, int setIndex) {
    if (exerciseIndex >= _exerciseRecords.length) return;
    
    final exercise = _exerciseRecords[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;
    
    setState(() {
      final updatedSets = List<SetRecord>.from(exercise.sets);
      updatedSets[setIndex] = exercise.sets[setIndex].copyWith(
        isCompleted: !exercise.sets[setIndex].isCompleted,
      );
      
      // 檢查是否所有組數都已完成
      final allSetsCompleted = updatedSets.every((set) => set.isCompleted);
      
      _exerciseRecords[exerciseIndex] = exercise.copyWith(
        sets: updatedSets,
        isCompleted: allSetsCompleted,
      );
    });
  }
  
  // 更新一組訓練的實際數據
  void _updateSetData(int exerciseIndex, int setIndex) {
    if (exerciseIndex >= _exerciseRecords.length) return;
    
    final exercise = _exerciseRecords[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;
    
    final currentSet = exercise.sets[setIndex];
    
    // 創建臨時控制器
    final repsController = TextEditingController(text: currentSet.reps.toString());
    final weightController = TextEditingController(text: currentSet.weight.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('更新第 ${currentSet.setNumber} 組'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsController,
                decoration: const InputDecoration(
                  labelText: '實際完成次數',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: '實際使用重量 (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              final reps = int.tryParse(repsController.text) ?? currentSet.reps;
              final weight = double.tryParse(weightController.text) ?? currentSet.weight;
              
              setState(() {
                final updatedSets = List<SetRecord>.from(exercise.sets);
                updatedSets[setIndex] = currentSet.copyWith(
                  reps: reps,
                  weight: weight,
                );
                
                _exerciseRecords[exerciseIndex] = exercise.copyWith(
                  sets: updatedSets,
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
  
  // 添加運動備註
  void _addExerciseNote(int exerciseIndex) {
    if (exerciseIndex >= _exerciseRecords.length) return;
    
    final exercise = _exerciseRecords[exerciseIndex];
    final notesController = TextEditingController(text: exercise.notes);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${exercise.exerciseName} 備註'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: '備註（例如：感覺、困難程度等）',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _exerciseRecords[exerciseIndex] = exercise.copyWith(
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
  
  // 構建運動詳情卡片
  Widget _buildExerciseCard(int index) {
    if (index >= _exerciseRecords.length) return const SizedBox.shrink();
    
    final exercise = _exerciseRecords[index];
    final isCurrentExercise = index == _currentExerciseIndex;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: isCurrentExercise ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${index + 1}. ${exercise.exerciseName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    if (!isCurrentExercise)
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline),
                        color: Colors.green,
                        onPressed: () {
                          setState(() {
                            _currentExerciseIndex = index;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.note_add_outlined),
                      color: Colors.blue,
                      onPressed: () => _addExerciseNote(index),
                    ),
                  ],
                ),
              ],
            ),
            if (exercise.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '備註: ${exercise.notes}',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const Divider(),
            const Text(
              '訓練組數',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercise.sets.length,
              itemBuilder: (context, setIndex) {
                final set = exercise.sets[setIndex];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('第 ${set.setNumber} 組'),
                  subtitle: Text('${set.reps} 次 x ${set.weight} kg'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        color: Colors.blue,
                        onPressed: () => _updateSetData(index, setIndex),
                      ),
                      Checkbox(
                        value: set.isCompleted,
                        activeColor: Colors.green,
                        onChanged: (value) {
                          _toggleSetCompletion(index, setIndex);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('執行訓練計畫'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _elapsedTime,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 訓練計畫標題區域
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.green.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _planTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '類型: $_planType',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '訓練日期: ${DateFormat('yyyy年MM月dd日').format(DateTime.now())}',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 動作列表標題
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '訓練動作',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '共 ${_exerciseRecords.length} 個動作',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 動作卡片列表
                  for (int i = 0; i < _exerciseRecords.length; i++)
                    _buildExerciseCard(i),
                  
                  const SizedBox(height: 16),
                  
                  // 訓練備註
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '訓練備註',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            hintText: '添加有關本次訓練的備註...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  
                  // 完成按鈕
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveWorkoutRecord,
                        icon: _isSaving 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(_isSaving ? '保存中...' : '完成訓練'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32, 
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
} 