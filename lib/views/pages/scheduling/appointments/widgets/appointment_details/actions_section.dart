import 'package:flutter/material.dart';
import 'package:strengthwise/models/appointment_model.dart';

/// 操作按鈕區域組件
class ActionsSection extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isCoachMode;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  /// 查看課程紀錄回調（學員專用）⭐ v3.0
  final VoidCallback? onViewRecord;

  /// 查看課程詳情回調（學員進入 Session Mode）⭐ v3.1
  final VoidCallback? onViewSession;

  const ActionsSection({
    super.key,
    required this.appointment,
    required this.isCoachMode,
    required this.onConfirm,
    required this.onReject,
    required this.onCancel,
    required this.onComplete,
    this.onViewRecord,
    this.onViewSession,
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
      if (appointment.status == AppointmentStatus.confirmed) {
        // ⭐ v3.1: 已確認：顯示查看課程詳情按鈕（進入 Session Mode）
        if (onViewSession != null) {
          buttons.add(
            FilledButton.icon(
              onPressed: onViewSession,
              icon: const Icon(Icons.fitness_center),
              label: const Text('查看課程詳情'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          );
          buttons.add(const SizedBox(height: 12));
        }
        // 取消按鈕
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
      } else if (appointment.status == AppointmentStatus.requested) {
        // 待確認：僅顯示取消按鈕
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
      } else if (appointment.status == AppointmentStatus.completed) {
        // ⭐ v3.0: 已完成：顯示查看課程紀錄按鈕
        if (onViewRecord != null) {
          buttons.add(
            FilledButton.icon(
              onPressed: onViewRecord,
              icon: const Icon(Icons.description_outlined),
              label: const Text('查看課程紀錄'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          );
        }
      }
    }

    return buttons;
  }
}

