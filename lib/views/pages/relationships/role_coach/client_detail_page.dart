import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/client_management_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/interfaces/i_workout_service.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/tabs/client_info_tab.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/tabs/client_workout_calendar_tab.dart';
import 'package:strengthwise/views/pages/notes/session_notes_list_page.dart';
import 'package:strengthwise/views/pages/statistics/statistics_page_v2.dart';

/// 學員詳情頁面（教練端）
///
/// 功能：
/// 1. 基本資訊 Tab
/// 2. 訓練行事曆 Tab（核心功能，整合時間偏好背景色）
/// 3. 課程筆記 Tab
/// 4. 統計分析 Tab（查看學員統計）
class ClientDetailPage extends StatefulWidget {
  final String clientId;
  final UserModel client;

  const ClientDetailPage({
    super.key,
    required this.clientId,
    required this.client,
  });

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ClientManagementController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 5 → 4（移除時間偏好 Tab）
    _controller = serviceLocator<ClientManagementController>();

    // 選擇學員（載入詳細資料）
    _controller.selectClient(widget.clientId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    // 清除選中的學員
    _controller.clearSelectedClient();
    super.dispose();
  }

  /// 刷新當前 Tab 的數據 ⭐
  Future<void> _refreshCurrentTab() async {
    final currentIndex = _tabController.index;

    switch (currentIndex) {
      case 0: // 基本資訊
        _controller.selectClient(widget.clientId);
        break;
      case 1: // 訓練行事曆
        // ⭐ 清除學員的快取，強制重新查詢資料庫
        final workoutService = serviceLocator<IWorkoutService>();
        workoutService.clearUserCache(userId: widget.clientId);

        final now = DateTime.now();
        await _controller.loadClientWorkouts(
          widget.clientId,
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
        );
        await _controller.loadClientAvailability(
          widget.clientId,
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
        );
        break;
      case 2: // 課程筆記
        // SessionNotesListPage 有自己的刷新邏輯
        break;
      case 3: // 統計分析
        // StatisticsPageV2 有自己的刷新邏輯
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ClientManagementController>.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.client.displayName ?? widget.client.email),
              Text(
                '學員詳情',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            // ⭐ 刷新按鈕
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重新載入',
              onPressed: _refreshCurrentTab,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: '基本資訊'),
              Tab(icon: Icon(Icons.calendar_today), text: '訓練行事曆'),
              Tab(icon: Icon(Icons.note), text: '課程筆記'),
              Tab(icon: Icon(Icons.bar_chart), text: '統計分析'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: 基本資訊
            ClientInfoTab(client: widget.client),

            // Tab 2: 訓練行事曆（核心功能，已整合時間偏好背景色）
            ClientWorkoutCalendarTab(
              clientId: widget.clientId,
              client: widget.client,
            ),

            // Tab 3: 課程筆記（過濾該學員）⭐ 傳入學員資訊
            SessionNotesListPage(
              clientId: widget.clientId,
              client: widget.client, // ⭐ 傳入學員資訊，用於顯示標題
            ),

            // Tab 4: 統計分析（查看學員統計）
            StatisticsPageV2(
              userId: widget.clientId,
              showAppBar: false, // ⭐ 不顯示 AppBar（已有外層 AppBar）
            ),
          ],
        ),
      ),
    );
  }
}
