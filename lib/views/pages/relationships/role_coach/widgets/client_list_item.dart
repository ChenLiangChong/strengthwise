import 'package:flutter/material.dart';
import 'package:strengthwise/models/coaching_relationship_model.dart';
import 'package:strengthwise/models/user_model.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/widgets/client_status_chip.dart';

/// 單個學員列表項組件
class ClientListItem extends StatelessWidget {
  final CoachingRelationshipModel relationship;
  final UserModel client;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onViewAvailability; // ⭐ 新增：查看時間偏好

  const ClientListItem({
    super.key,
    required this.relationship,
    required this.client,
    this.onTap,
    this.onArchive,
    this.onDelete,
    this.onViewAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 學員信息行
              Row(
                children: [
                  // 頭像
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      _getInitials(client.displayName ?? client.email),
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 學員名稱和 Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.displayName ?? '未設定姓名',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          client.email,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // 狀態標籤
                  ClientStatusChip(status: relationship.status),

                  // 更多選單
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    itemBuilder: (context) => [
                      // ⭐ 新增：查看時間偏好
                      if (relationship.status == 'active' &&
                          onViewAvailability != null)
                        const PopupMenuItem(
                          value: 'availability',
                          child: Row(
                            children: [
                              Icon(Icons.schedule_outlined),
                              SizedBox(width: 12),
                              Text('查看時間偏好'),
                            ],
                          ),
                        ),
                      if (relationship.status == 'active')
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined),
                              SizedBox(width: 12),
                              Text('歸檔'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 12),
                            Text('刪除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'availability' &&
                          onViewAvailability != null) {
                        onViewAvailability!();
                      } else if (value == 'archive' && onArchive != null) {
                        onArchive!();
                      } else if (value == 'delete' && onDelete != null) {
                        onDelete!();
                      }
                    },
                  ),
                ],
              ),

              // 日期信息
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '邀請於 ${_formatDate(relationship.invitedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                  ),
                  if (relationship.acceptedAt != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '接受於 ${_formatDate(relationship.acceptedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 獲取姓名首字母
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
