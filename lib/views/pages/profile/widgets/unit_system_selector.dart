import 'package:flutter/material.dart';

/// 單位系統選擇元件
class UnitSystemSelector extends StatelessWidget {
  final String selectedUnit;
  final ValueChanged<String?> onChanged;

  const UnitSystemSelector({
    super.key,
    required this.selectedUnit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('單位系統', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Radio<String>(
              value: 'metric',
              groupValue: selectedUnit,
              onChanged: onChanged,
            ),
            const Text('公制 (kg, cm)'),
            const SizedBox(width: 20),
            Radio<String>(
              value: 'imperial',
              groupValue: selectedUnit,
              onChanged: onChanged,
            ),
            const Text('英制 (lb, in)'),
          ],
        ),
      ],
    );
  }
}

