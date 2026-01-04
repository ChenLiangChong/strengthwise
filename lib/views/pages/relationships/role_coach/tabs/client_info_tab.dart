import 'package:flutter/material.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/models/coaching_relationship_model.dart';
import 'package:strengthwise/models/health_assessment/health_assessment_model.dart';
import 'package:strengthwise/models/coach_display_preferences_model.dart';
import 'package:strengthwise/models/coach_assessment_note_model.dart';
import 'package:strengthwise/controllers/coaching_relationship_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/interfaces/i_coaching_relationship_service.dart';
import 'package:strengthwise/services/interfaces/i_health_assessment_service.dart';
import 'package:strengthwise/services/interfaces/i_coach_display_preferences_service.dart';
import 'package:strengthwise/services/interfaces/i_coach_assessment_note_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/profile/health_assessment_detail_page.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/widgets/empty_health_assessment_card.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/widgets/health_assessment_summary_card.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/health_assessment_page.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/coach_display_preferences_page.dart';

/// 學員基本資訊 Tab
class ClientInfoTab extends StatefulWidget {
  final UserModel client;

  const ClientInfoTab({
    super.key,
    required this.client,
  });

  @override
  State<ClientInfoTab> createState() => _ClientInfoTabState();
}

class _ClientInfoTabState extends State<ClientInfoTab> {
  late final ICoachingRelationshipService _relationshipService;
  late final IAuthController _authController;
  late final IHealthAssessmentService _healthAssessmentService;
  late final ICoachDisplayPreferencesService _preferencesService;
  late final ICoachAssessmentNoteService _assessmentNoteService; // ⭐ 新增

  CoachingRelationshipModel? _relationship;
  bool _isLoadingProfile = true;

  HealthAssessmentModel? _healthAssessment;
  bool _isLoadingHealthAssessment = true;
  
  CoachDisplayPreferencesModel? _displayPreferences;
  CoachAssessmentNoteModel? _coachNote; // ⭐ 新增

  @override
  void initState() {
    super.initState();
    _relationshipService = serviceLocator<ICoachingRelationshipService>();
    _authController = serviceLocator<IAuthController>();
    _healthAssessmentService = serviceLocator<IHealthAssessmentService>();
    _preferencesService = serviceLocator<ICoachDisplayPreferencesService>();
    _assessmentNoteService = serviceLocator<ICoachAssessmentNoteService>(); // ⭐ 新增
    _loadRelationship();
    _loadHealthAssessment();
    _loadDisplayPreferences();
  }

  /// 載入關係（包含學員檔案）
  Future<void> _loadRelationship() async {
    final currentUser = _authController.user;
    if (currentUser == null) return;

    setState(() => _isLoadingProfile = true);

    try {
      final relationship =
          await _relationshipService.getRelationshipByUsersDetailed(
        currentUser.uid,
        widget.client.uid,
      );

      if (mounted) {
        setState(() {
          _relationship = relationship;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入學員檔案失敗: $e')),
        );
      }
    }
  }

  /// 載入健康評估
  Future<void> _loadHealthAssessment() async {
    setState(() => _isLoadingHealthAssessment = true);

    try {
      final assessment = await _healthAssessmentService.getCurrentAssessment(
        widget.client.uid,
      );

      // ⭐ 如果有評估，載入當前教練的備註
      CoachAssessmentNoteModel? coachNote;
      if (assessment != null) {
        final coachId = _authController.user?.uid;
        if (coachId != null) {
          coachNote = await _assessmentNoteService.getNote(
            coachId: coachId,
            assessmentId: assessment.id,
          );
        }
      }

      if (mounted) {
        setState(() {
          _healthAssessment = assessment;
          _coachNote = coachNote; // ⭐ 儲存備註
          _isLoadingHealthAssessment = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHealthAssessment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入健康評估失敗: $e')),
        );
      }
    }
  }

  /// 載入教練顯示偏好
  Future<void> _loadDisplayPreferences() async {
    try {
      final currentUser = _authController.user;
      if (currentUser == null) return;

      final preferences = await _preferencesService.getPreferences(currentUser.uid);
      
      if (mounted) {
        setState(() {
          _displayPreferences = preferences;
        });
      }
    } catch (e) {
      // 靜默失敗，使用預設偏好
    }
  }

  /// 顯示偏好設定頁面
  Future<void> _showPreferencesEditor() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CoachDisplayPreferencesPage(),
      ),
    );
    
    // 重新載入偏好
    await _loadDisplayPreferences();
  }

  /// 顯示健康評估編輯頁面
  Future<void> _showHealthAssessmentEditor() async {
    final result = await Navigator.of(context).push<HealthAssessmentModel>(
      MaterialPageRoute(
        builder: (context) => HealthAssessmentPage(
          clientId: widget.client.uid,
          clientName: widget.client.displayName ?? widget.client.email,
          existingAssessment: _healthAssessment,
        ),
      ),
    );

    if (result != null) {
      // TODO: 儲存健康評估
      // await _healthAssessmentService.saveAssessment(result);

      // 重新載入
      await _loadHealthAssessment();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('健康評估已儲存')),
        );
      }
    }
  }

  /// 顯示健康評估完整檢視
  Future<void> _showHealthAssessmentFull() async {
    if (_healthAssessment == null) return;
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HealthAssessmentDetailPage(
          assessment: _healthAssessment!,
          userName: widget.client.displayName ?? widget.client.email,
        ),
      ),
    );
  }

  /// ⭐ 儲存教練備註
  Future<void> _saveCoachNote(String notes) async {
    if (_healthAssessment == null) return;
    
    try {
      final currentUser = _authController.user;
      if (currentUser == null) return;

      await _assessmentNoteService.upsertNote(
        coachId: currentUser.uid,
        assessmentId: _healthAssessment!.id,
        notes: notes,
      );

      // 重新載入教練備註
      await _loadHealthAssessment();

      if (mounted) {
        NotificationUtils.showSuccess(context, '教練備註已儲存');
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, '儲存教練備註失敗');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 學員檔案卡片（頂部）
          if (_isLoadingProfile)
            const Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          // 健康評估卡片 ⭐ 主要內容
          else if (_healthAssessment != null)
            HealthAssessmentSummaryCard(
              assessment: _healthAssessment!,
              preferences: _displayPreferences,
              coachNote: _coachNote,
              onViewFull: _showHealthAssessmentFull,
              onEdit: _showHealthAssessmentEditor,
              onConfigurePreferences: _showPreferencesEditor,
              onCoachNoteChanged: _saveCoachNote, // ⭐ 新增：儲存備註回調
            )
          else
            EmptyHealthAssessmentCard(
              onCreateTap: _showHealthAssessmentEditor,
            ),

          const SizedBox(height: 24),

          // 頭像與基本資訊
          _buildProfileCard(context, colorScheme),
          const SizedBox(height: 24),

          // 聯絡資訊
          _buildSection(
            context: context,
            title: '聯絡資訊',
            icon: Icons.contact_mail,
            colorScheme: colorScheme,
            children: [
              _buildInfoRow(
                icon: Icons.email,
                label: 'Email',
                value: widget.client.email,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 身體數據
          _buildSection(
            context: context,
            title: '身體數據',
            icon: Icons.monitor_weight,
            colorScheme: colorScheme,
            children: [
              _buildInfoRow(
                icon: Icons.height,
                label: '身高',
                value: widget.client.height != null
                    ? '${widget.client.height} cm'
                    : '未設定',
              ),
              _buildInfoRow(
                icon: Icons.monitor_weight,
                label: '體重',
                value: widget.client.weight != null
                    ? '${widget.client.weight} kg'
                    : '未設定',
              ),
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: '生日',
                value: widget.client.birthDate != null
                    ? _formatDate(widget.client.birthDate!)
                    : '未設定',
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 危險區域：解除綁定
          _buildDangerZone(context, colorScheme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 危險區域：解除綁定 ⭐ 新增
  Widget _buildDangerZone(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: colorScheme.error),
                const SizedBox(width: 12),
                Text(
                  '危險區域',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                ),
              ],
            ),
          ),
          // 內容
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '解除與此學員的綁定關係後：',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                _buildWarningItem(
                  context,
                  '你創建的訓練計劃將對你不可見，但學員仍可查看',
                ),
                _buildWarningItem(context, '共享筆記雙方仍可查看'),
                _buildWarningItem(context, '私有筆記僅你可見'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleUnbind(context),
                    icon: const Icon(Icons.link_off),
                    label: const Text('解除綁定'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 警告項目
  Widget _buildWarningItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// 處理解除綁定 ⭐ 新增
  Future<void> _handleUnbind(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.link_off,
          size: 48,
          color: colorScheme.error,
        ),
        title: const Text('解除綁定'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 警告區塊
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '此操作無法復原！',
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 問題
              Text(
                '確定要解除與 ${widget.client.displayName ?? widget.client.email} 的綁定關係嗎？',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),

              // 影響標題
              Text(
                '解除綁定後：',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // 負面影響（紅色）
              _buildDialogItem(
                context,
                icon: Icons.visibility_off,
                text: '你創建的訓練計劃將對你不可見',
                color: colorScheme.error,
              ),
              _buildDialogItem(
                context,
                icon: Icons.notes,
                text: '私有筆記僅你可見',
                color: colorScheme.error,
              ),
              const SizedBox(height: 8),

              // 正面說明（藍色）
              _buildDialogItem(
                context,
                icon: Icons.check_circle_outline,
                text: '學員仍可查看訓練計劃',
                color: colorScheme.primary,
              ),
              _buildDialogItem(
                context,
                icon: Icons.check_circle_outline,
                text: '共享筆記雙方仍可查看',
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('解除綁定'),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final authController = serviceLocator<IAuthController>();
    final coachId = authController.user?.uid;

    if (coachId == null) {
      if (context.mounted) {
        NotificationUtils.showError(context, '無法獲取教練 ID');
      }
      return;
    }

    final relationshipController =
        serviceLocator<CoachingRelationshipController>();
    final relationship = await relationshipController.getRelationshipByUsers(
      coachId,
      widget.client.uid,
    );

    if (relationship == null) {
      if (context.mounted) {
        NotificationUtils.showError(context, '找不到綁定關係');
      }
      return;
    }

    final success =
        await relationshipController.deleteRelationship(relationship.id);
    if (context.mounted) {
      if (success) {
        NotificationUtils.showSuccess(context, '已解除綁定');
        Navigator.pop(context, true); // 返回並刷新列表
      } else {
        NotificationUtils.showError(
          context,
          relationshipController.errorMessage ?? '解除綁定失敗',
        );
      }
    }
  }

  /// Dialog 項目（帶顏色圖標）
  Widget _buildDialogItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color, // ⭐ 關鍵：文字顏色跟圖標一樣
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 頭像卡片
  Widget _buildProfileCard(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 頭像
          CircleAvatar(
            radius: 40,
            backgroundColor: colorScheme.primary,
            backgroundImage: widget.client.photoURL != null
                ? NetworkImage(widget.client.photoURL!)
                : null,
            child: widget.client.photoURL == null
                ? Text(
                    widget.client.displayName?.substring(0, 1).toUpperCase() ??
                        widget.client.email.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 20),
          // 姓名與基本資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.client.displayName ?? widget.client.email,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '學員',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 資訊區塊
  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          // 內容
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// 資訊行
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
