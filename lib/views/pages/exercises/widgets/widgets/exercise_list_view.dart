import 'package:flutter/material.dart';
import 'package:strengthwise/models/favorite_exercise_model.dart';
import 'exercise_item_card.dart';

/// 動作列表視圖組件
class ExerciseListView extends StatelessWidget {
  final List<ExerciseWithRecord> exercises;
  final Function(ExerciseWithRecord exercise)? onExerciseSelected;
  final Function(ExerciseWithRecord exercise) onToggleFavorite;

  const ExerciseListView({
    Key? key,
    required this.exercises,
    this.onExerciseSelected,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text('沒有找到動作'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        ...exercises.map((exercise) => ExerciseItemCard(
              exercise: exercise,
              onTap: () => onExerciseSelected?.call(exercise),
              onToggleFavorite: () => onToggleFavorite(exercise),
            )),
      ],
    );
  }

  /// 建立動作列表標題
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 選擇動作',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '💡 數字表示你有訓練記錄的動作數量',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
