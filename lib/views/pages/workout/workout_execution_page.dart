import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/workout_record_model.dart';
import '../../../models/exercise_model.dart';
import '../exercises_page.dart';

class WorkoutExecutionPage extends StatefulWidget {
  final String workoutRecordId;
  
  const WorkoutExecutionPage({
    super.key,
    required this.workoutRecordId,
  });
  
  @override
  _WorkoutExecutionPageState createState() => _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends State<WorkoutExecutionPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDataChanged = false;  // 新增：跟蹤資料是否已被修改
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

  // 新增運動的控制器
  final TextEditingController _newExerciseSetsController = TextEditingController(text: '3');
  final TextEditingController _newExerciseRepsController = TextEditingController(text: '10');
  final TextEditingController _newExerciseWeightController = TextEditingController(text: '0');
  final TextEditingController _newExerciseRestController = TextEditingController(text: '60');

  // 時間限制邏輯相關
  bool _isToday = false;  // 是否為今天的訓練計劃
  bool _isPastDate = false;  // 是否為過去的訓練計劃
  bool _isFutureDate = false;  // 是否為未來的訓練計劃
  DateTime? _planDate;  // 訓練計劃的日期
  
  // 訓練時間相關
  int _trainingHour = 8;  // 預設訓練時間為早上8點
  bool _hasScheduledTime = false;  // 是否有設定訓練時間

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
          .collection('workoutRecords')
          .doc(widget.workoutRecordId)
          .get();
          
      if (!doc.exists) {
        throw Exception('找不到訓練計畫');
      }
      
      final planData = doc.data()!;
      
      // 檢查是否為當前用戶的訓練計畫
      if (planData['userId'] != userId) {
        throw Exception('無權訪問此訓練計畫');
      }
      
      print('加載訓練記錄: ${doc.id}, 數據: ${planData.keys}');
      
      // 加載訓練時間
      if (planData['trainingHour'] != null) {
        _trainingHour = planData['trainingHour'] as int;
        _hasScheduledTime = true;
      }
      
      // 檢查訓練計劃日期並確定權限
      if (planData['date'] != null && planData['date'] is Timestamp) {
        final planTimestamp = planData['date'] as Timestamp;
        _planDate = planTimestamp.toDate();
        
        // 對比今日日期（僅考慮年月日，不考慮時分秒）
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final planDateOnly = DateTime(_planDate!.year, _planDate!.month, _planDate!.day);
        
        _isToday = planDateOnly.isAtSameMomentAs(todayDate);
        _isPastDate = planDateOnly.isBefore(todayDate);
        _isFutureDate = planDateOnly.isAfter(todayDate);
        
        print('計劃日期: $_planDate, 是今天: $_isToday, 是過去: $_isPastDate, 是未來: $_isFutureDate');
      } else {
        // 如果沒有日期，預設為今天
        _isToday = true;
        _isPastDate = false;
        _isFutureDate = false;
      }
      
      // 直接從文檔創建運動記錄
      final exercises = planData['exercises'] as List<dynamic>? ?? [];
      final exerciseRecords = <ExerciseRecord>[];
      
      for (final exercise in exercises) {
        try {
          if (exercise is Map<String, dynamic>) {
            // 處理sets數據 - 修復類型轉換錯誤
            final setsRecords = <SetRecord>[];
            
            // 檢查sets的類型並適當處理
            if (exercise['sets'] is List) {
              // 如果已經是List，直接處理
              final setsList = exercise['sets'] as List<dynamic>;
              
              if (setsList.isNotEmpty && setsList.first is Map<String, dynamic>) {
                for (final setData in setsList) {
                  if (setData is Map<String, dynamic>) {
                    setsRecords.add(SetRecord(
                      setNumber: setData['setNumber'] ?? 0,
                      reps: setData['reps'] ?? 0,
                      weight: (setData['weight'] as num?)?.toDouble() ?? 0.0,
                      restTime: setData['restTime'] ?? 60,
                      completed: setData['completed'] ?? false,
                    ));
                  }
                }
              } else {
                // 列表是空的或不包含Map，創建默認Set
                final totalSets = 3; // 默認3組
                for (int i = 0; i < totalSets; i++) {
                  setsRecords.add(SetRecord(
                    setNumber: i + 1,
                    reps: exercise['reps'] as int? ?? 10,
                    weight: (exercise['weight'] as num?)?.toDouble() ?? 0.0,
                    restTime: exercise['restTime'] as int? ?? 60,
                    completed: false,
                  ));
                }
              }
            } else if (exercise['sets'] is int) {
              // 如果sets是整數，表示組數
              final totalSets = exercise['sets'] as int;
              for (int i = 0; i < totalSets; i++) {
                setsRecords.add(SetRecord(
                  setNumber: i + 1,
                  reps: exercise['reps'] as int? ?? 10,
                  weight: (exercise['weight'] as num?)?.toDouble() ?? 0.0,
                  restTime: exercise['restTime'] as int? ?? 60,
                  completed: false,
                ));
              }
            } else {
              // 默認情況，創建3組
              for (int i = 0; i < 3; i++) {
                setsRecords.add(SetRecord(
                  setNumber: i + 1,
                  reps: exercise['reps'] as int? ?? 10,
                  weight: (exercise['weight'] as num?)?.toDouble() ?? 0.0,
                  restTime: exercise['restTime'] as int? ?? 60,
                  completed: false,
                ));
              }
            }
            
            // 優先使用exerciseName，然後是name，最後是actionName
            final name = exercise['exerciseName'] ?? 
                        exercise['name'] ?? 
                        exercise['actionName'] ?? 
                        '未命名運動';
                        
            exerciseRecords.add(ExerciseRecord(
              exerciseId: exercise['exerciseId'] ?? '',
              exerciseName: name,
              sets: setsRecords,
              notes: exercise['notes'] ?? '',
              completed: exercise['completed'] ?? false,
            ));
            
            print('加載運動: $name, 組數: ${setsRecords.length}');
          }
        } catch (e) {
          print('處理運動數據時出錯: $e');
        }
      }
      
      setState(() {
        _workoutPlan = planData;
        _planTitle = planData['title'] ?? '未命名訓練';
        _planType = planData['planType'] ?? '';
        _exerciseRecords = exerciseRecords;
        
        // 如果有筆記，加載它
        if (planData['note'] != null && planData['note'].toString().isNotEmpty) {
          _notesController.text = planData['note'];
        }
        
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
  
  // 檢查訓練計劃是否可以被修改
  bool _canModify({bool forAddingExercise = false}) {
    // 如果是為了添加新動作，則允許修改未來日期的訓練
    if (forAddingExercise && _isFutureDate) {
      return true;
    }
    // 否則只有當天的訓練才能修改
    return _isToday && !_isPastDate && !_isFutureDate;
  }
  
  // 顯示無法修改的提示消息
  void _showCannotModifyMessage() {
    String message = '';
    if (_isPastDate) {
      message = '無法修改過去的訓練記錄';
    } else if (_isFutureDate) {
      message = '無法修改未來的訓練記錄，請在訓練當天進行操作';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  // 保存訓練記錄
  Future<void> _saveWorkoutRecord() async {
    // 如果不是今天的訓練，不允許保存
    if (!_canModify()) {
      _showCannotModifyMessage();
      return;
    }
    
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
      
      // 計算訓練持續時間（分鐘）
      final durationInMinutes = _workoutEndTime!.difference(_workoutStartTime!).inMinutes;
      
      // 更新現有訓練記錄
      final recordData = {
        'completed': true,
        'note': _notesController.text,
        'exercises': _exerciseRecords.map((e) => e.toJson()).toList(),
        'startTime': Timestamp.fromDate(_workoutStartTime!),
        'endTime': Timestamp.fromDate(_workoutEndTime!),
        'duration': durationInMinutes,
        'trainingHour': _trainingHour,  // 添加訓練時間到記錄中
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // 更新 Firestore 中的訓練記錄
      await FirebaseFirestore.instance
          .collection('workoutRecords')
          .doc(widget.workoutRecordId)
          .update(recordData);
      
      setState(() {
        _isSaving = false;
        _isDataChanged = true;  // 標記數據已變更
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('訓練記錄已保存')),
        );
        
        // 返回上一頁，並傳遞數據已變更的標記
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
  void _toggleSetCompletion(int exerciseIndex, int setIndex) async {
    // 如果不是今天的訓練，不允許修改
    if (!_canModify()) {
      _showCannotModifyMessage();
      return;
    }
    
    if (exerciseIndex >= _exerciseRecords.length) return;
    
    final exercise = _exerciseRecords[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;
    
    try {
      // 顯示加載指示器
      setState(() {
        _isSaving = true;
      });
      
      // 更新本地狀態
      setState(() {
        final updatedSets = List<SetRecord>.from(exercise.sets);
        updatedSets[setIndex] = exercise.sets[setIndex].copyWith(
          completed: !exercise.sets[setIndex].completed,
        );
        
        // 檢查是否所有組數都已完成
        final allSetsCompleted = updatedSets.every((set) => set.completed);
        
        _exerciseRecords[exerciseIndex] = exercise.copyWith(
          sets: updatedSets,
          completed: allSetsCompleted,
        );
        
        _isDataChanged = true;  // 標記數據已變更
      });
      
      // 同步更新到 Firestore 資料庫
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('用戶未登入');
      }
      
      // 準備要更新的數據
      final recordData = {
        'exercises': _exerciseRecords.map((e) => e.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // 更新 Firestore 中的訓練記錄
      await FirebaseFirestore.instance
          .collection('workoutRecords')
          .doc(widget.workoutRecordId)
          .update(recordData);
      
      // 更新完成，關閉加載指示器
      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      // 發生錯誤，關閉加載指示器
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新組數狀態失敗: $e')),
      );
    }
  }
  
  // 更新一組訓練的實際數據
  void _updateSetData(int exerciseIndex, int setIndex) {
    // 如果不是今天的訓練，不允許修改
    if (!_canModify()) {
      _showCannotModifyMessage();
      return;
    }
    
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
            onPressed: () async {
              // 解析輸入值
              final reps = int.tryParse(repsController.text) ?? currentSet.reps;
              final weight = double.tryParse(weightController.text) ?? currentSet.weight;
              
              // 先關閉對話框
              Navigator.pop(context);
              
              try {
                // 顯示加載指示器
                setState(() {
                  _isSaving = true;
                });
                
                // 更新本地狀態
                setState(() {
                  final updatedSets = List<SetRecord>.from(exercise.sets);
                  updatedSets[setIndex] = currentSet.copyWith(
                    reps: reps,
                    weight: weight,
                  );
                  
                  _exerciseRecords[exerciseIndex] = exercise.copyWith(
                    sets: updatedSets,
                  );
                  
                  _isDataChanged = true;  // 標記數據已變更
                });
                
                // 同步更新到 Firestore 資料庫
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) {
                  throw Exception('用戶未登入');
                }
                
                // 準備要更新的數據
                final recordData = {
                  'exercises': _exerciseRecords.map((e) => e.toJson()).toList(),
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                
                // 更新 Firestore 中的訓練記錄
                await FirebaseFirestore.instance
                    .collection('workoutRecords')
                    .doc(widget.workoutRecordId)
                    .update(recordData);
                
                // 更新完成，關閉加載指示器
                setState(() {
                  _isSaving = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已更新組數數據並同步到資料庫')),
                );
              } catch (e) {
                // 發生錯誤，關閉加載指示器
                setState(() {
                  _isSaving = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('更新組數數據失敗: $e')),
                );
              }
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
    // 如果不是今天的訓練，不允許修改
    if (!_canModify()) {
      _showCannotModifyMessage();
      return;
    }
    
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
            onPressed: () async {
              // 先關閉對話框
              Navigator.pop(context);
              
              try {
                // 顯示加載指示器
                setState(() {
                  _isSaving = true;
                });
                
                // 更新本地狀態
                setState(() {
                  _exerciseRecords[exerciseIndex] = exercise.copyWith(
                    notes: notesController.text,
                  );
                  _isDataChanged = true;  // 標記數據已變更
                });
                
                // 同步更新到 Firestore 資料庫
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) {
                  throw Exception('用戶未登入');
                }
                
                // 準備要更新的數據
                final recordData = {
                  'exercises': _exerciseRecords.map((e) => e.toJson()).toList(),
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                
                // 更新 Firestore 中的訓練記錄
                await FirebaseFirestore.instance
                    .collection('workoutRecords')
                    .doc(widget.workoutRecordId)
                    .update(recordData);
                
                // 更新完成，關閉加載指示器
                setState(() {
                  _isSaving = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已更新運動備註並同步到資料庫')),
                );
              } catch (e) {
                // 發生錯誤，關閉加載指示器
                setState(() {
                  _isSaving = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('更新運動備註失敗: $e')),
                );
              }
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
  
  // 新增：添加新的訓練動作
  void _addNewExercise() async {
    // 允許修改未來日期的訓練計劃，但僅限於添加新動作
    if (_isPastDate) {
      _showCannotModifyMessage();
      return;
    }
    
    // 導航到運動選擇頁面
    final result = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExercisesPage(),
      ),
    );

    // 如果用戶選擇了運動，添加到列表中
    if (result != null) {
      // 顯示設置對話框
      _showExerciseSettingsDialog(result);
      // 標記數據已變更
      _isDataChanged = true;
    }
  }
  
  // 顯示運動設置對話框
  void _showExerciseSettingsDialog(Exercise exercise) {
    // 重置控制器值為默認值
    _newExerciseSetsController.text = '3';
    _newExerciseRepsController.text = '10';
    _newExerciseWeightController.text = '0';
    _newExerciseRestController.text = '60';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('設置 ${exercise.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newExerciseSetsController,
                decoration: const InputDecoration(
                  labelText: '組數',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _newExerciseRepsController,
                decoration: const InputDecoration(
                  labelText: '每組次數',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _newExerciseWeightController,
                decoration: const InputDecoration(
                  labelText: '重量 (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _newExerciseRestController,
                decoration: const InputDecoration(
                  labelText: '休息時間 (秒)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              // 解析設置
              final sets = int.tryParse(_newExerciseSetsController.text) ?? 3;
              final reps = int.tryParse(_newExerciseRepsController.text) ?? 10;
              final weight = double.tryParse(_newExerciseWeightController.text) ?? 0.0;
              final restTime = int.tryParse(_newExerciseRestController.text) ?? 60;
              
              // 創建組數記錄
              final setRecords = <SetRecord>[];
              for (int i = 0; i < sets; i++) {
                setRecords.add(SetRecord(
                  setNumber: i + 1,
                  reps: reps,
                  weight: weight,
                  restTime: restTime,
                  completed: false,
                ));
              }
              
              // 創建運動記錄
              final newExercise = ExerciseRecord(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                sets: setRecords,
                notes: '',
                completed: false,
              );
              
              // 先關閉對話框
              Navigator.pop(context);
              
              try {
                // 顯示加載指示器
                setState(() {
                  _isSaving = true;
                });
                
                // 添加新運動到本地列表
                setState(() {
                  _exerciseRecords.add(newExercise);
                  // 新添加的運動自動成為當前運動
                  _currentExerciseIndex = _exerciseRecords.length - 1;
                  // 標記數據已變更
                  _isDataChanged = true;
                });
                
                // 同步更新到 Firestore 資料庫
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) {
                  throw Exception('用戶未登入');
                }
                
                // 準備要更新的數據
                final recordData = {
                  'exercises': _exerciseRecords.map((e) => e.toJson()).toList(),
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                
                // 更新 Firestore 中的訓練記錄
                await FirebaseFirestore.instance
                    .collection('workoutRecords')
                    .doc(widget.workoutRecordId)
                    .update(recordData);
                
                // 更新完成，關閉加載指示器
                setState(() {
                  _isSaving = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已添加新動作並更新記錄: ${exercise.name}')),
                );
              } catch (e) {
                // 發生錯誤，關閉加載指示器
                setState(() {
                  _isSaving = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('添加運動失敗: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
  
  // 添加刪除運動的方法
  void _deleteExercise(int exerciseIndex) async {
    // 如果是過去的訓練，不允許刪除
    if (_isPastDate) {
      _showCannotModifyMessage();
      return;
    }
    
    if (exerciseIndex >= _exerciseRecords.length) return;
    
    final exercise = _exerciseRecords[exerciseIndex];
    
    // 顯示確認對話框
    showDialog(
      context: context,
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
              try {
                // 先關閉對話框
                Navigator.pop(context);
                
                // 顯示加載指示器
                setState(() {
                  _isSaving = true;
                });
                
                // 刪除此運動
                setState(() {
                  _exerciseRecords.removeAt(exerciseIndex);
                  
                  // 調整當前運動索引
                  if (_currentExerciseIndex >= _exerciseRecords.length) {
                    _currentExerciseIndex = _exerciseRecords.isEmpty ? 0 : _exerciseRecords.length - 1;
                  }
                  
                  // 標記數據已變更
                  _isDataChanged = true;
                });
                
                // 同步更新到 Firestore 資料庫
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) {
                  throw Exception('用戶未登入');
                }
                
                // 準備要更新的數據
                final recordData = {
                  'exercises': _exerciseRecords.map((e) => e.toJson()).toList(),
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                
                // 更新 Firestore 中的訓練記錄
                await FirebaseFirestore.instance
                    .collection('workoutRecords')
                    .doc(widget.workoutRecordId)
                    .update(recordData);
                
                // 更新完成，關閉加載指示器
                setState(() {
                  _isSaving = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已刪除運動並更新記錄：${exercise.exerciseName}')),
                );
              } catch (e) {
                // 發生錯誤，關閉加載指示器
                setState(() {
                  _isSaving = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('刪除運動失敗: $e')),
                );
              }
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
                    if (!isCurrentExercise && _canModify())
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
                      color: _canModify() ? Colors.blue : Colors.grey,
                      onPressed: _canModify() ? () => _addExerciseNote(index) : null,
                    ),
                    // 添加刪除按鈕
                    if (!_isPastDate)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        onPressed: () => _deleteExercise(index),
                        tooltip: '刪除此動作',
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
                        color: _canModify() ? Colors.blue : Colors.grey,
                        onPressed: _canModify() ? () => _updateSetData(index, setIndex) : null,
                      ),
                      if (!_canModify())
                        // 不可修改狀態只顯示勾選狀態，不能修改
                        Icon(
                          set.completed ? Icons.check_box : Icons.check_box_outline_blank,
                          color: set.completed ? Colors.green : Colors.grey,
                        )
                      else
                        // 當天可以修改勾選狀態
                        Checkbox(
                          value: set.completed,
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
  
  // 設置訓練時間
  void _setTrainingHour() async {
    // 是否允許修改
    final canModifyTime = !_isPastDate; // 過去的訓練不能修改時間
    
    if (!canModifyTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法修改過去訓練的時間')),
      );
      return;
    }
    
    // 顯示時間選擇器
    final selectedHour = await showDialog<int>(
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
                  const Text('請選擇每天的訓練時間', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(24, (index) {
                      final formattedHour = index.toString().padLeft(2, '0') + ':00';
                      return ChoiceChip(
                        label: Text(formattedHour),
                        selected: index == _trainingHour,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _trainingHour = index;
                            });
                          }
                        },
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: index == _trainingHour ? Colors.white : Colors.black,
                        ),
                      );
                    }),
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
            onPressed: () => Navigator.pop(context, _trainingHour),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('確定'),
          ),
        ],
      ),
    );
    
    if (selectedHour != null && selectedHour != _trainingHour) {
      try {
        // 顯示加載指示器
        setState(() {
          _isSaving = true;
        });
        
        setState(() {
          _trainingHour = selectedHour;
          _hasScheduledTime = true;
          _isDataChanged = true;
        });
        
        // 更新到 Firestore
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          throw Exception('用戶未登入');
        }
        
        await FirebaseFirestore.instance
            .collection('workoutRecords')
            .doc(widget.workoutRecordId)
            .update({
              'trainingHour': selectedHour,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        
        // 更新完成，關閉加載指示器
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('訓練時間已設定為 ${selectedHour.toString().padLeft(2, '0')}:00')),
        );
      } catch (e) {
        // 發生錯誤，關閉加載指示器
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('設定訓練時間失敗: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 攔截返回按鈕事件，傳遞數據變更狀態
      onWillPop: () async {
        Navigator.pop(context, _isDataChanged);
        return false;  // 返回 false 表示我們自己處理返回邏輯
      },
      child: Scaffold(
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
                          Row(
                            children: [
                              Text(
                                '訓練日期: ${_planDate != null ? DateFormat('yyyy年MM月dd日').format(_planDate!) : DateFormat('yyyy年MM月dd日').format(DateTime.now())}',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_isPastDate)
                                const Chip(
                                  label: Text('過去訓練 (僅查看)'),
                                  backgroundColor: Colors.amber,
                                  labelStyle: TextStyle(color: Colors.black87),
                                ),
                              if (_isFutureDate)
                                const Chip(
                                  label: Text('未來訓練 (僅查看)'),
                                  backgroundColor: Colors.blue,
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 添加訓練時間顯示
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '訓練時間: ${_trainingHour.toString().padLeft(2, '0')}:00',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!_isPastDate)
                                TextButton.icon(
                                  onPressed: _setTrainingHour,
                                  icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                                  label: const Text('修改時間'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
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
                          Row(
                            children: [
                              // 添加新動作按鈕 - 過去和當天的計劃保持原樣，但允許未來的計劃添加新動作
                              if (!_isPastDate)
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: Colors.green,
                                  onPressed: _addNewExercise,
                                  tooltip: '添加新動作',
                                ),
                              const SizedBox(width: 8),
                              Text(
                                '共 ${_exerciseRecords.length} 個動作',
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
                            enabled: _canModify(), // 只有當天訓練允許編輯備註
                          ),
                        ],
                      ),
                    ),
                    
                    // 完成按鈕
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: (_isSaving || !_canModify()) ? null : _saveWorkoutRecord,
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
                          label: Text(_isSaving 
                              ? '保存中...' 
                              : (_isPastDate 
                                  ? '過去的訓練無法修改' 
                                  : (_isFutureDate 
                                      ? '未來的訓練無法完成' 
                                      : '完成訓練'))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32, 
                              vertical: 12,
                            ),
                            disabledBackgroundColor: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
        floatingActionButton: (!_isLoading && !_isPastDate) ? FloatingActionButton(
          onPressed: _addNewExercise,
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
        ) : null,
      ),
    );
  }
  
  @override
  void dispose() {
    // 在頁面關閉時，將數據變更狀態返回
    if (_isDataChanged && Navigator.canPop(context)) {
      Navigator.pop(context, true);  // 返回 true 表示數據已變更
    }
    _notesController.dispose();
    _newExerciseSetsController.dispose();
    _newExerciseRepsController.dispose();
    _newExerciseWeightController.dispose();
    _newExerciseRestController.dispose();
    super.dispose();
  }
} 