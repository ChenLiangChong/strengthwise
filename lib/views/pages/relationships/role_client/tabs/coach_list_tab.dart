// ✅ v3.6: MVVM 重構 - 移除 Service 直接調用
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/interfaces/i_coach_management_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_coaching_relationship_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/views/pages/relationships/role_client/coach_detail_page.dart';
import 'package:strengthwise/views/pages/relationships/role_client/widgets/coach_card.dart';
import 'package:strengthwise/views/pages/relationships/role_client/widgets/input_invite_code_dialog.dart';
import 'package:strengthwise/views/pages/relationships/binding/binding_page.dart';

/// 教練列表 Tab（學員端）
class CoachListTab extends StatefulWidget {
  final String clientId;

  /// ⭐ P3：選中教練回調（用於 True Dual-Pane 佈局）
  final void Function(UserModel? coach)? onCoachSelected;

  const CoachListTab({
    super.key,
    required this.clientId,
    this.onCoachSelected,
  });

  @override
  State<CoachListTab> createState() => _CoachListTabState();
}

class _CoachListTabState extends State<CoachListTab>
    with AutomaticKeepAliveClientMixin {
  late final ICoachManagementController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true; // ⭐ 保持頁面狀態

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<ICoachManagementController>();
    _controller.loadCoaches(widget.clientId);

    _searchController.addListener(() {
      _controller.searchCoaches(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 刷新列表
  Future<void> _refresh() async {
    // ⭐ v3.6: 透過 Controller 清除快取
    final coachingController = serviceLocator<ICoachingRelationshipController>();
    coachingController.clearClientCache(widget.clientId);

    // 重新載入
    await _controller.loadCoaches(widget.clientId);
  }

  /// 查看教練詳情
  Future<void> _viewCoachDetail(UserModel coach) async {
    // ⭐ P3: 如果有回調，通知父層
    if (widget.onCoachSelected != null) {
      widget.onCoachSelected!(coach);
      return;
    }

    // 否則使用傳統 Push 導航
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachDetailPage(
          coachId: coach.uid,
          coach: coach,
          clientId: widget.clientId,
        ),
      ),
    );

    // ⭐ 如果解除綁定成功，刷新列表
    if (result == true && mounted) {
      _refresh();
    }
  }

  /// 顯示新增教練選項（QR Code）
  /// 顯示新增教練選項（邀請碼或 QR Code）
  Future<void> _showAddCoachOptions() async {
    final authController = serviceLocator<IAuthController>();
    final user = authController.user;
    if (user == null) return;

    final selectedOption = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('輸入邀請碼'),
              subtitle: const Text('使用教練提供的邀請碼'),
              onTap: () => Navigator.pop(context, 'invite_code'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('QR Code 綁定'),
              subtitle: const Text('掃描教練 QR Code'),
              onTap: () => Navigator.pop(context, 'qrcode'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (selectedOption == null || !mounted) return;

    if (selectedOption == 'invite_code') {
      _showInputInviteCodeDialog();
    } else if (selectedOption == 'qrcode') {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => BindingPage(
            currentRole: 'client',
            userName: user.displayName ?? '未知學員',
            userEmail: user.email,
          ),
        ),
      );

      if (result == true && mounted) {
        _refresh(); // 重新載入列表
      }
    }
  }

  /// 顯示輸入邀請碼對話框
  Future<void> _showInputInviteCodeDialog() async {
    final authController = serviceLocator<IAuthController>();
    final traineeId = authController.user?.uid;
    if (traineeId == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => InputInviteCodeDialog(
        traineeId: traineeId,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('成功加入教練！'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      _refresh(); // 重新載入列表
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ⭐ AutomaticKeepAliveClientMixin 要求
    return ChangeNotifierProvider<ICoachManagementController>.value(
      value: _controller,
      child: Consumer<ICoachManagementController>(
        builder: (context, controller, child) {
          // ⭐ 移除 AppBar，因為此頁面在 TabBarView 中使用
          return Scaffold(
            body: Column(
              children: [
                // 搜尋欄
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜尋教練姓名或 Email',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: controller.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                controller.clearSearch();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // 統計卡片
                if (controller.coaches.isNotEmpty)
                  _buildStatisticsCard(controller),

                // 教練列表
                Expanded(
                  child: _buildCoachList(controller),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'coach_list_fab', // ⭐ 防止 Hero tag 衝突
              onPressed: _showAddCoachOptions,
              icon: const Icon(Icons.person_add),
              label: const Text('新增教練'),
            ),
          );
        },
      ),
    );
  }

  /// 統計卡片
  Widget _buildStatisticsCard(ICoachManagementController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalCoaches = controller.coaches.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 32, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '共 $totalCoaches 位教練',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 教練列表
  Widget _buildCoachList(ICoachManagementController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (controller.filteredCoaches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.searchQuery.isNotEmpty ? '找不到符合的教練' : '尚未綁定任何教練',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '向下拉動可刷新列表',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                if (controller.searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      controller.clearSearch();
                    },
                    child: const Text('清除搜尋'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.filteredCoaches.length,
        itemBuilder: (context, index) {
          final coach = controller.filteredCoaches[index];
          return CoachCard(
            coach: coach,
            onTap: () => _viewCoachDetail(coach),
          );
        },
      ),
    );
  }
}
