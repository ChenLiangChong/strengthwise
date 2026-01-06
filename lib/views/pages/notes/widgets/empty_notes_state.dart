// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 空筆記狀態組件
/// 
/// 當沒有筆記時顯示的空狀態提示
class EmptyNotesState extends StatelessWidget {
  final String filter; // 'all', 'private', 'shared'
  final VoidCallback onCreateNote;

  const EmptyNotesState({
    Key? key,
    required this.filter,
    required this.onCreateNote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.xl), // ⭐ 響應式邊距
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 圖示
            Icon(
              _getIcon(),
              size: 80.scaled(context), // ⭐ 響應式圖標
              color: colorScheme.primary.withOpacity(0.3),
            ),
            
            SizedBox(height: context.spacing.lg), // ⭐ 響應式間距
            
            // 標題
            Text(
              _getTitle(),
              style: context.responsive.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ), // ⭐ 響應式文字
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: context.spacing.sm), // ⭐ 響應式間距
            
            // 說明文字
            Text(
              _getDescription(),
              style: context.responsive.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ), // ⭐ 響應式文字
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: context.spacing.xl), // ⭐ 響應式間距
            
            // 新增筆記按鈕（僅在 'all' 篩選時顯示）
            if (filter == 'all')
              ElevatedButton.icon(
                onPressed: onCreateNote,
                icon: Icon(Icons.add, size: 20.scaled(context)), // ⭐ 響應式圖標
                label: Text('新增筆記', style: context.responsive.labelLarge),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.xl, // ⭐ 響應式內距
                    vertical: context.spacing.md,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 根據篩選條件返回對應圖示
  IconData _getIcon() {
    switch (filter) {
      case 'private':
        return Icons.lock_outline;
      case 'shared':
        return Icons.share_outlined;
      default:
        return Icons.note_outlined;
    }
  }

  /// 根據篩選條件返回標題
  String _getTitle() {
    switch (filter) {
      case 'private':
        return '沒有私人筆記';
      case 'shared':
        return '沒有共享筆記';
      default:
        return '還沒有筆記';
    }
  }

  /// 根據篩選條件返回說明文字
  String _getDescription() {
    switch (filter) {
      case 'private':
        return '私人筆記只有教練自己可以查看';
      case 'shared':
        return '共享筆記可以與學員一起查看';
      default:
        return '開始記錄課程筆記，追蹤學員的訓練進度';
    }
  }
}

