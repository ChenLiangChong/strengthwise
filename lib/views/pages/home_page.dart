import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/interfaces/i_auth_controller.dart';
import '../../controllers/interfaces/i_workout_controller.dart';
import 'package:intl/intl.dart';
import '../../services/error_handling_service.dart';
import '../../services/service_locator.dart';
import 'workout/workout_execution_page.dart';
import 'statistics_page_v2.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final IWorkoutController _workoutController;
  late final ErrorHandlingService _errorService;
  late final IAuthController _authController;

  List<Map<String, dynamic>> _recentWorkouts = [];
  List<Map<String, dynamic>> _todayPlans = [];
  bool _isLoading = true;
  bool _isLoadingPlans = true;

  @override
  void initState() {
    super.initState();
    _workoutController = serviceLocator<IWorkoutController>();
    _errorService = serviceLocator<ErrorHandlingService>();
    _authController = serviceLocator<IAuthController>();
    _loadRecentWorkouts();
    _loadTodayPlans();
  }

  Future<void> _loadRecentWorkouts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('[HomePage] 查詢最近訓練，userId: $userId');

      // 從 workoutPlans 集合查詢已完成的訓練
      final List<Map<String, dynamic>> allCompletedPlans = [];

      // 查詢作為受訓者完成的計畫
      final traineeCompletedSnapshot = await FirebaseFirestore.instance
          .collection('workoutPlans')
          .where('traineeId', isEqualTo: userId)
          .where('completed', isEqualTo: true)
          .get();

      print(
          '[HomePage] 查詢到 ${traineeCompletedSnapshot.docs.length} 個作為受訓者完成的訓練');

      for (var doc in traineeCompletedSnapshot.docs) {
        final data = {...doc.data(), 'id': doc.id};
        allCompletedPlans.add(data);
      }

      // 如果是教練，也查詢作為創建者完成的計畫
      if (_authController.user?.isCoach == true) {
        final creatorCompletedSnapshot = await FirebaseFirestore.instance
            .collection('workoutPlans')
            .where('creatorId', isEqualTo: userId)
            .where('completed', isEqualTo: true)
            .get();

        print(
            '[HomePage] 查詢到 ${creatorCompletedSnapshot.docs.length} 個作為創建者完成的訓練');

        for (var doc in creatorCompletedSnapshot.docs) {
          final data = {...doc.data(), 'id': doc.id};
          // 避免重複添加
          if (!allCompletedPlans.any((plan) => plan['id'] == data['id'])) {
            allCompletedPlans.add(data);
          }
        }
      }

      if (!mounted) return;

      print('[HomePage] 查詢到總共 ${allCompletedPlans.length} 個已完成的訓練');

      // 直接使用 Map 格式
      final records = <Map<String, dynamic>>[];
      for (var data in allCompletedPlans) {
        try {
          // data 已經包含 id，不需要再處理

          // 添加日期用於排序
          DateTime? date;
          if (data['completedDate'] != null) {
            date = (data['completedDate'] as Timestamp).toDate();
          } else if (data['scheduledDate'] != null) {
            date = (data['scheduledDate'] as Timestamp).toDate();
          } else {
            date = DateTime.now();
          }
          data['_sortDate'] = date; // 用於排序的內部欄位

          records.add(data);
          print('[HomePage] ✓ 加入訓練記錄: ${data['title']}, 日期: $date');
        } catch (e) {
          print('[HomePage] 解析訓練記錄失敗: $e');
        }
      }

      // 按日期排序（最新的在前）
      records.sort((a, b) {
        final dateA = a['_sortDate'] as DateTime;
        final dateB = b['_sortDate'] as DateTime;
        return dateB.compareTo(dateA);
      });

      print('[HomePage] 最近訓練數量: ${records.length}');

      setState(() {
        _recentWorkouts = records.take(5).toList();
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
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('[HomePage] userId 為空，無法查詢');
        setState(() {
          _isLoadingPlans = false;
        });
        return;
      }

      // 獲取今天的開始和結束時間
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      print('[HomePage] 查詢今日訓練計畫，userId: $userId, 日期: $todayStart');

      // 查詢所有該用戶的訓練計畫（使用 traineeId 欄位）
      final snapshot = await FirebaseFirestore.instance
          .collection('workoutPlans')
          .where('traineeId', isEqualTo: userId)
          .get();

      if (!mounted) return;

      print('[HomePage] 查詢到 ${snapshot.docs.length} 個訓練計畫');

      final plans = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();

        // 檢查是否是今天的計畫
        if (data['scheduledDate'] != null) {
          final scheduledDate = (data['scheduledDate'] as Timestamp).toDate();
          final planDay = DateTime(
              scheduledDate.year, scheduledDate.month, scheduledDate.day);

          print(
              '[HomePage] 計畫 ${doc.id}: title=${data['title']}, scheduledDate=$scheduledDate, planDay=$planDay');

          if (planDay == todayStart) {
            data['id'] = doc.id;
            plans.add(data);
            print('[HomePage] ✓ 加入今日計畫: ${data['title']}');
          }
        } else {
          print('[HomePage] 計畫 ${doc.id} 沒有 scheduledDate');
        }
      }

      print('[HomePage] 今日訓練計畫數量: ${plans.length}');

      setState(() {
        _todayPlans = plans;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strength Wise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadRecentWorkouts(),
            _loadTodayPlans(),
          ]);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用戶問候區域
              _buildUserGreeting(user?.displayName ?? user?.nickname),

              // 今日訓練計畫
              _buildTodayPlans(),

              // 最近訓練記錄
              _buildRecentWorkouts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserGreeting(String? userName) {
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[400]!, Colors.green[700]!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$greeting，${userName ?? '健身愛好者'}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat('yyyy年MM月dd日 EEEE', 'zh_TW').format(now),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
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
              ? const Center(child: CircularProgressIndicator())
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

  Widget _buildNoPlansToday() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '今天還沒有安排訓練',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
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

    // 計算時間顯示
    String timeInfo = '全天';
    if (plan['scheduledDate'] != null) {
      final timestamp = plan['scheduledDate'] as Timestamp;
      final time = timestamp.toDate();
      if (time.hour != 0 || time.minute != 0) {
        timeInfo =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
    }

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
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeInfo,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: completed
                          ? Colors.purple.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      completed ? '已完成' : '待完成',
                      style: TextStyle(
                        color: completed ? Colors.purple : Colors.green,
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
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (exerciseCount > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completed ? Colors.purple : Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '完成度: ${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
              ? const Center(child: CircularProgressIndicator())
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '還沒有訓練記錄',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '完成訓練後就能看到記錄了！',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    // 獲取日期
    DateTime date = DateTime.now();
    if (workout['completedDate'] != null) {
      date = (workout['completedDate'] as Timestamp).toDate();
    } else if (workout['scheduledDate'] != null) {
      date = (workout['scheduledDate'] as Timestamp).toDate();
    } else if (workout['_sortDate'] != null) {
      date = workout['_sortDate'] as DateTime;
    }

    final formattedDate = DateFormat('MM/dd').format(date);
    final title = workout['title'] ?? '未命名訓練';
    final exercises = workout['exercises'] as List<dynamic>? ?? [];
    final completed = workout['completed'] as bool? ?? false;

    // 計算完成度
    final exerciseCount = exercises.length;
    final completedCount =
        exercises.where((e) => e['completed'] == true).length;
    final progress = exerciseCount > 0 ? completedCount / exerciseCount : 0.0;

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
                      color: Colors.grey[700],
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
                    color: completed ? Colors.purple : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$exerciseCount 個動作',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
              const SizedBox(height: 4),
              Text(
                '完成度: ${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
