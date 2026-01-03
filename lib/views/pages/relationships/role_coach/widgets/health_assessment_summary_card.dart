import 'package:flutter/material.dart';
import 'package:strengthwise/models/health_assessment_models.dart';

/// 健康評估摘要卡片
/// 
/// 顯示已填寫的健康評估重點資訊
class HealthAssessmentSummaryCard extends StatelessWidget {
  final HealthAssessmentModel assessment;
  final VoidCallback onViewFull;
  final VoidCallback onEdit;

  const HealthAssessmentSummaryCard({
    super.key,
    required this.assessment,
    required this.onViewFull,
    required this.onEdit,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '健康評估',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '評估日期：${_formatDate(assessment.assessmentDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  tooltip: '編輯',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 安全篩檢狀態
            _buildSafetyStatus(context),
            
            // 警示摘要
            if (assessment.hasWarnings) ...[
              const SizedBox(height: 12),
              _buildWarnings(context),
            ],
            
            // 訓練背景
            if (assessment.trainingExperience != null || assessment.trainingGoals != null) ...[
              const SizedBox(height: 12),
              _buildTrainingInfo(context),
            ],
            
            const SizedBox(height: 16),
            
            // 查看完整按鈕
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewFull,
                icon: const Icon(Icons.visibility_outlined, size: 20),
                label: const Text('查看完整評估'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 安全篩檢狀態
  Widget _buildSafetyStatus(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCleared = assessment.isCleared;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCleared 
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isCleared ? Icons.check_circle : Icons.warning,
            color: isCleared ? colorScheme.primary : colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isCleared ? '✅ 已通過安全篩檢' : '⚠️ 安全篩檢未通過，需特別注意',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCleared ? colorScheme.primary : colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 警示摘要
  Widget _buildWarnings(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final warnings = assessment.getWarningSummary();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 18,
                color: colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                '需要注意',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...warnings.map((warning) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Expanded(
                  child: Text(
                    warning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// 訓練資訊
  Widget _buildTrainingInfo(BuildContext context) {
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
          if (assessment.trainingExperience != null) ...[
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '訓練經驗：',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  assessment.trainingExperience!.label,
                  style: theme.textTheme.bodySmall,
                ),
                if (assessment.trainingYears != null) ...[
                  Text(
                    ' (${assessment.trainingYears}年)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (assessment.trainingGoals != null) ...[
            if (assessment.trainingExperience != null) const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.flag,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodySmall,
                      children: [
                        TextSpan(
                          text: '訓練目標：',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: assessment.trainingGoals.toString(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

