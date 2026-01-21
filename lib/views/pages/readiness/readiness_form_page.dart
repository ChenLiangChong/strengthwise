// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/interfaces/i_readiness_controller.dart';
import 'package:strengthwise/models/readiness/daily_readiness_model.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/themes/app_theme.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/views/pages/readiness/widgets/emoji_slider.dart';

/// 課前準備度調查表
///
/// 學員在課前填寫身體狀況、睡眠、壓力、能量水平等
class ReadinessFormPage extends StatelessWidget {
  /// 預約 ID（可選，用於關聯課程）
  final String? appointmentId;

  /// 教練名稱（顯示用）
  final String? coachName;

  /// 課程時間（顯示用）
  final DateTime? sessionTime;

  const ReadinessFormPage({
    super.key,
    this.appointmentId,
    this.coachName,
    this.sessionTime,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<IReadinessController>(
      create: (_) => serviceLocator<IReadinessController>(param1: appointmentId),
      child: _ReadinessFormContent(
        coachName: coachName,
        sessionTime: sessionTime,
      ),
    );
  }
}

class _ReadinessFormContent extends StatelessWidget {
  final String? coachName;
  final DateTime? sessionTime;

  const _ReadinessFormContent({
    this.coachName,
    this.sessionTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('課前準備度調查'),
        centerTitle: true,
      ),
      body: Consumer<IReadinessController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: context.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 課程資訊卡片
                    if (coachName != null || sessionTime != null)
                      _buildSessionInfoCard(context),

                    const SizedBox(height: 16),

                    // 說明卡片
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '請根據今天的身體狀況填寫，讓教練更了解你的狀態',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 1. 睡眠品質
                    EmojiSlider(
                      title: '睡眠睡得香嗎？',
                      description: '評估昨晚睡眠品質',
                      value: controller.metrics.sleepQuality,
                      onChanged: controller.setSleepQuality,
                      emojis: const ['😫', '😕', '😐', '😊', '😴'],
                      labels: const ['很差', '較差', '普通', '很好', '超棒'],
                    ),

                    const SizedBox(height: 16),

                    // 2. 睡眠時數
                    HoursSlider(
                      title: '昨晚睡了幾個小時？',
                      value: controller.metrics.sleepHours,
                      onChanged: controller.setSleepHours,
                      min: 3,
                      max: 12,
                      step: 0.5,
                    ),

                    const SizedBox(height: 16),

                    // 3. 痠痛程度（1=超痛 → 5=超棒）
                    // ⭐ v3.1 修正：數值越高表示身體狀態越好（不痠痛）
                    EmojiSlider(
                      title: '身體感覺痠痛嗎？',
                      description: '評估肌肉痠痛與恢復狀況',
                      value: controller.metrics.soreness,
                      onChanged: controller.setSoreness,
                      emojis: const ['🤕', '😣', '😐', '😌', '💪'],
                      labels: const ['超痛', '很痠', '還好', '輕微', '超棒'],
                    ),

                    const SizedBox(height: 16),

                    // 4. 心理壓力程度
                    EmojiSlider(
                      title: '最近壓力大嗎？',
                      description: '評估心理與生活壓力程度',
                      value: controller.metrics.stress,
                      onChanged: controller.setStress,
                      emojis: const ['😰', '😟', '😐', '😌', '😎'],
                      labels: const ['超大', '較大', '還好', '很放鬆', '超放鬆'],
                    ),

                    const SizedBox(height: 16),

                    // 5. 能量水平
                    EmojiSlider(
                      title: '今天有想練的感覺嗎？',
                      description: '評估訓練動力與能量水平',
                      value: controller.metrics.energyLevel,
                      onChanged: controller.setEnergyLevel,
                      emojis: const ['😴', '😑', '😐', '😃', '🔥'],
                      labels: const ['超累', '較累', '普通', '精神', '超想練'],
                    ),

                    const SizedBox(height: 24),

                    // 備註輸入
                    _buildNotesField(context, controller),

                    const SizedBox(height: 24),

                    // 預覽結果
                    _buildPreviewCard(context, controller),

                    const SizedBox(height: 24),

                    // 提交按鈕
                    FilledButton.icon(
                      onPressed: controller.isSubmitting
                          ? null
                          : () => _submitForm(context, controller),
                      icon: controller.isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(controller.isSubmitting ? '送出中...' : '送出問卷'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 課程資訊卡片
  Widget _buildSessionInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sessionTime != null)
                  Text(
                    _formatSessionTime(sessionTime!),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (coachName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '與 $coachName 教練',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 備註輸入欄位
  Widget _buildNotesField(
      BuildContext context, IReadinessController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '有什麼想讓教練知道的？（選填）',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: controller.setNotes,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: '例如：昨天跑步 30 分鐘、左膝有點痠痛...',
              filled: true,
              fillColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 預覽結果卡片
  Widget _buildPreviewCard(
      BuildContext context, IReadinessController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 計算預覽分數
    final result = controller.calculatePreviewScore();
    final score = result['score'] as int;
    final trafficLight = result['trafficLight'] as TrafficLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTrafficLightColor(trafficLight).withValues(alpha: 0.2),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                trafficLight.emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trafficLight.label,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _getTrafficLightColor(trafficLight),
                    ),
                  ),
                  Text(
                    '準備度 $score 分',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 指標標籤
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildMetricChip(
                  controller.metrics.sleepQualityEmoji, '睡眠', colorScheme),
              _buildMetricChip(
                  '${controller.metrics.sleepHours.toStringAsFixed(0)}h',
                  '時數',
                  colorScheme),
              _buildMetricChip(
                  controller.metrics.sorenessEmoji, '痠痛', colorScheme),
              _buildMetricChip(
                  controller.metrics.stressEmoji, '壓力', colorScheme),
              _buildMetricChip(
                  controller.metrics.energyEmoji, '能量', colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String value, String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 根據紅綠燈狀態使用專案語義色彩
  Color _getTrafficLightColor(TrafficLight light) {
    switch (light) {
      case TrafficLight.red:
        return AppTheme.errorRed;
      case TrafficLight.amber:
        return AppTheme.warningLight;
      case TrafficLight.green:
        return AppTheme.successLight;
    }
  }

  String _formatSessionTime(DateTime time) {
    final weekdays = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
    final weekday = weekdays[time.weekday - 1];
    return '${time.month}/${time.day} $weekday ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitForm(
      BuildContext context, IReadinessController controller) async {
    try {
      await controller.submitReadiness();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('問卷已送出！教練會收到你的狀態通知'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true); // 返回 true 表示成功
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送出失敗：$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
