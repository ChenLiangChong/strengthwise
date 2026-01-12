import 'package:flutter/material.dart';
import 'package:strengthwise/models/tracking_mode.dart';
import 'package:strengthwise/utils/body_part_utils.dart';

/// 「加入我的動作庫」對話框數據
class AddToMyExercisesData {
  final String name;
  final String trainingType;
  final String bodyPart;
  final String equipment;
  final TrackingMode trackingMode;

  AddToMyExercisesData({
    required this.name,
    required this.trainingType,
    required this.bodyPart,
    required this.equipment,
    required this.trackingMode,
  });
}

/// 「加入我的動作庫」對話框
///
/// v3.4+ 讓學員將教練的自訂動作複製到自己的動作庫
/// 可在複製前編輯動作名稱、身體部位、追蹤模式等
class AddToMyExercisesDialog extends StatefulWidget {
  /// 原始動作名稱
  final String originalName;

  /// 原始身體部位
  final String originalBodyPart;

  /// 原始器材
  final String originalEquipment;

  /// 原始追蹤模式
  final TrackingMode originalTrackingMode;

  /// 確認回調
  final Future<void> Function(AddToMyExercisesData data) onConfirm;

  /// 標題後綴（用於顯示進度，如 "(1/3)"）
  final String? titleSuffix;

  const AddToMyExercisesDialog({
    super.key,
    required this.originalName,
    required this.originalBodyPart,
    required this.originalEquipment,
    required this.originalTrackingMode,
    required this.onConfirm,
    this.titleSuffix,
  });

  @override
  State<AddToMyExercisesDialog> createState() => _AddToMyExercisesDialogState();
}

class _AddToMyExercisesDialogState extends State<AddToMyExercisesDialog> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // 下拉選單選項
  late String _selectedBodyPart;
  late String _selectedEquipment;
  late TrackingMode _selectedTrackingMode;

  // 訓練類型（根據追蹤模式自動推斷）
  String get _trainingType {
    switch (_selectedTrackingMode) {
      case TrackingMode.weightReps:
      case TrackingMode.weightTime:
      case TrackingMode.repsOnly:
        return '阻力訓練';
      case TrackingMode.timeOnly:
      case TrackingMode.repsTime:
        return '活動度與伸展';
      case TrackingMode.distanceTime:
      case TrackingMode.distanceOnly:
      case TrackingMode.calories:
        return '心肺適能訓練';
    }
  }

  // 身體部位選項
  static const List<String> _bodyPartOptions = [
    '胸部',
    '背部',
    '腿部',
    '肩部',
    '手臂',
    '核心',
  ];

  // 器材選項
  static const List<String> _equipmentOptions = [
    '徒手',
    '啞鈴',
    '槓鈴',
    '固定式機械',
    'Cable滑輪',
    '壺鈴',
    '彈力帶',
    '其他',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.originalName);
    _selectedBodyPart = _bodyPartOptions.contains(widget.originalBodyPart)
        ? widget.originalBodyPart
        : '核心'; // 預設值
    _selectedEquipment = _equipmentOptions.contains(widget.originalEquipment)
        ? widget.originalEquipment
        : '徒手'; // 預設值
    _selectedTrackingMode = widget.originalTrackingMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.add_circle_outline,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '加入我的動作庫${widget.titleSuffix ?? ''}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 提示文字
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '將此教練自訂動作加入你的動作庫，之後可自行使用',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 動作名稱
                _buildNameField(),
                const SizedBox(height: 16),

                // 身體部位
                _buildBodyPartDropdown(),
                const SizedBox(height: 16),

                // 器材
                _buildEquipmentDropdown(),
                const SizedBox(height: 16),

                // 追蹤模式
                _buildTrackingModeDropdown(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleConfirm,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('加入'),
        ),
      ],
    );
  }

  /// 建立動作名稱輸入欄位
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: '動作名稱',
        hintText: '可自訂動作名稱',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '請輸入動作名稱';
        }
        if (value.length > 50) {
          return '名稱不能超過50個字符';
        }
        return null;
      },
    );
  }

  /// 建立身體部位下拉選單
  Widget _buildBodyPartDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBodyPart,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: '身體部位',
        border: OutlineInputBorder(),
      ),
      items: _bodyPartOptions.map((part) {
        return DropdownMenuItem(
          value: part,
          child: Row(
            children: [
              Icon(BodyPartUtils.getBodyPartIcon(part), size: 20),
              const SizedBox(width: 8),
              Text(part),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedBodyPart = value);
        }
      },
    );
  }

  /// 建立器材下拉選單
  Widget _buildEquipmentDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedEquipment,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: '使用器材',
        border: OutlineInputBorder(),
      ),
      items: _equipmentOptions.map((equipment) {
        return DropdownMenuItem(
          value: equipment,
          child: Text(equipment),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedEquipment = value);
        }
      },
    );
  }

  /// 建立追蹤模式下拉選單
  Widget _buildTrackingModeDropdown() {
    return DropdownButtonFormField<TrackingMode>(
      value: _selectedTrackingMode,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: '追蹤模式',
        border: OutlineInputBorder(),
        helperText: '選擇此動作的記錄方式',
      ),
      // 選中後的顯示
      selectedItemBuilder: (context) {
        return TrackingMode.values.map((mode) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(mode.displayName),
          );
        }).toList();
      },
      // 下拉列表顯示
      items: TrackingMode.values.map((mode) {
        return DropdownMenuItem(
          value: mode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mode.displayName),
              Text(
                mode.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedTrackingMode = value);
        }
      },
      itemHeight: 72,
    );
  }

  /// 處理確認
  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final data = AddToMyExercisesData(
        name: _nameController.text.trim(),
        trainingType: _trainingType,
        bodyPart: _selectedBodyPart,
        equipment: _selectedEquipment,
        trackingMode: _selectedTrackingMode,
      );

      await widget.onConfirm(data);

      if (mounted) {
        Navigator.of(context).pop(true); // 返回 true 表示成功
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入失敗: $e')),
        );
      }
    }
  }
}
