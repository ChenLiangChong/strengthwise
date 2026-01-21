// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/health_assessment_models.dart';
import 'package:strengthwise/models/coach_display_preferences_model.dart';
import 'package:strengthwise/models/coach_assessment_note_model.dart';
import 'package:strengthwise/models/injury_coach_note_model.dart'; // ⭐ v3.3
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

  /// ⭐ v3.3: 快速編輯某個步驟（0=安全篩檢, 1=傷病史, 2=生活型態, 3=訓練目標, 4=緊急聯絡人）
  final ValueChanged<int>? onQuickEdit;

  /// ⭐ v3.3: 傷病教練備註（key=傷病部位, value=備註列表）
  final Map<String, List<InjuryCoachNoteModel>>? injuryCoachNotes;

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
    this.onQuickEdit, // ⭐ v3.3: 快速編輯
    this.injuryCoachNotes, // ⭐ v3.3: 傷病教練備註
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
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
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

  /// 根據偏好動態顯示欄位（固定順序）
  List<Widget> _buildPreferredFields(BuildContext context) {
    final fields = <Widget>[];
    final enabledFields = preferences?.healthAssessmentFields ??
        CoachDisplayPreferencesModel.defaultFields;

    // ⭐ v3.3: 按固定順序遍歷所有可用欄位，只顯示啟用的
    const orderedFieldKeys = [
      'safety_screening',
      'injuries',
      'cardiovascular',
      'bone_joint', // ⭐ v3.3: 新增
      'medications',
      'other_health_issues', // ⭐ v3.3: 新增
      'training_experience',
      'occupation_activity',
      'equipment_access',
      'training_goals',
      'emergency_contact',
    ];

    for (final fieldKey in orderedFieldKeys) {
      // 跳過未啟用的欄位
      if (!enabledFields.contains(fieldKey)) continue;

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
          // ⭐ v3.3: 檢查 PAR-Q+ 的心臟/胸痛/頭暈相關問題
          if (assessment.heartDisease ||
              assessment.chestPainExercise ||
              assessment.chestPainRest ||
              assessment.dizziness) {
            fieldWidget = _buildCardiovascular(context);
          }
          break;
        case 'bone_joint': // ⭐ v3.3: 骨骼關節問題
          if (assessment.boneJointProblem) {
            fieldWidget = _buildBoneJoint(context);
          }
          break;
        case 'other_health_issues': // ⭐ v3.3: 其他健康問題
          if (assessment.otherReason) {
            fieldWidget = _buildOtherHealthIssues(context);
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
          final emergencyContact = assessment.emergencyContact;
          if (emergencyContact != null && emergencyContact.isNotEmpty) {
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
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.errorContainer.withValues(alpha: 0.3),
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
                        color:
                            isLowRisk ? colorScheme.primary : colorScheme.error,
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

  /// 傷病史（⭐ v3.3: 顯示教練備註）
  Widget _buildInjuries(BuildContext context) {
    final theme = Theme.of(context);

    return _buildFieldContainer(
      context,
      icon: Icons.healing,
      title: '傷病史',
      onEdit: onQuickEdit != null ? () => onQuickEdit!(1) : null, // Step 2
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: assessment.injuries.take(3).map((injury) {
          // 取得該傷病的所有教練備註
          final notes = injuryCoachNotes?[injury.site] ?? [];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 傷病基本資訊
                Text(
                  '• ${injury.site} (${injury.status.label})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // 教練備註（左邊線條引用風格）
                if (notes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.primary.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: notes
                          .map((note) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  note.note,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
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
      onEdit: onQuickEdit != null ? () => onQuickEdit!(0) : null, // Step 1
      child: Text(
        assessment.medicationNote ?? '正在服用處方藥物',
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  /// 心血管系統（⭐ v3.3: 顯示 PAR-Q+ 詳細內容）
  Widget _buildCardiovascular(BuildContext context) {
    final theme = Theme.of(context);
    final items = <String>[];

    if (assessment.heartDisease) {
      items.add('• 心臟疾病');
      if (assessment.heartDiseaseNote?.isNotEmpty ?? false) {
        items.add('  → ${assessment.heartDiseaseNote}');
      }
    }
    if (assessment.chestPainExercise) {
      items.add('• 運動時胸痛');
    }
    if (assessment.chestPainRest) {
      items.add('• 靜止時胸痛');
    }
    if (assessment.dizziness) {
      items.add('• 頭暈或失去意識');
    }

    return _buildFieldContainer(
      context,
      icon: Icons.favorite,
      title: '心血管系統',
      onEdit: onQuickEdit != null ? () => onQuickEdit!(0) : null, // Step 1
      child: Text(
        items.join('\n'),
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  /// ⭐ v3.3: 骨骼關節問題
  Widget _buildBoneJoint(BuildContext context) {
    final theme = Theme.of(context);
    final boneJointNote = assessment.boneJointNote;

    return _buildFieldContainer(
      context,
      icon: Icons.accessibility_new,
      title: '骨骼關節問題',
      onEdit: onQuickEdit != null ? () => onQuickEdit!(0) : null, // Step 1
      child: Text(
        boneJointNote != null && boneJointNote.isNotEmpty
            ? boneJointNote
            : '有骨骼或關節問題',
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  /// ⭐ v3.3: 其他健康問題
  Widget _buildOtherHealthIssues(BuildContext context) {
    final theme = Theme.of(context);
    final otherReasonNote = assessment.otherReasonNote;

    return _buildFieldContainer(
      context,
      icon: Icons.info_outline,
      title: '其他健康問題',
      onEdit: onQuickEdit != null ? () => onQuickEdit!(0) : null, // Step 1
      child: Text(
        otherReasonNote != null && otherReasonNote.isNotEmpty
            ? otherReasonNote
            : '有其他不宜運動的原因',
        style: theme.textTheme.bodySmall,
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
      onEdit: onQuickEdit != null ? () => onQuickEdit!(2) : null, // Step 3
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
      onEdit: onQuickEdit != null ? () => onQuickEdit!(2) : null, // Step 3
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
      onEdit: onQuickEdit != null ? () => onQuickEdit!(2) : null, // Step 3
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
    final trainingGoals = assessment.trainingGoals;
    final notes = trainingGoals?.notes;

    return _buildFieldContainer(
      context,
      icon: Icons.flag,
      title: '訓練目標',
      onEdit: onQuickEdit != null ? () => onQuickEdit!(3) : null, // Step 4
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主要目標 + 數值 + 時程
          Text(
            trainingGoals.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          // 補充說明
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notes,
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
    final emergencyContact = assessment.emergencyContact;
    final name = emergencyContact?['name'] ?? '';
    final phone = emergencyContact?['phone'] ?? '';

    return _buildFieldContainer(
      context,
      icon: Icons.contact_phone,
      title: '緊急聯絡人',
      onEdit: onQuickEdit != null ? () => onQuickEdit!(4) : null, // Step 5
      child: Text(
        '$name ${phone.isNotEmpty ? '($phone)' : ''}',
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  /// 通用欄位容器（⭐ v3.3: 支援快速編輯圖標）
  Widget _buildFieldContainer(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
    VoidCallback? onEdit, // ⭐ v3.3: 快速編輯
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // ⭐ v3.3: 快速編輯圖標
              if (onEdit != null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: onEdit,
                    tooltip: '快速編輯',
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
