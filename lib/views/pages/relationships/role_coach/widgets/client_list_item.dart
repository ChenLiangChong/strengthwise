// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/coaching_relationship_model.dart';
import 'package:strengthwise/models/user_model.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
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
      margin: EdgeInsets.only(bottom: context.spacing.md), // ⭐ 響應式間距
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md), // ⭐ 響應式內距
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 學員信息行
              Row(
                children: [
                  // 頭像
                  CircleAvatar(
                    radius: 24.scaled(context), // ⭐ 響應式頭像
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      _getInitials(client.displayName ?? client.email),
                      style: context.responsive.titleSmall.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ), // ⭐ 響應式文字
                    ),
                  ),
                  SizedBox(width: context.spacing.md), // ⭐ 響應式間距

                  // 學員名稱和 Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.displayName ?? '未設定姓名',
                          style: context.responsive.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ), // ⭐ 響應式文字
                        ),
                        SizedBox(height: context.spacing.xs), // ⭐ 響應式間距
                        Text(
                          client.email,
                          style: context.responsive.bodySmall.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ), // ⭐ 響應式文字
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

              // 日期信息（⭐ 使用 Wrap 自動換行，避免大字體溢出）
              SizedBox(height: context.spacing.md), // ⭐ 響應式間距
              Wrap(
                spacing: context.spacing.md, // 水平間距
                runSpacing: context.spacing.xs, // 垂直換行間距
                children: [
                  // 邀請日期
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14.scaled(context), // ⭐ 響應式圖標
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                      SizedBox(width: context.spacing.xs), // ⭐ 響應式間距
                      Text(
                        '邀請於 ${_formatDate(relationship.invitedAt)}',
                        style: context.responsive.bodySmall.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ), // ⭐ 響應式文字
                      ),
                    ],
                  ),
                  // 接受日期
                  if (relationship.acceptedAt != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14.scaled(context), // ⭐ 響應式圖標
                          color: colorScheme.primary,
                        ),
                        SizedBox(width: context.spacing.xs), // ⭐ 響應式間距
                        Text(
                          '接受於 ${_formatDate(relationship.acceptedAt!)}',
                          style: context.responsive.bodySmall.copyWith(
                            color: colorScheme.primary,
                          ), // ⭐ 響應式文字
                        ),
                      ],
                    ),
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
