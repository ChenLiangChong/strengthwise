import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/theme_controller.dart';
import '../../themes/app_theme.dart';
import '../../utils/notification_utils.dart';
import '../widgets/exercise_card.dart';

/// 訓練 UI 測試頁面
/// 
/// 用於測試 Week 2 重構的卡片式訓練記錄介面
/// 展示 ExerciseCard 和 SetInputRow 組件
class WorkoutUITestPage extends StatefulWidget {
  const WorkoutUITestPage({super.key});

  @override
  State<WorkoutUITestPage> createState() => _WorkoutUITestPageState();
}

class _WorkoutUITestPageState extends State<WorkoutUITestPage> {
  // 模擬訓練數據
  late List<ExerciseCardData> _exercises;
  int? _activeSetNumber;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    _exercises = [
      // 槓鈴臥推
      ExerciseCardData(
        exerciseId: '1',
        exerciseName: '槓鈴臥推',
        targetSets: 3,
        targetReps: 10,
        targetWeight: 60,
        sets: [
          SetData(
            setNumber: 1,
            weight: 60,
            reps: 10,
            isCompleted: true,
            previousData: '55x10',
          ),
          SetData(
            setNumber: 2,
            weight: 60,
            reps: 9,
            isCompleted: true,
            previousData: '55x10',
          ),
          SetData(
            setNumber: 3,
            weight: null,
            reps: null,
            isCompleted: false,
            previousData: '55x8',
          ),
        ],
      ),
      
      // 上斜啞鈴臥推
      ExerciseCardData(
        exerciseId: '2',
        exerciseName: '上斜啞鈴臥推',
        targetSets: 3,
        targetReps: 12,
        targetWeight: 24,
        sets: [
          SetData(setNumber: 1, previousData: '22x12'),
          SetData(setNumber: 2, previousData: '22x12'),
          SetData(setNumber: 3, previousData: '22x10'),
        ],
      ),
      
      // 肩推
      ExerciseCardData(
        exerciseId: '3',
        exerciseName: '槓鈴肩推',
        targetSets: 3,
        targetReps: 8,
        targetWeight: 45,
        sets: [
          SetData(setNumber: 1, previousData: '40x8'),
          SetData(setNumber: 2, previousData: '40x8'),
          SetData(setNumber: 3, previousData: '40x6'),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      // ========================================
      // 固定頂部導航欄
      // ========================================
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '推力訓練 A',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '進行中 • 00:23:45',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          // 主題切換（測試用）
          IconButton(
            icon: Icon(themeController.themeModeIcon),
            onPressed: () {
              themeController.toggleTheme(context);
            },
            tooltip: '切換主題',
          ),
          // 完成按鈕
          TextButton(
            onPressed: () {
              NotificationUtils.showSuccess(context, '訓練已完成！');
            },
            child: const Text(
              '完成',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      
      // ========================================
      // 訓練內容
      // ========================================
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppTheme.spacingMd,
          bottom: 80, // 為 FAB 留出空間
        ),
        children: [
          // 動作卡片列表
          ..._exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            
            return ExerciseCard(
              data: exercise,
              isEditable: true,
              activeSetNumber: _activeSetNumber,
              onSetUpdate: (setNumber, weight, reps) {
                setState(() {
                  final setIndex = exercise.sets.indexWhere(
                    (s) => s.setNumber == setNumber,
                  );
                  if (setIndex != -1) {
                    exercise.sets[setIndex] = exercise.sets[setIndex].copyWith(
                      weight: weight,
                      reps: reps,
                    );
                  }
                });
              },
              onSetComplete: (setNumber) {
                setState(() {
                  final setIndex = exercise.sets.indexWhere(
                    (s) => s.setNumber == setNumber,
                  );
                  if (setIndex != -1) {
                    final currentSet = exercise.sets[setIndex];
                    exercise.sets[setIndex] = currentSet.copyWith(
                      isCompleted: !currentSet.isCompleted,
                    );
                    
                    // 如果勾選完成，自動移到下一組
                    if (!currentSet.isCompleted) {
                      _activeSetNumber = setNumber + 1;
                    }
                  }
                });
              },
              onAddSet: () {
                setState(() {
                  final newSetNumber = exercise.sets.length + 1;
                  exercise.sets.add(
                    SetData(
                      setNumber: newSetNumber,
                      previousData: exercise.sets.isNotEmpty
                          ? '${exercise.sets.last.weight ?? 0}x${exercise.sets.last.reps ?? 0}'
                          : null,
                    ),
                  );
                  _activeSetNumber = newSetNumber;
                });
              },
              onMenuTap: () {
                _showExerciseMenu(context, index);
              },
            );
          }),
          
          // 新增動作按鈕
          _buildAddExerciseButton(context),
          
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
      
      // ========================================
      // 浮動操作按鈕（測試說明）
      // ========================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showTestInfo(context);
        },
        icon: const Icon(Icons.info_outline),
        label: const Text('測試說明'),
      ),
    );
  }

  /// 構建新增動作按鈕
  Widget _buildAddExerciseButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingMd,
      ),
      child: OutlinedButton(
        onPressed: () {
          NotificationUtils.showInfo(context, '新增動作功能開發中...');
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(
            color: colorScheme.outline,
            width: 2,
            style: BorderStyle.solid,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: colorScheme.onSurface.withOpacity(0.6)),
            const SizedBox(width: 8),
            Text(
              '加入動作',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顯示動作菜單
  void _showExerciseMenu(BuildContext context, int exerciseIndex) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('替換動作'),
                onTap: () {
                  Navigator.pop(context);
                  NotificationUtils.showInfo(context, '替換動作功能開發中...');
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('查看歷史'),
                onTap: () {
                  Navigator.pop(context);
                  NotificationUtils.showInfo(context, '查看歷史功能開發中...');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('刪除動作'),
                textColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _exercises.removeAt(exerciseIndex);
                  });
                  NotificationUtils.showSuccess(context, '動作已刪除');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 顯示測試說明
  void _showTestInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Week 2 UI 測試頁面'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '✨ 新功能展示',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• 卡片式動作佈局'),
                Text('• JetBrains Mono 數據字體'),
                Text('• 觸覺回饋（勾選完成時）'),
                Text('• 自動聚焦下一組'),
                Text('• 鍵盤行動（Next/Done）'),
                SizedBox(height: 16),
                Text(
                  '🧪 測試項目',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('1. 輸入重量和次數'),
                Text('2. 勾選完成（感受觸覺回饋）'),
                Text('3. 新增組數'),
                Text('4. 點擊菜單按鈕'),
                Text('5. 切換深色/淺色模式'),
                SizedBox(height: 16),
                Text(
                  '📝 注意',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('這是測試頁面，數據不會保存。'),
                Text('Week 2 完成後會整合到真實頁面。'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('了解'),
            ),
          ],
        );
      },
    );
  }
}

