import 'package:flutter/material.dart';
import '../../../../models/statistics_model.dart';

/// 完成率 Tab 頁面
///
/// 顯示訓練完成率統計和分析
class CompletionRateTab extends StatelessWidget {
  /// 統計數據
  final StatisticsData data;

  const CompletionRateTab({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completion = data.completionRate;
    if (completion == null) {
      return const Center(child: Text('還沒有完成率數據'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 完成率總覽
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    completion.formattedCompletionRate,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '總完成率',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: completion.completionRate,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    minHeight: 12,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        '計劃組數',
                        completion.totalPlannedSets.toString(),
                      ),
                      _buildStatItem(
                        context,
                        '完成組數',
                        completion.completedSets.toString(),
                      ),
                      _buildStatItem(
                        context,
                        '失敗組數',
                        completion.failedSets.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 狀態評估
          if (completion.isExcellent)
            _buildStatusCard(
              context,
              '優秀！',
              '您的完成率非常高，保持下去！',
              Icons.emoji_events,
              Theme.of(context).colorScheme.secondary,
            )
          else if (completion.needsAdjustment)
            _buildStatusCard(
              context,
              '需要調整',
              '完成率較低，建議調整訓練計劃或減輕重量',
              Icons.warning,
              Theme.of(context).colorScheme.primary,
            ),

          const SizedBox(height: 16),

          // 弱點動作
          if (completion.weakPoints.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '需要關注的動作',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...completion.weakPoints.map((exercise) {
                      final failedCount =
                          completion.incompleteExercises[exercise] ?? 0;
                      return ListTile(
                        leading: Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(exercise),
                        trailing: Text('$failedCount 組未完成'),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 構建統計項
  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  /// 構建狀態卡片
  Widget _buildStatusCard(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

