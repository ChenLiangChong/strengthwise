import 'package:flutter/material.dart';

/// 訓練計劃卡片元件
/// 
/// 顯示訓練計劃的詳細資訊，包括：
/// - 計劃標題
/// - 計劃類型（自主訓練、教練計劃）
/// - 完成狀態
/// - 訓練時間
/// - 動作數量
/// - 訓練進度
/// - 操作按鈕（編輯、刪除、開始訓練）
class TrainingPlanCard extends StatelessWidget {
  /// 訓練計劃資料
  final Map<String, dynamic> training;
  
  /// 當前用戶 ID
  final String? currentUserId;
  
  /// 執行訓練計劃回調
  final void Function(String planId)? onExecute;
  
  /// 編輯訓練計劃回調
  final void Function(String planId, DateTime scheduledDate)? onEdit;
  
  /// 刪除訓練計劃回調
  final void Function(String planId, String planTitle)? onDelete;
  
  const TrainingPlanCard({
    super.key,
    required this.training,
    this.currentUserId,
    this.onExecute,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final planId = training['id'] as String;
    final title = training['title'] ?? '未命名訓練';
    final description = training['description'] ?? '';
    final planType = training['planType'] as String? ?? 'self';
    final exercises = training['exercises'] as List<dynamic>? ?? [];
    final completed = training['completed'] as bool? ?? false;
    final isCoachView = training['isCoachView'] as bool? ?? false;
    
    // 訓練計劃創建者和受訓者資訊
    final traineeId = training['trainee_id'] as String?;
    final creatorId = training['creator_id'] as String?;
    
    // 判斷訓練計劃是否為過去的
    final scheduledDate = _parseScheduledDate(training['scheduled_date']);
    final isPastPlan = _isPastDate(scheduledDate);
    final timeInfo = _formatTimeInfo(scheduledDate);
    
    // 根據完成狀態和計劃類型設置顏色和文字
    final typeInfo = _getTypeInfo(context, completed, planType);
    
    // 計算進度
    final progressInfo = _calculateProgress(exercises);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: InkWell(
        onTap: onExecute != null ? () => onExecute!(planId) : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題和類型標籤
              _buildHeader(context, title, typeInfo, isPastPlan, completed, planId, scheduledDate),
              
              // 描述
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 8),
              
              // 時間資訊
              _buildInfoRow(
                context,
                Icons.access_time,
                timeInfo,
              ),
              
              const SizedBox(height: 4),
              
              // 動作數量
              _buildInfoRow(
                context,
                Icons.fitness_center,
                '${exercises.length} 個動作',
              ),
              
              // 教練/學員資訊
              if (planType == 'trainer' && !isCoachView && currentUserId == traineeId) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  context,
                  Icons.person,
                  '教練安排的計劃',
                ),
              ],
              
              if (isCoachView && currentUserId == creatorId) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  context,
                  Icons.person,
                  '已分配給學員',
                ),
              ],
              
              // 進度條
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressInfo.progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                  completed 
                      ? Theme.of(context).colorScheme.secondary 
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              
              // 完成狀態和操作按鈕
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    completed 
                        ? '已完成' 
                        : '進行中: ${progressInfo.completed}/${progressInfo.total}',
                    style: TextStyle(
                      color: completed 
                          ? Theme.of(context).colorScheme.secondary 
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onExecute != null)
                    OutlinedButton(
                      onPressed: () => onExecute!(planId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: typeInfo.color,
                      ),
                      child: Text(completed ? '查看訓練' : '開始訓練'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 構建標題列（包含標題、類型標籤、編輯和刪除按鈕）
  Widget _buildHeader(
    BuildContext context,
    String title,
    _TypeInfo typeInfo,
    bool isPastPlan,
    bool completed,
    String planId,
    DateTime? scheduledDate,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        
        // 類型標籤
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: typeInfo.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            typeInfo.text,
            style: TextStyle(
              color: typeInfo.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        
        // 編輯按鈕（過去的訓練計劃不能編輯）
        if (!isPastPlan && !completed && onEdit != null && scheduledDate != null)
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () => onEdit!(planId, scheduledDate),
            tooltip: '編輯訓練計畫',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        
        // 刪除按鈕（過去的訓練計劃不能刪除）
        if (!isPastPlan && onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.red,
            onPressed: () => onDelete!(planId, title),
            tooltip: '刪除訓練計畫',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
  
  /// 構建資訊列（圖示 + 文字）
  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  /// 解析排程日期
  DateTime? _parseScheduledDate(dynamic scheduledDateData) {
    if (scheduledDateData == null) return null;
    
    try {
      return DateTime.parse(scheduledDateData);
    } catch (e) {
      return null;
    }
  }
  
  /// 判斷是否為過去的日期
  bool _isPastDate(DateTime? date) {
    if (date == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planDate = DateTime(date.year, date.month, date.day);
    
    return planDate.isBefore(today);
  }
  
  /// 格式化時間資訊
  String _formatTimeInfo(DateTime? scheduledDate) {
    if (scheduledDate == null) return '全天';
    
    // 只顯示時間部分，如果有
    if (scheduledDate.hour != 0 || scheduledDate.minute != 0) {
      return '${scheduledDate.hour.toString().padLeft(2, '0')}:'
          '${scheduledDate.minute.toString().padLeft(2, '0')}';
    }
    
    return '全天';
  }
  
  /// 獲取類型資訊（顏色和文字）
  _TypeInfo _getTypeInfo(BuildContext context, bool completed, String planType) {
    if (completed) {
      // 已完成的訓練顯示 Secondary 色「已完成」標籤
      return _TypeInfo(
        Theme.of(context).colorScheme.secondary,
        '已完成',
      );
    } else {
      // 未完成的訓練根據類型顯示
      final color = planType == 'self' 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).colorScheme.tertiary;
      final text = planType == 'self' ? '自主訓練' : '教練計劃';
      
      return _TypeInfo(color, text);
    }
  }
  
  /// 計算訓練進度
  _ProgressInfo _calculateProgress(List<dynamic> exercises) {
    final total = exercises.length;
    final completed = exercises.where((e) => e['completed'] == true).length;
    final progress = total > 0 ? completed / total : 0.0;
    
    return _ProgressInfo(total, completed, progress);
  }
}

/// 類型資訊（私有類別）
class _TypeInfo {
  final Color color;
  final String text;
  
  _TypeInfo(this.color, this.text);
}

/// 進度資訊（私有類別）
class _ProgressInfo {
  final int total;
  final int completed;
  final double progress;
  
  _ProgressInfo(this.total, this.completed, this.progress);
}

