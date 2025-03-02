import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'workout/workout_execution_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _todayWorkoutPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayWorkoutPlans();
  }

  // 獲取當天訓練計畫
  Future<void> _loadTodayWorkoutPlans() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final now = DateTime.now();
      print('當前時間: $now'); // 輸出當前時間以便調試
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      print('查詢範圍: ${today.toIso8601String()} 到 ${tomorrow.toIso8601String()}');
      
      // 由於可能有模擬器時間問題，先嘗試直接查詢所有計畫
      final querySnapshot = await FirebaseFirestore.instance
          .collection('workoutPlans')
          .where('userId', isEqualTo: userId)
          .get();
      
      print('找到 ${querySnapshot.docs.length} 個訓練計畫');
      
      // 在本地過濾日期，避開 Firestore 索引問題
      final filteredDocs = querySnapshot.docs.where((doc) {
        final timestamp = doc.data()['scheduledDate'] as Timestamp?;
        final completed = doc.data()['completed'] as bool? ?? false;
        
        if (timestamp == null) return false;
        
        final date = timestamp.toDate();
        print('計畫日期: ${date.toIso8601String()}, 完成狀態: $completed');
        
        // 檢查日期是否是今天
        final planDate = DateTime(date.year, date.month, date.day);
        final todayDate = DateTime(today.year, today.month, today.day);
        
        return planDate.isAtSameMomentAs(todayDate) && !completed;
      }).toList();
      
      print('過濾後剩餘 ${filteredDocs.length} 個今日訓練計畫');
      
      setState(() {
        _todayWorkoutPlans = filteredDocs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('加載今日訓練計畫失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 開始訓練
  Future<void> _startWorkout(String planId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutExecutionPage(
          workoutPlanId: planId,
        ),
      ),
    );
    
    if (result == true) {
      // 訓練完成後重新加載計畫
      await _loadTodayWorkoutPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy年MM月dd日').format(now);
    final weekday = _getWeekdayInChinese(now.weekday);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '歡迎回來',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$formattedDate ($weekday)',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            
            // 今日訓練計畫標題
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '今日訓練計畫',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () {
                    // 導航到訓練行事曆頁面
                    Navigator.of(context).pushNamed('/booking');
                  },
                  child: const Text(
                    '查看全部',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 今日訓練計畫列表
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _todayWorkoutPlans.isEmpty
                    ? _buildEmptyPlanCard()
                    : Column(
                        children: _todayWorkoutPlans
                            .map((plan) => _buildWorkoutPlanCard(plan))
                            .toList(),
                      ),
            
            const SizedBox(height: 20),
            
            // 其他信息卡片
            Expanded(
              child: ListView(
                children: [
                  _buildInfoCard(
                    title: '訓練統計',
                    content: '本週已完成 3/5 次訓練',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                  _buildInfoCard(
                    title: '下個訓練目標',
                    content: '增加上肢力量 5%',
                    icon: Icons.fitness_center,
                    color: Colors.orange,
                  ),
                  _buildInfoCard(
                    title: '健康提醒',
                    content: '記得補充水分和蛋白質',
                    icon: Icons.health_and_safety,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 沒有訓練計畫的卡片
  Widget _buildEmptyPlanCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            const Text(
              '今天沒有訓練計畫',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '為自己制定一個訓練計畫吧',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // 導航到訓練行事曆頁面
                Navigator.of(context).pushNamed('/booking');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('創建訓練計畫'),
            ),
          ],
        ),
      ),
    );
  }

  // 訓練計畫卡片
  Widget _buildWorkoutPlanCard(Map<String, dynamic> plan) {
    final title = plan['title'] ?? '未命名訓練';
    final type = plan['planType'] ?? '';
    final exercisesCount = (plan['exercises'] as List?)?.length ?? 0;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _startWorkout(plan['id']),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 訓練類型圖標
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 訓練計畫信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '類型: $type',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '包含 $exercisesCount 個訓練動作',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 開始訓練按鈕
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _startWorkout(plan['id']),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('開始訓練'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 輔助方法：獲取中文星期
  String _getWeekdayInChinese(int weekday) {
    switch (weekday) {
      case 1:
        return '星期一';
      case 2:
        return '星期二';
      case 3:
        return '星期三';
      case 4:
        return '星期四';
      case 5:
        return '星期五';
      case 6:
        return '星期六';
      case 7:
        return '星期日';
      default:
        return '';
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 25,
              child: Icon(
                icon,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
} 