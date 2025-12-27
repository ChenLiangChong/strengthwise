import 'package:flutter/material.dart';
import '../../../../models/statistics_model.dart';
import '../../../../controllers/interfaces/i_statistics_controller.dart';
import '../widgets/frequency_card.dart';
import '../widgets/volume_trend_chart.dart';
import '../widgets/body_part_distribution_card.dart';
import '../widgets/personal_records_card.dart';
import '../widgets/suggestions_card.dart';

/// 概覽 Tab 頁面
///
/// 顯示訓練統計的整體概覽
class OverviewTab extends StatelessWidget {
  /// 統計數據
  final StatisticsData data;

  /// 統計控制器（用於訪問建議等）
  final IStatisticsController controller;

  const OverviewTab({
    Key? key,
    required this.data,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 訓練頻率卡片
          FrequencyCard(frequency: data.frequency),
          const SizedBox(height: 16),

          // 訓練量趨勢圖
          VolumeTrendChart(history: data.volumeHistory),
          const SizedBox(height: 16),

          // 身體部位分布
          BodyPartDistributionCard(stats: data.bodyPartStats),
          const SizedBox(height: 16),

          // 個人記錄
          PersonalRecordsCard(records: data.personalRecords),
          const SizedBox(height: 16),

          // 訓練建議
          if (controller.suggestions.isNotEmpty)
            SuggestionsCard(suggestions: controller.suggestions),
        ],
      ),
    );
  }
}

