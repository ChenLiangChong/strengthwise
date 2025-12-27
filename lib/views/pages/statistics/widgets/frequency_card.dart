import 'package:flutter/material.dart';
import '../../../../models/statistics_model.dart';

/// 訓練頻率卡片組件
///
/// 顯示本週訓練次數、總時長、連續天數等統計
class FrequencyCard extends StatelessWidget {
  /// 訓練頻率數據
  final TrainingFrequency frequency;

  const FrequencyCard({
    Key? key,
    required this.frequency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fitness_center, size: 20),
                SizedBox(width: 8),
                Text(
                  '本週訓練',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFrequencyStat(
                  context,
                  Icons.check_circle,
                  '${frequency.totalWorkouts} 次',
                  '訓練次數',
                  frequency.comparisonPercentage,
                ),
                _buildFrequencyStat(
                  context,
                  Icons.access_time,
                  '${frequency.totalHours.toStringAsFixed(1)} 小時',
                  '總時長',
                  null,
                ),
                _buildFrequencyStat(
                  context,
                  Icons.local_fire_department,
                  '${frequency.consecutiveDays} 天',
                  '連續天數',
                  null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 構建單個統計項
  Widget _buildFrequencyStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    String? comparison,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (comparison != null && comparison != '0')
          Text(
            comparison,
            style: TextStyle(
              color: comparison.startsWith('+')
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.red,
              fontSize: 12,
            ),
          ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

