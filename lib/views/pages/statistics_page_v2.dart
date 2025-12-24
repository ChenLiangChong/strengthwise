import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/statistics_model.dart';
import '../../controllers/interfaces/i_statistics_controller.dart';
import '../../services/service_locator.dart';
import '../../services/interfaces/i_favorites_service.dart';
import '../widgets/favorite_exercises_list.dart';
import '../widgets/exercise_selection_navigator.dart';
import 'exercise_strength_detail_page.dart';

/// 統計頁面（專業版）
///
/// 包含力量進步、肌群平衡、訓練日曆等專業統計功能
class StatisticsPageV2 extends StatefulWidget {
  const StatisticsPageV2({Key? key}) : super(key: key);

  @override
  State<StatisticsPageV2> createState() => _StatisticsPageV2State();
}

class _StatisticsPageV2State extends State<StatisticsPageV2> with SingleTickerProviderStateMixin {
  late IStatisticsController _controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<IStatisticsController>();
    _tabController = TabController(length: 5, vsync: this);

    // 初始化統計數據
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _controller.initialize(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 檢查用戶是否登入
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('訓練統計')),
        body: const Center(child: Text('請先登入')),
      );
    }

    return ChangeNotifierProvider<IStatisticsController>.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('訓練統計'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _controller.refreshStatistics();
              },
              tooltip: '重新載入',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: '概覽', icon: Icon(Icons.dashboard, size: 20)),
              Tab(text: '力量進步', icon: Icon(Icons.trending_up, size: 20)),
              Tab(text: '肌群平衡', icon: Icon(Icons.pie_chart, size: 20)),
              Tab(text: '訓練日曆', icon: Icon(Icons.calendar_month, size: 20)),
              Tab(text: '完成率', icon: Icon(Icons.check_circle, size: 20)),
            ],
          ),
        ),
        body: Consumer<IStatisticsController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(controller.errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.initialize(user.uid),
                      child: const Text('重試'),
                    ),
                  ],
                ),
              );
            }

            final data = controller.statisticsData;
            if (data == null || !data.hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('還沒有訓練記錄'),
                    SizedBox(height: 8),
                    Text('開始訓練後就能看到統計數據了！', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // 時間範圍選擇器
                _buildTimeRangeSelector(controller),
                // Tab 內容
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(data, controller),
                      _buildStrengthProgressTab(data),
                      _buildMuscleBalanceTab(data),
                      _buildCalendarTab(data),
                      _buildCompletionRateTab(data),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 時間範圍選擇器
  Widget _buildTimeRangeSelector(IStatisticsController controller) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        children: TimeRange.values.map((range) {
          final isSelected = controller.timeRange == range;
          return ChoiceChip(
            label: Text(range.displayName),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                controller.changeTimeRange(range);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  /// 概覽 Tab
  Widget _buildOverviewTab(StatisticsData data, IStatisticsController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 訓練頻率卡片
          _buildFrequencyCard(data.frequency),
          const SizedBox(height: 16),
          
          // 訓練量趨勢圖
          _buildVolumeTrendCard(data.volumeHistory),
          const SizedBox(height: 16),
          
          // 身體部位分布
          _buildBodyPartDistributionCard(data.bodyPartStats),
          const SizedBox(height: 16),
          
          // 個人記錄
          _buildPersonalRecordsCard(data.personalRecords),
          const SizedBox(height: 16),
          
          // 訓練建議
          if (controller.suggestions.isNotEmpty)
            _buildSuggestionsCard(controller.suggestions),
        ],
      ),
    );
  }

  /// 訓練頻率卡片
  Widget _buildFrequencyCard(TrainingFrequency frequency) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fitness_center, size: 20),
                SizedBox(width: 8),
                Text('本週訓練', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFrequencyStat(
                  Icons.check_circle,
                  '${frequency.totalWorkouts} 次',
                  '訓練次數',
                  frequency.comparisonPercentage,
                ),
                _buildFrequencyStat(
                  Icons.access_time,
                  '${frequency.totalHours.toStringAsFixed(1)} 小時',
                  '總時長',
                  null,
                ),
                _buildFrequencyStat(
                  Icons.local_fire_department,
                  '${frequency.consecutiveDays} 天',
                  '連續天數',
                  null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyStat(IconData icon, String value, String label, String? comparison) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 32),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (comparison != null && comparison != '0')
          Text(comparison, style: TextStyle(
            color: comparison.startsWith('+') ? Colors.green : Colors.red,
            fontSize: 12,
          )),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  /// 訓練量趨勢圖卡片（美化版）
  Widget _buildVolumeTrendCard(List<TrainingVolumePoint> history) {
    if (history.isEmpty) return const SizedBox();

    // 找出最大值用於設置 Y 軸範圍
    final maxVolume = history.map((p) => p.totalVolume).reduce((a, b) => a > b ? a : b);
    final maxY = (maxVolume * 1.2).ceilToDouble(); // 增加 20% 留白

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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.show_chart, size: 20, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text('訓練量趨勢', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) {
                          if (value >= 1000) {
                            return Text(
                              '${(value / 1000).toStringAsFixed(1)}k',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            );
                          }
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < history.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                history[value.toInt()].formattedDate,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                      left: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: history.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.totalVolume);
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: Colors.blue,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: Colors.blue,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue.withOpacity(0.3),
                            Colors.blue.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final point = history[barSpot.x.toInt()];
                          return LineTooltipItem(
                            '${point.formattedDate}\n${(point.totalVolume / 1000).toStringAsFixed(1)}k kg',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 身體部位分布卡片
  Widget _buildBodyPartDistributionCard(List<BodyPartStats> stats) {
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
                Text('肌群訓練分布', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ...stats.take(5).map((stat) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(stat.bodyPart, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('${stat.formattedVolume}  ${stat.formattedPercentage}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: stat.percentage,
                    backgroundColor: Colors.grey[200],
                    minHeight: 8,
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// 個人記錄卡片（按身體部位分類，只顯示每個部位的最高紀錄）
  Widget _buildPersonalRecordsCard(List<PersonalRecord> records) {
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
                  child: const Icon(Icons.emoji_events, size: 20, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                const Text('個人最佳記錄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  '各部位 Top 1',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topRecords.take(6).map((pr) {
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
                            Colors.orange.withOpacity(0.05),
                          ],
                        )
                      : null,
                  border: Border.all(
                    color: pr.isNew ? Colors.amber.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
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
                        color: _getBodyPartColor(pr.bodyPart).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getBodyPartIcon(pr.bodyPart),
                        color: _getBodyPartColor(pr.bodyPart),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getBodyPartColor(pr.bodyPart).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  pr.bodyPart,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getBodyPartColor(pr.bodyPart),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                pr.formattedDate,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
                            color: _getBodyPartColor(pr.bodyPart),
                          ),
                        ),
                        Text(
                          'kg × ${pr.reps}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  /// 訓練建議卡片
  Widget _buildSuggestionsCard(List<TrainingSuggestion> suggestions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, size: 20),
                SizedBox(width: 8),
                Text('訓練建議', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ...suggestions.map((suggestion) => ListTile(
              leading: Icon(
                _getSuggestionIcon(suggestion.type),
                color: _getSuggestionColor(suggestion.type),
              ),
              title: Text(suggestion.title),
              subtitle: Text(suggestion.description),
            )),
          ],
        ),
      ),
    );
  }

  IconData _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.warning:
        return Icons.warning;
      case SuggestionType.info:
        return Icons.info;
      case SuggestionType.success:
        return Icons.check_circle;
    }
  }

  Color _getSuggestionColor(SuggestionType type) {
    switch (type) {
      case SuggestionType.warning:
        return Colors.orange;
      case SuggestionType.info:
        return Colors.blue;
      case SuggestionType.success:
        return Colors.green;
    }
  }

  /// 力量進步 Tab
  Widget _buildStrengthProgressTab(StatisticsData data) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('請先登入'));
    }

    return _StrengthProgressTabContent(
      userId: user.uid,
      statisticsData: data,
      timeRange: _controller.timeRange,
      onRefresh: () => _controller.refreshStatistics(),
    );
  }

  /// 根據身體部位返回顏色
  Color _getBodyPartColor(String bodyPart) {
    if (bodyPart.contains('胸')) return Colors.red;
    if (bodyPart.contains('背')) return Colors.blue;
    if (bodyPart.contains('腿')) return Colors.green;
    if (bodyPart.contains('肩')) return Colors.orange;
    if (bodyPart.contains('手')) return Colors.purple;
    if (bodyPart.contains('核心') || bodyPart.contains('腹')) return Colors.teal;
    return Colors.grey;
  }

  /// 根據身體部位返回圖標
  IconData _getBodyPartIcon(String bodyPart) {
    if (bodyPart.contains('胸')) return Icons.fitness_center;
    if (bodyPart.contains('背')) return Icons.accessibility_new;
    if (bodyPart.contains('腿')) return Icons.directions_run;
    if (bodyPart.contains('肩')) return Icons.sports_martial_arts;
    if (bodyPart.contains('手')) return Icons.sports_handball;
    if (bodyPart.contains('核心') || bodyPart.contains('腹')) return Icons.self_improvement;
    return Icons.fitness_center;
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  /// 肌群平衡 Tab
  Widget _buildMuscleBalanceTab(StatisticsData data) {
    final balance = data.muscleGroupBalance;
    if (balance == null || balance.stats.isEmpty) {
      return const Center(child: Text('還沒有足夠的數據分析肌群平衡'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 平衡狀態卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        balance.isPushPullBalanced ? Icons.check_circle : Icons.warning,
                        color: balance.isPushPullBalanced ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(balance.balanceStatus, 
                           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (balance.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('建議：', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...balance.recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(rec)),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 肌群分布
          ...balance.stats.map((stat) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(stat.category.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stat.category.displayName, 
                                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('${stat.formattedVolume}  ${stat.formattedPercentage}', 
                                 style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: stat.percentage,
                    backgroundColor: Colors.grey[200],
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: stat.topExercises.map((ex) => Chip(
                      label: Text(ex, style: const TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    )).toList(),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  /// 訓練日曆 Tab
  Widget _buildCalendarTab(StatisticsData data) {
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
              Expanded(child: _buildCalendarStatCard('訓練天數', calendar.trainingDays.toString(), Icons.fitness_center)),
              const SizedBox(width: 8),
              Expanded(child: _buildCalendarStatCard('最長連續', '${calendar.maxStreak} 天', Icons.local_fire_department)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildCalendarStatCard('當前連續', '${calendar.currentStreak} 天', Icons.trending_up)),
              const SizedBox(width: 8),
              Expanded(child: _buildCalendarStatCard('平均訓練量', '${calendar.averageVolume.toStringAsFixed(0)} kg', Icons.show_chart)),
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
                  const Text('訓練熱力圖', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildHeatmap(calendar.days),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 32),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(List<TrainingCalendarDay> days) {
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
              child: Center(child: Text(day, style: const TextStyle(fontSize: 12, color: Colors.grey))),
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
                return _buildHeatmapCell(day);
              }).toList(),
            ),
          );
        }),
        const SizedBox(height: 16),
        // 圖例
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('少', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 8),
            ...[0, 1, 2, 3, 4].map((level) {
              return Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _getHeatmapColor(level),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
            const SizedBox(width: 8),
            const Text('多', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildHeatmapCell(TrainingCalendarDay day) {
    return Tooltip(
      message: day.hasWorkout 
          ? '${day.formattedDate}\n訓練量: ${day.totalVolume.toStringAsFixed(0)} kg'
          : '${day.formattedDate}\n休息日',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getHeatmapColor(day.intensity),
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

  Color _getHeatmapColor(int intensity) {
    switch (intensity) {
      case 0: return Colors.grey[200]!;
      case 1: return Colors.green[100]!;
      case 2: return Colors.green[300]!;
      case 3: return Colors.green[500]!;
      case 4: return Colors.green[700]!;
      default: return Colors.grey[200]!;
    }
  }

  /// 完成率 Tab
  Widget _buildCompletionRateTab(StatisticsData data) {
    final completion = data.completionRate;
    if (completion == null) {
      return const Center(child: Text('還沒有完成率數據'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 完成率總覽
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(completion.formattedCompletionRate, 
                       style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                  const Text('總完成率', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: completion.completionRate,
                    backgroundColor: Colors.grey[200],
                    minHeight: 12,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('計劃組數', completion.totalPlannedSets.toString()),
                      _buildStatItem('完成組數', completion.completedSets.toString()),
                      _buildStatItem('失敗組數', completion.failedSets.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 狀態評估
          if (completion.isExcellent)
            _buildStatusCard('優秀！', '您的完成率非常高，保持下去！', Icons.emoji_events, Colors.green)
          else if (completion.needsAdjustment)
            _buildStatusCard('需要調整', '完成率較低，建議調整訓練計劃或減輕重量', Icons.warning, Colors.orange),
          
          const SizedBox(height: 16),
          
          // 弱點動作
          if (completion.weakPoints.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('需要關注的動作', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ...completion.weakPoints.map((exercise) {
                      final failedCount = completion.incompleteExercises[exercise] ?? 0;
                      return ListTile(
                        leading: const Icon(Icons.info_outline, color: Colors.orange),
                        title: Text(exercise),
                        trailing: Text('$failedCount 組未完成'),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String message, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 力量進步 Tab 內容組件（整合收藏功能）
class _StrengthProgressTabContent extends StatefulWidget {
  final String userId;
  final StatisticsData statisticsData;
  final TimeRange timeRange;
  final VoidCallback? onRefresh;

  const _StrengthProgressTabContent({
    required this.userId,
    required this.statisticsData,
    required this.timeRange,
    this.onRefresh,
  });

  @override
  State<_StrengthProgressTabContent> createState() => _StrengthProgressTabContentState();
}

class _StrengthProgressTabContentState extends State<_StrengthProgressTabContent> {
  final IFavoritesService _favoritesService = serviceLocator<IFavoritesService>();
  bool _hasFavorites = false;

  @override
  void initState() {
    super.initState();
    _checkFavorites();
  }

  /// 檢查是否有收藏
  Future<void> _checkFavorites() async {
    try {
      final favorites = await _favoritesService.getFavoriteExercises(widget.userId);
      setState(() => _hasFavorites = favorites.isNotEmpty);
    } catch (e) {
      // 忽略錯誤
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果沒有力量進步數據，顯示選擇頁面
    if (widget.statisticsData.strengthProgress.isEmpty) {
      return ExerciseSelectionNavigator(
        userId: widget.userId,
        onExerciseSelected: (exerciseId) {
          // 選擇動作後可以刷新數據
          widget.onRefresh?.call();
        },
      );
    }

    // 如果有收藏，顯示收藏列表；否則顯示分類導航
    if (_hasFavorites) {
      return _buildWithFavorites();
    } else {
      return _buildWithSelection();
    }
  }

  /// 建立帶收藏的視圖
  Widget _buildWithFavorites() {
    return FavoriteExercisesList(
      userId: widget.userId,
      timeRange: widget.timeRange,
      onExerciseTap: (exerciseId) {
        // 點擊收藏動作可以查看詳細
        _showExerciseDetails(exerciseId);
      },
      onAddMoreTap: () {
        // 導航到動作選擇頁面
        _showExerciseSelectionPage();
      },
    );
  }

  /// 顯示動作選擇頁面（全屏）
  void _showExerciseSelectionPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('選擇動作'),
          ),
          body: ExerciseSelectionNavigator(
            userId: widget.userId,
            onExerciseSelected: (exercise) {
              // 導航到動作詳情頁面
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ExerciseStrengthDetailPage(
                    userId: widget.userId,
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.exerciseName,
                    timeRange: widget.timeRange,
                  ),
                ),
              ).then((_) {
                // 從詳情頁返回後，重新檢查收藏狀態
                _checkFavorites();
              });
            },
          ),
        ),
      ),
    ).then((_) {
      // 從選擇頁面返回後，重新檢查收藏狀態
      _checkFavorites();
    });
  }

  /// 建立帶選擇的視圖
  Widget _buildWithSelection() {
    return Column(
      children: [
        // 提示卡片
        Card(
          margin: const EdgeInsets.all(16),
          color: Colors.blue.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue),
                    SizedBox(width: 12),
                    Text(
                      '💪 查看動作進步',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '選擇動作，查看完整的力量進步曲線和訓練記錄',
                ),
                const SizedBox(height: 4),
                Text(
                  '提示：點擊右上角星號可以收藏常用動作',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),

        // 分類導航
        Expanded(
          child: ExerciseSelectionNavigator(
            userId: widget.userId,
            onExerciseSelected: (exercise) {
              // 導航到動作詳情頁面（查看力量進步記錄）
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ExerciseStrengthDetailPage(
                    userId: widget.userId,
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.exerciseName,
                    timeRange: widget.timeRange,
                  ),
                ),
              ).then((_) {
                // 從詳情頁返回後，重新檢查收藏狀態
                _checkFavorites();
              });
            },
          ),
        ),
      ],
    );
  }

  /// 顯示動作詳情
  void _showExerciseDetails(String exerciseId) {
    // 從 strengthProgress 中找到動作名稱
    final progress = widget.statisticsData.strengthProgress.firstWhere(
      (p) => p.exerciseId == exerciseId,
      orElse: () => widget.statisticsData.strengthProgress.first,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseStrengthDetailPage(
          userId: widget.userId,
          exerciseId: exerciseId,
          exerciseName: progress.exerciseName,
          timeRange: widget.timeRange,
        ),
      ),
    ).then((_) {
      // 從詳情頁返回後，重新檢查收藏狀態
      _checkFavorites();
    });
  }
}

