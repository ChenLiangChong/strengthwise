import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/interfaces/i_statistics_controller.dart';
import '../../../controllers/interfaces/i_auth_controller.dart';
import '../../../services/service_locator.dart';
import '../../../widgets/statistics/empty_state_widget.dart';
import 'widgets/time_range_selector.dart';
import 'tabs/overview_tab.dart';
import 'tabs/strength_progress_tab.dart';
import 'tabs/muscle_balance_tab.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/completion_rate_tab.dart';
import 'tabs/body_data_tab.dart';

/// 統計頁面（重構版）
///
/// 包含力量進步、肌群平衡、訓練日曆等專業統計功能
class StatisticsPageV2 extends StatefulWidget {
  const StatisticsPageV2({Key? key}) : super(key: key);

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

  /// ⚡ 智能初始化統計數據
  ///
  /// - 如果已預載入（從首頁進入），使用現有數據
  /// - 如果未預載入（直接進入），使用 initializeMinimal
  /// - 初始化完成後，背景載入其他時間範圍
  Future<void> _initializeStatistics() async {
    final user = _authController.user;
    if (user == null) return;

    // 如果還沒有數據，載入本週數據
    if (_controller.statisticsData == null) {
      await _controller.initializeMinimal(user.uid);
    }

    // ⚡ 背景載入其他時間範圍（本月、三個月、本年）
    _preloadOtherTimeRanges(user.uid);
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
    // 檢查用戶是否登入
    final user = _authController.user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('訓練統計')),
        body: const Center(child: Text('請先登入')),
      );
    }

    return ChangeNotifierProvider<IStatisticsController>.value(
      value: _controller,
      child: Scaffold(
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
        body: Consumer<IStatisticsController>(
          builder: (context, controller, _) {
            // 載入中
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // 錯誤狀態
            if (controller.errorMessage != null) {
              return _buildErrorState(controller, user);
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
                    children: [
                      OverviewTab(data: data, controller: controller),
                      StrengthProgressTab(
                        userId: user.uid,
                        statisticsData: data,
                        timeRange: controller.timeRange,
                        onRefresh: () => controller.refreshStatistics(),
                      ),
                      MuscleBalanceTab(data: data),
                      CalendarTab(data: data),
                      CompletionRateTab(data: data),
                      BodyDataTab(userId: user.uid),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 構建錯誤狀態
  Widget _buildErrorState(IStatisticsController controller, user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(controller.errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.initialize(user.uid),
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }
}

