// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/models/coach_display_preferences_model.dart';
import 'package:strengthwise/services/interfaces/i_coach_display_preferences_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 教練顯示偏好設定頁面
///
/// 允許教練選擇學員詳情中要顯示的健康評估欄位
class CoachDisplayPreferencesPage extends StatefulWidget {
  const CoachDisplayPreferencesPage({super.key});

  @override
  State<CoachDisplayPreferencesPage> createState() =>
      _CoachDisplayPreferencesPageState();
}

class _CoachDisplayPreferencesPageState
    extends State<CoachDisplayPreferencesPage> {
  late final ICoachDisplayPreferencesService _preferencesService;

  CoachDisplayPreferencesModel? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  final Set<String> _selectedFields = {};

  @override
  void initState() {
    super.initState();
    _preferencesService = serviceLocator<ICoachDisplayPreferencesService>();
    _loadPreferences();
  }

  /// 載入偏好設定
  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('無法獲取使用者 ID');
      }

      final preferences =
          await _preferencesService.getPreferences(currentUserId);

      if (mounted) {
        setState(() {
          _preferences = preferences;
          _selectedFields.clear();
          _selectedFields.addAll(preferences.healthAssessmentFields);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NotificationUtils.showError(context, '載入設定失敗');
      }
    }
  }

  /// 儲存偏好設定
  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    setState(() => _isSaving = true);

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('無法獲取使用者 ID');
      }

      final updatedPreferences = _preferences!.copyWith(
        healthAssessmentFields: _selectedFields.toList(),
        updatedAt: DateTime.now(),
      );

      await _preferencesService.updatePreferences(updatedPreferences);

      if (mounted) {
        setState(() {
          _preferences = updatedPreferences;
          _isSaving = false;
        });
        NotificationUtils.showSuccess(context, '設定已儲存');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        NotificationUtils.showError(context, '儲存設定失敗');
      }
    }
  }

  /// 重置為預設設定
  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認重置'),
        content: const Text('確定要重置為預設設定嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('重置'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('無法獲取使用者 ID');
      }

      await _preferencesService.resetToDefault(currentUserId);
      await _loadPreferences();

      if (mounted) {
        NotificationUtils.showSuccess(context, '已重置為預設設定');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        NotificationUtils.showError(context, '重置失敗');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('顯示偏好設定'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefault,
            tooltip: '重置預設',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: context.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '選擇要在學員詳情中顯示的健康評估欄位',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '勾選的欄位會顯示在學員的健康評估摘要卡片中',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 欄位列表
                      ...CoachDisplayPreferencesModel.availableFields.entries
                          .map(
                        (entry) =>
                            _buildFieldTile(theme, entry.key, entry.value),
                      ),

                      const SizedBox(height: 24),

                      // 選中計數
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '已選擇 ${_selectedFields.length} / ${CoachDisplayPreferencesModel.availableFields.length} 個欄位',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _savePreferences,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? '儲存中...' : '儲存設定'),
          ),
        ),
      ),
    );
  }

  /// 欄位選擇項目
  Widget _buildFieldTile(ThemeData theme, String fieldKey, String fieldName) {
    final isSelected = _selectedFields.contains(fieldKey);

    return CheckboxListTile(
      title: Text(fieldName),
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _selectedFields.add(fieldKey);
          } else {
            _selectedFields.remove(fieldKey);
          }
        });
      },
      secondary: Icon(
        _getFieldIcon(fieldKey),
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// 取得欄位圖示
  IconData _getFieldIcon(String fieldKey) {
    switch (fieldKey) {
      case 'safety_screening':
        return Icons.health_and_safety;
      case 'injuries':
        return Icons.healing;
      case 'cardiovascular':
        return Icons.favorite;
      case 'bone_joint': // ⭐ v3.3: 新增
        return Icons.accessibility_new;
      case 'medications':
        return Icons.medication;
      case 'other_health_issues': // ⭐ v3.3: 新增
        return Icons.info_outline;
      case 'training_experience':
        return Icons.fitness_center;
      case 'occupation_activity':
        return Icons.work;
      case 'equipment_access':
        return Icons.settings;
      case 'training_goals':
        return Icons.flag;
      case 'emergency_contact':
        return Icons.contact_phone;
      default:
        return Icons.check_box;
    }
  }
}
