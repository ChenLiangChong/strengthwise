// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/readiness/daily_readiness_model.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 學員狀態卡（課前問卷結果）
///
/// 顯示學員的課前準備度問卷結果，包含紅綠燈狀態和各項指標
class ReadinessCard extends StatefulWidget {
  /// 問卷資料（可為 null 表示未填寫）
  final DailyReadinessModel? readiness;

  /// 發送提醒回調（學員未填時）
  final VoidCallback? onSendReminder;

  /// 是否可展開
  final bool expandable;

  const ReadinessCard({
    super.key,
    this.readiness,
    this.onSendReminder,
    this.expandable = true,
  });

  @override
  State<ReadinessCard> createState() => _ReadinessCardState();
}

class _ReadinessCardState extends State<ReadinessCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 未填寫狀態
    if (widget.readiness == null || !widget.readiness!.isSubmitted) {
      return _buildEmptyState(colorScheme);
    }

    final readiness = widget.readiness!;
    final trafficLight = readiness.trafficLight ?? TrafficLight.amber;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTrafficLightColor(trafficLight).withValues(alpha: 0.15),
            _getTrafficLightColor(trafficLight).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTrafficLightColor(trafficLight).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // 摘要列（可點擊展開）
          InkWell(
            onTap: widget.expandable
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: context.cardPadding,
              child: Row(
                children: [
                  // 紅綠燈圖示
                  Text(
                    trafficLight.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  // 狀態文字
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '課前狀態：${trafficLight.label}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getTrafficLightColor(trafficLight),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 簡短指標摘要
                        Text(
                          readiness.shortSummary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 分數
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getTrafficLightColor(trafficLight)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${readiness.readinessScore} 分',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w600,
                        color: _getTrafficLightColor(trafficLight),
                      ),
                    ),
                  ),
                  // 展開箭頭
                  if (widget.expandable) ...[
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // 展開詳情
          if (_isExpanded) _buildExpandedDetails(readiness, colorScheme),
        ],
      ),
    );
  }

  /// 未填寫狀態
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      padding: context.cardPadding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pending_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '尚未填寫課前問卷',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '學員可在課前填寫準備度問卷',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (widget.onSendReminder != null)
            TextButton.icon(
              onPressed: widget.onSendReminder,
              icon: const Icon(Icons.send, size: 18),
              label: const Text('發送提醒'),
            ),
        ],
      ),
    );
  }

  /// 展開詳情
  Widget _buildExpandedDetails(
      DailyReadinessModel readiness, ColorScheme colorScheme) {
    final metrics = readiness.metrics;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.spacing.md,
        0,
        context.spacing.md,
        context.spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          // 各項指標
          _buildMetricRow(
            '睡眠品質',
            metrics.sleepQualityEmoji,
            '${metrics.sleepQuality}/5',
            theme,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            '睡眠時數',
            '⏰',
            '${metrics.sleepHours.toStringAsFixed(1)} 小時',
            theme,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            '肌肉狀態',
            metrics.sorenessEmoji,
            '${metrics.soreness}/5',
            theme,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            '心理壓力',
            metrics.stressEmoji,
            '${metrics.stress}/5',
            theme,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            '能量水平',
            metrics.energyEmoji,
            '${metrics.energyLevel}/5',
            theme,
          ),
          // 學員備註
          if (metrics.notes != null && metrics.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '學員備註',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metrics.notes!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
          // 填寫時間
          const SizedBox(height: 8),
          Text(
            '填寫時間：${_formatTime(readiness.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String emoji,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getTrafficLightColor(TrafficLight light) {
    switch (light) {
      case TrafficLight.red:
        return const Color(0xFFEF4444); // Error
      case TrafficLight.amber:
        return const Color(0xFFF59E0B); // Warning
      case TrafficLight.green:
        return const Color(0xFF10B981); // Success
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

