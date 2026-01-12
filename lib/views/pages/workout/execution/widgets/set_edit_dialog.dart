import 'package:flutter/material.dart';
import 'package:strengthwise/models/tracking_mode.dart';
import 'package:strengthwise/utils/notification_utils.dart';

/// 單組編輯對話框
/// v3.2+ 支援多元追蹤模式
class SetEditDialog extends StatelessWidget {
  final int setNumber;
  final int initialReps;
  final double initialWeight;
  final int? initialTime;       // v3.2+
  final double? initialDistance; // v3.2+
  final double? initialCalories; // v3.2+
  final TrackingMode trackingMode; // v3.2+

  const SetEditDialog({
    super.key,
    required this.setNumber,
    required this.initialReps,
    required this.initialWeight,
    this.initialTime,
    this.initialDistance,
    this.initialCalories,
    this.trackingMode = TrackingMode.weightReps,
  });

  @override
  Widget build(BuildContext context) {
    final repsController = TextEditingController(text: initialReps.toString());
    final weightController = TextEditingController(text: initialWeight.toString());
    final timeController = TextEditingController(text: initialTime?.toString() ?? '0');
    final distanceController = TextEditingController(text: initialDistance?.toString() ?? '0');
    final caloriesController = TextEditingController(text: initialCalories?.toString() ?? '0');

    return AlertDialog(
      title: Text('編輯第 $setNumber 組'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildInputFields(
          repsController,
          weightController,
          timeController,
          distanceController,
          caloriesController,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final result = _parseInput(
              repsController,
              weightController,
              timeController,
              distanceController,
              caloriesController,
              context,
            );
            if (result != null) {
              Navigator.pop(context, result);
            }
          },
          style: ElevatedButton.styleFrom(),
          child: const Text('確定'),
        ),
      ],
    );
  }

  /// v3.2+ 根據追蹤模式構建輸入欄位
  List<Widget> _buildInputFields(
    TextEditingController repsController,
    TextEditingController weightController,
    TextEditingController timeController,
    TextEditingController distanceController,
    TextEditingController caloriesController,
  ) {
    switch (trackingMode) {
      case TrackingMode.weightReps:
        return [
          TextField(
            controller: repsController,
            decoration: const InputDecoration(labelText: '次數', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: weightController,
            decoration: const InputDecoration(labelText: '重量 (kg)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
      case TrackingMode.weightTime:
        return [
          TextField(
            controller: weightController,
            decoration: const InputDecoration(labelText: '重量 (kg)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: timeController,
            decoration: const InputDecoration(labelText: '時間 (秒)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ];
      case TrackingMode.repsOnly:
        return [
          TextField(
            controller: repsController,
            decoration: const InputDecoration(labelText: '次數', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ];
      case TrackingMode.timeOnly:
        return [
          TextField(
            controller: timeController,
            decoration: const InputDecoration(labelText: '時間 (秒)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ];
      case TrackingMode.repsTime:
        return [
          TextField(
            controller: repsController,
            decoration: const InputDecoration(labelText: '次數', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: timeController,
            decoration: const InputDecoration(labelText: '每次時間 (秒)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ];
      case TrackingMode.distanceTime:
        return [
          TextField(
            controller: distanceController,
            decoration: const InputDecoration(labelText: '距離 (公尺)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: timeController,
            decoration: const InputDecoration(labelText: '時間 (秒)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ];
      case TrackingMode.distanceOnly:
        return [
          TextField(
            controller: distanceController,
            decoration: const InputDecoration(labelText: '距離 (公尺)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
      case TrackingMode.calories:
        return [
          TextField(
            controller: caloriesController,
            decoration: const InputDecoration(labelText: '卡路里 (kcal)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
    }
  }

  /// v3.2+ 解析輸入並驗證
  Map<String, dynamic>? _parseInput(
    TextEditingController repsController,
    TextEditingController weightController,
    TextEditingController timeController,
    TextEditingController distanceController,
    TextEditingController caloriesController,
    BuildContext context,
  ) {
    switch (trackingMode) {
      case TrackingMode.weightReps:
        final reps = int.tryParse(repsController.text);
        final weight = double.tryParse(weightController.text);
        if (reps == null || weight == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'reps': reps, 'weight': weight};
      case TrackingMode.weightTime:
        final weight = double.tryParse(weightController.text);
        final time = int.tryParse(timeController.text);
        if (weight == null || time == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'weight': weight, 'time': time};
      case TrackingMode.repsOnly:
        final reps = int.tryParse(repsController.text);
        if (reps == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'reps': reps};
      case TrackingMode.timeOnly:
        final time = int.tryParse(timeController.text);
        if (time == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'time': time};
      case TrackingMode.repsTime:
        final reps = int.tryParse(repsController.text);
        final time = int.tryParse(timeController.text);
        if (reps == null || time == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'reps': reps, 'time': time};
      case TrackingMode.distanceTime:
        final distance = double.tryParse(distanceController.text);
        final time = int.tryParse(timeController.text);
        if (distance == null || time == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'distance': distance, 'time': time};
      case TrackingMode.distanceOnly:
        final distance = double.tryParse(distanceController.text);
        if (distance == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'distance': distance};
      case TrackingMode.calories:
        final calories = double.tryParse(caloriesController.text);
        if (calories == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'calories': calories};
    }
  }
}

/// 批量編輯對話框
/// v3.2+ 支援多元追蹤模式
class BatchSetEditDialog extends StatelessWidget {
  final int initialReps;
  final double initialWeight;
  final int? initialTime;       // v3.2+
  final double? initialDistance; // v3.2+
  final double? initialCalories; // v3.2+
  final TrackingMode trackingMode; // v3.2+

  const BatchSetEditDialog({
    super.key,
    required this.initialReps,
    required this.initialWeight,
    this.initialTime,
    this.initialDistance,
    this.initialCalories,
    this.trackingMode = TrackingMode.weightReps,
  });

  @override
  Widget build(BuildContext context) {
    final repsController = TextEditingController(text: initialReps.toString());
    final weightController = TextEditingController(text: initialWeight.toString());
    final timeController = TextEditingController(text: initialTime?.toString() ?? '0');
    final distanceController = TextEditingController(text: initialDistance?.toString() ?? '0');
    final caloriesController = TextEditingController(text: initialCalories?.toString() ?? '0');

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
          ..._buildInputFields(
            repsController,
            weightController,
            timeController,
            distanceController,
            caloriesController,
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
            final result = _parseInput(
              repsController,
              weightController,
              timeController,
              distanceController,
              caloriesController,
              context,
            );
            if (result != null) {
              Navigator.pop(context, result);
            }
          },
          style: ElevatedButton.styleFrom(),
          child: const Text('確定'),
        ),
      ],
    );
  }

  /// v3.2+ 根據追蹤模式構建輸入欄位（與 SetEditDialog 相同邏輯）
  List<Widget> _buildInputFields(
    TextEditingController repsController,
    TextEditingController weightController,
    TextEditingController timeController,
    TextEditingController distanceController,
    TextEditingController caloriesController,
  ) {
    switch (trackingMode) {
      case TrackingMode.weightReps:
        return [
          TextField(
            controller: repsController,
            decoration: const InputDecoration(labelText: '次數', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: weightController,
            decoration: const InputDecoration(labelText: '重量 (kg)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
      case TrackingMode.weightTime:
        return [
          TextField(
            controller: weightController,
            decoration: const InputDecoration(labelText: '重量 (kg)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: timeController,
            decoration: const InputDecoration(labelText: '時間 (秒)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ];
      case TrackingMode.repsOnly:
        return [
          TextField(
            controller: repsController,
            decoration: const InputDecoration(labelText: '次數', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ];
      case TrackingMode.timeOnly:
        return [
          TextField(
            controller: timeController,
            decoration: const InputDecoration(labelText: '時間 (秒)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ];
      case TrackingMode.repsTime:
        return [
          TextField(
            controller: repsController,
            decoration: const InputDecoration(labelText: '次數', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: timeController,
            decoration: const InputDecoration(labelText: '每次時間 (秒)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ];
      case TrackingMode.distanceTime:
        return [
          TextField(
            controller: distanceController,
            decoration: const InputDecoration(labelText: '距離 (公尺)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: timeController,
            decoration: const InputDecoration(labelText: '時間 (秒)', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ];
      case TrackingMode.distanceOnly:
        return [
          TextField(
            controller: distanceController,
            decoration: const InputDecoration(labelText: '距離 (公尺)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
      case TrackingMode.calories:
        return [
          TextField(
            controller: caloriesController,
            decoration: const InputDecoration(labelText: '卡路里 (kcal)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
    }
  }

  /// v3.2+ 解析輸入並驗證
  Map<String, dynamic>? _parseInput(
    TextEditingController repsController,
    TextEditingController weightController,
    TextEditingController timeController,
    TextEditingController distanceController,
    TextEditingController caloriesController,
    BuildContext context,
  ) {
    switch (trackingMode) {
      case TrackingMode.weightReps:
        final reps = int.tryParse(repsController.text);
        final weight = double.tryParse(weightController.text);
        if (reps == null || weight == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'reps': reps, 'weight': weight};
      case TrackingMode.weightTime:
        final weight = double.tryParse(weightController.text);
        final time = int.tryParse(timeController.text);
        if (weight == null || time == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'weight': weight, 'time': time};
      case TrackingMode.repsOnly:
        final reps = int.tryParse(repsController.text);
        if (reps == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'reps': reps};
      case TrackingMode.timeOnly:
        final time = int.tryParse(timeController.text);
        if (time == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'time': time};
      case TrackingMode.repsTime:
        final reps = int.tryParse(repsController.text);
        final time = int.tryParse(timeController.text);
        if (reps == null || time == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'reps': reps, 'time': time};
      case TrackingMode.distanceTime:
        final distance = double.tryParse(distanceController.text);
        final time = int.tryParse(timeController.text);
        if (distance == null || time == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'distance': distance, 'time': time};
      case TrackingMode.distanceOnly:
        final distance = double.tryParse(distanceController.text);
        if (distance == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'distance': distance};
      case TrackingMode.calories:
        final calories = double.tryParse(caloriesController.text);
        if (calories == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'calories': calories};
    }
  }
}
