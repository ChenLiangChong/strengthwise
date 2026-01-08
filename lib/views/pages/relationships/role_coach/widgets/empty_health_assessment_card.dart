// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 健康評估空狀態卡片
///
/// 提示教練建立健康評估
class EmptyHealthAssessmentCard extends StatelessWidget {
  final VoidCallback onCreateTap;

  const EmptyHealthAssessmentCard({
    super.key,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0, // ⭐ 移除陰影
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md), // ⭐ 響應式內距
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題列
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: colorScheme.primary,
                  size: 24.scaled(context), // ⭐ 響應式圖標
                ),
                SizedBox(width: context.spacing.md), // ⭐ 響應式間距
                Text(
                  '健康評估',
                  style: context.responsive.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ), // ⭐ 響應式文字
                ),
              ],
            ),

            SizedBox(height: context.spacing.md), // ⭐ 響應式間距

            // 提示內容
            Container(
              padding: EdgeInsets.all(context.spacing.md), // ⭐ 響應式內距
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 20.scaled(context), // ⭐ 響應式圖標
                      ),
                      SizedBox(width: context.spacing.sm), // ⭐ 響應式間距
                      Text(
                        '尚未建立健康評估',
                        style: context.responsive.titleMedium.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ), // ⭐ 響應式文字
                      ),
                    ],
                  ),
                  SizedBox(height: context.spacing.md), // ⭐ 響應式間距
                  Text(
                    '建議在首次上課前完成評估，以確保訓練安全與效果',
                    style: context.responsive.bodyMedium.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ), // ⭐ 響應式文字
                  ),
                  SizedBox(height: context.spacing.md), // ⭐ 響應式間距
                  _buildInfoItem(
                    context,
                    icon: Icons.shield_outlined,
                    text: '安全篩檢：排除訓練風險',
                  ),
                  SizedBox(height: context.spacing.xs), // ⭐ 響應式間距
                  _buildInfoItem(
                    context,
                    icon: Icons.healing_outlined,
                    text: '傷病史：避免動作禁忌',
                  ),
                  SizedBox(height: context.spacing.xs), // ⭐ 響應式間距
                  _buildInfoItem(
                    context,
                    icon: Icons.flag_outlined,
                    text: '訓練目標：個人化課表',
                  ),
                ],
              ),
            ),

            SizedBox(height: context.spacing.md), // ⭐ 響應式間距

            // 建立按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCreateTap,
                icon: Icon(Icons.add, size: 20.scaled(context)), // ⭐ 響應式圖標
                label: Text('立即建立評估', style: context.responsive.labelLarge),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      vertical: context.spacing.md), // ⭐ 響應式內距
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 建立資訊項目
  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 16.scaled(context), // ⭐ 響應式圖標
          color: colorScheme.primary,
        ),
        SizedBox(width: context.spacing.sm), // ⭐ 響應式間距
        Expanded(
          child: Text(
            text,
            style: context.responsive.bodySmall.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ), // ⭐ 響應式文字
          ),
        ),
      ],
    );
  }
}
