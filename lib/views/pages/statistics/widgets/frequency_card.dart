// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import '../../../../models/statistics_model.dart';

/// 訓練頻率卡片組件
///
/// 顯示訓練次數、總時長、連續天數等統計
/// 標題會根據 [timeRange] 動態顯示（本週/本月/三個月/本年）
class FrequencyCard extends StatelessWidget {
  /// 訓練頻率數據
  final TrainingFrequency frequency;

  /// 當前時間範圍（用於顯示標題）
  final TimeRange timeRange;

  const FrequencyCard({
    Key? key,
    required this.frequency,
    required this.timeRange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: context.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${timeRange.displayName}訓練',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 第一行：訓練計劃總數、完整完成、部分完成
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFrequencyStat(
                  context,
                  Icons.event_note,
                  '${frequency.scheduledWorkouts} 次',
                  '訓練計劃',
                  frequency.comparisonPercentage,
                ),
                _buildFrequencyStat(
                  context,
                  Icons.check_circle,
                  '${frequency.completedWorkouts} 次',
                  '完整完成',
                  null,
                  color: Colors.green,
                ),
                _buildFrequencyStat(
                  context,
                  Icons.timelapse,
                  '${frequency.partialWorkouts} 次',
                  '部分完成',
                  null,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 第二行：訓練天數、總時長、連續天數
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFrequencyStat(
                  context,
                  Icons.calendar_today,
                  '${frequency.trainingDays} 天',
                  '訓練天數',
                  null,
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
    String? comparison, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 32),
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

