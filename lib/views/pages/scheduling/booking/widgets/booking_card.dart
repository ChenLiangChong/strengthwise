import 'package:flutter/material.dart';

/// 預約卡片元件
/// 
/// 顯示預約的詳細資訊，包括：
/// - 課程名稱
/// - 預約狀態（待確認、已確認、已取消、已完成）
/// - 預約時間
/// - 教練/學生資訊
/// - 操作按鈕（取消、確認、查看詳情）
class BookingCard extends StatelessWidget {
  /// 預約資料
  final Map<String, dynamic> booking;
  
  /// 是否為用戶模式（非教練模式）
  final bool isUserMode;
  
  /// 取消預約回調
  final void Function(String bookingId)? onCancel;
  
  /// 確認預約回調
  final void Function(String bookingId)? onConfirm;
  
  /// 查看詳情回調
  final VoidCallback? onViewDetails;
  
  const BookingCard({
    super.key,
    required this.booking,
    required this.isUserMode,
    this.onCancel,
    this.onConfirm,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final bookingId = booking['id'] ?? '';
    final status = booking['status'] ?? 'pending';
    final dateTime = booking['dateTime'];
    final coachName = booking['coachName'] ?? '未知教練';
    final userName = booking['userName'] ?? '未知用戶';
    final course = booking['course'] ?? '個人訓練';
    
    // 格式化日期時間
    String formattedDateTime = '未知時間';
    if (dateTime != null) {
      final date = dateTime.toDate();
      formattedDateTime = '${date.year}/${date.month}/${date.day} '
          '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    // 狀態顏色和文字
    final statusInfo = _getStatusInfo(status);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 課程名稱和狀態標籤
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    course,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusInfo.text,
                    style: TextStyle(
                      color: statusInfo.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 預約時間
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDateTime,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // 教練/學生資訊
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  isUserMode ? '教練: $coachName' : '學生: $userName',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 操作按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 用戶模式：取消預約按鈕
                if (status == 'pending' && isUserMode && onCancel != null)
                  TextButton(
                    onPressed: () => onCancel!(bookingId),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('取消預約'),
                  ),
                
                // 教練模式：確認預約按鈕
                if (status == 'pending' && !isUserMode && onConfirm != null)
                  TextButton(
                    onPressed: () => onConfirm!(bookingId),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    child: const Text('確認預約'),
                  ),
                
                // 已確認：查看詳情按鈕
                if (status == 'confirmed' && onViewDetails != null)
                  OutlinedButton(
                    onPressed: onViewDetails,
                    child: const Text('查看詳情'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 獲取狀態資訊（顏色和文字）
  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return _StatusInfo(Colors.green, '已確認');
      case 'cancelled':
        return _StatusInfo(Colors.red, '已取消');
      case 'completed':
        return _StatusInfo(Colors.blue, '已完成');
      default:
        return _StatusInfo(Colors.orange, '待確認');
    }
  }
}

/// 狀態資訊（私有類別）
class _StatusInfo {
  final Color color;
  final String text;
  
  _StatusInfo(this.color, this.text);
}

