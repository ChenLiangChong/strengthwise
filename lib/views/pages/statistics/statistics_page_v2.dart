// ✅ 已響應式改造 (Phase 0)
// ✅ v3.5: AppEventBus 自動刷新
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/interfaces/i_statistics_controller.dart';
import 'package:strengthwise/models/statistics_model.dart'; // ⭐ 效能優化：Selector 需要
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_event_bus_controller.dart';
import 'package:strengthwise/services/core/app_event_bus.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/views/pages/statistics/widgets/empty_state_widget.dart';
import 'package:strengthwise/common_widgets/loading/skeleton_loader.dart';
import 'widgets/time_range_selector.dart';
import 'tabs/overview_tab.dart';
import 'tabs/strength_progress_tab.dart';
import 'tabs/muscle_balance_tab.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/completion_rate_tab.dart';
import 'tabs/body_data_tab.dart';

/// 統計頁面（重構版）
///
/// 響應式設計：子組件已適配多尺寸螢幕
///
/// 包含力量進步、肌群平衡、訓練日曆等專業統計功能
///
/// 參數：
/// - [userId]: 可選的用戶 ID
///   - 如果提供：查詢該用戶的統計（教練查看學員）
///   - 如果不提供：查詢當前登入用戶的統計
/// - [showAppBar]: 是否顯示 AppBar（預設 true，嵌入 Tab 時設為 false）
class StatisticsPageV2 extends StatefulWidget {
  /// 要查詢統計的用戶 ID（可選）
  final String? userId;

  /// 是否顯示 AppBar（嵌入 Tab 時設為 false）
  final bool showAppBar;

  const StatisticsPageV2({
    Key? key,
    this.userId,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  State<StatisticsPageV2> createState() => _StatisticsPageV2State();
}

class _StatisticsPageV2State extends State<StatisticsPageV2>
    with SingleTickerProviderStateMixin {
  late IStatisticsController _controller;
  late IAuthController _authController;
  late TabController _tabController;
  late IEventBusController _eventBusController; // ⭐ v3.5

  // ⭐ v3.5: 事件訂閱
  StreamSubscription<AppEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<IStatisticsController>();
    _authController = serviceLocator<IAuthController>();
    _eventBusController = serviceLocator<IEventBusController>();
    _tabController = TabController(length: 6, vsync: this);

    // ⚡ 智能初始化（檢查是否已預載入）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStatistics();
    });

    // ⭐ v3.5: 訂閱統計相關事件（訓練完成、身體數據更新）
    _eventSubscription =
        _eventBusController.statisticsEvents.listen(_onAppEvent);
  }

  /// 獲取目標用戶 ID
  ///
  /// 如果提供了 userId 參數，使用該 ID；否則使用當前登入用戶的 ID
  String? _getTargetUserId() {
    if (widget.userId != null) {
      return widget.userId;
    }
    return _authController.user?.uid;
  }

  /// ⚡ 智能初始化統計數據
  ///
  /// - 如果已預載入（從首頁進入），使用現有數據
  /// - 如果未預載入（直接進入），載入當前時間範圍數據
  /// - ⭐ 優化：移除重複的預載入邏輯，由首頁統一負責
  Future<void> _initializeStatistics() async {
    final targetUserId = _getTargetUserId();
    if (targetUserId == null) return;

    // ⭐ 只有在「完全沒有數據且未在載入中」時才載入
    // 這樣可以避免與首頁預載入的重複
    if (!_controller.hasData && !_controller.isLoading) {
      // ⭐ 使用 initializeMinimal 確保 userId 被正確設定
      await _controller.initializeMinimal(targetUserId);
    }

    // ⭐ 移除 _preloadOtherTimeRanges() 調用
    // 預載入統一由首頁的 _preloadStatistics() 負責
    // 這樣可以避免重複查詢
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventSubscription?.cancel(); // ⭐ v3.5: 取消事件訂閱
    super.dispose();
  }

  /// ⭐ v3.5: 處理 AppEventBus 事件
  void _onAppEvent(AppEvent event) {
    if (!mounted) return;

    if (kDebugMode) {
      debugPrint('[STATISTICS_PAGE] 📥 收到事件: ${event.type}');
    }

    // 收到統計相關事件時，重新載入數據
    _controller.refreshStatistics();
  }

  @override
  Widget build(BuildContext context) {
    // 獲取目標用戶 ID
    final targetUserId = _getTargetUserId();
    if (targetUserId == null) {
      return widget.showAppBar
          ? Scaffold(
              appBar: AppBar(title: const Text('訓練統計')),
              body: const Center(child: Text('請先登入')),
            )
          : const Center(child: Text('請先登入'));
    }

    return ChangeNotifierProvider<IStatisticsController>.value(
      value: _controller,
      child: widget.showAppBar
          ? _buildWithAppBar(targetUserId)
          : _buildBodyOnly(targetUserId),
    );
  }

  /// 構建帶 AppBar 的完整頁面
  Widget _buildWithAppBar(String targetUserId) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練統計'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _controller.refreshStatistics();
            },
            tooltip: '重新載入',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '概覽', icon: Icon(Icons.dashboard, size: 20)),
            Tab(text: '動作追蹤', icon: Icon(Icons.trending_up, size: 20)),
            Tab(text: '肌群平衡', icon: Icon(Icons.pie_chart, size: 20)),
            Tab(text: '訓練日曆', icon: Icon(Icons.calendar_month, size: 20)),
            Tab(text: '完成率', icon: Icon(Icons.check_circle, size: 20)),
            Tab(text: '身體數據', icon: Icon(Icons.monitor_weight, size: 20)),
          ],
        ),
      ),
      body: _buildBodyOnly(targetUserId),
    );
  }

  /// 構建僅 Body 部分（用於嵌入其他頁面的 Tab）
  /// ⭐ 效能優化：使用 Selector 細化重建範圍
  Widget _buildBodyOnly(String targetUserId) {
    return Column(
      children: [
        // ⭐ 效能優化：TimeRangeSelector 只在 timeRange 變化時重建
        Selector<IStatisticsController, TimeRange>(
          selector: (_, controller) => controller.timeRange,
          builder: (context, timeRange, _) {
            final controller = context.read<IStatisticsController>();
            return TimeRangeSelector(
              currentRange: timeRange,
              onRangeChanged: (range) => controller.changeTimeRange(range),
            );
          },
        ),
        // ⭐ 效能優化：TabBarView 只在必要時重建
        Expanded(
          child: Selector<IStatisticsController, _StatisticsState>(
            selector: (_, controller) => _StatisticsState(
              isLoading: controller.isLoading,
              errorMessage: controller.errorMessage,
              data: controller.statisticsData,
              timeRange: controller.timeRange,
            ),
            builder: (context, state, _) {
              final controller = context.read<IStatisticsController>();

              // ⚡ 載入中使用骨架屏
              if (state.isLoading) {
                return const SkeletonStatistics();
              }

              // 錯誤狀態
              if (state.errorMessage != null) {
                return _buildErrorState(controller, targetUserId);
              }

              // 無數據
              final data = state.data;
              if (data == null || !data.hasData) {
                return const EmptyStateWidget(
                  icon: Icons.fitness_center,
                  title: '這個時間範圍還沒有訓練記錄',
                  subtitle: '試試切換到其他時間範圍，或開始訓練吧！',
                );
              }

              // 正常顯示
              return TabBarView(
                controller: _tabController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  OverviewTab(data: data, controller: controller),
                  StrengthProgressTab(
                    userId: targetUserId,
                    statisticsData: data,
                    timeRange: state.timeRange,
                    onRefresh: () => controller.refreshStatistics(),
                  ),
                  MuscleBalanceTab(data: data),
                  CalendarTab(data: data),
                  CompletionRateTab(data: data),
                  BodyDataTab(userId: targetUserId),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// 構建錯誤狀態
  Widget _buildErrorState(
      IStatisticsController controller, String targetUserId) {
    final textTheme = Theme.of(context).textTheme;
    final iconSize = context.isMobileSmall ? 48.0 : 64.0;

    return Center(
      child: Padding(
        padding: context.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: iconSize, color: Colors.red),
            SizedBox(height: context.spacing.md),
            Text(
              controller.errorMessage!,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.spacing.md),
            ElevatedButton(
              onPressed: () => controller.initialize(targetUserId),
              child: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ⭐ 效能優化：用於 Selector 的狀態封裝
/// 只有當這些屬性變化時才會觸發 TabBarView 重建
class _StatisticsState {
  final bool isLoading;
  final String? errorMessage;
  final StatisticsData? data;
  final TimeRange timeRange;

  const _StatisticsState({
    required this.isLoading,
    required this.errorMessage,
    required this.data,
    required this.timeRange,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _StatisticsState &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.data == data &&
        other.timeRange == timeRange;
  }

  @override
  int get hashCode => Object.hash(isLoading, errorMessage, data, timeRange);
}
