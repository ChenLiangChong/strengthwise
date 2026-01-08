// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/health_assessment_models.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/interfaces/i_health_assessment_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// 健康評估問卷頁面
///
/// 多步驟表單，包含 PAR-Q+ 問卷、傷病史、訓練背景與目標
///
/// 使用情境：
/// - 教練為學員填寫（isClientSelfFilling = false）
/// - 學員自己填寫（isClientSelfFilling = true）
class HealthAssessmentPage extends StatefulWidget {
  /// 學員 ID
  final String clientId;

  /// 學員名稱（顯示用）
  final String clientName;

  /// 現有評估（編輯模式）
  final HealthAssessmentModel? existingAssessment;

  /// 是否為學員自填（學員端使用）
  final bool isClientSelfFilling;

  const HealthAssessmentPage({
    super.key,
    required this.clientId,
    required this.clientName,
    this.existingAssessment,
    this.isClientSelfFilling = false, // 預設為教練填寫
  });

  @override
  State<HealthAssessmentPage> createState() => _HealthAssessmentPageState();
}

class _HealthAssessmentPageState extends State<HealthAssessmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  int _currentStep = 0;
  final int _totalSteps = 5;

  // Services
  late final IHealthAssessmentService _healthService;
  late final ErrorHandlingService _errorService;
  final _uuid = const Uuid();
  bool _isLoading = false;

  // =========================================
  // PAR-Q+ 基礎篩檢（步驟 1）
  // =========================================
  bool _heartDisease = false;
  final _heartDiseaseNoteController = TextEditingController();

  bool _chestPainExercise = false;
  bool _chestPainRest = false;
  bool _dizziness = false;

  bool _boneJointProblem = false;
  final _boneJointNoteController = TextEditingController();

  bool _medication = false;
  final _medicationNoteController = TextEditingController();

  bool _otherReason = false;
  final _otherReasonNoteController = TextEditingController();

  // =========================================
  // 傷病史（步驟 2）
  // =========================================
  final List<InjuryRecord> _injuries = [];

  // =========================================
  // 生活型態（步驟 3）
  // =========================================
  TrainingLevel? _trainingExperience;
  final _trainingYearsController = TextEditingController();
  ActivityLevel? _occupationActivity;
  int? _weeklySessions;
  final _sleepHoursController = TextEditingController();
  final List<String> _selectedEquipment = [];

  // =========================================
  // 訓練目標（步驟 4）
  // =========================================
  String _primaryGoal = 'health';
  final _targetKgController = TextEditingController();
  final _timeframeMonthsController = TextEditingController();
  final _goalNotesController = TextEditingController();

  // =========================================
  // 緊急聯絡人（步驟 5）
  // =========================================
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _healthService = serviceLocator<IHealthAssessmentService>();
    _errorService = serviceLocator<ErrorHandlingService>();
    _loadExistingData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartDiseaseNoteController.dispose();
    _boneJointNoteController.dispose();
    _medicationNoteController.dispose();
    _otherReasonNoteController.dispose();
    _trainingYearsController.dispose();
    _sleepHoursController.dispose();
    _targetKgController.dispose();
    _timeframeMonthsController.dispose();
    _goalNotesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationshipController.dispose();
    super.dispose();
  }

  /// 載入現有資料（編輯模式）
  void _loadExistingData() {
    final assessment = widget.existingAssessment;
    if (assessment == null) return;

    setState(() {
      // PAR-Q+
      _heartDisease = assessment.heartDisease;
      _heartDiseaseNoteController.text = assessment.heartDiseaseNote ?? '';
      _chestPainExercise = assessment.chestPainExercise;
      _chestPainRest = assessment.chestPainRest;
      _dizziness = assessment.dizziness;
      _boneJointProblem = assessment.boneJointProblem;
      _boneJointNoteController.text = assessment.boneJointNote ?? '';
      _medication = assessment.medication;
      _medicationNoteController.text = assessment.medicationNote ?? '';
      _otherReason = assessment.otherReason;
      _otherReasonNoteController.text = assessment.otherReasonNote ?? '';

      // 傷病史
      _injuries.addAll(assessment.injuries);

      // 生活型態
      _trainingExperience = assessment.trainingExperience;
      _trainingYearsController.text =
          assessment.trainingYears?.toString() ?? '';
      _occupationActivity = assessment.occupationActivity;
      _weeklySessions = assessment.weeklySessions;
      _sleepHoursController.text = assessment.sleepHours?.toString() ?? '';
      _selectedEquipment.addAll(assessment.equipmentAccess);

      // 訓練目標
      if (assessment.trainingGoals != null) {
        _primaryGoal = assessment.trainingGoals!.primary;
        _targetKgController.text =
            assessment.trainingGoals!.targetKg?.toString() ?? '';
        _timeframeMonthsController.text =
            assessment.trainingGoals!.timeframeMonths?.toString() ?? '';
        _goalNotesController.text = assessment.trainingGoals!.notes ?? '';
      }

      // 緊急聯絡人
      if (assessment.emergencyContact != null) {
        _emergencyNameController.text =
            assessment.emergencyContact!['name'] ?? '';
        _emergencyPhoneController.text =
            assessment.emergencyContact!['phone'] ?? '';
        _emergencyRelationshipController.text =
            assessment.emergencyContact!['relationship'] ?? '';
      }
    });
  }

  /// 下一步
  void _nextStep() {
    // 驗證當前步驟
    if (!_validateCurrentStep()) {
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 驗證當前步驟
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // PAR-Q+
        // 檢查備註欄位
        if (_heartDisease && _heartDiseaseNoteController.text.trim().isEmpty) {
          NotificationUtils.showError(context, '請說明心臟疾病的詳細情況');
          return false;
        }
        if (_boneJointProblem && _boneJointNoteController.text.trim().isEmpty) {
          NotificationUtils.showError(context, '請說明骨骼或關節問題的部位與狀況');
          return false;
        }
        if (_medication && _medicationNoteController.text.trim().isEmpty) {
          NotificationUtils.showError(context, '請列出服用的藥物名稱');
          return false;
        }
        if (_otherReason && _otherReasonNoteController.text.trim().isEmpty) {
          NotificationUtils.showError(context, '請說明其他不宜運動的原因');
          return false;
        }
        return true;

      case 1: // 傷病史
        // 目前為佔位符，無需驗證
        return true;

      case 2: // 生活型態
        if (_trainingExperience == null) {
          NotificationUtils.showError(context, '請選擇訓練經驗等級');
          return false;
        }
        return true;

      case 3: // 訓練目標
        // 主要目標已有預設值，無需驗證
        return true;

      case 4: // 緊急聯絡人
        // 選填，無需驗證
        return true;

      default:
        return true;
    }
  }

  /// 上一步
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 儲存評估
  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      NotificationUtils.showError(context, '請檢查輸入內容');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 取得當前使用者 ID
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('無法取得使用者 ID');
      }

      // 建立或更新評估
      final assessment = HealthAssessmentModel(
        id: widget.existingAssessment?.id ?? _uuid.v4(),
        userId: widget.clientId,
        assessedBy: currentUserId,
        assessmentDate: DateTime.now(),

        // PAR-Q+ 基礎篩檢
        heartDisease: _heartDisease,
        heartDiseaseNote:
            _heartDisease ? _heartDiseaseNoteController.text.trim() : null,
        chestPainExercise: _chestPainExercise,
        chestPainRest: _chestPainRest,
        dizziness: _dizziness,
        boneJointProblem: _boneJointProblem,
        boneJointNote:
            _boneJointProblem ? _boneJointNoteController.text.trim() : null,
        medication: _medication,
        medicationNote:
            _medication ? _medicationNoteController.text.trim() : null,
        otherReason: _otherReason,
        otherReasonNote:
            _otherReason ? _otherReasonNoteController.text.trim() : null,
        isCleared: _isCleared(),

        // 進階評估
        cardiovascularDetails: null,
        injuries: _injuries,
        metabolicDetails: null,
        respiratoryDetails: null,

        // 生活型態
        trainingExperience: _trainingExperience,
        trainingYears: _trainingYearsController.text.isNotEmpty
            ? double.tryParse(_trainingYearsController.text)
            : null,
        occupationActivity: _occupationActivity,
        equipmentAccess: _selectedEquipment,
        weeklySessions: _weeklySessions,
        sleepHours: _sleepHoursController.text.isNotEmpty
            ? double.tryParse(_sleepHoursController.text)
            : null,

        // 訓練目標
        trainingGoals: TrainingGoals(
          primary: _primaryGoal,
          targetKg: _targetKgController.text.isNotEmpty
              ? double.tryParse(_targetKgController.text)
              : null,
          timeframeMonths: _timeframeMonthsController.text.isNotEmpty
              ? int.tryParse(_timeframeMonthsController.text)
              : null,
          notes: _goalNotesController.text.isNotEmpty
              ? _goalNotesController.text.trim()
              : null,
        ),

        // 版本控制
        version: (widget.existingAssessment?.version ?? 0) + 1,
        isCurrent: true,
        emergencyContact: _buildEmergencyContact(),
        createdAt: widget.existingAssessment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 呼叫 Service
      if (widget.existingAssessment != null) {
        await _healthService.updateAssessment(assessment);
        if (!mounted) return;
        NotificationUtils.showSuccess(context, '健康評估已更新');
      } else {
        await _healthService.createAssessment(assessment, setAsCurrent: true);
        if (!mounted) return;
        NotificationUtils.showSuccess(context, '健康評估已建立');
      }

      // 返回評估對象（讓調用者可以重新載入）
      if (!mounted) return;
      Navigator.pop(context, assessment);
    } catch (e, stackTrace) {
      _errorService.logError(
        '儲存健康評估失敗: $e',
        type: 'HealthAssessmentPage',
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      NotificationUtils.showError(context, '儲存失敗，請稍後再試');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 建立緊急聯絡人 Map
  Map<String, dynamic>? _buildEmergencyContact() {
    final name = _emergencyNameController.text.trim();
    final phone = _emergencyPhoneController.text.trim();
    final relationship = _emergencyRelationshipController.text.trim();

    if (name.isEmpty && phone.isEmpty && relationship.isEmpty) {
      return null;
    }

    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingAssessment == null
            ? (widget.isClientSelfFilling ? '填寫我的健康評估' : '建立健康評估')
            : '編輯健康評估'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 步驟指示器
            _buildStepIndicator(theme),

            // 表單內容
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1SafetyScreening(theme),
                  _buildStep2InjuryHistory(theme),
                  _buildStep3Lifestyle(theme),
                  _buildStep4TrainingGoals(theme),
                  _buildStep5EmergencyContact(theme),
                ],
              ),
            ),

            // 導航按鈕
            _buildNavigationButtons(theme),
          ],
        ),
      ),
    );
  }

  /// 步驟指示器
  Widget _buildStepIndicator(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.spacing.md, // ⭐ 響應式間距
        horizontal: context.spacing.lg,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: List.generate(
          _totalSteps,
          (index) => Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < _totalSteps - 1)
                  SizedBox(width: context.spacing.xs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 步驟 1：基礎安全篩檢
  Widget _buildStep1SafetyScreening(ThemeData theme) {
    return ListView(
      padding: context.pagePadding, // ⭐ 響應式邊距
      children: [
        Text(
          '步驟 1/5：基礎安全篩檢',
          style: context.responsive.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ), // ⭐ 響應式文字
        ),
        SizedBox(height: context.spacing.sm), // ⭐ 響應式間距
        Text(
          '請誠實回答以下問題，以確保訓練安全',
          style: context.responsive.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ), // ⭐ 響應式文字
        ),
        SizedBox(height: context.spacing.lg), // ⭐ 響應式間距

        // PAR-Q+ 7 題
        _buildQuestionCard(
          theme,
          question: '1. 醫生是否曾診斷您患有心臟疾病？',
          value: _heartDisease,
          onChanged: (val) => setState(() => _heartDisease = val!),
          noteController: _heartDiseaseNoteController,
        ),
        _buildQuestionCard(
          theme,
          question: '2. 您在運動時是否感到胸痛？',
          value: _chestPainExercise,
          onChanged: (val) => setState(() => _chestPainExercise = val!),
        ),
        _buildQuestionCard(
          theme,
          question: '3. 您在未運動時（過去一個月內）是否感到胸痛？',
          value: _chestPainRest,
          onChanged: (val) => setState(() => _chestPainRest = val!),
        ),
        _buildQuestionCard(
          theme,
          question: '4. 您是否因頭暈而失去平衡，或曾失去意識？',
          value: _dizziness,
          onChanged: (val) => setState(() => _dizziness = val!),
        ),
        _buildQuestionCard(
          theme,
          question: '5. 您是否有骨骼或關節問題，可能因運動而惡化？',
          value: _boneJointProblem,
          onChanged: (val) => setState(() => _boneJointProblem = val!),
          noteController: _boneJointNoteController,
          noteHint: '請說明部位與狀況',
        ),
        _buildQuestionCard(
          theme,
          question: '6. 您目前是否正在服用任何處方藥物（例如：血壓藥、心臟藥）？',
          value: _medication,
          onChanged: (val) => setState(() => _medication = val!),
          noteController: _medicationNoteController,
          noteHint: '請列出藥物名稱',
        ),
        _buildQuestionCard(
          theme,
          question: '7. 您是否知道任何其他不宜運動的原因？',
          value: _otherReason,
          onChanged: (val) => setState(() => _otherReason = val!),
          noteController: _otherReasonNoteController,
          noteHint: '請說明原因',
        ),

        const SizedBox(height: 24),

        // 警示提示
        if (!_isCleared())
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '建議在開始訓練前諮詢醫生，確保運動安全',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 步驟 2：傷病史記錄（完整版）
  Widget _buildStep2InjuryHistory(ThemeData theme) {
    return ListView(
      padding: context.pagePadding, // ⭐ 響應式邊距
      children: [
        Text(
          '步驟 2/5：傷病史記錄',
          style: context.responsive.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ), // ⭐ 響應式文字
        ),
        SizedBox(height: context.spacing.sm), // ⭐ 響應式間距
        Text(
          '記錄學員的傷病史，幫助規劃安全的訓練計劃',
          style: context.responsive.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ), // ⭐ 響應式文字
        ),
        SizedBox(height: context.spacing.lg), // ⭐ 響應式間距

        // 新增傷病按鈕
        FilledButton.icon(
          onPressed: () => _showAddInjuryDialog(theme),
          icon: const Icon(Icons.add),
          label: const Text('新增傷病記錄'),
        ),
        const SizedBox(height: 16),

        // 傷病列表
        if (_injuries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.healing_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  '尚未記錄傷病史',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '點擊上方按鈕新增傷病記錄',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._injuries.asMap().entries.map((entry) {
            final index = entry.key;
            final injury = entry.value;
            return _buildInjuryCard(theme, injury, index);
          }),

        const SizedBox(height: 16),

        // 提示
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '若無傷病史，可直接點擊「下一步」繼續',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 傷病卡片
  Widget _buildInjuryCard(ThemeData theme, InjuryRecord injury, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          injury.site,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('狀態：${injury.status.label}'),
            if (injury.diagnosis != null) ...[
              const SizedBox(height: 2),
              Text('診斷：${injury.diagnosis}'),
            ],
            if (injury.limitations != null) ...[
              const SizedBox(height: 2),
              Text('限制：${injury.limitations}'),
            ],
            if (injury.occurredDate != null) ...[
              const SizedBox(height: 2),
              Text(
                '發生日期：${injury.occurredDate!.year}/${injury.occurredDate!.month}/${injury.occurredDate!.day}',
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditInjuryDialog(theme, injury, index),
              tooltip: '編輯',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteInjury(index),
              tooltip: '刪除',
            ),
          ],
        ),
      ),
    );
  }

  /// 顯示新增傷病對話框
  Future<void> _showAddInjuryDialog(ThemeData theme) async {
    final injury = await _showInjuryDialog(theme, null);
    if (injury != null) {
      setState(() => _injuries.add(injury));
    }
  }

  /// 顯示編輯傷病對話框
  Future<void> _showEditInjuryDialog(
    ThemeData theme,
    InjuryRecord injury,
    int index,
  ) async {
    final updated = await _showInjuryDialog(theme, injury);
    if (updated != null) {
      setState(() => _injuries[index] = updated);
    }
  }

  /// 傷病對話框
  Future<InjuryRecord?> _showInjuryDialog(
    ThemeData theme,
    InjuryRecord? existingInjury,
  ) async {
    final siteController =
        TextEditingController(text: existingInjury?.site ?? '');
    final diagnosisController =
        TextEditingController(text: existingInjury?.diagnosis ?? '');
    final limitationsController =
        TextEditingController(text: existingInjury?.limitations ?? '');
    InjuryStatus selectedStatus =
        existingInjury?.status ?? InjuryStatus.chronic;
    DateTime? occurredDate = existingInjury?.occurredDate;

    return showDialog<InjuryRecord>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingInjury == null ? '新增傷病記錄' : '編輯傷病記錄'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 部位
                TextField(
                  controller: siteController,
                  decoration: const InputDecoration(
                    labelText: '部位 *',
                    hintText: '例如：右膝、左肩、腰椎 L4-L5',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: existingInjury == null,
                ),
                const SizedBox(height: 16),

                // 狀態
                Text('狀態 *', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: InjuryStatus.values.map((status) {
                    return ChoiceChip(
                      label: Text(status.label),
                      selected: selectedStatus == status,
                      onSelected: (selected) {
                        setDialogState(() => selectedStatus = status);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // 診斷
                TextField(
                  controller: diagnosisController,
                  decoration: const InputDecoration(
                    labelText: '診斷',
                    hintText: '例如：前十字韌帶撕裂、椎間盤突出',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // 功能限制
                TextField(
                  controller: limitationsController,
                  decoration: const InputDecoration(
                    labelText: '功能限制',
                    hintText: '例如：避免跳躍動作、無法完全伸直',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // 發生日期
                Text('發生日期', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: occurredDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => occurredDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(occurredDate != null
                      ? '${occurredDate!.year}/${occurredDate!.month}/${occurredDate!.day}'
                      : '選擇日期'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final site = siteController.text.trim();
                if (site.isEmpty) {
                  NotificationUtils.showError(context, '請輸入傷病部位');
                  return;
                }

                final injury = InjuryRecord(
                  site: site,
                  status: selectedStatus,
                  diagnosis: diagnosisController.text.trim().isEmpty
                      ? null
                      : diagnosisController.text.trim(),
                  limitations: limitationsController.text.trim().isEmpty
                      ? null
                      : limitationsController.text.trim(),
                  occurredDate: occurredDate,
                );

                Navigator.pop(context, injury);
              },
              child: Text(existingInjury == null ? '新增' : '儲存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 刪除傷病記錄
  void _deleteInjury(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除「${_injuries[index].site}」的傷病記錄嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _injuries.removeAt(index));
              Navigator.pop(context);
              NotificationUtils.showSuccess(context, '已刪除傷病記錄');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  /// 步驟 3：生活型態（完整版）
  Widget _buildStep3Lifestyle(ThemeData theme) {
    return ListView(
      padding: context.pagePadding, // ⭐ 響應式邊距
      children: [
        Text(
          '步驟 3/5：生活型態與訓練背景',
          style: context.responsive.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ), // ⭐ 響應式文字
        ),
        SizedBox(height: context.spacing.sm), // ⭐ 響應式間距
        Text(
          '幫助我們了解學員的訓練背景與生活型態',
          style: context.responsive.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ), // ⭐ 響應式文字
        ),
        SizedBox(height: context.spacing.lg), // ⭐ 響應式間距

        // 訓練經驗
        Text('訓練經驗 *', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TrainingLevel.values.map((level) {
            return ChoiceChip(
              label: Text(level.label),
              selected: _trainingExperience == level,
              onSelected: (selected) {
                setState(() => _trainingExperience = selected ? level : null);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 訓練年資
        Text('訓練年資（年）', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _trainingYearsController,
          decoration: const InputDecoration(
            hintText: '例如：2.5',
            border: OutlineInputBorder(),
            suffixText: '年',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final years = double.tryParse(value);
            if (years == null) return '請輸入有效數字';
            if (years < 0 || years > 50) return '訓練年資必須在 0-50 年之間';
            return null;
          },
        ),
        const SizedBox(height: 24),

        // 職業活動度
        Text('職業活動度', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ActivityLevel.values.map((level) {
            return ChoiceChip(
              label: Text(level.label),
              selected: _occupationActivity == level,
              onSelected: (selected) {
                setState(() => _occupationActivity = selected ? level : null);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 可用器材
        Text('可用器材', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          '可複選',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            '槓鈴',
            '啞鈴',
            '彈力帶',
            '壺鈴',
            '臥推椅',
            '深蹲架',
            '拉力器',
            '跑步機',
            '飛輪',
            '徒手',
          ].map((equipment) {
            return FilterChip(
              label: Text(equipment),
              selected: _selectedEquipment.contains(equipment),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedEquipment.add(equipment);
                  } else {
                    _selectedEquipment.remove(equipment);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 每週訓練次數
        Text('每週訓練次數', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [1, 2, 3, 4, 5, 6, 7].map((count) {
            return ChoiceChip(
              label: Text('$count 次'),
              selected: _weeklySessions == count,
              onSelected: (selected) {
                setState(() => _weeklySessions = selected ? count : null);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 平均睡眠時數
        Text('平均睡眠時數', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _sleepHoursController,
          decoration: const InputDecoration(
            hintText: '例如：7.5',
            border: OutlineInputBorder(),
            suffixText: '小時',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final hours = double.tryParse(value);
            if (hours == null) return '請輸入有效數字';
            if (hours < 4 || hours > 12) return '睡眠時數必須在 4-12 小時之間';
            return null;
          },
        ),
      ],
    );
  }

  /// 步驟 4：訓練目標（完整版）
  Widget _buildStep4TrainingGoals(ThemeData theme) {
    return ListView(
      padding: context.pagePadding, // ⭐ 響應式邊距
      children: [
        Text(
          '步驟 4/5：訓練目標',
          style: context.responsive.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ), // ⭐ 響應式文字
        ),
        SizedBox(height: context.spacing.sm), // ⭐ 響應式間距
        Text(
          '設定明確的訓練目標與期望時程',
          style: context.responsive.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ), // ⭐ 響應式文字
        ),
        SizedBox(height: context.spacing.lg), // ⭐ 響應式間距

        Text('主要目標 *', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('減重減脂'),
              selected: _primaryGoal == 'weight_loss',
              onSelected: (selected) {
                setState(() => _primaryGoal = 'weight_loss');
              },
            ),
            ChoiceChip(
              label: const Text('增肌增重'),
              selected: _primaryGoal == 'muscle_gain',
              onSelected: (selected) {
                setState(() => _primaryGoal = 'muscle_gain');
              },
            ),
            ChoiceChip(
              label: const Text('運動表現'),
              selected: _primaryGoal == 'performance',
              onSelected: (selected) {
                setState(() => _primaryGoal = 'performance');
              },
            ),
            ChoiceChip(
              label: const Text('健康維持'),
              selected: _primaryGoal == 'health',
              onSelected: (selected) {
                setState(() => _primaryGoal = 'health');
              },
            ),
            ChoiceChip(
              label: const Text('復健改善'),
              selected: _primaryGoal == 'rehabilitation',
              onSelected: (selected) {
                setState(() => _primaryGoal = 'rehabilitation');
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 目標數值（僅適用於減重/增重）
        if (_primaryGoal == 'weight_loss' || _primaryGoal == 'muscle_gain') ...[
          Text(
            '目標體重變化',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _targetKgController,
            decoration: InputDecoration(
              hintText: _primaryGoal == 'weight_loss'
                  ? '例如：-5（減少 5kg）'
                  : '例如：+3（增加 3kg）',
              border: const OutlineInputBorder(),
              suffixText: 'kg',
            ),
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final kg = double.tryParse(value);
              if (kg == null) return '請輸入有效數字（可使用負號）';
              if (kg < -50 || kg > 50) return '目標變化必須在 -50 到 +50 kg 之間';
              return null;
            },
          ),
          const SizedBox(height: 24),
        ],

        // 期望時程
        Text('期望達成時程', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _timeframeMonthsController,
          decoration: const InputDecoration(
            hintText: '例如：3',
            border: OutlineInputBorder(),
            suffixText: '個月',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final months = int.tryParse(value);
            if (months == null) return '請輸入有效數字';
            if (months < 1 || months > 24) return '時程必須在 1-24 個月之間';
            return null;
          },
        ),
        const SizedBox(height: 24),

        // 補充說明
        Text('補充說明', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _goalNotesController,
          decoration: const InputDecoration(
            hintText: '例如：準備馬拉松、改善體態等',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  /// 步驟 5：緊急聯絡人（完整版）
  Widget _buildStep5EmergencyContact(ThemeData theme) {
    return ListView(
      padding: context.pagePadding, // ⭐ 響應式邊距
      children: [
        Text(
          '步驟 5/5：緊急聯絡人',
          style: context.responsive.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ), // ⭐ 響應式文字
        ),
        SizedBox(height: context.spacing.sm), // ⭐ 響應式間距
        Text(
          '建議填寫以確保訓練安全（選填）',
          style: context.responsive.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ), // ⭐ 響應式文字
        ),
        SizedBox(height: context.spacing.lg), // ⭐ 響應式間距

        TextFormField(
          controller: _emergencyNameController,
          decoration: const InputDecoration(
            labelText: '姓名',
            hintText: '例如：王小明',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _emergencyPhoneController,
          decoration: const InputDecoration(
            labelText: '電話',
            hintText: '例如：0912-345-678',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            // 簡單的台灣手機號碼驗證（09 開頭，10 位數字）
            final phoneRegex = RegExp(r'^09\d{8}$');
            final cleanedPhone = value.replaceAll(RegExp(r'[-\s]'), '');
            if (!phoneRegex.hasMatch(cleanedPhone)) {
              return '請輸入有效的台灣手機號碼（例如：0912345678）';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _emergencyRelationshipController,
          decoration: const InputDecoration(
            labelText: '關係',
            hintText: '例如：配偶、父母、朋友',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.family_restroom),
          ),
        ),
        const SizedBox(height: 24),

        // 提示卡片
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '緊急聯絡人資訊僅用於緊急狀況聯繫，將嚴格保密',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 免責聲明
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '免責聲明',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '本問卷僅用於教練了解學員基本健康狀況，以調整訓練計畫。不構成醫療診斷或建議。如有健康疑慮，請諮詢專業醫療人員。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 問題卡片
  Widget _buildQuestionCard(
    ThemeData theme, {
    required String question,
    required bool value,
    required ValueChanged<bool?> onChanged,
    TextEditingController? noteController,
    String? noteHint,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('是'),
                    value: true,
                    groupValue: value,
                    onChanged: onChanged,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('否'),
                    value: false,
                    groupValue: value,
                    onChanged: onChanged,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            if (value && noteController != null) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: '請說明',
                  hintText: noteHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (val) {
                  if (value && (val == null || val.trim().isEmpty)) {
                    return '請說明詳細情況';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 導航按鈕
  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: context.pagePadding, // ⭐ 響應式邊距
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('上一步'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isLoading
                  ? null
                  : (_currentStep < _totalSteps - 1
                      ? _nextStep
                      : _saveAssessment),
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_currentStep < _totalSteps - 1
                      ? Icons.arrow_forward
                      : Icons.check),
              label: Text(_isLoading
                  ? '儲存中...'
                  : (_currentStep < _totalSteps - 1 ? '下一步' : '完成')),
            ),
          ),
        ],
      ),
    );
  }

  /// 是否通過安全篩檢
  bool _isCleared() {
    return !_heartDisease &&
        !_chestPainExercise &&
        !_chestPainRest &&
        !_dizziness &&
        !_boneJointProblem &&
        !_medication &&
        !_otherReason;
  }
}
