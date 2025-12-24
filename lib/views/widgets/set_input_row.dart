import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../themes/app_theme.dart';

/// 訓練組數輸入列
/// 
/// 用於輸入每組的重量和次數，並標記完成狀態
/// 整合 JetBrains Mono 字體以確保數字對齊
class SetInputRow extends StatefulWidget {
  /// 組數序號（1, 2, 3...）
  final int setNumber;
  
  /// 當前重量值（kg）
  final double? weight;
  
  /// 當前次數值
  final int? reps;
  
  /// 上一組的參考數據（用於顯示）
  final String? previousData;
  
  /// 是否已完成
  final bool isCompleted;
  
  /// 是否為當前活動組（高亮顯示）
  final bool isActive;
  
  /// 是否可編輯（過去的訓練不可編輯）
  final bool isEditable;
  
  /// 數據更新回調
  final Function(double? weight, int? reps) onUpdate;
  
  /// 完成狀態切換回調
  final VoidCallback onComplete;

  const SetInputRow({
    required this.setNumber,
    this.weight,
    this.reps,
    this.previousData,
    this.isCompleted = false,
    this.isActive = false,
    this.isEditable = true,
    required this.onUpdate,
    required this.onComplete,
    super.key,
  });

  @override
  State<SetInputRow> createState() => _SetInputRowState();
}

class _SetInputRowState extends State<SetInputRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late FocusNode _weightFocusNode;
  late FocusNode _repsFocusNode;

  @override
  void initState() {
    super.initState();
    
    // 初始化控制器
    _weightController = TextEditingController(
      text: widget.weight != null 
          ? _formatNumber(widget.weight!) 
          : '',
    );
    _repsController = TextEditingController(
      text: widget.reps?.toString() ?? '',
    );
    
    // 初始化焦點節點
    _weightFocusNode = FocusNode();
    _repsFocusNode = FocusNode();
  }
  
  @override
  void didUpdateWidget(SetInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 當外部數據更新時，同步更新控制器
    // 只有當值真的改變且當前輸入框沒有焦點時才更新
    if (widget.weight != oldWidget.weight && !_weightFocusNode.hasFocus) {
      _weightController.text = widget.weight != null 
          ? _formatNumber(widget.weight!) 
          : '';
    }
    if (widget.reps != oldWidget.reps && !_repsFocusNode.hasFocus) {
      _repsController.text = widget.reps?.toString() ?? '';
    }
  }
  
  /// 格式化數字，移除不必要的小數點和零
  String _formatNumber(double value) {
    // 如果是整數，直接返回整數字符串
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    // 如果有小數，保留最多 2 位小數，並移除尾部的 0
    return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _weightFocusNode.dispose();
    _repsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditable = widget.isEditable && !widget.isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          // ========================================
          // 組數序號（佔 15%）
          // ========================================
          SizedBox(
            width: 40,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? colorScheme.primary.withOpacity(0.1)
                      : colorScheme.surface,
                  shape: BoxShape.circle,
                  border: widget.isActive
                      ? Border.all(color: colorScheme.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${widget.setNumber}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14,
                      fontWeight: widget.isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: widget.isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(
                              widget.isCompleted ? 0.4 : 0.7,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingSm),
          
          // ========================================
          // 上一組參考數據（佔 20%）
          // ========================================
          if (widget.previousData != null) ...[
            SizedBox(
              width: 60,
              child: Center(
                child: Text(
                  widget.previousData!,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.4),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
          ],
          
          // ========================================
          // 重量輸入框（佔 25%）
          // ========================================
          Expanded(
            flex: 3,
            child: _buildNumberInput(
              controller: _weightController,
              focusNode: _weightFocusNode,
              hintText: 'kg',
              enabled: isEditable,
              isCompleted: widget.isCompleted,
              onChanged: (value) {
                widget.onUpdate(
                  double.tryParse(value),
                  int.tryParse(_repsController.text),
                );
              },
              onSubmitted: (_) {
                // 按下 Enter 後跳到次數輸入框
                FocusScope.of(context).requestFocus(_repsFocusNode);
              },
              textInputAction: TextInputAction.next,
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingSm),
          
          // ========================================
          // 次數輸入框（佔 25%）
          // ========================================
          Expanded(
            flex: 3,
            child: _buildNumberInput(
              controller: _repsController,
              focusNode: _repsFocusNode,
              hintText: 'reps',
              enabled: isEditable,
              isCompleted: widget.isCompleted,
              onChanged: (value) {
                widget.onUpdate(
                  double.tryParse(_weightController.text),
                  int.tryParse(value),
                );
              },
              onSubmitted: (_) {
                // 按下 Enter 後收起鍵盤
                FocusScope.of(context).unfocus();
              },
              textInputAction: TextInputAction.done,
            ),
          ),
          
          const SizedBox(width: AppTheme.spacingSm),
          
          // ========================================
          // 完成勾選按鈕（佔 15%）
          // ========================================
          SizedBox(
            width: 40,
            height: AppTheme.minTouchTarget,
            child: Center(
              child: GestureDetector(
                onTap: widget.isEditable
                    ? () {
                        // 觸覺回饋
                        HapticFeedback.mediumImpact();
                        widget.onComplete();
                      }
                    : null,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.isCompleted
                        ? const Color(0xFF10B981) // Success 綠色
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: widget.isCompleted
                        ? null
                        : Border.all(
                            color: colorScheme.outline,
                            width: 2,
                          ),
                  ),
                  child: widget.isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 構建數字輸入框
  Widget _buildNumberInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required bool enabled,
    required bool isCompleted,
    required Function(String) onChanged,
    required Function(String) onSubmitted,
    required TextInputAction textInputAction,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      textInputAction: textInputAction,
      inputFormatters: [
        // 只允許數字和小數點
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: GoogleFonts.jetBrainsMono(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: isCompleted
            ? colorScheme.onSurface.withOpacity(0.5)
            : colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.3),
        ),
        filled: true,
        fillColor: enabled
            ? (AppTheme.isDarkMode(context)
                ? colorScheme.surface.withOpacity(0.5)
                : colorScheme.surface)
            : colorScheme.surface.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 8,
        ),
      ),
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
  }
}

