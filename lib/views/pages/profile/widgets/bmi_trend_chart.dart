import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../models/body_data_record.dart';

/// BMI 趨勢圖表
class BMITrendChart extends StatelessWidget {
  final List<BodyDataRecord> records;

  const BMITrendChart({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final sortedRecords =
        List<BodyDataRecord>.from(records.where((r) => r.bmi != null))
          ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    final spots = sortedRecords
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.bmi!))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BMI 趨勢', style: textTheme.titleMedium),
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
                          return Text(value.toStringAsFixed(1),
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
                      color: colorScheme.secondary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.secondary.withOpacity(0.1),
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

