import 'package:flutter/material.dart';
import '../../models/custom_exercise_model.dart';

class CustomExerciseDialog extends StatefulWidget {
  final CustomExercise? exercise; // 如果是编辑现有动作则提供，否则为null
  final Future<void> Function(String name) onSubmit;
  
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
  bool _isSubmitting = false;
  
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
          onPressed: _isSubmitting ? null : () async {
            if (_formKey.currentState!.validate()) {
              setState(() {
                _isSubmitting = true;
              });
              
              try {
                // 等待操作完成
                await widget.onSubmit(_nameController.text.trim());
                
                // 操作成功後再關閉 Dialog
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                // 如果出錯，恢復按鈕狀態
                if (mounted) {
                  setState(() {
                    _isSubmitting = false;
                  });
                }
              }
            }
          },
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
        ),
      ],
    );
  }
} 