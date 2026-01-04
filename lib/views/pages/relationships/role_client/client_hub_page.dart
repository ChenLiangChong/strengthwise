import 'package:flutter/material.dart';
import 'package:strengthwise/views/pages/relationships/role_client/tabs/coach_list_tab.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/appointments_list_page.dart';
import 'package:strengthwise/views/pages/scheduling/availability/client_availability_page.dart';
import 'package:strengthwise/views/pages/notes/session_notes_list_page.dart';
import 'package:strengthwise/views/pages/relationships/role_client/my_health_assessment_page.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/service_locator.dart';

/// 學員功能整合頁面（Hub Page）
///
/// 功能：
/// 1. 教練列表（Phase 4C）⭐ 查看所有教練、進入教練詳情
/// 2. 我的預約（Phase 2）- 查看預約記錄
/// 3. 時間偏好設定（Phase 3）- 設定可訓練時間（行事曆模式）
/// 4. 課程筆記（Phase 4）- 查看教練分享的課程筆記
class ClientHubPage extends StatefulWidget {
  const ClientHubPage({super.key});

  @override
  State<ClientHubPage> createState() => _ClientHubPageState();
}

class _ClientHubPageState extends State<ClientHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final IAuthController _authController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 4 → 5（新增健康評估 Tab）
    _authController = serviceLocator<IAuthController>();
    _currentUserId = _authController.user?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('我的教練'),
        ),
        body: const Center(
          child: Text('無法獲取當前用戶 ID'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('學員中心'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // 5 個 Tab 需要滾動
          tabs: const [
            Tab(icon: Icon(Icons.people), text: '我的教練'),
            Tab(icon: Icon(Icons.schedule), text: '時間偏好'),
            Tab(icon: Icon(Icons.list_alt), text: '我的預約'),
            Tab(icon: Icon(Icons.note_alt), text: '課程筆記'),
            Tab(icon: Icon(Icons.health_and_safety), text: '健康評估'), // ⭐ 新增
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: 教練列表（Phase 4C）⭐ 查看所有教練
          CoachListTab(clientId: _currentUserId!),

          // Tab 2: 時間偏好設定（Phase 3）- 設定可訓練時間（行事曆模式）
          ClientAvailabilityPage(
            clientId: _currentUserId!,
            clientName: _authController.user?.displayName ?? '我',
            isViewMode: false, // 學員自己可編輯
            showAppBar: false, // ⭐ 不顯示 AppBar（已有外層 AppBar）
          ),

          // Tab 3: 我的預約（Phase 2）- 查看預約記錄
          const AppointmentsListPage(isCoachMode: false),

          // Tab 4: 課程筆記（Phase 4）- 查看教練分享的課程筆記
          const SessionNotesListPage(
            isClientMode: true, // ⭐ 學員模式（只顯示共享筆記）
          ),

          // Tab 5: 健康評估（v2.8）- 學員自行查看/填寫健康評估 ⭐ 新增
          MyHealthAssessmentPage(userId: _currentUserId!),
        ],
      ),
    );
  }
}
