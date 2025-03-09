import 'package:flutter/material.dart';
import '../../controllers/interfaces/i_auth_controller.dart';
import '../../controllers/interfaces/i_workout_controller.dart';
import 'package:intl/intl.dart';
import '../../services/error_handling_service.dart';
import '../../models/workout_record_model.dart';
import '../../services/service_locator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final IWorkoutController _workoutController;
  late final ErrorHandlingService _errorService;
  late final IAuthController _authController;
  
  List<WorkoutRecord> _recentWorkouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _workoutController = serviceLocator<IWorkoutController>();
    _errorService = serviceLocator<ErrorHandlingService>();
    _authController = serviceLocator<IAuthController>();
    _loadRecentWorkouts();
  }

  Future<void> _loadRecentWorkouts() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final records = await _workoutController.loadUserRecords();
      
      if (!mounted) return;
      
      setState(() {
        _recentWorkouts = records.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      _errorService.handleLoadingError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strength Wise'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecentWorkouts,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用戶問候區域
              _buildUserGreeting(user?.displayName ?? user?.nickname),
              
              // 今日統計
              _buildDailyStats(),
              
              // 最近訓練記錄
              _buildRecentWorkouts(),
              
              // 快捷操作
              _buildQuickActions(),
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
  
  Widget _buildDailyStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日進度',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('今日消耗', '650', '卡路里', Icons.local_fire_department, Colors.orange),
              _buildStatCard('活動時間', '45', '分鐘', Icons.timer, Colors.blue),
              _buildStatCard('完成訓練', '1', '組', Icons.check_circle, Colors.green),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
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
          ElevatedButton(
            onPressed: () {
              // TODO: 導航到訓練頁面
            },
            child: const Text('開始訓練'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWorkoutCard(WorkoutRecord workout) {
    final date = workout.date;
    final formattedDate = DateFormat('MM/dd').format(date);
    final exerciseCount = workout.exerciseRecords.length;
    final completedCount = workout.exerciseRecords.where((e) => e.completed).length;
    final progress = exerciseCount > 0 ? completedCount / exerciseCount : 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: 導航到訓練記錄詳情頁面
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
                      workout.notes.isNotEmpty ? workout.notes : '未命名訓練',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    workout.completed ? Icons.check_circle : Icons.circle_outlined,
                    color: workout.completed ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${workout.exerciseRecords.length} 個動作',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
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
  
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快捷操作',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                '開始訓練',
                Icons.fitness_center,
                Colors.green,
                () {
                  // TODO: 導航到訓練頁面
                },
              ),
              _buildActionButton(
                '查看數據',
                Icons.bar_chart,
                Colors.blue,
                () {
                  // TODO: 導航到數據頁面
                },
              ),
              _buildActionButton(
                '訓練計畫',
                Icons.calendar_today,
                Colors.orange,
                () {
                  // TODO: 導航到訓練計畫頁面
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 