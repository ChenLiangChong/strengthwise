import 'package:flutter/material.dart';
import '../../../../models/statistics_model.dart';

/// 統計卡片 Widget
///
/// 顯示訓練統計數據（進步幅度、當前最大、總組數、平均重量）
class StatisticsCard extends StatelessWidget {
  final ExerciseStrengthProgress progress;

  const StatisticsCard({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = progress.progressPercentage > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '訓練統計',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    '進步幅度',
                    progress.formattedProgress,
                    isPositive ? Icons.trending_up : Icons.trending_flat,
                    isPositive 
                        ? Theme.of(context).colorScheme.secondary 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '當前最大',
                    progress.formattedCurrentMax,
                    Icons.fitness_center,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    '總組數',
                    '${progress.totalSets}',
                    Icons.format_list_numbered,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '平均重量',
                    '${progress.averageWeight.toStringAsFixed(1)} kg',
                    Icons.balance,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

