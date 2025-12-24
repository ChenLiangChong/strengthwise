import 'package:flutter/material.dart';
import '../../models/custom_exercise_model.dart';
import '../../controllers/interfaces/i_custom_exercise_controller.dart';
import '../../services/error_handling_service.dart';
import '../../services/service_locator.dart';
import '../widgets/custom_exercise_dialog.dart';

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
      builder: (context) {
        return CustomExerciseDialog(
          onSubmit: (name) async {
            try {
              final newExercise = await _controller.addExercise(name);

              if (!mounted) return;

              setState(() {
                _exercises.insert(0, newExercise);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('成功添加自訂動作')),
              );
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
      builder: (context) {
        return CustomExerciseDialog(
          exercise: exercise,
          onSubmit: (name) async {
            try {
              await _controller.updateExercise(exercise.id, name);

              if (!mounted) return;

              final index = _exercises.indexWhere((e) => e.id == exercise.id);
              if (index != -1) {
                final updatedExercise = CustomExercise(
                  id: exercise.id,
                  name: name,
                  userId: exercise.userId,
                  createdAt: exercise.createdAt,
                );

                setState(() {
                  _exercises[index] = updatedExercise;
                });
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('成功更新自訂動作')),
              );
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

      setState(() {
        _exercises.removeWhere((e) => e.id == exerciseId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('成功刪除自訂動作')),
      );
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
            title: Text(exercise.name),
            subtitle: Text('創建於: ${_formatDate(exercise.createdAt)}'),
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
