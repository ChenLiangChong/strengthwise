import 'package:flutter/material.dart';

/// 顏色選擇圓圈元件
class ColorPickerCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const ColorPickerCircle({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.outline 
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

