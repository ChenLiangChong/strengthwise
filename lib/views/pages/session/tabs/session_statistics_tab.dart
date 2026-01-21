// ✅ v3.6: MVVM 重構 - 移除 Service 直接調用
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/interfaces/i_session_mode_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_statistics_controller.dart'; // ⭐ v3.6: MVVM
import 'package:strengthwise/models/statistics_model.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/statistics/widgets/frequency_card.dart';
import 'package:strengthwise/views/pages/statistics/widgets/volume_trend_chart.dart';
import 'package:strengthwise/views/pages/statistics/widgets/personal_records_card.dart';
import 'package:strengthwise/common_widgets/loading/skeleton_loader.dart';

/// 近期統計 Tab
///
/// 顯示學員最近 7 天的訓練概覽，複用現有統計組件
class SessionStatisticsTab extends StatefulWidget {
  const SessionStatisticsTab({super.key});

  @override
  State<SessionStatisticsTab> createState() => _SessionStatisticsTabState();
}

class _SessionStatisticsTabState extends State<SessionStatisticsTab> {
  late final IStatisticsController _statisticsController; // ⭐ v3.6: MVVM
  StatisticsData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _statisticsController = serviceLocator<IStatisticsController>(); // ⭐ v3.6: MVVM

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatistics();
    });
  }

  /// ⭐ v3.6: 透過 Controller 查詢
  Future<void> _loadStatistics() async {
    final controller = context.read<ISessionModeController>();
    final clientId = controller.clientId;

    setState(() => _isLoading = true);

    try {
      // 載入最近 7 天的統計
      final data = await _statisticsController.getStatistics(
        clientId,
        TimeRange.sevenDays,
      );

      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('載入統計失敗: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ISessionModeController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      // ⚡ 使用骨架屏取代轉圈
      return const SkeletonStatistics();
    }

    final data = _data;
    if (data == null) {
      return _buildEmptyState(colorScheme);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Text(
            '${controller.clientName} 的近期訓練',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '最近 7 天統計',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // 訓練頻率（複用現有組件）
          FrequencyCard(
            frequency: data.frequency,
            timeRange: TimeRange.sevenDays,
          ),
          const SizedBox(height: 16),

          // 訓練量趨勢（複用現有組件）
          VolumeTrendChart(history: data.volumeHistory),
          const SizedBox(height: 16),

          // 個人記錄（複用現有組件）
          if (data.personalRecords.isNotEmpty) ...[
            PersonalRecordsCard(records: data.personalRecords),
            const SizedBox(height: 16),
          ],

          // 快速摘要
          _buildQuickSummary(colorScheme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insights,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '尚無訓練統計',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            '學員完成訓練後將顯示統計資料',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary(ColorScheme colorScheme) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快速摘要',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '總訓練次數',
                  '${data.frequency.totalWorkouts} 次',
                  Icons.fitness_center,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  '訓練天數',
                  '${data.frequency.trainingDays} 天',
                  Icons.calendar_today,
                  colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
