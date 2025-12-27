import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../controllers/interfaces/i_auth_controller.dart';
import '../../controllers/interfaces/i_statistics_controller.dart';
import '../../services/interfaces/i_workout_service.dart';
import 'package:intl/intl.dart';
import '../../services/service_locator.dart';
import 'workout/workout_execution_page.dart';
import 'statistics/statistics_page_v2.dart';
import 'dev/notification_test_page.dart'; // 通知測試頁面

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final IAuthController _authController;
  late final IWorkoutService _workoutService;

  List<Map<String, dynamic>> _recentWorkouts = [];
  List<Map<String, dynamic>> _todayPlans = [];
  bool _isLoading = true;
  bool _isLoadingPlans = true;

  @override
  void initState() {
    super.initState();
    _authController = serviceLocator<IAuthController>();
    _workoutService = serviceLocator<IWorkoutService>();

    // ⚡ 優先載入首頁關鍵數據，完成後才預載入其他
    _initializeHomePage();
  }

  /// ⚡ 初始化首頁（優先級策略）
  ///
  /// 1. 立即載入首頁必需數據（最近訓練 + 今日計劃）
  /// 2. 首頁數據完成後，背景預載入統計（不阻塞）
  Future<void> _initializeHomePage() async {
    // 步驟 1：並行載入首頁必需數據
    await _loadCriticalDataInParallel();

    // 步驟 2：背景預載入統計（完全不阻塞用戶操作）
    if (mounted) {
      _preloadStatistics();
    }
  }

  /// ⚡ 並行載入關鍵數據
  ///
  /// 只載入首頁必需的數據（最近訓練 + 今日計劃）
  Future<void> _loadCriticalDataInParallel() async {
    // 並行執行並等待完成
    await Future.wait([
      _loadRecentWorkouts(),
      _loadTodayPlans(),
    ], eagerError: false);

    if (kDebugMode) {
      print('[HomePage] ✅ 首頁關鍵數據載入完成');
    }
  }

  /// ⚡ 背景預載入統計數據（所有時間範圍）
  ///
  /// 真機效能足夠，預載入所有時間範圍（本週、本月、三個月、本年）
  Future<void> _preloadStatistics() async {
    // ⚡ 真機優化：首頁數據完成後立即預載入所有時間範圍
    // 使用 microtask 確保在下一個事件循環執行
    Future.microtask(() async {
      try {
        final user = _authController.user;
        if (user == null) return;

        final statisticsController = serviceLocator<IStatisticsController>();

        // ⚡ 完整初始化：預載入所有時間範圍（本週、本月、三個月、本年）
        await statisticsController.initialize(user.uid);

        if (kDebugMode) {
          print('[HomePage] ✅ 統計數據預載入完成（所有時間範圍）');
        }
      } catch (e) {
        // 預載入失敗不影響主頁面
        if (kDebugMode) {
          print('[HomePage] ⚠️ 統計數據預載入失敗: $e');
        }
      }
    });
  }

  Future<void> _loadRecentWorkouts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 使用 AuthController 獲取當前用戶
      final userId = _authController.user?.uid;
      if (userId == null) {
        print('[HomePage] 用戶未登入');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('[HomePage] 查詢最近訓練，userId: $userId');

      // 使用 WorkoutService 查詢已完成的訓練記錄
      final records = await _workoutService.getUserRecords();

      print('[HomePage] 查詢到 ${records.length} 個已完成的訓練');

      // 轉換為 Map 格式（為了相容現有 UI）
      final recentWorkouts = records.take(5).map((record) {
        return {
          'id': record.id,
          'title': record.title, // 使用實際的訓練標題
          'completedDate': record.date,
          'exercises': record.exerciseRecords
              .map((e) => {
                    'exerciseName': e.exerciseName,
                    'sets': e.sets.length,
                    'completed': e.completed, // 添加完成狀態
                  })
              .toList(),
          'completed': record.completed, // 添加整體完成狀態
          '_sortDate': record.date,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _recentWorkouts = recentWorkouts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      print('[HomePage] 載入最近訓練失敗: $e');
    }
  }

  // 載入今日訓練計畫
  Future<void> _loadTodayPlans() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPlans = true;
    });

    try {
      // 使用 AuthController 的當前用戶 UID（已經是 Supabase UUID）
      final userId = _authController.user?.uid;
      if (userId == null) {
        print('[HomePage] 用戶未登入');
        setState(() {
          _todayPlans = [];
          _isLoadingPlans = false;
        });
        return;
      }

      print('[HomePage] 查詢今日訓練計畫，userId: $userId');

      // 計算今天的日期範圍（00:00 到 23:59）
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // 使用 WorkoutService 查詢今天的訓練計畫（未完成的）
      final plans = await _workoutService.getUserPlans(
        completed: false,
        startDate: today,
        endDate: tomorrow,
      );

      print('[HomePage] 查詢到 ${plans.length} 個今日訓練計畫');

      // 轉換為 Map 格式（為了相容現有 UI）
      final todayPlans = plans.map((plan) {
        return {
          'id': plan.id,
          'title': plan.title,
          'scheduledDate': plan.date, // 使用 date 而不是 scheduledDate
          'exercises': plan.exerciseRecords
              .map((e) => {
                    'exerciseName': e.exerciseName,
                    'sets': e.sets.length,
                    'completed': e.completed, // 使用 completed 而不是 isCompleted
                  })
              .toList(),
          'completed': plan.completed,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _todayPlans = todayPlans;
        _isLoadingPlans = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingPlans = false;
      });
      print('[HomePage] 載入今日計畫失敗: $e');
    }
  }

  // 跳轉到訓練執行頁面
  Future<void> _navigateToPlan(String planId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutExecutionPage(
          workoutRecordId: planId,
        ),
      ),
    );

    if (result == true) {
      // 重新載入數據
      _loadTodayPlans();
      _loadRecentWorkouts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.user;
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final now = DateTime.now();
    final hour = now.hour;

    String greeting;
    if (hour < 12) {
      greeting = '早安';
    } else if (hour < 18) {
      greeting = '午安';
    } else {
      greeting = '晚安';
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadRecentWorkouts(),
            _loadTodayPlans(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            // SliverAppBar with gradient background
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: brightness == Brightness.light
                  ? colorScheme.primary // 淺色模式：藍色
                  : null, // 深色模式：使用預設深色背景
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Text(
                  'Strength Wise',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: brightness == Brightness.light
                          ? [
                              colorScheme.primary,
                              colorScheme.primary.withOpacity(0.8),
                            ]
                          : [
                              colorScheme.surface,
                              colorScheme.surface.withOpacity(0.95),
                            ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 56),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$greeting，${user?.displayName ?? user?.nickname ?? '健身愛好者'}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('yyyy年MM月dd日 EEEE', 'zh_TW').format(now),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                // 📊 訓練統計
                IconButton(
                  icon: const Icon(Icons.bar_chart, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsPageV2(),
                      ),
                    );
                  },
                  tooltip: '訓練統計',
                ),
                // 🔔 通知測試頁面
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationTestPage(),
                      ),
                    );
                  },
                  tooltip: '通知測試',
                ),
              ],
            ),
            // 今日訓練計畫
            SliverToBoxAdapter(
              child: _buildTodayPlans(),
            ),
            // 最近訓練記錄
            SliverToBoxAdapter(
              child: _buildRecentWorkouts(),
            ),
            // 底部填充，避免被底部導航遮擋
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 24),
            ),
          ],
        ),
      ),
    );
  }

  // 今日訓練計畫
  Widget _buildTodayPlans() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日訓練',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _isLoadingPlans
              ? _buildLoadingSkeleton() // ⚡ 使用骨架屏替代 Loading
              : _todayPlans.isEmpty
                  ? _buildNoPlansToday()
                  : Column(
                      children: _todayPlans
                          .map((plan) => _buildTodayPlanCard(plan))
                          .toList(),
                    ),
        ],
      ),
    );
  }

  /// ⚡ 骨架屏（Loading 狀態）
  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題骨架
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              // 內容骨架
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNoPlansToday() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '今天還沒有安排訓練',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500, // 加粗以提升可讀性
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPlanCard(Map<String, dynamic> plan) {
    final title = plan['title'] ?? '未命名訓練';
    final exercises = plan['exercises'] as List<dynamic>? ?? [];
    final completed = plan['completed'] as bool? ?? false;

    final exerciseCount = exercises.length;
    final completedCount =
        exercises.where((e) => e['completed'] == true).length;
    final progress = exerciseCount > 0 ? completedCount / exerciseCount : 0.0;

    // 計算時間顯示（暫時簡化）
    String timeInfo = '全天';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: completed ? 1 : 3,
      child: InkWell(
        onTap: () => _navigateToPlan(plan['id']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeInfo,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      completed ? '已完成' : '待完成',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$exerciseCount 個動作',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (exerciseCount > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '完成度: ${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentWorkouts() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近訓練',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? _buildLoadingSkeleton() // ⚡ 使用骨架屏替代 Loading
              : _recentWorkouts.isEmpty
                  ? _buildEmptyWorkouts()
                  : Column(
                      children: _recentWorkouts
                          .map((workout) => _buildWorkoutCard(workout))
                          .toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildEmptyWorkouts() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '還沒有訓練記錄',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '完成訓練後就能看到記錄了！',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    // 獲取日期（Supabase 已經是 DateTime，不需要轉換）
    DateTime date = DateTime.now();
    if (workout['completedDate'] is DateTime) {
      date = workout['completedDate'] as DateTime;
    } else if (workout['_sortDate'] is DateTime) {
      date = workout['_sortDate'] as DateTime;
    }

    final formattedDate = DateFormat('MM/dd').format(date);
    final title = workout['title'] ?? '未命名訓練';
    final exercises = workout['exercises'] as List<dynamic>? ?? [];
    final completed = workout['completed'] as bool? ?? true; // 已完成的訓練

    // 計算完成度
    final exerciseCount = exercises.length;
    final completedCount =
        exercises.where((e) => e['completed'] == true).length;
    final progress = exerciseCount > 0 ? completedCount / exerciseCount : 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // 導航到訓練記錄詳情頁面
          _navigateToPlan(workout['id']);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    completed ? Icons.check_circle : Icons.circle_outlined,
                    color: completed
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$exerciseCount 個動作',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '完成度: ${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
