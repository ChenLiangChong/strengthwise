import 'package:flutter/material.dart';
import '../../../models/favorite_exercise_model.dart';
import '../../../models/statistics_model.dart';
import '../../../utils/body_part_utils.dart';
import '../../../utils/date_format_utils.dart';
import '../../common/mini_line_chart.dart';

/// 收藏動作卡片組件
class FavoriteExerciseCard extends StatelessWidget {
  final FavoriteExercise favorite;
  final ExerciseStrengthProgress? progress;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const FavoriteExerciseCard({
    Key? key,
    required this.favorite,
    this.progress,
    required this.onTap,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(context),
              progress != null 
                  ? _buildProgressSection(context, progress!)
                  : _buildNoDataSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立卡片標題
  Widget _buildCardHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                favorite.exerciseName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  BodyPartUtils.buildBodyPartTag(context, favorite.bodyPart),
                  Text(
                    favorite.lastViewedAt != null
                        ? '最後查看: ${DateFormatUtils.formatRelativeDate(favorite.lastViewedAt!)}'
                        : '尚未查看',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.star, color: Colors.amber),
          onPressed: onToggleFavorite,
          tooltip: '取消收藏',
        ),
      ],
    );
  }

  /// 建立進度區塊
  Widget _buildProgressSection(BuildContext context, ExerciseStrengthProgress progress) {
    final progressPercentage = progress.progressPercentage;
    final isPositive = progressPercentage > 0;

    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProgressBadge(context, progress, isPositive),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '最大: ${progress.formattedCurrentMax}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (progress.history.length >= 2)
              _buildMiniChart(context, progress, isPositive),
          ],
        ),
      ],
    );
  }

  /// 建立進度標籤
  Widget _buildProgressBadge(BuildContext context, ExerciseStrengthProgress progress, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPositive
            ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
            : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_flat,
            size: 16,
            color: isPositive 
                ? Theme.of(context).colorScheme.secondary 
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            progress.formattedProgress,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPositive 
                  ? Theme.of(context).colorScheme.secondary 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立迷你圖表
  Widget _buildMiniChart(BuildContext context, ExerciseStrengthProgress progress, bool isPositive) {
    return SizedBox(
      width: 100,
      height: 40,
      child: MiniLineChart(
        dataPoints: progress.history,
        width: 100,
        height: 40,
        lineColor: isPositive 
            ? Theme.of(context).colorScheme.secondary 
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fillColor: isPositive 
            ? Theme.of(context).colorScheme.secondary 
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// 建立無數據區塊
  Widget _buildNoDataSection(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          '尚未有訓練記錄',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

