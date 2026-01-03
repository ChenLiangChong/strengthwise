import 'package:flutter/material.dart';
import 'package:strengthwise/models/appointment_model.dart';

/// 詳情資訊區域組件
class DetailsInfoSection extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isCoachMode;

  const DetailsInfoSection({
    super.key,
    required this.appointment,
    required this.isCoachMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Text(
            '預約資訊',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // 資訊列表
          _buildInfoRow(
            Icons.person_outline,
            isCoachMode ? '學員' : '教練',
            isCoachMode ? appointment.clientId : appointment.coachId,
          ),

          const SizedBox(height: 12),

          _buildInfoRow(
            Icons.calendar_today_outlined,
            '創建時間',
            _formatDateTime(appointment.createdAt),
          ),

          const SizedBox(height: 12),

          _buildInfoRow(
            Icons.update_outlined,
            '最後更新',
            _formatDateTime(appointment.updatedAt),
          ),

          // 取消資訊（如果已取消）
          if (appointment.isCancelled) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              '取消資訊',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            if (appointment.cancelledAt != null)
              _buildInfoRow(
                Icons.event_busy,
                '取消時間',
                _formatDateTime(appointment.cancelledAt!),
              ),
            if (appointment.cancellationReason != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.comment_outlined,
                '取消原因',
                appointment.cancellationReason!,
              ),
            ],
          ],

          // 關聯訓練計劃（如果有）
          if (appointment.workoutPlanId != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.fitness_center_outlined,
              '關聯訓練計劃',
              appointment.workoutPlanId!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

