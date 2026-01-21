import 'package:flutter/material.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/controllers/interfaces/i_coaching_relationship_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/profile/widgets/coach/coach_profile_content.dart';

/// 教練基本資訊 Tab（學員中心）
///
/// 使用共用的 CoachProfileContent 組件
class CoachInfoTab extends StatelessWidget {
  final UserModel coach;
  final String clientId;

  const CoachInfoTab({
    super.key,
    required this.coach,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    return CoachProfileContent(
      coachId: coach.uid,
      email: coach.email,
      photoUrl: coach.photoURL,
      isEditable: false, // 學員不能編輯
      showContactInfo: true,
      emptyStateTitle: '此教練尚未建立檔案',
      emptyStateSubtitle: '請稍後再試',
      dangerZoneWidget: _DangerZone(
        coach: coach,
        clientId: clientId,
      ),
    );
  }
}

/// 危險區域：解除綁定
class _DangerZone extends StatelessWidget {
  final UserModel coach;
  final String clientId;

  const _DangerZone({
    required this.coach,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  '解除與此教練的綁定關係後：',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                _buildWarningItem(context, '教練創建的訓練計劃你仍可查看'),
                _buildWarningItem(context, '共享筆記雙方仍可查看'),
                _buildWarningItem(context, '私有筆記你將無法查看'),
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

  Future<void> _handleUnbind(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: colorScheme.error,
        ),
        title: const Text('解除綁定'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              Text(
                '確定要解除與 ${coach.displayName ?? coach.email} 的綁定關係嗎？',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              _buildDialogItem(
                context,
                icon: Icons.notes,
                text: '私有筆記你將無法查看',
                color: colorScheme.error,
              ),
              const SizedBox(height: 12),
              _buildDialogItem(
                context,
                icon: Icons.check_circle_outline,
                text: '教練創建的訓練計劃你仍可查看',
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

    final relationshipController =
        serviceLocator<ICoachingRelationshipController>();
    final relationship = await relationshipController.getRelationshipByUsers(
      coach.uid,
      clientId,
    );

    if (relationship == null) {
      if (context.mounted) {
        NotificationUtils.showError(context, '找不到綁定關係');
      }
      return;
    }

    final success =
        await relationshipController.archiveRelationship(relationship.id);
    if (context.mounted) {
      if (success) {
        NotificationUtils.showSuccess(context, '已解除綁定');
        Navigator.of(context).pop(true);
      } else {
        NotificationUtils.showError(
          context,
          relationshipController.errorMessage ?? '解除綁定失敗',
        );
      }
    }
  }

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
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
