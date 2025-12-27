import 'package:flutter/material.dart';
import '../../../../models/workout_exercise_model.dart';

/// 計劃動作卡片（顯示和編輯）
class PlanExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final VoidCallback onBatchEdit;
  final VoidCallback onDelete;
  final Function(int setIndex) onEditSet;
  final Function(int delta) onAdjustSets;

  const PlanExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.onBatchEdit,
    required this.onDelete,
    required this.onEditSet,
    required this.onAdjustSets,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key(exercise.id),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 動作標題和操作按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exercise.equipment} | ${exercise.bodyParts.join(", ")}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      iconSize: 24,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: onBatchEdit,
                      tooltip: '批量編輯',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 24,
                      color: Theme.of(context).colorScheme.error,
                      onPressed: onDelete,
                      tooltip: '刪除動作',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            
            // 組數調整
            Row(
              children: [
                Text(
                  '訓練組數',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 24,
                  color: exercise.sets > 1
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  onPressed: exercise.sets > 1 ? () => onAdjustSets(-1) : null,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
                Text(
                  '${exercise.sets} 組',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 24,
                  color: exercise.sets < 10
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  onPressed: exercise.sets < 10 ? () => onAdjustSets(1) : null,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 每組詳情
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exercise.sets,
              itemBuilder: (context, setIndex) {
                // 獲取這一組的目標
                int targetReps;
                double targetWeight;

                if (exercise.setTargets != null &&
                    setIndex < exercise.setTargets!.length) {
                  final target = exercise.setTargets![setIndex];
                  targetReps = target['reps'] as int? ?? exercise.reps;
                  targetWeight = (target['weight'] as num?)?.toDouble() ?? exercise.weight;
                } else {
                  targetReps = exercise.reps;
                  targetWeight = exercise.weight;
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  minVerticalPadding: 8,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: Text('${setIndex + 1}'),
                  ),
                  title: Text(
                    '第 ${setIndex + 1} 組',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    '$targetReps 次 × $targetWeight kg',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 24,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () => onEditSet(setIndex),
                    tooltip: '編輯',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                );
              },
            ),
            
            // 休息時間和備註
            if (exercise.restTime != 90 || exercise.notes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  if (exercise.restTime != 90)
                    Text(
                      '休息: ${exercise.restTime}秒',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  if (exercise.notes.isNotEmpty)
                    Text(
                      '備註: ${exercise.notes}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

