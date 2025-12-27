import 'package:flutter/material.dart';

/// 動作篩選步驟 Widget
///
/// 用於顯示訓練類型、身體部位、特定肌群、器材類別、器材子類別的選擇列表
class ExerciseFilterStep extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> items;
  final String? selectedValue;
  final Function(String) onSelect;
  final bool showSkipButton;
  final VoidCallback? onSkip;

  const ExerciseFilterStep({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    this.selectedValue,
    required this.onSelect,
    this.showSkipButton = false,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題區域
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle != null) ...[
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),

        // 選項列表
        if (items.isEmpty)
          _buildEmptyState(context)
        else
          _buildItemList(context),

        // 跳過按鈕
        if (showSkipButton && items.isNotEmpty && onSkip != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.skip_next),
              label: const Text('跳過此分類，直接查看動作'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: onSkip,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '沒有找到符合條件的分類',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '將自動進入下一步',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item == selectedValue;

          return Card(
            elevation: isSelected ? 4 : 1,
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            margin: const EdgeInsets.only(bottom: 8.0),
            child: ListTile(
              title: Text(
                item,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => onSelect(item),
            ),
          );
        },
      ),
    );
  }
}
