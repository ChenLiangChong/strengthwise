import 'package:flutter/material.dart';
import '../../../../utils/notification_utils.dart';

/// 單組編輯對話框
class SetEditDialog extends StatelessWidget {
  final int setNumber;
  final int initialReps;
  final double initialWeight;

  const SetEditDialog({
    super.key,
    required this.setNumber,
    required this.initialReps,
    required this.initialWeight,
  });

  @override
  Widget build(BuildContext context) {
    final repsController = TextEditingController(text: initialReps.toString());
    final weightController = TextEditingController(text: initialWeight.toString());

    return AlertDialog(
      title: Text('編輯第 $setNumber 組'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: repsController,
            decoration: const InputDecoration(
              labelText: '次數',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: weightController,
            decoration: const InputDecoration(
              labelText: '重量 (kg)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final reps = int.tryParse(repsController.text);
            final weight = double.tryParse(weightController.text);

            if (reps == null || weight == null) {
              NotificationUtils.showWarning(context, '請輸入有效的數值');
              return;
            }

            Navigator.pop(context, {'reps': reps, 'weight': weight});
          },
          style: ElevatedButton.styleFrom(),
          child: const Text('確定'),
        ),
      ],
    );
  }
}

/// 批量編輯對話框
class BatchSetEditDialog extends StatelessWidget {
  final int initialReps;
  final double initialWeight;

  const BatchSetEditDialog({
    super.key,
    required this.initialReps,
    required this.initialWeight,
  });

  @override
  Widget build(BuildContext context) {
    final repsController = TextEditingController(text: initialReps.toString());
    final weightController = TextEditingController(text: initialWeight.toString());

    return AlertDialog(
      title: const Text('批量編輯所有組'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '這將應用到所有組',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: repsController,
            decoration: const InputDecoration(
              labelText: '次數',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: weightController,
            decoration: const InputDecoration(
              labelText: '重量 (kg)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final reps = int.tryParse(repsController.text);
            final weight = double.tryParse(weightController.text);

            if (reps == null || weight == null) {
              NotificationUtils.showWarning(context, '請輸入有效的數值');
              return;
            }

            Navigator.pop(context, {'reps': reps, 'weight': weight});
          },
          style: ElevatedButton.styleFrom(),
          child: const Text('確定'),
        ),
      ],
    );
  }
}

