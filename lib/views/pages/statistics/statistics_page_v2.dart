// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/interfaces/i_statistics_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/views/pages/statistics/widgets/empty_state_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<IStatisticsController>();
    _authController = serviceLocator<IAuthController>();
    _tabController = TabController(length: 6, vsync: this);

    // ⚡ 智能初始化（檢查是否已預載入）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStatistics();
    });
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
  /// - 如果未預載入（直接進入），使用 initializeMinimal
  /// - 初始化完成後，背景載入其他時間範圍
  Future<void> _initializeStatistics() async {
    final targetUserId = _getTargetUserId();
    if (targetUserId == null) return;

    // 如果還沒有數據，載入本週數據
    if (_controller.statisticsData == null) {
      await _controller.initializeMinimal(targetUserId);
    }

    // ⚡ 背景載入其他時間範圍（本月、三個月、本年）
    _preloadOtherTimeRanges(targetUserId);
  }

  /// ⚡ 背景載入其他時間範圍
  ///
  /// 在本週數據載入完成後，背景載入其他時間範圍
  /// 這樣切換時間範圍時就能秒開
  Future<void> _preloadOtherTimeRanges(String userId) async {
    // 延遲 500ms，確保頁面渲染完成
    await Future.delayed(const Duration(milliseconds: 500));

    // 背景初始化（會預載入其他時間範圍）
    await _controller.initialize(userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            Tab(text: '力量進步', icon: Icon(Icons.trending_up, size: 20)),
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
  Widget _buildBodyOnly(String targetUserId) {
    return Consumer<IStatisticsController>(
      builder: (context, controller, _) {
        // 載入中
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 錯誤狀態
        if (controller.errorMessage != null) {
          return _buildErrorState(controller, targetUserId);
        }

        // 無數據
        final data = controller.statisticsData;
        if (data == null || !data.hasData) {
          return Column(
            children: [
              // 🐛 修復：即使沒有數據，也顯示時間範圍選擇器
              TimeRangeSelector(
                currentRange: controller.timeRange,
                onRangeChanged: (range) => controller.changeTimeRange(range),
              ),
              Expanded(
                child: const EmptyStateWidget(
                  icon: Icons.fitness_center,
                  title: '這個時間範圍還沒有訓練記錄',
                  subtitle: '試試切換到其他時間範圍，或開始訓練吧！',
                ),
              ),
            ],
          );
        }

        // 正常顯示
        return Column(
          children: [
            TimeRangeSelector(
              currentRange: controller.timeRange,
              onRangeChanged: (range) => controller.changeTimeRange(range),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const AlwaysScrollableScrollPhysics(), // ⭐ 確保支援滑動
                children: [
                  OverviewTab(data: data, controller: controller),
                  StrengthProgressTab(
                    userId: targetUserId,
                    statisticsData: data,
                    timeRange: controller.timeRange,
                    onRefresh: () => controller.refreshStatistics(),
                  ),
                  MuscleBalanceTab(data: data),
                  CalendarTab(data: data),
                  CompletionRateTab(data: data),
                  BodyDataTab(userId: targetUserId),
                ],
              ),
            ),
          ],
        );
      },
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
