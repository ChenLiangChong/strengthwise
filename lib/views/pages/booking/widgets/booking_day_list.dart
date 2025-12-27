import 'package:flutter/material.dart';
import 'booking_card.dart';
import 'training_plan_card.dart';
import 'empty_booking_state.dart';

/// 選定日期的活動列表元件
/// 
/// 顯示選定日期的所有訓練計劃和預約
class BookingDayList extends StatelessWidget {
  /// 選定日期的訓練計劃
  final List<Map<String, dynamic>> trainings;
  
  /// 選定日期的預約
  final List<Map<String, dynamic>> bookings;
  
  /// 當前用戶 ID
  final String? currentUserId;
  
  /// 是否為教練模式
  final bool isCoachMode;
  
  /// 執行訓練計劃回調
  final void Function(String planId)? onExecuteTraining;
  
  /// 編輯訓練計劃回調
  final void Function(String planId, DateTime scheduledDate)? onEditTraining;
  
  /// 刪除訓練計劃回調
  final void Function(String planId, String planTitle)? onDeleteTraining;
  
  /// 取消預約回調
  final void Function(String bookingId)? onCancelBooking;
  
  /// 確認預約回調
  final void Function(String bookingId)? onConfirmBooking;
  
  /// 查看預約詳情回調
  final VoidCallback? onViewBookingDetails;
  
  const BookingDayList({
    super.key,
    required this.trainings,
    required this.bookings,
    this.currentUserId,
    required this.isCoachMode,
    this.onExecuteTraining,
    this.onEditTraining,
    this.onDeleteTraining,
    this.onCancelBooking,
    this.onConfirmBooking,
    this.onViewBookingDetails,
  });

  @override
  Widget build(BuildContext context) {
    // 合併所有選定日期的數據
    final allItems = <Map<String, dynamic>>[
      ...trainings,
      ...bookings,
    ];
    
    // 沒有活動時顯示空狀態
    if (allItems.isEmpty) {
      return const EmptyBookingState(
        title: '今日沒有活動',
        subtitle: '點擊右下角按鈕創建訓練計劃',
        icon: Icons.calendar_today,
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: 96, // 增加底部填充，避免被 FAB 遮擋
      ),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        
        // 根據數據類型構建不同的卡片
        if (item.containsKey('status')) {
          // 預約卡片（有 status 字段）
          return BookingCard(
            booking: item,
            isUserMode: !isCoachMode,
            onCancel: onCancelBooking,
            onConfirm: onConfirmBooking,
            onViewDetails: onViewBookingDetails,
          );
        } else {
          // 訓練計劃卡片
          return TrainingPlanCard(
            training: item,
            currentUserId: currentUserId,
            onExecute: onExecuteTraining,
            onEdit: onEditTraining,
            onDelete: onDeleteTraining,
          );
        }
      },
    );
  }
}

