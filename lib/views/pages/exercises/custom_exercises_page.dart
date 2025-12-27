import 'package:flutter/material.dart';
import '../../../models/custom_exercise_model.dart';
import '../../../controllers/interfaces/i_custom_exercise_controller.dart';
import '../../../services/core/error_handling_service.dart';
import '../../../services/service_locator.dart';
import '../../../utils/notification_utils.dart';
import '../../../widgets/exercises/custom_exercise_dialog.dart';

class CustomExercisesPage extends StatefulWidget {
  const CustomExercisesPage({super.key});

  @override
  _CustomExercisesPageState createState() => _CustomExercisesPageState();
}

class _CustomExercisesPageState extends State<CustomExercisesPage> {
  late final ICustomExerciseController _controller;
  late final ErrorHandlingService _errorService;

  List<CustomExercise> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 從服務定位器獲取依賴
    _controller = serviceLocator<ICustomExerciseController>();
    _errorService = serviceLocator<ErrorHandlingService>();

    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exercises = await _controller.getUserExercises();

      if (!mounted) return;

      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _errorService.handleLoadingError(context, e);
    }
  }

  Future<void> _addExercise() async {
    showDialog(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) {
        return CustomExerciseDialog(
          onSubmit: (data) async {
            try {
              final newExercise = await _controller.addExercise(
                name: data.name,
                trainingType: data.trainingType,
                bodyPart: data.bodyPart,
                equipment: data.equipment,
                description: data.description,
                notes: data.notes,
              );

              if (!mounted) return;

              // 🐛 修復：重新載入列表以確保數據同步
              await _loadExercises();

              NotificationUtils.showSuccess(context, '成功添加自訂動作');
            } catch (e) {
              if (!mounted) return;

              _errorService.handleSavingError(context, e);
            }
          },
        );
      },
    );
  }

  Future<void> _editExercise(CustomExercise exercise) async {
    showDialog(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) {
        return CustomExerciseDialog(
          exercise: exercise,
          onSubmit: (data) async {
            try {
              await _controller.updateExercise(
                exerciseId: exercise.id,
                name: data.name,
                trainingType: data.trainingType,
                bodyPart: data.bodyPart,
                equipment: data.equipment,
                description: data.description,
                notes: data.notes,
              );

              if (!mounted) return;

              // 重新載入列表以顯示更新後的資料
              await _loadExercises();

              NotificationUtils.showSuccess(context, '成功更新自訂動作');
            } catch (e) {
              if (!mounted) return;

              _errorService.handleSavingError(context, e);
            }
          },
        );
      },
    );
  }

  Future<void> _deleteExercise(String exerciseId) async {
    try {
      await _controller.deleteExercise(exerciseId);

      if (!mounted) return;

      // 🐛 修復：重新載入列表以確保數據同步
      await _loadExercises();

      NotificationUtils.showSuccess(context, '成功刪除自訂動作');
    } catch (e) {
      if (!mounted) return;

      _errorService.handleError(context, e);
    }
  }

  void _selectExercise(CustomExercise exercise) {
    final standardExercise = _controller.convertToExercise(exercise);
    Navigator.pop(context, standardExercise);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自訂動作'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? _buildEmptyState()
              : _buildExerciseList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        tooltip: '添加新的自訂動作',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '還沒有自訂動作',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '點擊右下角按鈕添加',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: 96, // 增加底部填充，避免被 FAB 遮擋
      ),
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getBodyPartColor(exercise.bodyPart),
              child: Icon(
                _getBodyPartIcon(exercise.bodyPart),
                color: Colors.white,
              ),
            ),
            title: Text(
              exercise.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // 使用 Wrap 替代 Row，允許自動換行
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(exercise.bodyPart),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports_handball, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(exercise.equipment),
                      ],
                    ),
                  ],
                ),
                if (exercise.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    exercise.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '創建於: ${_formatDate(exercise.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            onTap: () => _selectExercise(exercise),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editExercise(exercise),
                  tooltip: '編輯',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () =>
                      _showDeleteConfirmDialog(exercise.id, exercise.name),
                  tooltip: '刪除',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 根據身體部位返回顏色
  Color _getBodyPartColor(String bodyPart) {
    switch (bodyPart) {
      case '胸部':
        return Colors.red;
      case '背部':
        return Colors.blue;
      case '腿部':
        return Colors.green;
      case '肩部':
        return Colors.orange;
      case '手臂':
        return Colors.purple;
      case '核心':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// 根據身體部位返回圖標
  IconData _getBodyPartIcon(String bodyPart) {
    switch (bodyPart) {
      case '胸部':
        return Icons.self_improvement;
      case '背部':
        return Icons.accessibility_new;
      case '腿部':
        return Icons.directions_run;
      case '肩部':
        return Icons.sports_gymnastics;
      case '手臂':
        return Icons.back_hand;
      case '核心':
        return Icons.sports_martial_arts;
      default:
        return Icons.fitness_center;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  Future<void> _showDeleteConfirmDialog(
      String exerciseId, String exerciseName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除 "$exerciseName" 嗎？此操作不可撤銷。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteExercise(exerciseId);
    }
  }
}
