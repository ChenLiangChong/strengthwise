import 'package:flutter/material.dart';
import '../../models/custom_exercise_model.dart';
import '../../utils/body_part_utils.dart';

/// 自訂動作對話框數據
class CustomExerciseData {
  final String name;
  final String trainingType;
  final String bodyPart;
  final String equipment;
  final String description;
  final String notes;

  CustomExerciseData({
    required this.name,
    required this.trainingType,
    required this.bodyPart,
    required this.equipment,
    required this.description,
    required this.notes,
  });
}

class CustomExerciseDialog extends StatefulWidget {
  final CustomExercise? exercise; // 如果是編輯現有動作則提供，否則為null
  final Future<void> Function(CustomExerciseData data) onSubmit;
  
  const CustomExerciseDialog({
    super.key,
    this.exercise,
    required this.onSubmit,
  });

  @override
  State<CustomExerciseDialog> createState() => _CustomExerciseDialogState();
}

class _CustomExerciseDialogState extends State<CustomExerciseDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  
  // 下拉選單選項
  String _selectedTrainingType = '阻力訓練';
  String _selectedBodyPart = '胸部';
  String _selectedEquipment = '徒手';
  
  // 訓練類型選項
  static const List<String> _trainingTypeOptions = [
    '阻力訓練',
    '心肺適能訓練',
    '活動度與伸展',
  ];
  
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
    
    // 如果是編輯模式，預填資料
    if (widget.exercise != null) {
      _nameController = TextEditingController(text: widget.exercise!.name);
      _descriptionController = TextEditingController(text: widget.exercise!.description);
      _notesController = TextEditingController(text: widget.exercise!.notes);
      _selectedTrainingType = widget.exercise!.trainingType;
      _selectedBodyPart = widget.exercise!.bodyPart;
      _selectedEquipment = widget.exercise!.equipment;
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _notesController = TextEditingController();
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.exercise != null;
    
    return AlertDialog(
      title: Text(isEditing ? '編輯自訂動作' : '新增自訂動作'),
      // 🐛 修復：barrierDismissible 已由 showDialog 設置
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameField(),
              const SizedBox(height: 16),
              _buildTrainingTypeDropdown(),
              const SizedBox(height: 16),
              _buildBodyPartDropdown(),
              const SizedBox(height: 16),
              _buildEquipmentDropdown(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildNotesField(),
            ],
          ),
        ),
      ),
      actions: [
        _buildCancelButton(),
        _buildSubmitButton(isEditing),
      ],
    );
  }

  /// 建立動作名稱輸入欄位
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: '動作名稱 *',
        hintText: '例如：交叉捲腹、單腿深蹲',
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

  /// 建立訓練類型下拉選單
  Widget _buildTrainingTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTrainingType,
      decoration: const InputDecoration(
        labelText: '訓練類型 *',
        border: OutlineInputBorder(),
        helperText: '用於分類和篩選',
      ),
      items: _trainingTypeOptions.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedTrainingType = value);
        }
      },
    );
  }

  /// 建立身體部位下拉選單
  Widget _buildBodyPartDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBodyPart,
      decoration: const InputDecoration(
        labelText: '身體部位 *',
        border: OutlineInputBorder(),
        helperText: '用於統計和分類',
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
      decoration: const InputDecoration(
        labelText: '使用器材',
        border: OutlineInputBorder(),
        helperText: '選填',
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

  /// 建立動作說明輸入欄位
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: '動作說明',
        hintText: '例如：雙手持啞鈴，彎曲肘關節...',
        border: OutlineInputBorder(),
        helperText: '選填',
        counterText: '',  // 隱藏字數計數器
      ),
      maxLines: 2,
      maxLength: 200,
    );
  }

  /// 建立個人筆記輸入欄位
  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: '個人筆記',
        hintText: '例如：注意膝蓋角度、呼吸節奏...',
        border: OutlineInputBorder(),
        helperText: '選填',
        counterText: '',  // 隱藏字數計數器
      ),
      maxLines: 2,
      maxLength: 200,
    );
  }

  /// 建立取消按鈕
  Widget _buildCancelButton() {
    return TextButton(
      onPressed: _isSubmitting ? null : () {
        Navigator.of(context).pop();
      },
      child: const Text('取消'),
    );
  }

  /// 建立提交按鈕
  Widget _buildSubmitButton(bool isEditing) {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _handleSubmit,
      child: _isSubmitting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(isEditing ? '更新' : '新增'),
    );
  }

  /// 處理表單提交
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final data = CustomExerciseData(
        name: _nameController.text.trim(),
        trainingType: _selectedTrainingType,
        bodyPart: _selectedBodyPart,
        equipment: _selectedEquipment,
        description: _descriptionController.text.trim(),
        notes: _notesController.text.trim(),
      );

      await widget.onSubmit(data);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

