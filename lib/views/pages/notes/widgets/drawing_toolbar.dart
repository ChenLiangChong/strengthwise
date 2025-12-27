import 'package:flutter/material.dart';
import 'color_picker_circle.dart';

/// 繪圖工具欄元件
class DrawingToolbar extends StatelessWidget {
  final Color currentColor;
  final double currentStrokeWidth;
  final VoidCallback onClearDrawing;
  final Function(Color) onColorChanged;
  final Function(double) onStrokeWidthChanged;

  const DrawingToolbar({
    super.key,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.onClearDrawing,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 清空繪圖
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空繪圖',
            onPressed: onClearDrawing,
          ),
          // 線條顏色選擇
          ColorPickerCircle(
            color: Colors.black,
            isSelected: currentColor == Colors.black,
            onTap: () => onColorChanged(Colors.black),
          ),
          ColorPickerCircle(
            color: Colors.red,
            isSelected: currentColor == Colors.red,
            onTap: () => onColorChanged(Colors.red),
          ),
          ColorPickerCircle(
            color: Colors.blue,
            isSelected: currentColor == Colors.blue,
            onTap: () => onColorChanged(Colors.blue),
          ),
          ColorPickerCircle(
            color: Theme.of(context).colorScheme.secondary,
            isSelected: currentColor == Theme.of(context).colorScheme.secondary,
            onTap: () => onColorChanged(Theme.of(context).colorScheme.secondary),
          ),
          // 線條粗細選擇
          DropdownButton<double>(
            value: currentStrokeWidth,
            items: [1.0, 3.0, 5.0, 8.0, 12.0]
                .map((width) => DropdownMenuItem<double>(
                      value: width,
                      child: Text('${width.toInt()} px'),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onStrokeWidthChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}

