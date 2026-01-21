import 'package:flutter/material.dart';
import 'package:strengthwise/services/interfaces/i_availability_slot_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';

/// 時段列表視圖組件
class SlotListView extends StatelessWidget {
  final DateTime selectedDay;
  final List<AvailabilitySlotWithBooking> availableSlots;
  final Function(AvailabilitySlotWithBooking) onSlotTapped;

  const SlotListView({
    super.key,
    required this.selectedDay,
    required this.availableSlots,
    required this.onSlotTapped,
  });

  @override
  Widget build(BuildContext context) {
    final slotsForDay = _getSlotsForDay();

    if (slotsForDay.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: slotsForDay.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final slot = slotsForDay[index];
        return _buildSlotCard(context, slot);
      },
    );
  }

  List<AvailabilitySlotWithBooking> _getSlotsForDay() {
    return availableSlots.where((slot) {
      final slotDate = DateTime(
        slot.slot.startTime.year,
        slot.slot.startTime.month,
        slot.slot.startTime.day,
      );
      final checkDate = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
      );
      return slotDate == checkDate;
    }).toList()
      ..sort((a, b) => a.slot.startTime.compareTo(b.slot.startTime));
  }

  Widget _buildSlotCard(BuildContext context, AvailabilitySlotWithBooking slot) {
    final colorScheme = Theme.of(context).colorScheme;
    final authController = serviceLocator<IAuthController>();
    final currentUserId = authController.user?.uid;
    
    // ⭐ 判斷是否為自己的預約
    final isMyBooking = slot.isBooked && slot.bookedByClientId == currentUserId;
    // ⭐ 判斷是否被他人預約
    final isBookedByOthers = slot.isBooked && slot.bookedByClientId != currentUserId;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: slot.isBooked ? null : () => onSlotTapped(slot),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 時間顯示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isBookedByOthers
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                      : isMyBooking
                          ? colorScheme.primaryContainer.withValues(alpha: 0.7)
                          : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _formatTime(slot.slot.startTime),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isBookedByOthers 
                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                            : isMyBooking
                                ? colorScheme.primary
                                : colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${slot.slot.durationMinutes} 分鐘',
                      style: TextStyle(
                        fontSize: 12,
                        color: isBookedByOthers 
                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                            : isMyBooking
                                ? colorScheme.primary.withValues(alpha: 0.8)
                                : colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // 狀態資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.slot.displayTimeRange,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isBookedByOthers 
                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                            : isMyBooking
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // ⭐ 第二行：狀態標籤或備註
                    if (isMyBooking)
                      // 自己的預約：使用主題色 + 成功圖示
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '已預約',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      )
                    else if (isBookedByOthers)
                      // 他人的預約：使用錯誤色 + 鎖定圖示
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: colorScheme.error.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '已被他人預約',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.error.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      )
                    else if (slot.slot.notes != null && slot.slot.notes!.isNotEmpty)
                      Text(
                        slot.slot.notes!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // 右側圖示
              Icon(
                isMyBooking 
                    ? Icons.event_available
                    : isBookedByOthers 
                        ? Icons.block 
                        : Icons.chevron_right,
                color: isMyBooking
                    ? colorScheme.primary
                    : isBookedByOthers 
                        ? colorScheme.error.withValues(alpha: 0.6)
                        : colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '此日期無可預約時段',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '請選擇其他日期',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

