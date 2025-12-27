import 'package:flutter/material.dart';

/// 動作設置對話框（用於新增動作時設置參數）
class ExerciseSettingsDialog extends StatelessWidget {
  final String exerciseName;
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController restController;

  const ExerciseSettingsDialog({
    super.key,
    required this.exerciseName,
    required this.setsController,
    required this.repsController,
    required this.weightController,
    required this.restController,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('設置 $exerciseName'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              decoration: const InputDecoration(
                labelText: '組數',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: repsController,
              decoration: const InputDecoration(
                labelText: '每組次數',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(
                labelText: '重量 (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: restController,
              decoration: const InputDecoration(
                labelText: '休息時間 (秒)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          style: ElevatedButton.styleFrom(),
          child: const Text('添加'),
        ),
      ],
    );
  }
}

