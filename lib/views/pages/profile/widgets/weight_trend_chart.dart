import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../models/body_data_record.dart';

/// 體重趨勢圖表
class WeightTrendChart extends StatelessWidget {
  final List<BodyDataRecord> records;

  const WeightTrendChart({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 按日期升序排列
    final sortedRecords = List<BodyDataRecord>.from(records)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    final spots = sortedRecords
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.weight))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('體重趨勢', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}kg',
                              style: textTheme.bodySmall);
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sortedRecords.length) {
                            return const SizedBox.shrink();
                          }
                          
                          // 只顯示特定位置的日期標籤，避免重複
                          final totalRecords = sortedRecords.length;
                          final showInterval = (totalRecords / 4).ceil().clamp(1, totalRecords);
                          
                          // 只在間隔位置顯示標籤
                          if (index % showInterval != 0 && index != totalRecords - 1) {
                            return const SizedBox.shrink();
                          }
                          
                          final date = sortedRecords[index].recordDate;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
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

