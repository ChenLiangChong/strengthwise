// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/appointment_model.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 空狀態組件
class EmptyAppointmentsState extends StatelessWidget {
  final bool isCoachMode;
  final AppointmentStatus? selectedStatus;

  const EmptyAppointmentsState({
    super.key,
    required this.isCoachMode,
    this.selectedStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIcon(),
            size: 80.scaled(context), // ⭐ 響應式圖標
            color: colorScheme.outline,
          ),
          SizedBox(height: context.spacing.lg), // ⭐ 響應式間距
          Text(
            _getTitle(),
            style: context.responsive.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ), // ⭐ 響應式文字
          ),
          SizedBox(height: context.spacing.sm), // ⭐ 響應式間距
          Text(
            _getSubtitle(),
            style: context.responsive.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ), // ⭐ 響應式文字
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    if (selectedStatus == AppointmentStatus.requested) {
      return Icons.schedule_outlined;
    } else if (selectedStatus == AppointmentStatus.completed) {
      return Icons.check_circle_outline;
    } else if (selectedStatus == AppointmentStatus.cancelled) {
      return Icons.cancel_outlined;
    }
    return Icons.event_busy_outlined;
  }

  String _getTitle() {
    if (selectedStatus != null) {
      return '無 ${selectedStatus!.displayName} 的預約';
    }
    return '尚無預約記錄';
  }

  String _getSubtitle() {
    if (isCoachMode) {
      if (selectedStatus == AppointmentStatus.requested) {
        return '目前沒有待確認的預約';
      }
      return '您還沒有任何預約\n等待學員預約您的課程';
    } else {
      if (selectedStatus == AppointmentStatus.requested) {
        return '您沒有待確認的預約';
      }
      return '您還沒有預約任何課程\n前往「預約教練」建立預約';
    }
  }
}
