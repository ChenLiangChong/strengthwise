import 'package:flutter/material.dart';
import 'package:strengthwise/common_widgets/time_picker/time_input_field.dart';
import 'package:strengthwise/models/tracking_mode.dart';
import 'package:strengthwise/utils/notification_utils.dart';

/// 單組編輯對話框
/// v3.2+ 支援多元追蹤模式
/// v3.7+ 時間欄位使用 mm:ss 格式
class SetEditDialog extends StatefulWidget {
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
  State<SetEditDialog> createState() => _SetEditDialogState();
}

class _SetEditDialogState extends State<SetEditDialog> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _distanceController;
  late TextEditingController _caloriesController;
  int? _timeValue; // ⭐ v3.7+: 時間值直接存為 int，不用 controller

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(text: widget.initialReps.toString());
    _weightController = TextEditingController(text: widget.initialWeight.toString());
    _distanceController = TextEditingController(text: widget.initialDistance?.toString() ?? '0');
    _caloriesController = TextEditingController(text: widget.initialCalories?.toString() ?? '0');
    _timeValue = widget.initialTime;
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _distanceController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('編輯第 ${widget.setNumber} 組'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildInputFields(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final result = _parseInput(context);
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
  /// v3.7+ 時間欄位使用 TimeInputField
  List<Widget> _buildInputFields() {
    switch (widget.trackingMode) {
      case TrackingMode.weightReps:
        return [
          TextField(
            controller: _repsController,
            decoration: const InputDecoration(labelText: '次數', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(labelText: '重量 (kg)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
      case TrackingMode.weightTime:
        return [
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(labelText: '重量 (kg)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TimeInputField(
            value: _timeValue,
            onChanged: (seconds) => setState(() => _timeValue = seconds),
            useOutlineBorder: true,
            labelText: '時間',
          ),
        ];
      case TrackingMode.repsOnly:
        return [
          TextField(
            controller: _repsController,
            decoration: const InputDecoration(labelText: '次數', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ];
      case TrackingMode.timeOnly:
        return [
          TimeInputField(
            value: _timeValue,
            onChanged: (seconds) => setState(() => _timeValue = seconds),
            useOutlineBorder: true,
            labelText: '時間',
          ),
        ];
      case TrackingMode.repsTime:
        return [
          TextField(
            controller: _repsController,
            decoration: const InputDecoration(labelText: '次數', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TimeInputField(
            value: _timeValue,
            onChanged: (seconds) => setState(() => _timeValue = seconds),
            useOutlineBorder: true,
            labelText: '每次時間',
          ),
        ];
      case TrackingMode.distanceTime:
        return [
          TextField(
            controller: _distanceController,
            decoration: const InputDecoration(labelText: '距離 (公尺)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TimeInputField(
            value: _timeValue,
            onChanged: (seconds) => setState(() => _timeValue = seconds),
            useOutlineBorder: true,
            labelText: '時間',
          ),
        ];
      case TrackingMode.distanceOnly:
        return [
          TextField(
            controller: _distanceController,
            decoration: const InputDecoration(labelText: '距離 (公尺)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
      case TrackingMode.calories:
        return [
          TextField(
            controller: _caloriesController,
            decoration: const InputDecoration(labelText: '卡路里 (kcal)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
    }
  }

  /// v3.2+ 解析輸入並驗證
  /// v3.7+ 時間值直接使用 _timeValue
  Map<String, dynamic>? _parseInput(BuildContext context) {
    switch (widget.trackingMode) {
      case TrackingMode.weightReps:
        final reps = int.tryParse(_repsController.text);
        final weight = double.tryParse(_weightController.text);
        if (reps == null || weight == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'reps': reps, 'weight': weight};
      case TrackingMode.weightTime:
        final weight = double.tryParse(_weightController.text);
        if (weight == null || _timeValue == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'weight': weight, 'time': _timeValue};
      case TrackingMode.repsOnly:
        final reps = int.tryParse(_repsController.text);
        if (reps == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'reps': reps};
      case TrackingMode.timeOnly:
        if (_timeValue == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'time': _timeValue};
      case TrackingMode.repsTime:
        final reps = int.tryParse(_repsController.text);
        if (reps == null || _timeValue == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'reps': reps, 'time': _timeValue};
      case TrackingMode.distanceTime:
        final distance = double.tryParse(_distanceController.text);
        if (distance == null || _timeValue == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'distance': distance, 'time': _timeValue};
      case TrackingMode.distanceOnly:
        final distance = double.tryParse(_distanceController.text);
        if (distance == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'distance': distance};
      case TrackingMode.calories:
        final calories = double.tryParse(_caloriesController.text);
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
/// v3.7+ 時間欄位使用 mm:ss 格式
class BatchSetEditDialog extends StatefulWidget {
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
  State<BatchSetEditDialog> createState() => _BatchSetEditDialogState();
}

class _BatchSetEditDialogState extends State<BatchSetEditDialog> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _distanceController;
  late TextEditingController _caloriesController;
  int? _timeValue;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(text: widget.initialReps.toString());
    _weightController = TextEditingController(text: widget.initialWeight.toString());
    _distanceController = TextEditingController(text: widget.initialDistance?.toString() ?? '0');
    _caloriesController = TextEditingController(text: widget.initialCalories?.toString() ?? '0');
    _timeValue = widget.initialTime;
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _distanceController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          ..._buildInputFields(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            final result = _parseInput(context);
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
  /// v3.7+ 時間欄位使用 TimeInputField
  List<Widget> _buildInputFields() {
    switch (widget.trackingMode) {
      case TrackingMode.weightReps:
        return [
          TextField(
            controller: _repsController,
            decoration: const InputDecoration(labelText: '次數', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(labelText: '重量 (kg)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
      case TrackingMode.weightTime:
        return [
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(labelText: '重量 (kg)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TimeInputField(
            value: _timeValue,
            onChanged: (seconds) => setState(() => _timeValue = seconds),
            useOutlineBorder: true,
            labelText: '時間',
          ),
        ];
      case TrackingMode.repsOnly:
        return [
          TextField(
            controller: _repsController,
            decoration: const InputDecoration(labelText: '次數', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
        ];
      case TrackingMode.timeOnly:
        return [
          TimeInputField(
            value: _timeValue,
            onChanged: (seconds) => setState(() => _timeValue = seconds),
            useOutlineBorder: true,
            labelText: '時間',
          ),
        ];
      case TrackingMode.repsTime:
        return [
          TextField(
            controller: _repsController,
            decoration: const InputDecoration(labelText: '次數', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TimeInputField(
            value: _timeValue,
            onChanged: (seconds) => setState(() => _timeValue = seconds),
            useOutlineBorder: true,
            labelText: '每次時間',
          ),
        ];
      case TrackingMode.distanceTime:
        return [
          TextField(
            controller: _distanceController,
            decoration: const InputDecoration(labelText: '距離 (公尺)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TimeInputField(
            value: _timeValue,
            onChanged: (seconds) => setState(() => _timeValue = seconds),
            useOutlineBorder: true,
            labelText: '時間',
          ),
        ];
      case TrackingMode.distanceOnly:
        return [
          TextField(
            controller: _distanceController,
            decoration: const InputDecoration(labelText: '距離 (公尺)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
      case TrackingMode.calories:
        return [
          TextField(
            controller: _caloriesController,
            decoration: const InputDecoration(labelText: '卡路里 (kcal)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
    }
  }

  /// v3.2+ 解析輸入並驗證
  /// v3.7+ 時間值直接使用 _timeValue
  Map<String, dynamic>? _parseInput(BuildContext context) {
    switch (widget.trackingMode) {
      case TrackingMode.weightReps:
        final reps = int.tryParse(_repsController.text);
        final weight = double.tryParse(_weightController.text);
        if (reps == null || weight == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'reps': reps, 'weight': weight};
      case TrackingMode.weightTime:
        final weight = double.tryParse(_weightController.text);
        if (weight == null || _timeValue == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'weight': weight, 'time': _timeValue};
      case TrackingMode.repsOnly:
        final reps = int.tryParse(_repsController.text);
        if (reps == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'reps': reps};
      case TrackingMode.timeOnly:
        if (_timeValue == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'time': _timeValue};
      case TrackingMode.repsTime:
        final reps = int.tryParse(_repsController.text);
        if (reps == null || _timeValue == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'reps': reps, 'time': _timeValue};
      case TrackingMode.distanceTime:
        final distance = double.tryParse(_distanceController.text);
        if (distance == null || _timeValue == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'distance': distance, 'time': _timeValue};
      case TrackingMode.distanceOnly:
        final distance = double.tryParse(_distanceController.text);
        if (distance == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'distance': distance};
      case TrackingMode.calories:
        final calories = double.tryParse(_caloriesController.text);
        if (calories == null) {
          NotificationUtils.showWarning(context, '請輸入有效的數值');
          return null;
        }
        return {'calories': calories};
    }
  }
}
