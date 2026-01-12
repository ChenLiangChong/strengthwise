import 'package:flutter/material.dart';
import '../../../../models/statistics_model.dart';
import '../../../../models/tracking_mode.dart';

/// 訓練歷史卡片 Widget
/// v3.3+ 支援多元追蹤模式
///
/// 顯示訓練歷史記錄列表
class TrainingHistoryCard extends StatelessWidget {
  final List<StrengthProgressPoint> history;

  const TrainingHistoryCard({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final reversedHistory = history.reversed.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '訓練歷史',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...reversedHistory.take(10).map(
              (record) => _buildHistoryItem(context, record),
            ),
            if (reversedHistory.length > 10) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '還有 ${reversedHistory.length - 10} 條記錄...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// v3.3+ 根據追蹤模式構建歷史記錄項目
  Widget _buildHistoryItem(
    BuildContext context,
    StrengthProgressPoint record,
  ) {
    final isWeightBased = record.trackingMode.isWeightBased;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // 日期
          SizedBox(
            width: 60,
            child: Text(
              record.formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // v3.3+ 根據追蹤模式顯示不同內容
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: record.isPR && isWeightBased
                    ? Colors.amber.withOpacity(0.1)
                    : Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: record.isPR && isWeightBased
                    ? Border.all(color: Colors.amber.withOpacity(0.3))
                    : null,
              ),
              child: Row(
                children: [
                  // PR 標記（只在重訓模式顯示）
                  if (record.isPR && isWeightBased) ...[
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                  ],
                  // v3.3+ 使用統一的格式化值
                  Text(
                    record.formattedValue,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // 1RM（只在重訓模式顯示）
                  if (isWeightBased)
                    Text(
                      '1RM: ${record.estimatedOneRM.toStringAsFixed(0)}kg',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

