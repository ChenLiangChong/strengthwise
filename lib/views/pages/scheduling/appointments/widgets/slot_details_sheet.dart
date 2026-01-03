import 'package:flutter/material.dart';
import 'package:strengthwise/models/availability_slot_model.dart';

/// 時段詳情底部彈窗
/// 
/// 顯示時段的完整信息，並提供操作：
/// - 教練模式：刪除時段
/// - 學員模式：預約時段
class SlotDetailsSheet extends StatelessWidget {
  final AvailabilitySlotModel slot;
  final VoidCallback? onDelete; // 教練模式：刪除時段
  final VoidCallback? onBook;   // 學員模式：預約時段
  final bool isViewMode;        // 是否為查看模式（學員）

  const SlotDetailsSheet({
    super.key,
    required this.slot,
    this.onDelete,
    this.onBook,
    this.isViewMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Row(
            children: [
              Icon(
                slot.isRecurring ? Icons.repeat : Icons.event,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                slot.isRecurring ? '週期性時段' : '單次時段',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 時間
          _buildDetailRow(
            Icons.access_time,
            '時間',
            slot.getTimeRangeString(),
          ),

          // 重複規則（僅週期性時段）
          if (slot.recurrenceRule != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.repeat,
              '重複規則',
              slot.getRecurrenceDescription(),
            ),
          ],

          // 備註（如果有）
          if (slot.notes != null && slot.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildDetailRow(Icons.note, '備註', slot.notes!),
          ],

          const SizedBox(height: 24),

          // 操作按鈕
          Row(
            children: [
              // 學員模式：預約按鈕
              if (isViewMode && onBook != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onBook!();
                    },
                    icon: const Icon(Icons.event_available),
                    label: const Text('預約此時段'),
                  ),
                ),
              
              // 教練模式：刪除按鈕
              if (!isViewMode && onDelete != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete!();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('刪除'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // 關閉按鈕
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('關閉'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 建立詳情行
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

