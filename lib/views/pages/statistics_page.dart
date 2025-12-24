import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/statistics_model.dart';
import '../../controllers/interfaces/i_statistics_controller.dart';
import '../../services/service_locator.dart';
import 'package:fl_chart/fl_chart.dart';

/// 統計頁面
///
/// 顯示用戶的訓練統計數據和分析
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late IStatisticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<IStatisticsController>();

    // 初始化統計數據 - 使用 Firebase Auth 直接獲取當前用戶
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _controller.initialize(user.uid);
      } else {
        // 如果用戶未登入，顯示錯誤
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 檢查用戶是否登入
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('訓練統計'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                '請先登入',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('訓練統計'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  // 清除快取並重新載入
                  await _controller.refreshStatistics();
                }
              },
              tooltip: '重新載入',
            ),
          ],
        ),
        body: Consumer<IStatisticsController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          await controller.initialize(currentUser.uid);
                        }
                      },
                      child: const Text('重試'),
                    ),
                  ],
                ),
              );
            }

            if (!controller.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '還沒有訓練記錄',
                      style: TextStyle(
                          fontSize: 18,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '完成訓練後，這裡會顯示統計數據',
                      style: TextStyle(
                          fontSize: 14,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.refreshStatistics(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 時間選擇器
                      _buildTimeRangePicker(controller),
                      const SizedBox(height: 24),

                      // 訓練頻率卡片
                      _buildFrequencyCard(controller),
                      const SizedBox(height: 24),

                      // 訓練量趨勢圖
                      _buildVolumeChart(controller),
                      const SizedBox(height: 24),

                      // 身體部位分布
                      _buildBodyPartDistribution(controller),
                      const SizedBox(height: 24),

                      // 訓練建議
                      if (controller.suggestions.isNotEmpty)
                        _buildSuggestions(controller),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 構建時間範圍選擇器
  Widget _buildTimeRangePicker(IStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: TimeRange.values.map((range) {
            final isSelected = controller.timeRange == range;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(
                    range.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => controller.changeTimeRange(range),
                  selectedColor: Theme.of(context).primaryColor,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 構建訓練頻率卡片
  Widget _buildFrequencyCard(IStatisticsController controller) {
    final frequency = controller.statisticsData?.frequency;
    if (frequency == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${controller.timeRange.displayName}訓練',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.event_available,
                  label: '訓練次數',
                  value: '${frequency.totalWorkouts} 次',
                  comparison: frequency.comparisonPercentage,
                  hasGrowth: frequency.hasGrowth,
                ),
                _buildStatItem(
                  icon: Icons.access_time,
                  label: '總時長',
                  value: '${frequency.totalHours.toStringAsFixed(1)} 小時',
                ),
                _buildStatItem(
                  icon: Icons.local_fire_department,
                  label: '連續天數',
                  value: '${frequency.consecutiveDays} 天',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 構建單個統計項目
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    String? comparison,
    bool hasGrowth = false,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (comparison != null)
          Text(
            comparison,
            style: TextStyle(
              fontSize: 12,
              color: hasGrowth
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.red,
            ),
          ),
        const SizedBox(height: 4),
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

  /// 構建訓練量趨勢圖
  Widget _buildVolumeChart(IStatisticsController controller) {
    final volumeHistory = controller.statisticsData?.volumeHistory ?? [];
    if (volumeHistory.isEmpty) return const SizedBox.shrink();

    // 準備圖表數據
    final spots = volumeHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.totalVolume);
    }).toList();

    // 找出最大值用於 Y 軸範圍
    final maxVolume =
        volumeHistory.map((p) => p.totalVolume).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '訓練量趨勢',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value >= 1000) {
                            return Text(
                                '${(value / 1000).toStringAsFixed(0)}k');
                          }
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < volumeHistory.length) {
                            return Text(
                              volumeHistory[value.toInt()].formattedDate,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: maxVolume * 1.2, // 留 20% 空間
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 構建身體部位分布
  Widget _buildBodyPartDistribution(IStatisticsController controller) {
    final bodyPartStats = controller.statisticsData?.bodyPartStats ?? [];
    if (bodyPartStats.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '肌群訓練分布',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...bodyPartStats.map((stat) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              stat.bodyPart,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Text(
                            stat.formattedVolume,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            stat.formattedPercentage,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: stat.percentage,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getColorForBodyPart(stat.bodyPart),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// 構建訓練建議
  Widget _buildSuggestions(IStatisticsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '訓練建議',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...controller.suggestions.map((suggestion) {
              final icon = _getIconForSuggestionType(suggestion.type);
              final color = _getColorForSuggestionType(suggestion.type);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            suggestion.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
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

  /// 根據身體部位獲取顏色
  Color _getColorForBodyPart(String bodyPart) {
    const colors = {
      '胸': Colors.red,
      '背': Colors.blue,
      '肩': Colors.orange,
      '腿': Colors.green,
      '手': Colors.purple,
      '核心': Colors.teal,
      '臀': Colors.pink,
      '全身': Colors.indigo,
    };
    return colors[bodyPart] ?? Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// 根據建議類型獲取圖標
  IconData _getIconForSuggestionType(SuggestionType type) {
    switch (type) {
      case SuggestionType.warning:
        return Icons.warning;
      case SuggestionType.info:
        return Icons.info;
      case SuggestionType.success:
        return Icons.check_circle;
    }
  }

  /// 根據建議類型獲取顏色
  Color _getColorForSuggestionType(SuggestionType type) {
    switch (type) {
      case SuggestionType.warning:
        return Colors.orange;
      case SuggestionType.info:
        return Colors.blue;
      case SuggestionType.success:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
