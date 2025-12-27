import 'package:flutter/material.dart';

/// 性別選擇元件
class GenderSelector extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String?> onChanged;

  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('性別', style: TextStyle(fontSize: 16)),
        Row(
          children: [
            Radio<String>(
              value: '男',
              groupValue: selectedGender,
              onChanged: onChanged,
            ),
            const Text('男'),
            const SizedBox(width: 20),
            Radio<String>(
              value: '女',
              groupValue: selectedGender,
              onChanged: onChanged,
            ),
            const Text('女'),
          ],
        ),
      ],
    );
  }
}

