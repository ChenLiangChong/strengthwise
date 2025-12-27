import 'package:flutter/material.dart';
import '../../../../models/statistics_model.dart';

/// 訓練日曆 Tab 頁面
///
/// 顯示訓練日曆熱力圖和統計
class CalendarTab extends StatelessWidget {
  /// 統計數據
  final StatisticsData data;

  const CalendarTab({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final calendar = data.calendarData;
    if (calendar == null || calendar.days.isEmpty) {
      return const Center(child: Text('還沒有訓練日曆數據'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 統計卡片
          Row(
            children: [
              Expanded(
                child: _buildCalendarStatCard(
                  context,
                  '訓練天數',
                  calendar.trainingDays.toString(),
                  Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCalendarStatCard(
                  context,
                  '最長連續',
                  '${calendar.maxStreak} 天',
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCalendarStatCard(
                  context,
                  '當前連續',
                  '${calendar.currentStreak} 天',
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCalendarStatCard(
                  context,
                  '平均訓練量',
                  '${calendar.averageVolume.toStringAsFixed(0)} kg',
                  Icons.show_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 熱力圖
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '訓練熱力圖',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildHeatmap(context, calendar.days),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 構建統計卡片
  Widget _buildCalendarStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 構建熱力圖
  Widget _buildHeatmap(BuildContext context, List<TrainingCalendarDay> days) {
    // 按週分組
    final weeks = <List<TrainingCalendarDay>>[];
    List<TrainingCalendarDay> currentWeek = [];

    for (var day in days) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return Column(
      children: [
        // 星期標題
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['日', '一', '二', '三', '四', '五', '六'].map((day) {
            return SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // 熱力圖
        ...weeks.map((week) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: week.map((day) {
                return _buildHeatmapCell(context, day);
              }).toList(),
            ),
          );
        }),
        const SizedBox(height: 16),
        // 圖例
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '少',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            ...[0, 1, 2, 3, 4].map((level) {
              return Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _getHeatmapColor(context, level),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
            const SizedBox(width: 8),
            Text(
              '多',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 構建熱力圖單元格
  Widget _buildHeatmapCell(BuildContext context, TrainingCalendarDay day) {
    return Tooltip(
      message: day.hasWorkout
          ? '${day.formattedDate}\n訓練量: ${day.totalVolume.toStringAsFixed(0)} kg'
          : '${day.formattedDate}\n休息日',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getHeatmapColor(context, day.intensity),
          borderRadius: BorderRadius.circular(8),
          border: day.isToday ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Center(
          child: Text(
            day.date.day.toString(),
            style: TextStyle(
              fontSize: 12,
              color: day.intensity > 1 ? Colors.white : Colors.black54,
              fontWeight: day.isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// 根據訓練強度返回顏色
  static Color _getHeatmapColor(BuildContext context, int intensity) {
    final surfaceVariant = Theme.of(context).colorScheme.surfaceVariant;
    final secondary = Theme.of(context).colorScheme.secondary;
    switch (intensity) {
      case 0:
        return surfaceVariant;
      case 1:
        return secondary.withOpacity(0.2);
      case 2:
        return secondary.withOpacity(0.5);
      case 3:
        return secondary.withOpacity(0.7);
      case 4:
        return secondary;
      default:
        return surfaceVariant;
    }
  }
}

