import 'package:flutter/material.dart';
import '../../../../models/user_model.dart';

/// 個人資料頭部卡片
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

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                // 大頭像
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.surfaceVariant,
                      backgroundImage: userProfile?.photoURL != null
                          ? NetworkImage(userProfile!.photoURL!)
                          : null,
                      child: userProfile?.photoURL == null
                          ? Icon(Icons.person,
                              size: 45,
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
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 名稱 + 角色標籤
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userProfile?.nickname ??
                                  userProfile?.displayName ??
                                  userProfile?.email ??
                                  '用戶名稱',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 角色標籤
                          if (userProfile?.isCoach ?? false)
                            _buildRoleBadge(
                              context,
                              '教練',
                              Icons.star,
                              colorScheme.primary,
                            )
                          else if (userProfile?.isStudent ?? true)
                            _buildRoleBadge(
                              context,
                              '學員',
                              Icons.school,
                              colorScheme.secondary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 基本資訊（年齡、性別）
                      Row(
                        children: [
                          if (userProfile?.age != null) ...[
                            Icon(Icons.cake,
                                size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              '${userProfile!.age} 歲',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (userProfile?.age != null &&
                              userProfile?.gender != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '·',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          if (userProfile?.gender != null) ...[
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
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // 個人簡介
                      if (userProfile?.bio != null &&
                          userProfile!.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            userProfile!.bio!,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
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
            const SizedBox(height: 16),
            // 快捷按鈕
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditProfile,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('編輯資料'),
                  ),
                ),
                const SizedBox(width: 12),
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

  Widget _buildRoleBadge(
      BuildContext context, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

