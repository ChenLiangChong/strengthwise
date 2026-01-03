import 'package:flutter/material.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/controllers/coaching_relationship_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';

/// 教練基本資訊 Tab
class CoachInfoTab extends StatelessWidget {
  final UserModel coach;
  final String clientId; // ⭐ 新增：學員 ID

  const CoachInfoTab({
    super.key,
    required this.coach,
    required this.clientId, // ⭐ 新增
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                value: coach.email ?? '未設定',
              ),
              // 電話暫時隱藏（UserModel 沒有此欄位）
              // _buildInfoRow(
              //   icon: Icons.phone,
              //   label: '電話',
              //   value: coach.phoneNumber ?? '未設定',
              // ),
            ],
          ),
          const SizedBox(height: 24),

          // 教練資訊
          _buildSection(
            context: context,
            title: '教練資訊',
            icon: Icons.fitness_center,
            colorScheme: colorScheme,
            children: [
              _buildInfoRow(
                icon: Icons.info,
                label: '簡介',
                value: coach.bio ?? '未設定',
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
              const SizedBox(height: 16),

              // 問題
              Text(
                '確定要解除與 ${coach.displayName ?? coach.email} 的綁定關係嗎？',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),

              // 負面影響（紅色）
              _buildDialogItem(
                context,
                icon: Icons.notes,
                text: '私有筆記你將無法查看',
                color: colorScheme.error,
              ),
              const SizedBox(height: 12),

              // 正面說明（藍色）
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
        serviceLocator<CoachingRelationshipController>();
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

    // ⭐ 修正：使用 archiveRelationship 而不是 deleteRelationship
    final success =
        await relationshipController.archiveRelationship(relationship.id);
    if (context.mounted) {
      if (success) {
        NotificationUtils.showSuccess(context, '已解除綁定');
        // ⭐ 返回上一頁並傳遞成功結果，觸發刷新
        Navigator.of(context).pop(true);
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
            backgroundImage:
                coach.photoURL != null ? NetworkImage(coach.photoURL!) : null,
            child: coach.photoURL == null
                ? Text(
                    coach.displayName?.substring(0, 1).toUpperCase() ??
                        coach.email?.substring(0, 1).toUpperCase() ??
                        'C',
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
                  coach.displayName ?? coach.email ?? '教練',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '認證教練',
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
}
