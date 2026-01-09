import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 骨架屏載入組件
///
/// 提供多種預設骨架屏樣式，用於資料載入時的佔位符。
/// 使用 flutter_animate 的 shimmer 效果，與 HomePage 風格一致。
class SkeletonLoader extends StatelessWidget {
  /// 骨架屏子組件
  final Widget child;

  /// 動畫時長（毫秒）
  final int animationDurationMs;

  /// 是否啟用動畫
  final bool enableAnimation;

  const SkeletonLoader({
    super.key,
    required this.child,
    this.animationDurationMs = 1200,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableAnimation) {
      return child;
    }

    // 使用 flutter_animate 的 shimmer 效果
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: Duration(milliseconds: animationDurationMs),
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withValues(alpha: 0.08),
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

/// Session Mode 骨架屏
///
/// 用於 Session Mode 頁面載入時顯示
/// 包含：頭部資訊區 + 訓練內容區 + SOAP 區
class SkeletonSessionMode extends StatelessWidget {
  const SkeletonSessionMode({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SkeletonLoader(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頭部資訊區
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 學員名稱
                  Row(
                    children: [
                      SkeletonCircle(size: 40),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(height: 16, width: 100),
                          SizedBox(height: 6),
                          SkeletonBox(height: 12, width: 150),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // 時間資訊
                  Row(
                    children: [
                      SkeletonBox(height: 14, width: 80),
                      SizedBox(width: 16),
                      SkeletonBox(height: 14, width: 120),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 訓練內容區標題
            const SkeletonBox(height: 18, width: 100),
            const SizedBox(height: 12),

            // 訓練動作卡片 x 3
            ...List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 16, width: 150),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          SkeletonBox(height: 32, width: 60),
                          SizedBox(width: 8),
                          SkeletonBox(height: 32, width: 60),
                          SizedBox(width: 8),
                          SkeletonBox(height: 32, width: 60),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // SOAP 區
            const SkeletonBox(height: 18, width: 80),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  SkeletonBox(height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(height: 14, width: 200),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 學員列表骨架屏
///
/// 用於教練中心學員列表載入時顯示
class SkeletonClientList extends StatelessWidget {
  /// 顯示幾個學員卡片
  final int itemCount;

  const SkeletonClientList({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SkeletonLoader(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                // 頭像
                const SkeletonCircle(size: 48),
                const SizedBox(width: 12),
                // 資訊
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(height: 16, width: 100),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SkeletonBox(
                            height: 20,
                            width: 50,
                            borderRadius: 10,
                          ),
                          const SizedBox(width: 8),
                          const SkeletonBox(height: 12, width: 80),
                        ],
                      ),
                    ],
                  ),
                ),
                // 箭頭
                const SkeletonBox(height: 24, width: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 統計頁骨架屏
///
/// 用於統計頁面載入時顯示
class SkeletonStatistics extends StatelessWidget {
  const SkeletonStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SkeletonLoader(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 時間範圍選擇器
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(height: 36, width: 80, borderRadius: 18),
                SizedBox(width: 8),
                SkeletonBox(height: 36, width: 80, borderRadius: 18),
                SizedBox(width: 8),
                SkeletonBox(height: 36, width: 80, borderRadius: 18),
              ],
            ),
            const SizedBox(height: 24),

            // 統計摘要卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          SkeletonBox(height: 32, width: 60),
                          SizedBox(height: 8),
                          SkeletonBox(height: 12, width: 50),
                        ],
                      ),
                      Column(
                        children: [
                          SkeletonBox(height: 32, width: 60),
                          SizedBox(height: 8),
                          SkeletonBox(height: 12, width: 50),
                        ],
                      ),
                      Column(
                        children: [
                          SkeletonBox(height: 32, width: 60),
                          SizedBox(height: 8),
                          SkeletonBox(height: 12, width: 50),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 圖表區域
            const SkeletonBox(height: 18, width: 120),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // 列表區域
            const SkeletonBox(height: 18, width: 100),
            const SizedBox(height: 12),
            ...List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      SkeletonBox(height: 14, width: 120),
                      Spacer(),
                      SkeletonBox(height: 14, width: 60),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 時段管理骨架屏
///
/// 用於教練時段管理頁面載入時顯示
class SkeletonSlotCalendar extends StatelessWidget {
  const SkeletonSlotCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SkeletonLoader(
      child: Column(
        children: [
          // 月份標題
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonBox(height: 24, width: 24),
                SizedBox(width: 16),
                SkeletonBox(height: 20, width: 100),
                SizedBox(width: 16),
                SkeletonBox(height: 24, width: 24),
              ],
            ),
          ),

          // 週標題
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                return const SkeletonBox(height: 14, width: 30);
              }),
            ),
          ),
          const SizedBox(height: 12),

          // 日曆格子
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: 35,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
