// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import '../../../../models/user_model.dart';

/// 個人資料頭部卡片
///
/// 響應式設計：
/// - 使用 Theme 文字樣式
/// - 響應式間距
/// - 小螢幕按鈕垂直排列
class ProfileHeaderCard extends StatelessWidget {
  final UserModel? userProfile;
  final VoidCallback onEditProfile;
  final VoidCallback onViewBodyData;

  const ProfileHeaderCard({
    super.key,
    required this.userProfile,
    required this.onEditProfile,
    required this.onViewBodyData,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isMobileSmall = context.isMobileSmall;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Padding(
        padding: context.cardPadding,
        child: Column(
          children: [
            Row(
              children: [
                // 大頭像
                Stack(
                  children: [
                    CircleAvatar(
                      radius: isMobileSmall ? 32 : 40,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      backgroundImage: userProfile?.photoURL != null
                          ? NetworkImage(userProfile!.photoURL!)
                          : null,
                      child: userProfile?.photoURL == null
                          ? Icon(Icons.person,
                              size: isMobileSmall ? 36 : 45,
                              color: colorScheme.onSurfaceVariant)
                          : null,
                    ),
                    // 教練標記
                    if (userProfile?.isCoach ?? false)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.star,
                            size: 14,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: context.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 名稱 + 角色標籤
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: context.spacing.sm,
                        runSpacing: context.spacing.xs,
                        children: [
                          Text(
                            userProfile?.nickname ??
                                userProfile?.displayName ??
                                userProfile?.email ??
                                '用戶名稱',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // 角色標籤
                          if (userProfile?.isCoach ?? false)
                            _RoleBadge(
                              label: '教練',
                              icon: Icons.star,
                              color: colorScheme.primary,
                            )
                          else if (userProfile?.isStudent ?? true)
                            _RoleBadge(
                              label: '學員',
                              icon: Icons.school,
                              color: colorScheme.secondary,
                            ),
                        ],
                      ),
                      SizedBox(height: context.spacing.sm),
                      // 基本資訊（年齡、性別）
                      Wrap(
                        spacing: context.spacing.sm,
                        children: [
                          if (userProfile?.age != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cake,
                                    size: 16, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  '${userProfile!.age} 歲',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (userProfile?.gender != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  userProfile!.gender == '男'
                                      ? Icons.male
                                      : Icons.female,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  userProfile!.gender!,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      // 個人簡介
                      if (userProfile?.bio != null &&
                          userProfile!.bio!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: context.spacing.sm),
                          child: Text(
                            userProfile!.bio!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacing.md),
            // 快捷按鈕（小螢幕垂直排列）
            if (isMobileSmall)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: onEditProfile,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('編輯資料'),
                  ),
                  SizedBox(height: context.spacing.sm),
                  FilledButton.icon(
                    onPressed: onViewBodyData,
                    icon: const Icon(Icons.show_chart, size: 18),
                    label: const Text('身體數據'),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEditProfile,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('編輯資料'),
                    ),
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onViewBodyData,
                      icon: const Icon(Icons.show_chart, size: 18),
                      label: const Text('身體數據'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 角色標籤組件
class _RoleBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _RoleBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

