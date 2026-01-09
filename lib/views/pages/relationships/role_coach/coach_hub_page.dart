// ✅ 已響應式改造 (P3 Dual-Pane)
// ✅ v3.2: Coach Mark 引導
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/services/core/onboarding_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/coach_slots_management_page.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/appointments_list_page.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointment_details_content.dart';
import 'package:strengthwise/views/pages/notes/session_notes_list_page.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/client_management_page.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/tabs/coach_profile_tab.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/widgets/client_detail_content.dart';
import 'package:strengthwise/views/widgets/onboarding/coach_mark_helper.dart';

/// 教練功能集成頁面（Hub Page）
///
/// 採 P3 響應式布局：
/// - 手機：傳統 AppBar + TabBar（上下排列）
/// - 平板/桌面：True Dual-Pane（左側面板獨立 Header + Tabs）
class CoachHubPage extends StatefulWidget {
  const CoachHubPage({super.key});

  @override
  State<CoachHubPage> createState() => _CoachHubPageState();
}

class _CoachHubPageState extends State<CoachHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 【P3 Dual-Pane】：右側 Detail 狀態
  // TODO: 當 ClientManagementPage 和 AppointmentsListPage 實作回調後啟用
  UserModel? _selectedClient;
  String? _selectedAppointmentId;
  
  // ⭐ v3.2: Coach Mark 引導
  final GlobalKey _tabBarKey = GlobalKey();
  bool _coachMarkShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    
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
      OnboardingService.keyCoachHub,
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
          title: '教練中心',
          description: '這裡管理你的學員：\n• 我的學員：查看學員詳情、訓練記錄\n• 可上課時段：設定你的可上課時間\n• 預約管理：確認/拒絕學員預約',
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

  /// Tab 切換時清除選中狀態
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedClient = null;
        _selectedAppointmentId = null;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// 學員子頁回調：選中學員
  /// TODO: 當 ClientManagementPage 實作 onClientSelected 參數後啟用
  void _onClientSelected(UserModel? client) {
    setState(() {
      _selectedClient = client;
      _selectedAppointmentId = null;
    });
  }

  /// 預約子頁回調：選中預約
  /// TODO: 當 AppointmentsListPage 實作 onAppointmentSelected 參數後啟用
  void _onAppointmentSelected(String? appointmentId) {
    setState(() {
      _selectedAppointmentId = appointmentId;
      _selectedClient = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 【平板/桌面】：True Dual-Pane
    if (!context.isMobile) {
      return _buildDualPaneLayout(context);
    }

    // 手機：傳統布局
    return _buildMobileLayout(context);
  }

  /// 手機佈局：傳統 AppBar + TabBar
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('教練管理中心'),
        bottom: TabBar(
          key: _tabBarKey, // ⭐ v3.2: Coach Mark 引導用
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.badge), text: '公開檔案'),
            Tab(icon: Icon(Icons.people), text: '學員管理'),
            Tab(icon: Icon(Icons.schedule), text: '時段管理'),
            Tab(icon: Icon(Icons.list_alt), text: '預約列表'),
            Tab(icon: Icon(Icons.note_alt), text: '課程筆記'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CoachProfileTab(),
          ClientManagementPage(),
          CoachSlotsManagementPage(),
          AppointmentsListPage(isCoachMode: true),
          SessionNotesListPage(showClientFilter: true),
        ],
      ),
    );
  }

  /// 平板/桌面佈局：True Dual-Pane
  Widget _buildDualPaneLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Row(
        children: [
          // 【左側面板】（固定寬度 420dp）
          SizedBox(
            width: 420,
            child: Column(
              children: [
                // 左側 Header
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      Text('教練管理中心', style: textTheme.titleLarge),
                    ],
                  ),
                ),
                // 左側 TabBar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                    tabs: const [
                      Tab(text: '公開檔案'),
                      Tab(text: '學員管理'),
                      Tab(text: '時段管理'),
                      Tab(text: '預約列表'),
                      Tab(text: '課程筆記'),
                    ],
                  ),
                ),
                // 左側 Master 內容
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      const CoachProfileTab(),
                      // ⭐ P3: 傳入回調，選中學員時更新右側
                      ClientManagementPage(
                        onClientSelected: _onClientSelected,
                      ),
                      const CoachSlotsManagementPage(),
                      // ⭐ P3: 傳入回調，選中預約時更新右側
                      AppointmentsListPage(
                        isCoachMode: true,
                        onAppointmentSelected: _onAppointmentSelected,
                      ),
                      const SessionNotesListPage(showClientFilter: true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 分隔線
          VerticalDivider(
              width: 1, thickness: 1, color: colorScheme.outlineVariant),

          // 【右側面板】 - 根據選中內容顯示不同 Detail
          Expanded(
            child: _selectedClient != null
                ? ClientDetailContent(
                    key: ValueKey(_selectedClient!.uid),
                    clientId: _selectedClient!.uid,
                    client: _selectedClient!,
                  )
                : _selectedAppointmentId != null
                    ? AppointmentDetailsContent(
                        key: ValueKey(_selectedAppointmentId),
                        appointmentId: _selectedAppointmentId!,
                        isCoachMode: true,
                        onClose: () =>
                            setState(() => _selectedAppointmentId = null),
                      )
                    : _buildEmptyDetailState(context),
          ),
        ],
      ),
    );
  }

  /// 空詳情狀態
  Widget _buildEmptyDetailState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            '選擇一個項目查看詳情',
            style: textTheme.bodyLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
