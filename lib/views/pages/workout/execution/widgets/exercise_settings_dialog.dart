import 'package:flutter/material.dart';
import 'package:strengthwise/common_widgets/time_picker/time_input_field.dart';
import 'package:strengthwise/models/tracking_mode.dart';

/// 動作設置對話框（用於新增動作時設置參數）
///
/// 注意：休息時間由打勾後的計時器選擇，不在這裡設定
/// v3.2+ 根據 trackingMode 顯示不同輸入欄位
/// v3.7+ 時間欄位使用 mm:ss 格式
class ExerciseSettingsDialog extends StatefulWidget {
  final String exerciseName;
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController weightController;
  // restController 保留但不顯示 UI，供外部使用預設值
  final TextEditingController restController;
  // v3.2+ 新增欄位控制器
  // v3.7+ timeController 仍保留用於向後相容，但 UI 改用 TimeInputField
  final TextEditingController? timeController;
  final TextEditingController? distanceController;
  final TextEditingController? caloriesController;
  final TrackingMode trackingMode;

  const ExerciseSettingsDialog({
    super.key,
    required this.exerciseName,
    required this.setsController,
    required this.repsController,
    required this.weightController,
    required this.restController,
    this.timeController,
    this.distanceController,
    this.caloriesController,
    this.trackingMode = TrackingMode.weightReps,
  });

  @override
  State<ExerciseSettingsDialog> createState() => _ExerciseSettingsDialogState();
}

class _ExerciseSettingsDialogState extends State<ExerciseSettingsDialog> {
  int? _timeValue;

  @override
  void initState() {
    super.initState();
    // 從 controller 初始化時間值
    if (widget.timeController != null) {
      _timeValue = int.tryParse(widget.timeController!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('設置 ${widget.exerciseName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 組數（所有模式都需要）
            TextField(
              controller: widget.setsController,
              decoration: const InputDecoration(
                labelText: '組數',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            // v3.2+ 根據追蹤模式顯示不同欄位
            ..._buildTrackingModeFields(),
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
            // v3.7+: 同步時間值回 controller
            if (widget.timeController != null && _timeValue != null) {
              widget.timeController!.text = _timeValue.toString();
            }
            Navigator.pop(context, true);
          },
          child: const Text('添加'),
        ),
      ],
    );
  }

  /// v3.2+ 根據追蹤模式構建輸入欄位
  /// v3.7+ 時間欄位使用 TimeInputField
  List<Widget> _buildTrackingModeFields() {
    switch (widget.trackingMode) {
      case TrackingMode.weightReps:
        return [
          TextField(
            controller: widget.repsController,
            decoration: const InputDecoration(
              labelText: '每組次數',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.weightController,
            decoration: const InputDecoration(
              labelText: '重量 (kg)',
              border: OutlineInputBorder(),
              hintText: '0 = 徒手',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ];
      case TrackingMode.weightTime:
        return [
          TextField(
            controller: widget.weightController,
            decoration: const InputDecoration(
              labelText: '重量 (kg)',
              border: OutlineInputBorder(),
              hintText: '0 = 徒手',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
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
            controller: widget.repsController,
            decoration: const InputDecoration(
              labelText: '每組次數',
              border: OutlineInputBorder(),
            ),
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
            controller: widget.repsController,
            decoration: const InputDecoration(
              labelText: '每組次數',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TimeInputField(
            value: _timeValue,
            onChanged: (seconds) => setState(() => _timeValue = seconds),
            useOutlineBorder: true,
            labelText: '每次時間',
          ),
        ];
      case TrackingMode.distanceTime:
        return [
          if (widget.distanceController != null)
            TextField(
              controller: widget.distanceController,
              decoration: const InputDecoration(
                labelText: '距離 (公尺)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          const SizedBox(height: 12),
          TimeInputField(
            value: _timeValue,
            onChanged: (seconds) => setState(() => _timeValue = seconds),
            useOutlineBorder: true,
            labelText: '時間',
          ),
        ];
      case TrackingMode.distanceOnly:
        return [
          if (widget.distanceController != null)
            TextField(
              controller: widget.distanceController,
              decoration: const InputDecoration(
                labelText: '距離 (公尺)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
        ];
      case TrackingMode.calories:
        return [
          if (widget.caloriesController != null)
            TextField(
              controller: widget.caloriesController,
              decoration: const InputDecoration(
                labelText: '卡路里 (kcal)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
        ];
    }
  }
}
