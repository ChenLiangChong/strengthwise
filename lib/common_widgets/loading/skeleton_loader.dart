import 'package:flutter/material.dart';

/// 骨架屏載入組件
///
/// 提供多種預設骨架屏樣式，用於資料載入時的佔位符。
/// 支援自動閃爍動畫效果。
class SkeletonLoader extends StatefulWidget {
  /// 骨架屏子組件
  final Widget child;

  /// 動畫時長（毫秒）
  final int animationDurationMs;

  /// 是否啟用動畫
  final bool enableAnimation;

  const SkeletonLoader({
    super.key,
    required this.child,
    this.animationDurationMs = 1500,
    this.enableAnimation = true,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animationDurationMs),
    );

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.enableAnimation) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableAnimation) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// 骨架屏盒子組件
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// 骨架屏圓形組件
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({
    super.key,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// 卡片骨架屏（預設樣式）
class SkeletonCard extends StatelessWidget {
  /// 標題寬度比例（0.0-1.0）
  final double titleWidthRatio;

  /// 顯示幾行內容
  final int contentLines;

  /// 是否顯示頭像
  final bool showAvatar;

  const SkeletonCard({
    super.key,
    this.titleWidthRatio = 0.5,
    this.contentLines = 2,
    this.showAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            const SkeletonCircle(size: 48),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題
                FractionallySizedBox(
                  widthFactor: titleWidthRatio,
                  child: const SkeletonBox(height: 16),
                ),
                const SizedBox(height: 12),
                // 內容行
                ...List.generate(contentLines, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < contentLines - 1 ? 8 : 0,
                    ),
                    child: SkeletonBox(
                      height: 12,
                      width: index == contentLines - 1
                          ? MediaQuery.of(context).size.width * 0.5
                          : double.infinity,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 列表項骨架屏
class SkeletonListTile extends StatelessWidget {
  /// 是否顯示頭像
  final bool showAvatar;

  /// 是否顯示尾部圖標
  final bool showTrailing;

  const SkeletonListTile({
    super.key,
    this.showAvatar = true,
    this.showTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          if (showAvatar) ...[
            const SkeletonCircle(size: 40),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 14, width: 120),
                const SizedBox(height: 8),
                SkeletonBox(
                  height: 12,
                  width: MediaQuery.of(context).size.width * 0.4,
                ),
              ],
            ),
          ),
          if (showTrailing) const SkeletonBox(height: 24, width: 24),
        ],
      ),
    );
  }
}

/// 預約卡片骨架屏
class SkeletonAppointmentCard extends StatelessWidget {
  const SkeletonAppointmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題列
            Row(
              children: [
                const SkeletonCircle(size: 20),
                const SizedBox(width: 8),
                const Expanded(child: SkeletonBox(height: 16, width: 120)),
                const SizedBox(width: 8),
                SkeletonBox(
                  height: 24,
                  width: 60,
                  borderRadius: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 時間行
            const Row(
              children: [
                SkeletonCircle(size: 18),
                SizedBox(width: 8),
                SkeletonBox(height: 14, width: 100),
                SizedBox(width: 12),
                SkeletonBox(height: 14, width: 60),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 骨架屏列表
class SkeletonList extends StatelessWidget {
  /// 顯示幾個項目
  final int itemCount;

  /// 項目建構器
  final Widget Function(BuildContext, int)? itemBuilder;

  /// 項目間距
  final double spacing;

  const SkeletonList({
    super.key,
    this.itemCount = 3,
    this.itemBuilder,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) => SizedBox(height: spacing),
        itemBuilder: (context, index) {
          return itemBuilder?.call(context, index) ?? const SkeletonCard();
        },
      ),
    );
  }
}
