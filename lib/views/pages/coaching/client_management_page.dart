import 'package:flutter/material.dart';
import '../../../services/interfaces/i_coaching_relationship_service.dart';
import '../../../controllers/interfaces/i_auth_controller.dart';
import '../../../services/service_locator.dart';
import '../../../models/coaching_relationship_model.dart';
import '../../../models/user_model.dart';
import 'widgets/client_list_card.dart';
import 'widgets/invite_client_dialog.dart';

/// 學員管理頁面（教練專用）
class ClientManagementPage extends StatefulWidget {
  const ClientManagementPage({super.key});

  @override
  State<ClientManagementPage> createState() => _ClientManagementPageState();
}

class _ClientManagementPageState extends State<ClientManagementPage> {
  late final ICoachingRelationshipService _relationshipService;
  late final IAuthController _authController;

  String _selectedFilter = 'active'; // active, pending, archived, all
  bool _isLoading = false;
  String? _errorMessage;
  List<CoachingRelationshipModel> _relationships = [];
  Map<String, UserModel> _clientsMap = {};
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _relationshipService = serviceLocator<ICoachingRelationshipService>();
    _authController = serviceLocator<IAuthController>();
    _initializeAndLoad();
  }

  /// 初始化並載入數據
  Future<void> _initializeAndLoad() async {
    _currentUserId = _authController.user?.uid;
    
    if (_currentUserId != null) {
      await _loadClients();
    } else {
      setState(() {
        _errorMessage = '無法獲取當前用戶 ID';
      });
    }
  }

  /// 載入學員列表
  Future<void> _loadClients() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 使用 getCoachClientsWithDetails 獲取學員詳情
      final clientUsers = await _relationshipService.getCoachClientsWithDetails(
        _currentUserId!,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      // 同時獲取關係列表（包含備註、創建時間等）
      final relationships = await _relationshipService.getCoachClients(
        _currentUserId!,
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      // 建立 clientId -> UserModel 的對應
      final clientsMap = <String, UserModel>{};
      for (final client in clientUsers) {
        clientsMap[client.uid] = client;
      }

      if (mounted) {
        setState(() {
          _relationships = relationships;
          _clientsMap = clientsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '載入學員列表失敗: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// 顯示邀請學員 Dialog
  Future<void> _showInviteDialog() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法獲取當前用戶 ID')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => InviteClientDialog(
        onInvite: (clientId, notes) async {
          await _relationshipService.createRelationship(
            _currentUserId!,
            clientId,
            status: 'active',
            notes: notes,
          );
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('學員已成功綁定！'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadClients(); // 重新載入列表
    }
  }

  /// 歸檔學員
  Future<void> _archiveClient(String relationshipId) async {
    try {
      await _relationshipService.archiveRelationship(relationshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('學員已歸檔')),
        );
        _loadClients();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('歸檔失敗: $e')),
        );
      }
    }
  }

  /// 刪除學員
  Future<void> _deleteClient(String relationshipId) async {
    try {
      await _relationshipService.deleteRelationship(relationshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('學員已刪除'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadClients();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('學員管理'),
        actions: [
          // 顯示當前用戶 UUID（開發專用）
          if (_currentUserId != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: '查看我的 UUID',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.fingerprint),
                        SizedBox(width: 12),
                        Text('我的 UUID'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '教練 ID（可分享給開發測試）：',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _currentUserId!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '⚠️ 僅供開發測試使用',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('關閉'),
                      ),
                    ],
                  ),
                );
              },
            ),
          
          // 篩選按鈕
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            initialValue: _selectedFilter,
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
              _loadClients();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'active',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Text('活躍'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.pending, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('待接受'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archived',
                child: Row(
                  children: [
                    Icon(Icons.archive, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('已歸檔'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 12),
                    Text('全部'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 統計卡片
          if (!_isLoading) _buildStatisticsCard(colorScheme),

          // 錯誤提示
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),

          // 學員列表
          Expanded(
            child: ClientListCard(
              relationships: _relationships,
              clientsMap: _clientsMap,
              isLoading: _isLoading,
              onRefresh: _loadClients,
              onInviteClient: _showInviteDialog,
              onArchiveClient: (relationship) => _archiveClient(relationship.id),
              onDeleteClient: (relationship) => _deleteClient(relationship.id),
              onClientTap: (relationship, client) {
                // TODO: 導航到學員詳情頁面
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('查看學員: ${client.displayName ?? client.email}')),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('邀請學員'),
      ),
    );
  }

  /// 統計卡片
  Widget _buildStatisticsCard(ColorScheme colorScheme) {
    final totalClients = _relationships.length;
    final activeClients = _relationships.where((r) => r.status == 'active').length;
    final pendingClients = _relationships.where((r) => r.status == 'pending').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.people,
            label: '總學員',
            value: totalClients.toString(),
            color: colorScheme.primary,
          ),
          _buildStatItem(
            icon: Icons.check_circle,
            label: '活躍',
            value: activeClients.toString(),
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.pending,
            label: '待接受',
            value: pendingClients.toString(),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  /// 統計項目
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

