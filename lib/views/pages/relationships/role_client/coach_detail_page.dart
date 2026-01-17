// ✅ 已響應式改造 (Phase 0) - Tab 子組件處理
// ✅ v3.2: Coach Mark 引導
// ✅ v3.9: Realtime 訂閱移至 CoachSlotsManagementPage（頁面級訂閱）
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:strengthwise/controllers/coach_management_controller.dart';
import 'package:strengthwise/services/core/onboarding_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/views/pages/relationships/role_client/tabs/coach_info_tab.dart';
import 'package:strengthwise/views/pages/notes/session_notes_list_page.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/coach_slots_management_page.dart';
import 'package:strengthwise/views/widgets/onboarding/coach_mark_helper.dart';

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
  
  // ⭐ v3.2: Coach Mark 引導
  final GlobalKey _tabBarKey = GlobalKey();
  bool _coachMarkShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this); // 4 → 3（移除預約 Tab，改到 BookingPage）
    _controller = serviceLocator<CoachManagementController>();

    // 選中教練（載入詳細資料）
    _controller.selectCoach(widget.coachId, widget.clientId);
    
    // ⭐ v3.9: Realtime 訂閱已移至 CoachSlotsManagementPage（Tab 2）
    
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
      OnboardingService.keyClientCoachDetail,
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
          title: '教練詳情',
          description: '查看教練可以上課的時間\n點擊「預約上課」Tab 預約',
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
            key: _tabBarKey, // ⭐ v3.2: Coach Mark 引導用
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
