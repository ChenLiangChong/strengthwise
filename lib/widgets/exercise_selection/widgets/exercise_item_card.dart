import 'package:flutter/material.dart';
import '../../../models/favorite_exercise_model.dart';
import '../../../utils/body_part_utils.dart';

/// 動作項目卡片組件
class ExerciseItemCard extends StatelessWidget {
  final ExerciseWithRecord exercise;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const ExerciseItemCard({
    Key? key,
    required this.exercise,
    required this.onTap,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildStats(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立動作卡片標題列
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.exerciseName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '最後訓練: ${exercise.formattedLastTrainingDate}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            exercise.isFavorite ? Icons.star : Icons.star_border,
            color: exercise.isFavorite
                ? Colors.amber
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: onToggleFavorite,
          tooltip: exercise.isFavorite ? '取消收藏' : '收藏',
        ),
      ],
    );
  }

  /// 建立動作統計資訊
  Widget _buildStats(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: BodyPartUtils.getBodyPartColor(context, exercise.bodyPart)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            exercise.bodyPart,
            style: TextStyle(
              fontSize: 11,
              color: BodyPartUtils.getBodyPartColor(context, exercise.bodyPart),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '最大重量: ${exercise.formattedMaxWeight}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

