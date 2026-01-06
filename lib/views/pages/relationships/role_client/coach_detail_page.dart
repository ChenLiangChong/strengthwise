// ✅ 已響應式改造 (Phase 0) - Tab 子組件處理
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/coach_management_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/views/pages/relationships/role_client/tabs/coach_info_tab.dart';
import 'package:strengthwise/views/pages/notes/session_notes_list_page.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/coach_slots_management_page.dart';

/// 教練詳情頁面（學員端）
///
/// 功能：
/// 1. 基本資料 Tab
/// 2. 預約上課 Tab（該教練的可約時段）
/// 3. 分享筆記 Tab（該教練對此學員的筆記記錄）
class CoachDetailPage extends StatefulWidget {
  final String coachId;
  final UserModel coach;
  final String clientId;

  const CoachDetailPage({
    super.key,
    required this.coachId,
    required this.coach,
    required this.clientId,
  });

  @override
  State<CoachDetailPage> createState() => _CoachDetailPageState();
}

class _CoachDetailPageState extends State<CoachDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CoachManagementController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this); // 4 → 3（移除預約 Tab，改到 BookingPage）
    _controller = serviceLocator<CoachManagementController>();

    // 選中教練（載入詳細資料）
    _controller.selectCoach(widget.coachId, widget.clientId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    // 清除選中的教練
    _controller.clearSelectedCoach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CoachManagementController>.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.coach.displayName ?? widget.coach.email),
              Text(
                '教練資訊',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false, // 3 個 Tab 不需要滾動
            tabs: const [
              Tab(icon: Icon(Icons.person), text: '基本資料'),
              Tab(icon: Icon(Icons.event_available), text: '預約上課'),
              Tab(icon: Icon(Icons.note), text: '分享筆記'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: 基本資料
            CoachInfoTab(
              coach: widget.coach,
              clientId: widget.clientId, // 【傳入 clientId】
            ),

            // Tab 2: 預約上課（該教練的可約時段）【過濾該教練】
            CoachSlotsManagementPage(
              isViewMode: true, // 學員唯讀模式
              coachId: widget.coachId, // 【傳入教練 ID 過濾】
            ),

            // Tab 3: 分享筆記（該教練對此學員的筆記記錄）【過濾 coachId + clientId】
            SessionNotesListPage(
              clientId: widget.clientId,
              coachId: widget.coachId,
              isClientView: true, // 學員視角（只看已分享內容）
              coach: widget.coach, // 【傳入教練資料，用於顯示名稱】
            ),
          ],
        ),
      ),
    );
  }
}
