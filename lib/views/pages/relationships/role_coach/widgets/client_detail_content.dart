// ✅ P3 響應式分欄佈局
// ✅ v3.6: MVVM 重構 - 移除 Service 直接調用
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/interfaces/i_client_management_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_workout_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/tabs/client_info_tab.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/tabs/client_workout_calendar_tab.dart';
import 'package:strengthwise/views/pages/notes/session_notes_list_page.dart';
import 'package:strengthwise/views/pages/statistics/statistics_page_v2.dart';

/// 學員詳情內容 - 用於嵌入式顯示（無外層 Scaffold）
///
/// 設計用於：
/// 1. Master-Detail 佈局的右側詳情區
/// 2. 可獨立使用或嵌入其他頁面
///
/// 與 [ClientDetailPage] 的差異：
/// - 沒有外層 Scaffold
/// - AppBar 替換為較簡潔的標題欄
class ClientDetailContent extends StatefulWidget {
  final String clientId;
  final UserModel client;

  /// 當數據變更時的回調（用於刷新列表）
  final VoidCallback? onDataChanged;

  const ClientDetailContent({
    super.key,
    required this.clientId,
    required this.client,
    this.onDataChanged,
  });

  @override
  State<ClientDetailContent> createState() => _ClientDetailContentState();
}

class _ClientDetailContentState extends State<ClientDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late IClientManagementController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _controller = serviceLocator<IClientManagementController>();
    _controller.selectClient(widget.clientId);
  }

  @override
  void didUpdateWidget(ClientDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當 clientId 變更時重新載入
    if (oldWidget.clientId != widget.clientId) {
      _controller.selectClient(widget.clientId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 刷新當前 Tab 的數據
  Future<void> _refreshCurrentTab() async {
    final currentIndex = _tabController.index;

    switch (currentIndex) {
      case 0:
        _controller.selectClient(widget.clientId);
        break;
      case 1:
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
      case 2:
      case 3:
        // 這些 Tab 有自己的刷新邏輯
        break;
    }
    widget.onDataChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ChangeNotifierProvider<IClientManagementController>.value(
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
                  backgroundImage: widget.client.photoURL != null
                      ? NetworkImage(widget.client.photoURL!)
                      : null,
                  child: widget.client.photoURL == null
                      ? Text(
                          (widget.client.displayName ?? widget.client.email)
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
                        widget.client.displayName ?? widget.client.email,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.client.email,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '重新載入',
                  onPressed: _refreshCurrentTab,
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
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: const [
                Tab(text: '基本資訊'),
                Tab(text: '行事曆'),
                Tab(text: '筆記'),
                Tab(text: '統計'),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ClientInfoTab(client: widget.client),
                ClientWorkoutCalendarTab(
                  clientId: widget.clientId,
                  client: widget.client,
                ),
                SessionNotesListPage(
                  clientId: widget.clientId,
                  client: widget.client,
                ),
                StatisticsPageV2(
                  userId: widget.clientId,
                  showAppBar: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
