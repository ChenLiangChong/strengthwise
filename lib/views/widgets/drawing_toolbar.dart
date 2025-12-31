import 'package:flutter/material.dart';
import '../../models/drawing_note_model.dart';

/// 繪圖工具列
class DrawingToolbar extends StatelessWidget {
  final DrawingTool currentTool;
  final Color currentColor;
  final double currentStrokeWidth;
  final ValueChanged<DrawingTool> onToolChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final bool canUndo;
  final bool canRedo;

  const DrawingToolbar({
    super.key,
    required this.currentTool,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.canUndo,
    required this.canRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 工具選擇列（可滾動）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildToolButton(
                  icon: Icons.edit,
                  tool: DrawingTool.pencil,
                  label: '鉛筆',
                ),
                _buildToolButton(
                  icon: Icons.brush,
                  tool: DrawingTool.marker,
                  label: '麥克筆',
                ),
                _buildToolButton(
                  icon: Icons.highlight,
                  tool: DrawingTool.highlighter,
                  label: '螢光筆',
                ),
                _buildToolButton(
                  icon: Icons.auto_fix_high,
                  tool: DrawingTool.eraser,
                  label: '橡皮擦',
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: canUndo ? onUndo : null,
                  tooltip: '撤銷',
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: canRedo ? onRedo : null,
                  tooltip: '重做',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onClear,
                  tooltip: '清空畫布',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 顏色與粗細列（可滾動）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('顏色：'),
                const SizedBox(width: 8),
                _buildColorButton(Colors.black),
                _buildColorButton(Colors.red),
                _buildColorButton(Colors.blue),
                _buildColorButton(Colors.green),
                _buildColorButton(Colors.yellow),
                _buildColorButton(Colors.orange),
                _buildColorButton(Colors.purple),
                const SizedBox(width: 16),
                // 粗細調整
                const Text('粗細：'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: Slider(
                    value: currentStrokeWidth,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: currentStrokeWidth.toStringAsFixed(0),
                    onChanged: onStrokeWidthChanged,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required DrawingTool tool,
    required String label,
  }) {
    final isSelected = currentTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(icon, color: isSelected ? Colors.white : Colors.black),
              onPressed: () => onToolChanged(tool),
              tooltip: label,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = currentColor == color;
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

