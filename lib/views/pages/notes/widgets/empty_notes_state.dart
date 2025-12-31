import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 圖示
            Icon(
              _getIcon(),
              size: 80,
              color: colorScheme.primary.withOpacity(0.3),
            ),
            
            const SizedBox(height: 24),
            
            // 標題
            Text(
              _getTitle(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // 說明文字
            Text(
              _getDescription(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // 新增筆記按鈕（僅在 'all' 篩選時顯示）
            if (filter == 'all')
              ElevatedButton.icon(
                onPressed: onCreateNote,
                icon: const Icon(Icons.add),
                label: const Text('新增筆記'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
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

