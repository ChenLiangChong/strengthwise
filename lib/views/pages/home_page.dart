import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'workout/workout_execution_page.dart';
import 'booking_page.dart';
import 'workout/plan_editor_page.dart';

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
    _loadTodaysWorkouts();
  }

  // 獲取當天訓練計畫
  Future<void> _loadTodaysWorkouts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('用戶未登入');
      }

      // 獲取今天的日期範圍 - 使用更寬鬆的時間範圍
      final now = DateTime.now();
      print('原始當前時間: $now');

      // 首先嘗試不使用日期範圍查詢，避免時區問題
      final querySnapshot = await FirebaseFirestore.instance
          .collection('workoutRecords')
          .where('userId', isEqualTo: userId)
          .get();

      print('找到總共 ${querySnapshot.docs.length} 個訓練記錄');
      
      // 在本地過濾今天的記錄
      final todayRecords = <Map<String, dynamic>>[];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final recordDate = (data['date'] as Timestamp).toDate();
        
        // 調試信息
        print('記錄日期: ${recordDate}, 時間戳: ${data['date']}');
        
        // 檢查是否是今天的記錄（忽略時間部分）
        final recordDay = DateTime(recordDate.year, recordDate.month, recordDate.day);
        final today = DateTime(now.year, now.month, now.day);
        
        if (recordDay.isAtSameMomentAs(today)) {
          print('找到今天的記錄: ${doc.id}');
          todayRecords.add({...data, 'id': doc.id});
        }
      }

      setState(() {
        _todayWorkoutPlans = todayRecords;
        _isLoading = false;
      });

      print('過濾後今日訓練數量: ${_todayWorkoutPlans.length}');
    } catch (e) {
      print('載入今日訓練失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 開始訓練
  Future<void> _startWorkout(String recordId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutExecutionPage(
          workoutRecordId: recordId,
        ),
      ),
    );
    
    if (result == true) {
      // 訓練完成後重新加載計畫
      await _loadTodaysWorkouts();
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
                  onTap: () async {
                    // 導航到訓練行事曆頁面
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BookingPage(),
                      ),
                    );
                    
                    // 返回後重新加載數據
                    await _loadTodaysWorkouts();
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
                            .map((plan) => _buildWorkoutCard(plan))
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
    // 獲取當天日期
    final today = DateTime.now();
    
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
              onPressed: () async {
                // 直接導航到訓練計畫編輯頁面並傳入當天日期
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlanEditorPage(
                      selectedDate: today,
                    ),
                  ),
                );
                
                // 無論結果如何，返回後都重新加載今日訓練數據
                await _loadTodaysWorkouts();
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
  Widget _buildWorkoutCard(Map<String, dynamic> record) {
    final title = record['title'] ?? '未命名訓練';
    final type = record['planType'] ?? '';
    final exercisesCount = (record['exercises'] as List?)?.length ?? 0;
    final isCompleted = record['completed'] ?? false;
    
    // 處理訓練時間顯示邏輯
    String trainingTimeDisplay = '';
    if (record['trainingTime'] != null) {
      // 新格式：DateTime 類型
      final trainingTime = (record['trainingTime'] as Timestamp).toDate();
      trainingTimeDisplay = DateFormat('HH:mm').format(trainingTime);
    } else if (record['trainingHour'] != null) {
      // 舊格式：int 類型
      final hour = record['trainingHour'] as int;
      trainingTimeDisplay = '${hour.toString().padLeft(2, '0')}:00';
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _startWorkout(record['id']),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
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
                        if (trainingTimeDisplay.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '訓練時間: $trainingTimeDisplay',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
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
                  onPressed: () => _startWorkout(record['id']),
                  icon: Icon(
                    isCompleted ? Icons.visibility : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  label: Text(
                    isCompleted ? '查看詳情' : '開始訓練',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? Colors.blue : Colors.green,
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