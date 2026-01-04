import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/coach_profile_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/profile/widgets/coach/specialty_tag_selector.dart';
import 'package:strengthwise/views/pages/profile/widgets/coach/certification_form.dart';

/// 教練公開檔案表單頁面
/// 
/// 2 步驟表單：
/// 1. 基本資料：顯示名稱、專業介紹、專業頭銜
/// 2. 專業背景：專長選擇、證照、年資、語言
class CoachProfileFormPage extends StatefulWidget {
  /// 是否為首次填寫（強制模式，無法返回）
  final bool isFirstTime;

  const CoachProfileFormPage({
    super.key,
    this.isFirstTime = false,
  });

  @override
  State<CoachProfileFormPage> createState() => _CoachProfileFormPageState();
}

class _CoachProfileFormPageState extends State<CoachProfileFormPage> {
  late final CoachProfileController _controller;
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 2;

  // 表單控制器
  final _displayNameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _bioController = TextEditingController();
  final _yearsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<CoachProfileController>();
    _controller.loadCoachProfile().then((_) {
      _initFormControllers();
    });
  }

  void _initFormControllers() {
    _displayNameController.text = _controller.displayName;
    _headlineController.text = _controller.headline;
    _bioController.text = _controller.bio;
    _yearsController.text = _controller.yearsExperience.toString();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    _yearsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // 驗證當前步驟
    if (_currentStep == 0) {
      if (_displayNameController.text.trim().isEmpty) {
        NotificationUtils.showError(context, '請填寫顯示名稱');
        return;
      }
      if (_bioController.text.trim().isEmpty) {
        NotificationUtils.showError(context, '請填寫專業介紹');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveProfile() async {
    // 同步表單到 controller
    _controller.setDisplayName(_displayNameController.text.trim());
    _controller.setHeadline(_headlineController.text.trim());
    _controller.setBio(_bioController.text.trim());
    
    final years = int.tryParse(_yearsController.text.trim()) ?? 0;
    _controller.setYearsExperience(years);

    // 驗證專長
    if (_controller.specialties.isEmpty) {
      NotificationUtils.showError(context, '請至少選擇一個專長');
      return;
    }

    // 儲存
    final success = await _controller.saveProfile();
    
    if (success && mounted) {
      NotificationUtils.showSuccess(context, '教練檔案已儲存');
      Navigator.of(context).pop(true);
    } else if (_controller.errorMessage != null && mounted) {
      NotificationUtils.showError(context, _controller.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<CoachProfileController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.isFirstTime ? '建立教練檔案' : '編輯教練檔案'),
              leading: widget.isFirstTime
                  ? null  // 首次填寫不能返回
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
              automaticallyImplyLeading: !widget.isFirstTime,
            ),
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // 步驟指示器
                      _StepIndicator(
                        currentStep: _currentStep,
                        totalSteps: _totalSteps,
                      ),

                      // 表單內容
                      Expanded(
                        child: Form(
                          key: _formKey,
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (index) {
                              setState(() => _currentStep = index);
                            },
                            children: [
                              _Step1BasicInfo(
                                displayNameController: _displayNameController,
                                headlineController: _headlineController,
                                bioController: _bioController,
                              ),
                              _Step2ProfessionalBackground(
                                controller: controller,
                                yearsController: _yearsController,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 底部按鈕
                      _BottomButtons(
                        currentStep: _currentStep,
                        totalSteps: _totalSteps,
                        isFirstTime: widget.isFirstTime,
                        isSaving: controller.isSaving,
                        onPrevious: _previousStep,
                        onNext: _nextStep,
                        onSave: _saveProfile,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

/// 步驟指示器
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = index <= currentStep;
          final isCurrent = index == currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive 
                    ? colorScheme.primary 
                    : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
              child: isCurrent
                  ? null
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

/// 步驟 1：基本資料
class _Step1BasicInfo extends StatelessWidget {
  final TextEditingController displayNameController;
  final TextEditingController headlineController;
  final TextEditingController bioController;

  const _Step1BasicInfo({
    required this.displayNameController,
    required this.headlineController,
    required this.bioController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '基本資料',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '這些資訊將顯示在您的教練檔案中',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),

          // 顯示名稱
          TextFormField(
            controller: displayNameController,
            decoration: const InputDecoration(
              labelText: '顯示名稱 *',
              hintText: '您的品牌名稱或暱稱',
              helperText: '學員會看到這個名稱',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 24),

          // 專業介紹
          TextFormField(
            controller: bioController,
            decoration: const InputDecoration(
              labelText: '專業介紹 *',
              hintText: '介紹您的專業背景、教學理念...',
              helperText: '詳細描述您的經驗和專長',
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            minLines: 3,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 24),

          // 專業頭銜
          TextFormField(
            controller: headlineController,
            decoration: const InputDecoration(
              labelText: '專業頭銜（選填）',
              hintText: '例如：專業健身教練 | 體態雕塑專家',
              helperText: '一句話描述您的定位（最多 160 字）',
            ),
            maxLength: 160,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}

/// 步驟 2：專業背景
class _Step2ProfessionalBackground extends StatelessWidget {
  final CoachProfileController controller;
  final TextEditingController yearsController;

  const _Step2ProfessionalBackground({
    required this.controller,
    required this.yearsController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: screenWidth - 32, // 減去 padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '專業背景',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '選擇您的專長領域和證照',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),

            // 專長標籤選擇器
            SpecialtyTagSelector(
              selectedTags: controller.specialties,
              onChanged: (tags) {
                // 清空後重新加入
                while (controller.specialties.isNotEmpty) {
                  controller.removeSpecialty(controller.specialties.first);
                }
                for (final tag in tags) {
                  controller.addSpecialty(tag);
                }
              },
            ),
            const SizedBox(height: 32),

            // 證照
            CertificationForm(
              certifications: controller.certifications,
              onAdd: (cert) => controller.addCertification(cert),
              onRemove: (index) => controller.removeCertification(index),
            ),
            const SizedBox(height: 32),

            // 年資
            TextFormField(
              controller: yearsController,
              decoration: const InputDecoration(
                labelText: '從業年資（選填）',
                hintText: '例如：5',
                suffixText: '年',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),

            // 語言能力
            _LanguageSelector(
              languages: controller.languages,
              onAdd: controller.addLanguage,
              onRemove: controller.removeLanguage,
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

/// 語言選擇器
class _LanguageSelector extends StatelessWidget {
  final List<String> languages;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _LanguageSelector({
    required this.languages,
    required this.onAdd,
    required this.onRemove,
  });

  static const _availableLanguages = {
    'zh-TW': '繁體中文',
    'zh-CN': '簡體中文',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '教學語言（選填）',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableLanguages.entries.map((entry) {
            final isSelected = languages.contains(entry.key);
            
            return FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onAdd(entry.key);
                } else if (languages.length > 1) {
                  onRemove(entry.key);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 底部按鈕
class _BottomButtons extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isFirstTime;
  final bool isSaving;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSave;

  const _BottomButtons({
    required this.currentStep,
    required this.totalSteps,
    required this.isFirstTime,
    required this.isSaving,
    required this.onPrevious,
    required this.onNext,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;
    final isFirstStep = currentStep == 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 上一步
            if (!isFirstStep)
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving ? null : onPrevious,
                  child: const Text('上一步'),
                ),
              ),
            
            if (!isFirstStep) const SizedBox(width: 16),

            // 下一步/儲存
            Expanded(
              child: FilledButton(
                onPressed: isSaving
                    ? null
                    : (isLastStep ? onSave : onNext),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isLastStep ? '儲存' : '下一步'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

