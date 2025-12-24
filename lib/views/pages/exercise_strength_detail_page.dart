import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/statistics_model.dart';
import '../../services/interfaces/i_statistics_service.dart';
import '../../services/interfaces/i_favorites_service.dart';
import '../../services/service_locator.dart';

/// 動作力量進步詳情頁面
/// 
/// 顯示單個動作的完整力量進步曲線、PR 記錄、歷史訓練
class ExerciseStrengthDetailPage extends StatefulWidget {
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final TimeRange timeRange;

  const ExerciseStrengthDetailPage({
    Key? key,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.timeRange,
  }) : super(key: key);

  @override
  State<ExerciseStrengthDetailPage> createState() => _ExerciseStrengthDetailPageState();
}

class _ExerciseStrengthDetailPageState extends State<ExerciseStrengthDetailPage> {
  final IStatisticsService _statisticsService = serviceLocator<IStatisticsService>();
  final IFavoritesService _favoritesService = serviceLocator<IFavoritesService>();
  
  ExerciseStrengthProgress? _progress;
  bool _isLoading = true;
  bool _isFavorite = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 載入數據
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // 載入力量進步數據
      final progressList = await _statisticsService.getStrengthProgress(
        widget.userId,
        widget.timeRange,
        limit: 100,
      );

      // 找到目標動作
      final progress = progressList.firstWhere(
        (p) => p.exerciseId == widget.exerciseId,
        orElse: () => throw Exception('找不到該動作的訓練記錄'),
      );

      // 檢查是否已收藏
      final isFavorite = await _favoritesService.isFavorite(
        widget.userId,
        widget.exerciseId,
      );

      setState(() {
        _progress = progress;
        _isFavorite = isFavorite;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 切換收藏狀態
  Future<void> _toggleFavorite() async {
    if (_progress == null) return;

    try {
      if (_isFavorite) {
        await _favoritesService.removeFavorite(widget.userId, widget.exerciseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已移除收藏')),
          );
        }
      } else {
        await _favoritesService.addFavorite(
          widget.userId,
          widget.exerciseId,
          _progress!.exerciseName,
          _progress!.bodyPart,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已添加收藏')),
          );
        }
      }

      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        actions: [
          // 收藏按鈕
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
            color: _isFavorite ? Colors.amber : null,
            onPressed: _isLoading ? null : _toggleFavorite,
            tooltip: _isFavorite ? '取消收藏' : '添加收藏',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '載入失敗',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('重試'),
              ),
            ],
          ),
        ),
      );
    }

    if (_progress == null) {
      return const Center(child: Text('沒有數據'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 統計卡片
          _buildStatisticsCard(),
          const SizedBox(height: 16),

          // 力量進步曲線
          _buildStrengthChart(),
          const SizedBox(height: 16),

          // PR 記錄
          _buildPRRecords(),
          const SizedBox(height: 16),

          // 歷史記錄
          _buildHistoryList(),
        ],
      ),
    );
  }

  /// 建立統計卡片
  Widget _buildStatisticsCard() {
    final progress = _progress!;
    final isPositive = progress.progressPercentage > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '訓練統計',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '進步幅度',
                    progress.formattedProgress,
                    isPositive ? Icons.trending_up : Icons.trending_flat,
                    isPositive ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '當前最大',
                    progress.formattedCurrentMax,
                    Icons.fitness_center,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '總組數',
                    '${progress.totalSets}',
                    Icons.format_list_numbered,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '平均重量',
                    '${progress.averageWeight.toStringAsFixed(1)} kg',
                    Icons.balance,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 建立力量進步曲線圖
  Widget _buildStrengthChart() {
    final progress = _progress!;
    final history = progress.history;

    if (history.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              '暫無歷史數據',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '力量進步曲線',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}kg',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < history.length) {
                            final date = history[index].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.month}/${date.day}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (history.length - 1).toDouble(),
                  minY: 0,
                  maxY: history.map((p) => p.weight).reduce((a, b) => a > b ? a : b) * 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: history.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.weight);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          // PR 標記為金色
                          final isPR = history[index].isPR;
                          return FlDotCirclePainter(
                            radius: isPR ? 6 : 4,
                            color: isPR ? Colors.amber : Colors.blue,
                            strokeWidth: isPR ? 2 : 0,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index >= 0 && index < history.length) {
                            final point = history[index];
                            return LineTooltipItem(
                              '${point.weight.toStringAsFixed(1)}kg × ${point.reps}\n'
                              '${point.formattedDate}'
                              '${point.isPR ? '\n🏆 PR!' : ''}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.circle, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                const Text('個人記錄 (PR)', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 16),
                Icon(Icons.circle, size: 12, color: Colors.blue),
                const SizedBox(width: 4),
                const Text('一般訓練', style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 建立 PR 記錄列表
  Widget _buildPRRecords() {
    final progress = _progress!;
    final prRecords = progress.history.where((p) => p.isPR).toList();

    if (prRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  '個人記錄 (PR)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...prRecords.reversed.take(5).map((record) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.star, color: Colors.amber, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${record.weight.toStringAsFixed(1)} kg × ${record.reps}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          record.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '1RM: ${record.estimatedOneRM.toStringAsFixed(1)}kg',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
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

  /// 建立歷史記錄列表
  Widget _buildHistoryList() {
    final progress = _progress!;
    final history = progress.history.reversed.toList();

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
            ...history.take(10).map((record) => Padding(
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
                  // 重量和次數
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: record.isPR 
                            ? Colors.amber.withOpacity(0.1)
                            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: record.isPR 
                            ? Border.all(color: Colors.amber.withOpacity(0.3))
                            : null,
                      ),
                      child: Row(
                        children: [
                          if (record.isPR) ...[
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '${record.weight.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(' × '),
                          Text('${record.reps} 次'),
                          const Spacer(),
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
            )),
            if (history.length > 10) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '還有 ${history.length - 10} 條記錄...',
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
}

