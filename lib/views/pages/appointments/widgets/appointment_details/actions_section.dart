import 'package:flutter/material.dart';
import '../../../../../models/appointment_model.dart';

/// 操作按鈕區域組件
class ActionsSection extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isCoachMode;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  const ActionsSection({
    super.key,
    required this.appointment,
    required this.isCoachMode,
    required this.onConfirm,
    required this.onReject,
    required this.onCancel,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    // 根據狀態和角色顯示不同的操作按鈕
    final buttons = _getActionButtons();

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons,
      ),
    );
  }

  List<Widget> _getActionButtons() {
    final buttons = <Widget>[];

    if (isCoachMode) {
      // 教練端操作
      if (appointment.status == AppointmentStatus.requested) {
        // 待確認：顯示確認/拒絕按鈕
        buttons.add(
          FilledButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('確認預約'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
        buttons.add(const SizedBox(height: 12));
        buttons.add(
          OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('拒絕預約'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      } else if (appointment.status == AppointmentStatus.confirmed) {
        // 已確認：顯示完成/取消按鈕
        buttons.add(
          FilledButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.done_all),
            label: const Text('標記為完成'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
        buttons.add(const SizedBox(height: 12));
        buttons.add(
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('取消預約'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      }
    } else {
      // 學員端操作
      if (appointment.status == AppointmentStatus.requested ||
          appointment.status == AppointmentStatus.confirmed) {
        // 待確認或已確認：顯示取消按鈕
        buttons.add(
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('取消預約'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      }
    }

    return buttons;
  }
}

