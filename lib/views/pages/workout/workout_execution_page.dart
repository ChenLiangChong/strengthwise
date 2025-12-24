import 'package:flutter/material.dart';
import '../../../models/exercise_model.dart';
import '../../../controllers/interfaces/i_workout_controller.dart';
import '../../../controllers/interfaces/i_workout_execution_controller.dart';
import '../../../services/error_handling_service.dart';
import '../../../services/service_locator.dart';
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
  late final IWorkoutController _workoutController;
  late final IWorkoutExecutionController _executionController;
  late final ErrorHandlingService _errorService;
  
  // 計時器相關變數
  DateTime? _workoutStartTime;
  DateTime? _workoutEndTime;
  String _elapsedTime = '00:00:00';

  // 新增運動的控制器
  final TextEditingController _newExerciseSetsController = TextEditingController(text: '3');
  final TextEditingController _newExerciseRepsController = TextEditingController(text: '10');
  final TextEditingController _newExerciseWeightController = TextEditingController(text: '0');
  final TextEditingController _newExerciseRestController = TextEditingController(text: '60');
  
  // 訓練備註控制器
  final TextEditingController _workoutNotesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // 從服務定位器獲取依賴
    _workoutController = serviceLocator<IWorkoutController>();
    _executionController = serviceLocator<IWorkoutExecutionController>();
    _errorService = serviceLocator<ErrorHandlingService>();
    
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
        _startTimer(); // 遞迴調用以繼續計時
      }
    });
  }
  
  // 加載訓練計畫
  Future<void> _loadWorkoutPlan() async {
    await _executionController.loadWorkoutPlan(widget.workoutRecordId);
    
    // 載入備註到控制器
    _workoutNotesController.text = _executionController.getNotes();
    
    setState(() {}); // 觸發重新構建
  }
  
  @override
  void dispose() {
    _newExerciseSetsController.dispose();
    _newExerciseRepsController.dispose();
    _newExerciseWeightController.dispose();
    _newExerciseRestController.dispose();
    _workoutNotesController.dispose();
    super.dispose();
  }
  
  // 顯示無法修改的提示消息
  void _showCannotEditMessage() {
    if (_executionController.isPastDate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法編輯過去的訓練記錄')),
      );
    }
  }
  
  // 顯示無法勾選完成的提示消息
  void _showCannotToggleCompletionMessage() {
    if (_executionController.isFutureDate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未來的訓練無法勾選完成，請在訓練當天標記')),
      );
    } else if (_executionController.isPastDate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法修改過去的訓練記錄')),
      );
    }
  }
  
  // 保存訓練記錄
  Future<void> _saveWorkoutRecord() async {
    final success = await _executionController.saveWorkoutRecord(context: context);
    if (success) {
      Navigator.pop(context, true);
    }
  }
  
  // 新增：添加新的訓練動作
  void _addNewExercise() async {
    // 檢查是否可以編輯（過去的訓練不能編輯）
    if (!_executionController.canEdit()) {
      _showCannotEditMessage();
      return;
    }
    
    // 導航到運動選擇頁面
    final result = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExercisesPage(),
        fullscreenDialog: true,  // 使用全屏對話框風格打開頁面
      ),
    );

    // 如果用戶選擇了運動，添加到列表中
    if (result != null) {
      // 顯示設置對話框
      _showExerciseSettingsDialog(result);
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
              
              // 先關閉對話框
              Navigator.pop(context);
              
              // 使用控制器添加新動作
              await _executionController.addNewExercise(
                exercise, 
                sets, 
                reps, 
                weight, 
                restTime,
                context: context,
              );
              
              setState(() {}); // 觸發重新構建
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
    // 檢查是否可以編輯（過去的訓練不能刪除）
    if (!_executionController.canEdit()) {
      _showCannotEditMessage();
      return;
    }
    
    final exerciseRecords = _executionController.getExerciseRecords();
    if (exerciseIndex >= exerciseRecords.length) return;
    
    final exercise = exerciseRecords[exerciseIndex];
    
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
              // 先關閉對話框
              Navigator.pop(context);
              
              // 使用控制器刪除運動
              await _executionController.deleteExercise(exerciseIndex, context: context);
              
              setState(() {}); // 觸發重新構建
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
    final exerciseRecords = _executionController.getExerciseRecords();
    if (index >= exerciseRecords.length) return const SizedBox.shrink();
    
    final exercise = exerciseRecords[index];
    final isCurrentExercise = index == _executionController.getCurrentExerciseIndex();
    
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '總組數: ${exercise.sets.length}組',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // 添加備註按鈕
                    IconButton(
                      icon: const Icon(Icons.note_add_outlined),
                      color: Colors.blue,
                      onPressed: () => _addExerciseNote(index),
                      tooltip: '添加備註',
                    ),
                    // 設為當前運動按鈕
                    if (!isCurrentExercise)
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline),
                        color: Colors.green,
                        onPressed: () {
                          setState(() {
                            _executionController.setCurrentExerciseIndex(index);
                          });
                        },
                        tooltip: '設為當前運動',
                      ),
                    // 添加刪除按鈕（過去的訓練不能刪除）
                    if (_executionController.canEdit())
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
                        color: _executionController.canEdit() ? Colors.blue : Colors.grey,
                        onPressed: () => _updateSetData(index, setIndex),
                        tooltip: '編輯組數',
                      ),
                      // 根據是否可以修改來顯示不同的完成狀態指示器
                      if (!_executionController.canToggleCompletion())
                        // 過去或未來的訓練：只顯示圖標，點擊顯示提示
                        GestureDetector(
                          onTap: _showCannotToggleCompletionMessage,
                          child: Icon(
                            set.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: set.completed ? Colors.green : Colors.grey,
                          ),
                        )
                      else
                        // 今天的訓練：可以勾選完成
                        Checkbox(
                          value: set.completed,
                          activeColor: Colors.green,
                          onChanged: (value) {
                            _executionController.toggleSetCompletion(index, setIndex, context: context);
                            setState(() {}); // 觸發重新構建
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
            // 新增：增加組數按鈕（過去的訓練不能增加組數）
            if (_executionController.canEdit())
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('增加組數'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                    onPressed: () {
                      _executionController.addSetToExercise(index, context: context);
                      setState(() {}); // 觸發重新構建
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // 設置訓練時間
  void _setTrainingHour() async {
    // 是否允許修改
    final canModifyTime = !_executionController.isPastDate(); // 過去的訓練不能修改時間
    
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
                  const Text('選擇訓練開始的小時', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(24, (hour) {
                      return ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, hour);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(50, 40),
                        ),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: const TextStyle(fontSize: 14),
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
        ],
      ),
    );
    
    if (selectedHour != null) {
      // 使用控制器設置訓練時間
      await _executionController.setTrainingHour(selectedHour, context: context);
      setState(() {}); // 觸發重新構建
    }
  }
  
  // 更新一組訓練的實際數據
  void _updateSetData(int exerciseIndex, int setIndex) {
    // 檢查是否可以編輯（過去的訓練不能編輯）
    if (!_executionController.canEdit()) {
      _showCannotEditMessage();
      return;
    }
    
    final exerciseRecords = _executionController.getExerciseRecords();
    if (exerciseIndex >= exerciseRecords.length) return;
    
    final exercise = exerciseRecords[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;
    
    final currentSet = exercise.sets[setIndex];
    
    // 創建控制器並設置初始值
    final repsController = TextEditingController(text: currentSet.reps.toString());
    final weightController = TextEditingController(text: currentSet.weight.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('修改 ${exercise.exerciseName} 第 ${currentSet.setNumber} 組'),
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
            onPressed: () async {
              // 解析輸入
              final reps = int.tryParse(repsController.text) ?? currentSet.reps;
              final weight = double.tryParse(weightController.text) ?? currentSet.weight;
              
              // 先關閉對話框
              Navigator.pop(context);
              
              // 使用控制器更新數據
              await _executionController.updateSetData(
                exerciseIndex, 
                setIndex, 
                reps, 
                weight,
                context: context,
              );
              
              setState(() {}); // 觸發重新構建
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
    // 檢查是否可以編輯（過去的訓練不能編輯）
    if (!_executionController.canEdit()) {
      _showCannotEditMessage();
      return;
    }
    
    final exerciseRecords = _executionController.getExerciseRecords();
    if (exerciseIndex >= exerciseRecords.length) return;
    
    final exercise = exerciseRecords[exerciseIndex];
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
              
              // 使用控制器添加備註
              await _executionController.addExerciseNote(
                exerciseIndex, 
                notesController.text,
                context: context,
              );
              
              setState(() {}); // 觸發重新構建
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
  
  @override
  Widget build(BuildContext context) {
    final isLoading = _executionController.isLoading;
    final isSaving = _executionController.isSaving;
    final exerciseRecords = _executionController.getExerciseRecords();
    
    return PopScope(
      canPop: false,  // 攔截返回
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // 如果有未保存的變更，自動保存
        if (_executionController.isDataChanged && _executionController.canModify()) {
          await _executionController.saveWorkoutRecord(context: context);
        }
        
        // 返回上一頁
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_executionController.getPlanTitle()),
          actions: [
            // 設置訓練時間按鈕
            IconButton(
              icon: const Icon(Icons.access_time),
              onPressed: _setTrainingHour,
              tooltip: '設置訓練時間',
            ),
            // 完成訓練按鈕
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _saveWorkoutRecord,
              tooltip: '完成訓練',
            ),
          ],
        ),
      body: isLoading || isSaving
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 頂部信息卡片
                Card(
                  margin: const EdgeInsets.all(16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '訓練類型:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(_executionController.getPlanType()),
                                ],
                              ),
                            ),
                            // 訓練計時器
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  '訓練時間:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(_elapsedTime),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '運動數量:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text('${exerciseRecords.length} 個運動, ${_executionController.calculateTotalSets()} 組'),
                                ],
                              ),
                            ),
                            // 總訓練量
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  '總訓練量:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text('${_executionController.calculateTotalVolume().toStringAsFixed(1)} kg'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 備註輸入框
                        TextField(
                          controller: _workoutNotesController,
                          decoration: const InputDecoration(
                            labelText: '訓練備註',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          onChanged: (value) {
                            _executionController.setNotes(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 訓練動作列表
                Expanded(
                  child: exerciseRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.fitness_center,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '還沒有添加運動',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _addNewExercise,
                                icon: const Icon(Icons.add),
                                label: const Text('添加運動'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: exerciseRecords.length,
                          itemBuilder: (context, index) {
                            return _buildExerciseCard(index);
                          },
                        ),
                ),
              ],
            ),
        // 添加運動的浮動按鈕（過去的訓練不能新增動作）
        floatingActionButton: _executionController.canEdit() && exerciseRecords.isNotEmpty
            ? FloatingActionButton(
                onPressed: _addNewExercise,
                backgroundColor: Colors.green,
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
} 