import 'package:flutter/material.dart';
import 'package:strengthwise/models/client_profile_model.dart';

/// 學員檔案卡片
/// 
/// 顯示學員的訓練目標、健康注意事項、訓練偏好
class ClientProfileCard extends StatelessWidget {
  final ClientProfile profile;
  final VoidCallback onEditTap;

  const ClientProfileCard({
    super.key,
    required this.profile,
    required this.onEditTap,
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
                  Icons.assignment,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '學員檔案',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEditTap,
                  tooltip: '編輯檔案',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 訓練目標
            _buildSection(
              context,
              icon: Icons.flag,
              iconColor: Colors.blue,
              label: '訓練目標',
              content: profile.goals,
            ),
            
            // 健康注意事項
            if (profile.hasHealthNotes) ...[
              const SizedBox(height: 12),
              _buildSection(
                context,
                icon: Icons.healing,
                iconColor: Colors.orange,
                label: '健康注意',
                content: profile.healthNotes!,
              ),
            ],
            
            // 訓練偏好
            if (profile.hasPreferences) ...[
              const SizedBox(height: 12),
              _buildSection(
                context,
                icon: Icons.favorite,
                iconColor: Colors.red,
                label: '訓練偏好',
                content: profile.preferences!,
              ),
            ],
            
            // 建檔日期
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '建檔於 ${_formatDate(profile.assessmentDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 建立區段
  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String content,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

