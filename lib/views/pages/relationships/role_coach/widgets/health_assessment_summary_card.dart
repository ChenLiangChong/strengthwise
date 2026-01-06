// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/health_assessment_models.dart';
import 'package:strengthwise/models/coach_display_preferences_model.dart';
import 'package:strengthwise/models/coach_assessment_note_model.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 健康評估摘要卡片
/// 
/// 顯示已填寫的健康評估重點資訊
/// 
/// 使用情境：
/// - 教練端：顯示所有欄位，包含教練備註與設定按鈕
/// - 學員端：隱藏教練備註與設定按鈕
class HealthAssessmentSummaryCard extends StatelessWidget {
  final HealthAssessmentModel assessment;
  final CoachDisplayPreferencesModel? preferences;
  final CoachAssessmentNoteModel? coachNote;
  final VoidCallback onViewFull;
  final VoidCallback? onEdit; // ⭐ v3.1: 可選，學員模式不需要
  final VoidCallback? onConfigurePreferences;
  final ValueChanged<String>? onCoachNoteChanged;
  final bool isClientView;

  const HealthAssessmentSummaryCard({
    super.key,
    required this.assessment,
    this.preferences,
    this.coachNote,
    required this.onViewFull,
    this.onEdit, // ⭐ v3.1: 改為可選
    this.onConfigurePreferences,
    this.onCoachNoteChanged,
    this.isClientView = false,
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
                // ⭐ 教練視角：顯示設定按鈕
                if (!isClientView && onConfigurePreferences != null)
                  IconButton(
                    icon: const Icon(Icons.tune_outlined),
                    onPressed: onConfigurePreferences,
                    tooltip: '設定顯示偏好',
                  ),
                // ⭐ v3.1: 只有有編輯權限時才顯示編輯按鈕
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                    tooltip: '編輯',
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 根據偏好動態顯示欄位
            ..._buildPreferredFields(context),
            
            const SizedBox(height: 16),
            
            // 底部按鈕列
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewFull,
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: const Text('查看完整評估'),
                  ),
                ),
              ],
            ),
            
            // ⭐ 教練備註區塊（僅教練視角顯示）
            if (!isClientView && onCoachNoteChanged != null) ...[
              const SizedBox(height: 16),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 16),
              _buildCoachNoteSection(context),
            ],
          ],
        ),
      ),
    );
  }

  /// 根據偏好動態顯示欄位
  List<Widget> _buildPreferredFields(BuildContext context) {
    final fields = <Widget>[];
    final enabledFields = preferences?.healthAssessmentFields ?? 
        CoachDisplayPreferencesModel.defaultFields;

    for (final fieldKey in enabledFields) {
      Widget? fieldWidget;

      switch (fieldKey) {
        case 'safety_screening':
          fieldWidget = _buildSafetyStatus(context);
          break;
        case 'injuries':
          if (assessment.injuries.isNotEmpty) {
            fieldWidget = _buildInjuries(context);
          }
          break;
        case 'medications':
          if (assessment.medication) {
            fieldWidget = _buildMedications(context);
          }
          break;
        case 'cardiovascular':
          if (assessment.cardiovascularDetails != null && 
              assessment.cardiovascularDetails!.isNotEmpty) {
            fieldWidget = _buildCardiovascular(context);
          }
          break;
        case 'metabolic':
          if (assessment.metabolicDetails != null && 
              assessment.metabolicDetails!.isNotEmpty) {
            fieldWidget = _buildMetabolic(context);
          }
          break;
        case 'respiratory':
          if (assessment.respiratoryDetails != null && 
              assessment.respiratoryDetails!.isNotEmpty) {
            fieldWidget = _buildRespiratory(context);
          }
          break;
        case 'training_experience':
          if (assessment.trainingExperience != null) {
            fieldWidget = _buildTrainingExperience(context);
          }
          break;
        case 'occupation_activity':
          if (assessment.occupationActivity != null) {
            fieldWidget = _buildOccupationActivity(context);
          }
          break;
        case 'equipment_access':
          if (assessment.equipmentAccess.isNotEmpty) {
            fieldWidget = _buildEquipmentAccess(context);
          }
          break;
        case 'training_goals':
          if (assessment.trainingGoals != null) {
            fieldWidget = _buildTrainingGoals(context);
          }
          break;
        case 'emergency_contact':
          if (assessment.emergencyContact != null && 
              assessment.emergencyContact!.isNotEmpty) {
            fieldWidget = _buildEmergencyContact(context);
          }
          break;
      }

      if (fieldWidget != null) {
        if (fields.isNotEmpty) {
          fields.add(const SizedBox(height: 12));
        }
        fields.add(fieldWidget);
      }
    }

    // 如果沒有任何欄位，顯示預設的安全篩檢
    if (fields.isEmpty) {
      fields.add(_buildSafetyStatus(context));
    }

    return fields;
  }

  /// 安全篩檢狀態
  Widget _buildSafetyStatus(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLowRisk = assessment.isCleared;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLowRisk 
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLowRisk ? Icons.check_circle : Icons.warning,
                color: isLowRisk ? colorScheme.primary : colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '風險評估：${assessment.riskLevelLabel}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLowRisk ? colorScheme.primary : colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              assessment.riskLevelDescription,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 傷病史
  Widget _buildInjuries(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildFieldContainer(
      context,
      icon: Icons.healing,
      title: '傷病史',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: assessment.injuries.take(3).map((injury) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '• ${injury.site} (${injury.status.label})',
            style: theme.textTheme.bodySmall,
          ),
        )).toList(),
      ),
    );
  }

  /// 用藥記錄
  Widget _buildMedications(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildFieldContainer(
      context,
      icon: Icons.medication,
      title: '用藥記錄',
      child: Text(
        assessment.medicationNote ?? '正在服用處方藥物',
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  /// 心血管系統
  Widget _buildCardiovascular(BuildContext context) {
    return _buildFieldContainer(
      context,
      icon: Icons.favorite,
      title: '心血管系統',
      child: Text(
        '有心血管相關記錄',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  /// 代謝系統
  Widget _buildMetabolic(BuildContext context) {
    return _buildFieldContainer(
      context,
      icon: Icons.biotech,
      title: '代謝系統',
      child: Text(
        '有代謝系統相關記錄',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  /// 呼吸系統
  Widget _buildRespiratory(BuildContext context) {
    return _buildFieldContainer(
      context,
      icon: Icons.air,
      title: '呼吸系統',
      child: Text(
        '有呼吸系統相關記錄',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  /// 訓練經驗
  Widget _buildTrainingExperience(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildFieldContainer(
      context,
      icon: Icons.fitness_center,
      title: '訓練經驗',
      child: Text(
        '${assessment.trainingExperience!.label}'
        '${assessment.trainingYears != null ? ' (${assessment.trainingYears}年)' : ''}',
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  /// 職業活動度
  Widget _buildOccupationActivity(BuildContext context) {
    return _buildFieldContainer(
      context,
      icon: Icons.work,
      title: '職業活動度',
      child: Text(
        assessment.occupationActivity!.label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  /// 可用器材
  Widget _buildEquipmentAccess(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildFieldContainer(
      context,
      icon: Icons.settings,
      title: '可用器材',
      child: Text(
        assessment.equipmentAccess.take(5).join('、') +
            (assessment.equipmentAccess.length > 5 ? ' 等' : ''),
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  /// 訓練目標
  Widget _buildTrainingGoals(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildFieldContainer(
      context,
      icon: Icons.flag,
      title: '訓練目標',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主要目標 + 數值 + 時程
          Text(
            assessment.trainingGoals.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          // 補充說明
          if (assessment.trainingGoals!.notes != null && 
              assessment.trainingGoals!.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              assessment.trainingGoals!.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 緊急聯絡人
  Widget _buildEmergencyContact(BuildContext context) {
    final theme = Theme.of(context);
    final name = assessment.emergencyContact!['name'] ?? '';
    final phone = assessment.emergencyContact!['phone'] ?? '';
    
    return _buildFieldContainer(
      context,
      icon: Icons.contact_phone,
      title: '緊急聯絡人',
      child: Text(
        '$name ${phone.isNotEmpty ? '($phone)' : ''}',
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  /// 通用欄位容器
  Widget _buildFieldContainer(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: child,
          ),
        ],
      ),
    );
  }

  /// ⭐ 教練備註區塊
  Widget _buildCoachNoteSection(BuildContext context) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: coachNote?.notes ?? '');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '教練私人備註',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '您的私人觀察與建議（學員無法查看）',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '例如：需特別注意右膝舊傷，深蹲時建議使用輔助器材...',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.all(12),
            suffixIcon: IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: () {
                if (onCoachNoteChanged != null) {
                  onCoachNoteChanged!(controller.text.trim());
                }
              },
              tooltip: '儲存備註',
            ),
          ),
          maxLines: 3,
          minLines: 2,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (onCoachNoteChanged != null) {
              onCoachNoteChanged!(value.trim());
            }
          },
        ),
      ],
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

