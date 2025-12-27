import 'package:flutter/material.dart';
import '../../../../models/statistics_model.dart';

/// 個人記錄卡片組件
///
/// 顯示各身體部位的個人最佳記錄
class PersonalRecordsCard extends StatelessWidget {
  /// 個人記錄列表
  final List<PersonalRecord> records;

  /// 最多顯示的項目數量
  final int maxItems;

  const PersonalRecordsCard({
    Key? key,
    required this.records,
    this.maxItems = 6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox();

    // 按身體部位分組，每個部位只保留最高重量的記錄
    final Map<String, PersonalRecord> bestByBodyPart = {};
    for (var pr in records) {
      if (!bestByBodyPart.containsKey(pr.bodyPart) ||
          pr.maxWeight > bestByBodyPart[pr.bodyPart]!.maxWeight) {
        bestByBodyPart[pr.bodyPart] = pr;
      }
    }

    // 轉換為列表並按重量排序
    final topRecords = bestByBodyPart.values.toList()
      ..sort((a, b) => b.maxWeight.compareTo(a.maxWeight));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_events,
                      size: 20, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                const Text(
                  '個人最佳記錄',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '各部位 Top 1',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topRecords.take(maxItems).map((pr) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: pr.isNew
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.withOpacity(0.1),
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.05),
                          ],
                        )
                      : null,
                  border: Border.all(
                    color: pr.isNew
                        ? Colors.amber.withOpacity(0.3)
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.2),
                    width: pr.isNew ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            _getBodyPartColor(context, pr.bodyPart).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getBodyPartIcon(pr.bodyPart),
                        color: _getBodyPartColor(context, pr.bodyPart),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  pr.exerciseName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (pr.isNew) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getBodyPartColor(context, pr.bodyPart)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  pr.bodyPart,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getBodyPartColor(context, pr.bodyPart),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                pr.formattedDate,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${pr.maxWeight.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getBodyPartColor(context, pr.bodyPart),
                          ),
                        ),
                        Text(
                          'kg × ${pr.reps}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 根據身體部位返回顏色
  static Color _getBodyPartColor(BuildContext context, String bodyPart) {
    if (bodyPart.contains('胸')) return Colors.red;
    if (bodyPart.contains('背')) return Colors.blue;
    if (bodyPart.contains('腿')) return Theme.of(context).colorScheme.secondary;
    if (bodyPart.contains('肩')) return Theme.of(context).colorScheme.primary;
    if (bodyPart.contains('手')) return Theme.of(context).colorScheme.primary;
    if (bodyPart.contains('核心') || bodyPart.contains('腹')) return Colors.teal;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// 根據身體部位返回圖標
  static IconData _getBodyPartIcon(String bodyPart) {
    if (bodyPart.contains('胸')) return Icons.fitness_center;
    if (bodyPart.contains('背')) return Icons.accessibility_new;
    if (bodyPart.contains('腿')) return Icons.directions_run;
    if (bodyPart.contains('肩')) return Icons.sports_martial_arts;
    if (bodyPart.contains('手')) return Icons.sports_handball;
    if (bodyPart.contains('核心') || bodyPart.contains('腹')) {
      return Icons.self_improvement;
    }
    return Icons.fitness_center;
  }
}

