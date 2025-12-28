import 'package:flutter/material.dart';
import 'client_booking_page.dart';
import 'appointments_list_page.dart';

/// 學員預約中心（Hub Page）
///
/// 功能：
/// 1. 預約課程（向教練預約）
/// 2. 我的預約（查看預約記錄）
class ClientHubPage extends StatefulWidget {
  const ClientHubPage({super.key});

  @override
  State<ClientHubPage> createState() => _ClientHubPageState();
}

class _ClientHubPageState extends State<ClientHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('學員預約中心'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.event_available), text: '預約課程'),
            Tab(icon: Icon(Icons.list_alt), text: '我的預約'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: 預約課程
          ClientBookingPage(),

          // Tab 2: 我的預約
          AppointmentsListPage(isCoachMode: false),
        ],
      ),
    );
  }
}

