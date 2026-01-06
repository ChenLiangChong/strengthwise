// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/appointment_model.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 預約卡片組件
class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isCoachMode;
  final VoidCallback onTap;
  final Function(String) onQuickAction;

  /// 開始課程回調（Session Mode 入口 - 教練）⭐ v3.0
  final VoidCallback? onStartSession;

  /// 查看課程回調（Session Mode 入口 - 學員）⭐ v3.1
  final VoidCallback? onViewSession;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.isCoachMode,
    required this.onTap,
    required this.onQuickAction,
    this.onStartSession,
    this.onViewSession,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0, // ⭐ 移除陰影
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md), // ⭐ 響應式內距
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題列（日期 + 狀態）
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 20.scaled(context), // ⭐ 響應式圖標
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: context.spacing.sm), // ⭐ 響應式間距
                  Expanded(
                    child: Text(
                      _formatDate(appointment.startTime),
                      style: context.responsive.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ), // ⭐ 響應式文字
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),

              SizedBox(height: context.spacing.md), // ⭐ 響應式間距

              // 時間範圍（使用 Wrap 防止大字體溢出）
              Wrap(
                spacing: context.spacing.sm,
                runSpacing: context.spacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18.scaled(context),
                        color: colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: context.spacing.xs),
                      Text(
                        _formatTimeRange(),
                        style: context.responsive.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${appointment.durationMinutes} 分鐘',
                    style: context.responsive.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // 備註（如果有）
              if (appointment.notes != null) ...[
                SizedBox(height: context.spacing.sm), // ⭐ 響應式間距
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 18.scaled(context), // ⭐ 響應式圖標
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: context.spacing.sm), // ⭐ 響應式間距
                    Expanded(
                      child: Text(
                        appointment.notes!,
                        style: context.responsive.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ), // ⭐ 響應式文字
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // 快速操作按鈕
              if (_shouldShowQuickActions()) ...[
                SizedBox(height: context.spacing.md), // ⭐ 響應式間距
                const Divider(height: 1),
                SizedBox(height: context.spacing.sm), // ⭐ 響應式間距
                _buildQuickActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final color = _getStatusColor();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md, // ⭐ 響應式內距
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        appointment.status.displayName,
        style: context.responsive.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ), // ⭐ 響應式文字
      ),
    );
  }

  bool _shouldShowQuickActions() {
    if (isCoachMode) {
      // 教練：待確認時顯示確認/拒絕按鈕，已確認時顯示取消按鈕
      return appointment.status == AppointmentStatus.requested ||
          appointment.status == AppointmentStatus.confirmed;
    } else {
      // 學員：待確認或已確認時顯示取消按鈕
      return appointment.status == AppointmentStatus.requested ||
          appointment.status == AppointmentStatus.confirmed;
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    if (isCoachMode && appointment.status == AppointmentStatus.requested) {
      // 教練：待確認時 - 確認/拒絕
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: context.spacing.sm,
        runSpacing: context.spacing.xs,
        children: [
          TextButton.icon(
            onPressed: () => onQuickAction('reject'),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('拒絕'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
          FilledButton.icon(
            onPressed: () => onQuickAction('confirm'),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('確認'),
          ),
        ],
      );
    } else if (isCoachMode && appointment.status == AppointmentStatus.confirmed) {
      // 教練：已確認時 - 開始課程 / 查看課程 / 取消
      final canStart = _canStartSession();
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: context.spacing.sm,
        runSpacing: context.spacing.xs,
        children: [
          TextButton.icon(
            onPressed: () => onQuickAction('cancel'),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('取消'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
          // ⭐ v3.1: 教練隨時可進入 Session Mode
          if (onStartSession != null)
            FilledButton.icon(
              onPressed: onStartSession,
              icon: Icon(canStart ? Icons.play_arrow : Icons.visibility, size: 18),
              label: Text(canStart ? '開始課程' : '查看課程'),
            ),
        ],
      );
    } else {
      // 學員：取消 / 查看課程
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: context.spacing.sm,
        runSpacing: context.spacing.xs,
        children: [
          TextButton.icon(
            onPressed: () => onQuickAction('cancel'),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('取消預約'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
          // ⭐ v3.1: 學員已確認時顯示「查看課程」按鈕
          if (appointment.status == AppointmentStatus.confirmed && onViewSession != null)
            FilledButton.icon(
              onPressed: onViewSession,
              icon: const Icon(Icons.fitness_center, size: 18),
              label: const Text('查看課程'),
            ),
        ],
      );
    }
  }

  /// 判斷是否可以開始課程（課程開始前 15 分鐘到結束後 4 小時）⭐ v3.0
  bool _canStartSession() {
    final now = DateTime.now();
    final startBuffer = appointment.startTime.subtract(const Duration(minutes: 15));
    final endBuffer = appointment.endTime.add(const Duration(hours: 4));
    return now.isAfter(startBuffer) && now.isBefore(endBuffer);
  }

  Color _getStatusColor() {
    switch (appointment.status) {
      case AppointmentStatus.requested:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final weekday = _getWeekdayName(date.weekday);
    return '$year-$month-$day ($weekday)';
  }

  String _formatTimeRange() {
    final start = _formatTime(appointment.startTime);
    final end = _formatTime(appointment.endTime);
    return '$start - $end';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return '週一';
      case 2:
        return '週二';
      case 3:
        return '週三';
      case 4:
        return '週四';
      case 5:
        return '週五';
      case 6:
        return '週六';
      case 7:
        return '週日';
      default:
        return '';
    }
  }
}

