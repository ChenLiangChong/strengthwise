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
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${record.weight.toInt()}'),
                  ),
                  title: Text('${record.weight.toStringAsFixed(1)} kg'),
                  subtitle: Text(_formatDate(record.recordDate)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (record.bmi != null)
                        Chip(
                          label: Text('BMI ${record.bmi!.toStringAsFixed(1)}'),
                          backgroundColor:
                              _getBMIColor(record.bmi!).withOpacity(0.2),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDelete(record),
                      ),
                    ],
                  ),
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

