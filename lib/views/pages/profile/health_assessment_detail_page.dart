// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/health_assessment/health_assessment_model.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/models/health_assessment/injury_record.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/interfaces/i_injury_coach_note_service.dart';
import 'package:strengthwise/models/injury_coach_note_model.dart';

/// 健康評估完整詳情頁面
///
/// 顯示健康評估的所有欄位詳細資訊
/// 共用於教練端和學員端
class HealthAssessmentDetailPage extends StatefulWidget {
  final HealthAssessmentModel assessment;
  final String? userName; // 顯示用（可選）

  const HealthAssessmentDetailPage({
    super.key,
    required this.assessment,
    this.userName,
  });

  @override
  State<HealthAssessmentDetailPage> createState() =>
      _HealthAssessmentDetailPageState();
}

class _HealthAssessmentDetailPageState
    extends State<HealthAssessmentDetailPage> {
  late final IInjuryCoachNoteService _injuryNoteService;

  // ⭐ v3.4: 傷病教練備註快取（Map<injurySite, List<InjuryCoachNoteModel>>）
  Map<String, List<InjuryCoachNoteModel>> _injuryCoachNotes = {};
  bool _isLoadingNotes = true;

  HealthAssessmentModel get assessment => widget.assessment;
  String? get userName => widget.userName;

  @override
  void initState() {
    super.initState();
    _injuryNoteService = serviceLocator<IInjuryCoachNoteService>();
    _loadInjuryCoachNotes();
  }

  /// ⭐ v3.4: 載入傷病教練備註
  Future<void> _loadInjuryCoachNotes() async {
    debugPrint('[HealthAssessmentDetail] 開始載入教練備註');
    debugPrint('[HealthAssessmentDetail] assessment.userId = ${assessment.userId}');
    debugPrint('[HealthAssessmentDetail] injuries = ${assessment.injuries.map((e) => e.site).toList()}');
    
    try {
      final notes = await _injuryNoteService.getNotesForClient(
        clientId: assessment.userId,
      );
      debugPrint('[HealthAssessmentDetail] 載入完成，共 ${notes.length} 個部位有備註');
      for (final entry in notes.entries) {
        debugPrint('[HealthAssessmentDetail]   - ${entry.key}: ${entry.value.length} 個備註');
      }
      if (mounted) {
        setState(() {
          _injuryCoachNotes = notes;
          _isLoadingNotes = false;
        });
      }
    } catch (e) {
      debugPrint('[HealthAssessmentDetail] 載入教練備註失敗: $e');
      if (mounted) {
        setState(() => _isLoadingNotes = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName != null ? '$userName 的健康評估' : '健康評估詳情'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: context.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 評估日期與風險狀態
                _buildHeaderSection(context),
                const SizedBox(height: 24),

                // PAR-Q+ 安全篩檢
                _buildSectionTitle(context, Icons.health_and_safety, 'PAR-Q+ 安全篩檢'),
                const SizedBox(height: 12),
                _buildParQSection(context),
                const SizedBox(height: 24),

                // 傷病史
                if (assessment.injuries.isNotEmpty) ...[
                  _buildSectionTitle(context, Icons.healing, '傷病史'),
                  const SizedBox(height: 12),
                  _buildInjuriesSection(context),
                  const SizedBox(height: 24),
                ],

                // 生活型態
                _buildSectionTitle(context, Icons.self_improvement, '生活型態'),
                const SizedBox(height: 12),
                _buildLifestyleSection(context),
                const SizedBox(height: 24),

                // 訓練目標
                if (assessment.trainingGoals != null) ...[
                  _buildSectionTitle(context, Icons.flag, '訓練目標'),
                  const SizedBox(height: 12),
                  _buildGoalsSection(context),
                  const SizedBox(height: 24),
                ],

                // 緊急聯絡人
                if (assessment.emergencyContact != null &&
                    assessment.emergencyContact!.isNotEmpty) ...[
                  _buildSectionTitle(context, Icons.contact_phone, '緊急聯絡人'),
                  const SizedBox(height: 12),
                  _buildEmergencyContactSection(context),
                  const SizedBox(height: 24),
                ],

                // 免責聲明
                _buildDisclaimerSection(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 標題區塊
  Widget _buildHeaderSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLowRisk = assessment.isCleared;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 風險評估狀態
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isLowRisk
                    ? colorScheme.primaryContainer.withOpacity(0.5)
                    : colorScheme.errorContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isLowRisk ? Icons.check_circle : Icons.warning,
                    color: isLowRisk ? colorScheme.primary : colorScheme.error,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '風險等級：${assessment.riskLevelLabel}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLowRisk
                                ? colorScheme.primary
                                : colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assessment.riskLevelDescription,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 評估日期
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '評估日期：${_formatDate(assessment.assessmentDate)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
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

  /// 區塊標題
  Widget _buildSectionTitle(BuildContext context, IconData icon, String title) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// PAR-Q+ 區塊
  Widget _buildParQSection(BuildContext context) {
    final theme = Theme.of(context);

    final questions = [
      _ParQItem(
        question: '心臟或心血管疾病',
        answer: assessment.heartDisease,
        note: assessment.heartDiseaseNote,
      ),
      _ParQItem(
        question: '運動時胸痛',
        answer: assessment.chestPainExercise,
      ),
      _ParQItem(
        question: '休息時胸痛',
        answer: assessment.chestPainRest,
      ),
      _ParQItem(
        question: '頭暈或失去平衡',
        answer: assessment.dizziness,
      ),
      _ParQItem(
        question: '骨骼或關節問題',
        answer: assessment.boneJointProblem,
        note: assessment.boneJointNote,
      ),
      _ParQItem(
        question: '正在服用處方藥物',
        answer: assessment.medication,
        note: assessment.medicationNote,
      ),
      _ParQItem(
        question: '其他不適合運動的原因',
        answer: assessment.otherReason,
        note: assessment.otherReasonNote,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: questions.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.answer ? Icons.warning_amber : Icons.check,
                    size: 20,
                    color: item.answer
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.question,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (item.note != null && item.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.note!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    item.answer ? '是' : '否',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: item.answer
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 傷病史區塊
  Widget _buildInjuriesSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: assessment.injuries.map((injury) {
            // ⭐ v3.4: 獲取該傷病的教練備註
            final coachNotes = _injuryCoachNotes[injury.site] ?? [];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getInjuryStatusColor(injury.status, theme)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          injury.status.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getInjuryStatusColor(injury.status, theme),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              injury.site,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (injury.diagnosis != null &&
                                injury.diagnosis!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                injury.diagnosis!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            if (injury.limitations != null &&
                                injury.limitations!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '限制：${injury.limitations!}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  // ⭐ v3.4: 顯示教練備註
                  if (coachNotes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.note_alt,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '教練備註',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...coachNotes.map((note) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  note.note,
                                  style: theme.textTheme.bodySmall,
                                ),
                              )),
                        ],
                      ),
                    ),
                  ] else if (_isLoadingNotes) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '載入教練備註...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 生活型態區塊
  Widget _buildLifestyleSection(BuildContext context) {
    final theme = Theme.of(context);

    final items = <_InfoItem>[];

    if (assessment.trainingExperience != null) {
      items.add(_InfoItem(
        label: '訓練經驗',
        value: assessment.trainingExperience!.label +
            (assessment.trainingYears != null
                ? ' (${assessment.trainingYears}年)'
                : ''),
      ));
    }

    if (assessment.occupationActivity != null) {
      items.add(_InfoItem(
        label: '職業活動度',
        value: assessment.occupationActivity!.label,
      ));
    }

    if (assessment.sleepHours != null) {
      items.add(_InfoItem(
        label: '平均睡眠',
        value: '${assessment.sleepHours} 小時/天',
      ));
    }

    if (assessment.weeklySessions != null) {
      items.add(_InfoItem(
        label: '每週訓練',
        value: '${assessment.weeklySessions} 次/週',
      ));
    }

    if (assessment.equipmentAccess.isNotEmpty) {
      items.add(_InfoItem(
        label: '可用器材',
        value: assessment.equipmentAccess.join('、'),
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.value,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 訓練目標區塊
  Widget _buildGoalsSection(BuildContext context) {
    final theme = Theme.of(context);
    final goals = assessment.trainingGoals!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主要目標
            Row(
              children: [
                Icon(
                  Icons.flag,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  goals.primaryLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // 目標數值
            if (goals.targetKg != null || goals.timeframeMonths != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  '${goals.targetKg != null ? '目標: ${goals.targetKg}kg' : ''}'
                  '${goals.targetKg != null && goals.timeframeMonths != null ? ' / ' : ''}'
                  '${goals.timeframeMonths != null ? '${goals.timeframeMonths}個月' : ''}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
            // 補充說明
            if (goals.notes != null && goals.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  goals.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 緊急聯絡人區塊
  Widget _buildEmergencyContactSection(BuildContext context) {
    final theme = Theme.of(context);
    final contact = assessment.emergencyContact!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact['name'] != null) ...[
              _buildContactRow(theme, '姓名', contact['name']!),
            ],
            if (contact['phone'] != null) ...[
              const SizedBox(height: 8),
              _buildContactRow(theme, '電話', contact['phone']!),
            ],
            if (contact['relationship'] != null) ...[
              const SizedBox(height: 8),
              _buildContactRow(theme, '關係', contact['relationship']!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(ThemeData theme, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  /// 免責聲明
  Widget _buildDisclaimerSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '本評估僅供參考，不構成醫療診斷。如有任何健康疑慮，請諮詢醫療專業人員。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 傷病狀態顏色
  Color _getInjuryStatusColor(InjuryStatus status, ThemeData theme) {
    switch (status) {
      case InjuryStatus.acute:
        return theme.colorScheme.error;
      case InjuryStatus.subacute:
        return Colors.orange;
      case InjuryStatus.chronic:
        return Colors.amber;
      case InjuryStatus.postSurgery:
        return theme.colorScheme.primary;
    }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

/// PAR-Q 項目
class _ParQItem {
  final String question;
  final bool answer;
  final String? note;

  _ParQItem({
    required this.question,
    required this.answer,
    this.note,
  });
}

/// 資訊項目
class _InfoItem {
  final String label;
  final String value;

  _InfoItem({
    required this.label,
    required this.value,
  });
}

