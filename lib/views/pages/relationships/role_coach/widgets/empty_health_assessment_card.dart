import 'package:flutter/material.dart';

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題列
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '健康評估',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 提示內容
            Container(
              padding: const EdgeInsets.all(16),
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
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '尚未建立健康評估',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '建議在首次上課前完成評估，以確保訓練安全與效果',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    context,
                    icon: Icons.shield_outlined,
                    text: '安全篩檢：排除訓練風險',
                  ),
                  const SizedBox(height: 4),
                  _buildInfoItem(
                    context,
                    icon: Icons.healing_outlined,
                    text: '傷病史：避免動作禁忌',
                  ),
                  const SizedBox(height: 4),
                  _buildInfoItem(
                    context,
                    icon: Icons.flag_outlined,
                    text: '訓練目標：個人化課表',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 建立按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCreateTap,
                icon: const Icon(Icons.add),
                label: const Text('立即建立評估'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
          size: 16,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}

