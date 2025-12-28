import 'package:flutter/material.dart';
import '../appointments/coach_slots_management_page.dart';
import '../appointments/appointments_list_page.dart';
import 'client_management_page.dart';

/// 教練功能整合頁面（Hub Page）
///
/// 功能：
/// 1. 學員管理（Phase 1）
/// 2. 時段管理（Phase 2）
/// 3. 我的預約（Phase 2 - 教練視角）
/// 4. 未來：收入統計、課程筆記等
class CoachHubPage extends StatefulWidget {
  const CoachHubPage({super.key});

  @override
  State<CoachHubPage> createState() => _CoachHubPageState();
}

class _CoachHubPageState extends State<CoachHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('教練管理中心'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: '學員管理'),
            Tab(icon: Icon(Icons.schedule), text: '時段管理'),
            Tab(icon: Icon(Icons.list_alt), text: '我的預約'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: 學員管理（Phase 1）
          ClientManagementPage(),

          // Tab 2: 時段管理（Phase 2）
          CoachSlotsManagementPage(),

          // Tab 3: 我的預約（Phase 2 - 教練視角）
          AppointmentsListPage(isCoachMode: true),
        ],
      ),
    );
  }
}

