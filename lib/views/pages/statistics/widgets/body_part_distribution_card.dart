import 'package:flutter/material.dart';
import '../../../../models/statistics_model.dart';

/// 身體部位分布卡片組件
///
/// 顯示不同肌群的訓練量分布
class BodyPartDistributionCard extends StatelessWidget {
  /// 身體部位統計數據
  final List<BodyPartStats> stats;

  /// 最多顯示的項目數量
  final int maxItems;

  const BodyPartDistributionCard({
    Key? key,
    required this.stats,
    this.maxItems = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, size: 20),
                SizedBox(width: 8),
                Text(
                  '肌群訓練分布',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.take(maxItems).map(
                  (stat) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stat.bodyPart,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${stat.formattedVolume}  ${stat.formattedPercentage}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: stat.percentage,
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceVariant,
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

