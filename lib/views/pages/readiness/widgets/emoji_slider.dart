// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 表情滑桿組件
///
/// 用於課前問卷的五維度評估，滑動時顯示對應表情
/// 支援吸附效果（Snapping）和觸覺回饋
class EmojiSlider extends StatefulWidget {
  /// 問題標題
  final String title;

  /// 問題描述（選填）
  final String? description;

  /// 當前值（1-5）
  final int value;

  /// 值變更回調
  final ValueChanged<int> onChanged;

  /// 表情列表（5 個，對應 1-5 分）
  final List<String> emojis;

  /// 評分標籤（選填，5 個）
  final List<String>? labels;

  /// 是否顯示數值
  final bool showValue;

  /// 是否啟用觸覺回饋
  final bool hapticFeedback;

  const EmojiSlider({
    super.key,
    required this.title,
    this.description,
    required this.value,
    required this.onChanged,
    required this.emojis,
    this.labels,
    this.showValue = true,
    this.hapticFeedback = true,
  }) : assert(emojis.length == 5, 'emojis 必須有 5 個元素');

  @override
  State<EmojiSlider> createState() => _EmojiSliderState();
}

class _EmojiSliderState extends State<EmojiSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _lastValue = 0;

  @override
  void initState() {
    super.initState();
    _lastValue = widget.value;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onValueChanged(double newValue) {
    final intValue = newValue.round();
    if (intValue != _lastValue) {
      _lastValue = intValue;

      // 觸覺回饋
      if (widget.hapticFeedback) {
        HapticFeedback.selectionClick();
      }

      // 播放縮放動畫
      _controller.forward().then((_) => _controller.reverse());

      widget.onChanged(intValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
          // 標題列
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // 當前表情（放大動畫）
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Text(
                    widget.emojis[widget.value - 1],
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ],
            ),
          ),

          // 描述文字
          if (widget.description != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 滑桿
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _getTrackColor(colorScheme),
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
              thumbColor: _getTrackColor(colorScheme),
              overlayColor: _getTrackColor(colorScheme).withValues(alpha: 0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: widget.value.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: _onValueChanged,
            ),
          ),

          // 表情指示列
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final isSelected = index + 1 == widget.value;
                return Column(
                  children: [
                    Text(
                      widget.emojis[index],
                      style: TextStyle(
                        fontSize: isSelected ? 20 : 16,
                        color: isSelected
                            ? null
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    if (widget.labels != null && widget.labels!.length > index)
                      Text(
                        widget.labels![index],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),

          // 數值顯示
          if (widget.showValue) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTrackColor(colorScheme).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getValueLabel(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _getTrackColor(colorScheme),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 根據值取得軌道顏色（使用語意色彩）
  Color _getTrackColor(ColorScheme colorScheme) {
    // 使用 ColorScheme 語意色彩 + 手動定義的紅綠燈色
    switch (widget.value) {
      case 1:
        return colorScheme.error; // 紅色 - 使用 error
      case 2:
        return const Color(0xFFF59E0B); // Warning 橘色
      case 3:
        return const Color(0xFFFBBF24); // Warning 黃色
      case 4:
        return const Color(0xFF34D399); // Success 淺綠
      case 5:
        return const Color(0xFF10B981); // Success 綠色
      default:
        return colorScheme.primary;
    }
  }

  /// 取得當前值的標籤文字
  String _getValueLabel() {
    if (widget.labels != null && widget.labels!.length >= widget.value) {
      return '${widget.value}/5 - ${widget.labels![widget.value - 1]}';
    }
    return '${widget.value}/5';
  }
}

/// 睡眠時數滑桿
///
/// 專門用於課前問卷的睡眠時數輸入
class HoursSlider extends StatelessWidget {
  /// 問題標題
  final String title;

  /// 當前值（小時）
  final double value;

  /// 值變更回調
  final ValueChanged<double> onChanged;

  /// 最小值
  final double min;

  /// 最大值
  final double max;

  /// 步進值
  final double step;

  const HoursSlider({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.min = 3,
    this.max = 12,
    this.step = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 計算顏色（根據睡眠時數，使用語意色彩）
    Color trackColor;
    if (value < 5) {
      trackColor = colorScheme.error; // 紅色
    } else if (value < 6) {
      trackColor = const Color(0xFFF59E0B); // Warning 橘色
    } else if (value < 7) {
      trackColor = const Color(0xFFFBBF24); // Warning 黃色
    } else if (value <= 9) {
      trackColor = const Color(0xFF10B981); // Success 綠色
    } else {
      trackColor = const Color(0xFF34D399); // Success 淺綠
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12), // 統一卡片圓角 12dp
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: trackColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${value.toStringAsFixed(1)} 小時',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: trackColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 滑桿
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: trackColor,
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
              thumbColor: trackColor,
              overlayColor: trackColor.withValues(alpha: 0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / step).round(),
              onChanged: (newValue) {
                HapticFeedback.selectionClick();
                onChanged(newValue);
              },
            ),
          ),

          // 刻度標籤
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${min.toInt()}hr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '建議 7-9hr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF10B981), // Success 綠色
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${max.toInt()}hr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

