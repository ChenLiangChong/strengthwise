// ✅ 已響應式改造 (Phase 0) - Tab 子組件處理
// ✅ v3.2: Coach Mark 引導
// ✅ v3.6: MVVM 重構 - 移除 Service 直接調用
// ✅ v3.9: Realtime 訂閱移至 ClientWorkoutCalendarTab（頁面級訂閱）
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:strengthwise/controllers/interfaces/i_client_management_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_controller.dart';
import 'package:strengthwise/services/core/onboarding_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/tabs/client_info_tab.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/tabs/client_workout_calendar_tab.dart';
import 'package:strengthwise/views/pages/notes/session_notes_list_page.dart';
import 'package:strengthwise/views/pages/statistics/statistics_page_v2.dart';
import 'package:strengthwise/views/widgets/onboarding/coach_mark_helper.dart';

/// 學員詳情頁面（教練端）
///
/// 功能：
/// 1. 基本資料 Tab
/// 2. 訓練行事曆 Tab（核心重構：完整的偏好背景提示）
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
  late IClientManagementController _controller;
  
  // ⭐ v3.2: Coach Mark 引導
  final GlobalKey _tabBarKey = GlobalKey();
  bool _coachMarkShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 5 → 4（移除預約 Tab）
    _controller = serviceLocator<IClientManagementController>();

    // 選中學員（載入詳細資料）
    _controller.selectClient(widget.clientId);
    
    // ⭐ v3.9: Realtime 訂閱已移至 ClientWorkoutCalendarTab（Tab 2）
    
    // ⭐ v3.2: 檢查 Coach Mark 引導
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCoachMark();
    });
  }
  
  // ⭐ v3.2: 檢查是否顯示 Coach Mark
  Future<void> _checkCoachMark() async {
    if (_coachMarkShown) return;
    
    final onboardingService = serviceLocator<OnboardingService>();
    final shouldShow = await onboardingService.shouldShowCoachMark(
      OnboardingService.keyCoachClientDetail,
    );
    
    if (shouldShow && mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showCoachMark();
      });
    }
  }
  
  // ⭐ v3.2: 顯示 Coach Mark 引導
  void _showCoachMark() {
    if (_coachMarkShown) return;
    _coachMarkShown = true;
    
    final targets = <TargetFocus>[];
    
    if (_tabBarKey.currentContext != null) {
      targets.add(
        CoachMarkHelper.createRectTarget(
          key: _tabBarKey,
          title: '學員詳情',
          description: '學員行事曆：查看學員可訓練時間\n過往運動紀錄',
          contentAlign: ContentAlign.bottom,
        ),
      );
    }
    
    if (targets.isNotEmpty) {
      CoachMarkHelper.show(
        context: context,
        targets: targets,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // 清除選中的學員
    _controller.clearSelectedClient();
    super.dispose();
  }

  /// 刷新當前 Tab 的數據
  Future<void> _refreshCurrentTab() async {
    final currentIndex = _tabController.index;

    switch (currentIndex) {
      case 0: // 基本資料
        _controller.selectClient(widget.clientId);
        break;
      case 1: // 訓練行事曆
        // ⭐ v3.6: 透過 Controller 清除快取
        final workoutController = serviceLocator<IWorkoutController>();
        workoutController.clearUserCache(userId: widget.clientId);

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
    return ChangeNotifierProvider<IClientManagementController>.value(
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
            // 【刷新按鈕】
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重新載入',
              onPressed: _refreshCurrentTab,
            ),
          ],
          bottom: TabBar(
            key: _tabBarKey, // ⭐ v3.2: Coach Mark 引導用
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: '基本資料'),
              Tab(icon: Icon(Icons.calendar_today), text: '訓練行事曆'),
              Tab(icon: Icon(Icons.note), text: '課程筆記'),
              Tab(icon: Icon(Icons.bar_chart), text: '統計分析'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: 基本資料
            ClientInfoTab(client: widget.client),

            // Tab 2: 訓練行事曆（完整功能，已包含偏好背景提示）
            ClientWorkoutCalendarTab(
              clientId: widget.clientId,
              client: widget.client,
            ),

            // Tab 3: 課程筆記（過濾該學員）【傳入學員資料】
            SessionNotesListPage(
              clientId: widget.clientId,
              client: widget.client, // 【傳入學員資料，用於顯示名稱】
            ),

            // Tab 4: 統計分析（查看學員統計）
            StatisticsPageV2(
              userId: widget.clientId,
              showAppBar: false, // 【不顯示 AppBar（已有頁面 AppBar）】
            ),
          ],
        ),
      ),
    );
  }
}
