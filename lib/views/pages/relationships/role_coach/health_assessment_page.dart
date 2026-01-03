import 'package:flutter/material.dart';
import 'package:strengthwise/models/health_assessment_models.dart';
import 'package:strengthwise/utils/notification_utils.dart';

/// 健康評估問卷頁面
/// 
/// 多步驟表單，包含 PAR-Q+ 問卷、傷病史、訓練背景與目標
class HealthAssessmentPage extends StatefulWidget {
  /// 學員 ID
  final String clientId;
  
  /// 學員名稱（顯示用）
  final String clientName;
  
  /// 現有評估（編輯模式）
  final HealthAssessmentModel? existingAssessment;

  const HealthAssessmentPage({
    super.key,
    required this.clientId,
    required this.clientName,
    this.existingAssessment,
  });

  @override
  State<HealthAssessmentPage> createState() => _HealthAssessmentPageState();
}

class _HealthAssessmentPageState extends State<HealthAssessmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  int _currentStep = 0;
  final int _totalSteps = 5;

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
      _trainingYearsController.text = assessment.trainingYears?.toString() ?? '';
      _occupationActivity = assessment.occupationActivity;
      _weeklySessions = assessment.weeklySessions;
      _sleepHoursController.text = assessment.sleepHours?.toString() ?? '';
      _selectedEquipment.addAll(assessment.equipmentAccess);

      // 訓練目標
      if (assessment.trainingGoals != null) {
        _primaryGoal = assessment.trainingGoals!.primary;
        _targetKgController.text = assessment.trainingGoals!.targetKg?.toString() ?? '';
        _timeframeMonthsController.text = assessment.trainingGoals!.timeframeMonths?.toString() ?? '';
        _goalNotesController.text = assessment.trainingGoals!.notes ?? '';
      }

      // 緊急聯絡人
      if (assessment.emergencyContact != null) {
        _emergencyNameController.text = assessment.emergencyContact!['name'] ?? '';
        _emergencyPhoneController.text = assessment.emergencyContact!['phone'] ?? '';
        _emergencyRelationshipController.text = assessment.emergencyContact!['relationship'] ?? '';
      }
    });
  }

  /// 下一步
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
  void _saveAssessment() {
    if (!_formKey.currentState!.validate()) {
      NotificationUtils.showError(context, '請檢查輸入內容');
      return;
    }

    // TODO: 建立 HealthAssessmentModel 並返回
    NotificationUtils.showError(context, '功能開發中：儲存評估');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingAssessment == null ? '建立健康評估' : '編輯健康評估'),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
                if (index < _totalSteps - 1) const SizedBox(width: 4),
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
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '步驟 1/5：基礎安全篩檢',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '請誠實回答以下問題，以確保訓練安全',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        
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

  /// 步驟 2：傷病史（簡化版 - 僅說明）
  Widget _buildStep2InjuryHistory(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '步驟 2/5：傷病史記錄',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '詳細記錄您的傷病史（開發中）',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '此步驟將允許您記錄傷病部位、狀態、診斷與功能限制。\n\n目前可以點擊「下一步」繼續填寫其他資料。',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  /// 步驟 3：生活型態（簡化版）
  Widget _buildStep3Lifestyle(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '步驟 3/5：生活型態與訓練背景',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        // 訓練經驗
        Text('訓練經驗', style: theme.textTheme.titleMedium),
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
        
        // 職業活動度
        Text('職業活動度', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
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
        
        // 每週訓練次數
        Text('每週訓練次數', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [2, 3, 4, 5, 6, 7].map((count) {
            return ChoiceChip(
              label: Text('$count 次'),
              selected: _weeklySessions == count,
              onSelected: (selected) {
                setState(() => _weeklySessions = selected ? count : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 步驟 4：訓練目標（簡化版）
  Widget _buildStep4TrainingGoals(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '步驟 4/5：訓練目標',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        Text('主要目標', style: theme.textTheme.titleMedium),
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
          ],
        ),
      ],
    );
  }

  /// 步驟 5：緊急聯絡人（簡化版）
  Widget _buildStep5EmergencyContact(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '步驟 5/5：緊急聯絡人',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        TextFormField(
          controller: _emergencyNameController,
          decoration: const InputDecoration(
            labelText: '姓名',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _emergencyPhoneController,
          decoration: const InputDecoration(
            labelText: '電話',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _emergencyRelationshipController,
          decoration: const InputDecoration(
            labelText: '關係（例如：配偶、父母）',
            border: OutlineInputBorder(),
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
      padding: const EdgeInsets.all(16),
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
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('上一步'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              onPressed: _currentStep < _totalSteps - 1 ? _nextStep : _saveAssessment,
              icon: Icon(_currentStep < _totalSteps - 1 ? Icons.arrow_forward : Icons.check),
              label: Text(_currentStep < _totalSteps - 1 ? '下一步' : '完成'),
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

