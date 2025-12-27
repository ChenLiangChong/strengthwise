import 'package:flutter/material.dart';
import '../../../../models/body_data_record.dart';

/// 最新身體數據卡片
class LatestBodyDataCard extends StatelessWidget {
  final BodyDataRecord record;

  const LatestBodyDataCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('最新記錄', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDataItem(
                    context,
                    icon: Icons.monitor_weight_outlined,
                    label: '體重',
                    value: '${record.weight.toStringAsFixed(1)} kg',
                    color: colorScheme.primary,
                  ),
                ),
                if (record.bodyFat != null)
                  Expanded(
                    child: _buildDataItem(
                      context,
                      icon: Icons.water_drop_outlined,
                      label: '體脂率',
                      value: '${record.bodyFat!.toStringAsFixed(1)}%',
                      color: colorScheme.secondary,
                    ),
                  ),
              ],
            ),
            if (record.bmi != null || record.muscleMass != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (record.bmi != null)
                    Expanded(
                      child: _buildDataItem(
                        context,
                        icon: Icons.straighten_outlined,
                        label: 'BMI',
                        value: record.bmi!.toStringAsFixed(1),
                        color: _getBMIColor(record.bmi!),
                        subtitle: record.getBMICategory(),
                      ),
                    ),
                  if (record.muscleMass != null)
                    Expanded(
                      child: _buildDataItem(
                        context,
                        icon: Icons.fitness_center_outlined,
                        label: '肌肉量',
                        value: '${record.muscleMass!.toStringAsFixed(1)} kg',
                        color: colorScheme.tertiary,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: textTheme.bodySmall?.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 24) return Colors.green;
    if (bmi < 27) return Colors.orange;
    return Colors.red;
  }
}

