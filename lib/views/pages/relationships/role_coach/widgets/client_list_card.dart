// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/coaching_relationship_model.dart';
import 'package:strengthwise/models/user_model.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/widgets/client_list_item.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/widgets/empty_clients_state.dart';

/// 學員列表卡片組件
class ClientListCard extends StatelessWidget {
  final List<CoachingRelationshipModel> relationships;
  final Map<String, UserModel> clientsMap;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(CoachingRelationshipModel) onArchiveClient;
  final Function(CoachingRelationshipModel) onDeleteClient;
  final Function(CoachingRelationshipModel, UserModel)? onClientTap;
  final Function(CoachingRelationshipModel, UserModel)?
      onViewClientAvailability;

  const ClientListCard({
    super.key,
    required this.relationships,
    required this.clientsMap,
    required this.isLoading,
    required this.onRefresh,
    required this.onArchiveClient,
    required this.onDeleteClient,
    this.onClientTap,
    this.onViewClientAvailability,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (relationships.isEmpty) {
      return const EmptyClientsState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView.builder(
        padding: context.pagePadding, // ⭐ 響應式邊距
        itemCount: relationships.length,
        itemBuilder: (context, index) {
          final relationship = relationships[index];
          final client = clientsMap[relationship.clientId];

          // 如果找不到學員資料，顯示錯誤卡片
          if (client == null) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '無法載入學員資料 (ID: ${relationship.clientId})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ClientListItem(
            relationship: relationship,
            client: client,
            onTap: onClientTap != null
                ? () => onClientTap!(relationship, client)
                : null,
            onArchive: () =>
                _showArchiveConfirmDialog(context, relationship, client),
            onDelete: () =>
                _showDeleteConfirmDialog(context, relationship, client),
            onViewAvailability: onViewClientAvailability != null
                ? () => onViewClientAvailability!(relationship, client)
                : null,
          );
        },
      ),
    );
  }

  /// 顯示歸檔確認對話框
  Future<void> _showArchiveConfirmDialog(
    BuildContext context,
    CoachingRelationshipModel relationship,
    UserModel client,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => AlertDialog(
        title: const Text('確認歸檔'),
        content: Text(
            '確定要歸檔學員「${client.displayName ?? client.email}」嗎？\n\n歸檔後可以隨時恢復。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('確定歸檔'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onArchiveClient(relationship);
    }
  }

  /// 顯示刪除確認對話框
  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    CoachingRelationshipModel relationship,
    UserModel client,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('確認刪除'),
          ],
        ),
        content: Text(
          '確定要刪除學員「${client.displayName ?? client.email}」嗎？\n\n'
          '⚠️ 此操作無法復原！\n'
          '學員的訓練記錄將不會被刪除，但你將無法再查看或管理。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('確定刪除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onDeleteClient(relationship);
    }
  }
}
