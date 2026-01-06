// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 空狀態組件 - 當教練還沒有學員時顯示
class EmptyClientsState extends StatelessWidget {
  const EmptyClientsState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.xl), // ⭐ 響應式邊距
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80.scaled(context), // ⭐ 響應式圖標
              color: colorScheme.primary.withOpacity(0.3),
            ),
            SizedBox(height: context.spacing.lg), // ⭐ 響應式間距
            Text(
              '還沒有學員',
              style: context.responsive.titleLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ), // ⭐ 響應式文字
            ),
            SizedBox(height: context.spacing.md), // ⭐ 響應式間距
            Text(
              '點擊右下角「+」按鈕開始邀請學員',
              style: context.responsive.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ), // ⭐ 響應式文字
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

