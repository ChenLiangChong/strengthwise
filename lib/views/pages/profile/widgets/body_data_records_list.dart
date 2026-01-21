import 'package:flutter/material.dart';
import '../../../../models/body_data_record.dart';

/// 身體數據歷史記錄列表
class BodyDataRecordsList extends StatelessWidget {
  final List<BodyDataRecord> records;
  final Function(BodyDataRecord) onDelete;

  const BodyDataRecordsList({
    super.key,
    required this.records,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('歷史記錄', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final record = records[index];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // 響應式斷點：< 350 為小螢幕
                    final isCompact = constraints.maxWidth < 350;

                    if (isCompact) {
                      // 小螢幕：垂直佈局，簡化顯示
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${record.weight.toStringAsFixed(1)} kg',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(record.recordDate),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (record.bmi != null)
                                    Builder(
                                      builder: (context) {
                                        final bmi = record.bmi!;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              'BMI ${bmi.toStringAsFixed(1)}',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: _getBMIColor(bmi),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => onDelete(record),
                            ),
                          ],
                        ),
                      );
                    }

                    // 大螢幕：標準 ListTile 佈局
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text('${record.weight.toInt()}'),
                      ),
                      title: Text('${record.weight.toStringAsFixed(1)} kg'),
                      subtitle: Text(_formatDate(record.recordDate)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (record.bmi != null)
                            Builder(
                              builder: (context) {
                                final bmi = record.bmi!;
                                return Chip(
                                  label: Text('BMI ${bmi.toStringAsFixed(1)}'),
                                  backgroundColor: _getBMIColor(bmi)
                                      .withValues(alpha: 0.2),
                                );
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => onDelete(record),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 24) return Colors.green;
    if (bmi < 27) return Colors.orange;
    return Colors.red;
  }
}
