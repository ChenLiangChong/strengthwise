// ✅ P3 響應式分欄佈局 (True Dual-Pane Content)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/interfaces/i_coach_management_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/views/pages/relationships/role_client/tabs/coach_info_tab.dart';
import 'package:strengthwise/views/pages/notes/session_notes_list_page.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/coach_slots_management_page.dart';

/// 教練詳情內容（用於 Dual-Pane 右側面板）
class CoachDetailContent extends StatefulWidget {
  final String coachId;
  final UserModel coach;
  final String clientId;
  final VoidCallback? onClose; // 用於關閉詳情（手機版可能需要，但在 Dual-Pane 中通常是切換）

  const CoachDetailContent({
    super.key,
    required this.coachId,
    required this.coach,
    required this.clientId,
    this.onClose,
  });

  @override
  State<CoachDetailContent> createState() => _CoachDetailContentState();
}

class _CoachDetailContentState extends State<CoachDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ICoachManagementController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = serviceLocator<ICoachManagementController>();

    // 選中教練（載入詳細資料）
    _controller.selectCoach(widget.coachId, widget.clientId);
  }

  @override
  void didUpdateWidget(covariant CoachDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coachId != oldWidget.coachId) {
      _controller.selectCoach(widget.coachId, widget.clientId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.clearSelectedCoach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ChangeNotifierProvider<ICoachManagementController>.value(
      value: _controller,
      child: Column(
        children: [
          // 標題欄（高度 56px 與左側對齊）
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary,
                  backgroundImage: widget.coach.photoURL != null
                      ? NetworkImage(widget.coach.photoURL!)
                      : null,
                  child: widget.coach.photoURL == null
                      ? Text(
                          (widget.coach.displayName ?? widget.coach.email)
                              .substring(0, 1)
                              .toUpperCase(),
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.coach.displayName ?? widget.coach.email,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '教練資訊',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 如果有 onClose 回調（例如手機版 Modal 模式），顯示關閉按鈕
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
              ],
            ),
          ),

          // TabBar（高度 48px 與左側對齊）
          Container(
            height: 48,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false, // 3 個 Tab 不需要滾動
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: const [
                Tab(text: '基本資料'),
                Tab(text: '預約上課'),
                Tab(text: '分享筆記'),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: 基本資料
                CoachInfoTab(
                  coach: widget.coach,
                  clientId: widget.clientId,
                ),

                // Tab 2: 預約上課（該教練的可約時段）
                CoachSlotsManagementPage(
                  isViewMode: true,
                  coachId: widget.coachId,
                ),

                // Tab 3: 分享筆記（該教練對此學員的筆記記錄）
                SessionNotesListPage(
                  clientId: widget.clientId,
                  coachId: widget.coachId,
                  isClientView: true,
                  coach: widget.coach,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
