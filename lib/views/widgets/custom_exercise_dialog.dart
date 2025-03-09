import 'package:flutter/material.dart';
import '../../models/custom_exercise_model.dart';

class CustomExerciseDialog extends StatefulWidget {
  final CustomExercise? exercise; // 如果是编辑现有动作则提供，否则为null
  final Function(String name) onSubmit;
  
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
  final _formKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise?.name ?? '');
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.exercise != null;
    
    return AlertDialog(
      title: Text(isEditing ? '編輯自訂動作' : '新增自訂動作'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '動作名稱',
                hintText: '例如：交叉捲腹、單腿深蹲...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請輸入動作名稱';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSubmit(_nameController.text.trim());
              Navigator.of(context).pop();
            }
          },
          child: Text(isEditing ? '更新' : '新增'),
        ),
      ],
    );
  }
} 