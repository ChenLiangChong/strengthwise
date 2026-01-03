import 'package:flutter/material.dart';
import 'package:strengthwise/services/interfaces/i_coaching_relationship_service.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/models/coaching_relationship_model.dart';
import 'package:strengthwise/models/user_model.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/widgets/client_list_card.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/widgets/generate_invite_code_dialog.dart';
import 'package:strengthwise/views/pages/scheduling/availability/client_availability_page.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/client_detail_page.dart';
import 'package:strengthwise/views/pages/relationships/binding/binding_page.dart';

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

    // 清除教練關係快取
    _relationshipService.clearCoachCache(_currentUserId!);

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
  /// 顯示生成邀請碼對話框
  Future<void> _showGenerateInviteCodeDialog() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法獲取當前用戶 ID')),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GenerateInviteCodeDialog(
        coachId: _currentUserId!,
      ),
    );

    // 可選：重新載入列表（因為可能有新學員）
    if (mounted) {
      _loadClients();
    }
  }

  /// 顯示邀請學員選項（邀請碼或 QR Code）
  Future<void> _showInviteOptions() async {
    final user = _authController.user;
    if (user == null) return;

    final selectedOption = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('生成邀請碼'),
              subtitle: const Text('遠端邀請學員（5 分鐘有效）'),
              onTap: () => Navigator.pop(context, 'invite_code'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('QR Code 綁定'),
              subtitle: const Text('掃描學員 QR Code 或分享我的 QR Code'),
              onTap: () => Navigator.pop(context, 'qrcode'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (selectedOption == null || !mounted) return;

    if (selectedOption == 'invite_code') {
      _showGenerateInviteCodeDialog();
    } else if (selectedOption == 'qrcode') {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => BindingPage(
            currentRole: 'coach',
            userName: user.displayName ?? '未知教練',
            userEmail: user.email,
          ),
        ),
      );

      if (result == true && mounted) {
        _loadClients(); // 重新載入列表
      }
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

  /// 查看學員的時間偏好
  void _viewClientAvailability(
      CoachingRelationshipModel relationship, UserModel client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientAvailabilityPage(
          clientId: client.uid,
          clientName: client.displayName ?? client.email,
          isViewMode: true, // 教練查看模式（只讀）
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ⭐ 移除返回按鈕（TabBar 子頁面不需要）
        title: const Text('學員管理'),
        actions: [
          // 刷新按鈕
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新列表',
            onPressed: _isLoading ? null : _loadClients,
          ),
          // 顯示當前用戶 UUID（開發專用）
          if (_currentUserId != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: '查看我的 UUID',
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
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
                              Icon(Icons.warning_amber,
                                  color: Colors.orange, size: 20),
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
              onArchiveClient: (relationship) =>
                  _archiveClient(relationship.id),
              onDeleteClient: (relationship) => _deleteClient(relationship.id),
              onViewClientAvailability: _viewClientAvailability,
              onClientTap: (relationship, client) {
                // 導航到學員詳情頁面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClientDetailPage(
                      clientId: client.uid,
                      client: client,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteOptions,
        icon: const Icon(Icons.person_add),
        label: const Text('邀請學員'),
      ),
    );
  }

  /// 統計卡片
  Widget _buildStatisticsCard(ColorScheme colorScheme) {
    final totalClients = _relationships.length;
    final activeClients =
        _relationships.where((r) => r.status == 'active').length;
    final pendingClients =
        _relationships.where((r) => r.status == 'pending').length;

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
