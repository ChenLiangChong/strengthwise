import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// 時間輸入欄位（分:秒 雙欄位模式）
/// 
/// 左邊輸入分鐘，右邊輸入秒數，內部儲存為秒數（int）。
/// 
/// 使用方式：
/// ```dart
/// TimeInputField(
///   value: 90,  // 秒數
///   onChanged: (seconds) => print('新值: $seconds 秒'),
///   enabled: true,
/// )
/// ```
class TimeInputField extends StatefulWidget {
  /// 當前時間值（秒）
  final int? value;

  /// 值變更回調
  final ValueChanged<int?> onChanged;

  /// 是否啟用
  final bool enabled;

  /// 是否已完成（用於訓練執行頁面）
  final bool isCompleted;

  /// 標籤文字（用於 Dialog 中）
  final String? labelText;

  /// 是否使用 OutlineInputBorder（Dialog 樣式）
  final bool useOutlineBorder;

  /// 最小寬度
  final double? minWidth;

  /// FocusNode（可選）
  final FocusNode? focusNode;

  const TimeInputField({
    super.key,
    this.value,
    required this.onChanged,
    this.enabled = true,
    this.isCompleted = false,
    this.labelText,
    this.useOutlineBorder = false,
    this.minWidth,
    this.focusNode,
  });

  @override
  State<TimeInputField> createState() => _TimeInputFieldState();
}

class _TimeInputFieldState extends State<TimeInputField> {
  late TextEditingController _minutesController;
  late TextEditingController _secondsController;
  late FocusNode _minutesFocusNode;
  late FocusNode _secondsFocusNode;

  @override
  void initState() {
    super.initState();
    _minutesFocusNode = widget.focusNode ?? FocusNode();
    _secondsFocusNode = FocusNode();
    _initControllers();
    
    _minutesFocusNode.addListener(_onFocusChange);
    _secondsFocusNode.addListener(_onFocusChange);
  }

  void _initControllers() {
    final totalSeconds = widget.value ?? 0;
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    _minutesController = TextEditingController(text: mins > 0 ? mins.toString() : '');
    _secondsController = TextEditingController(text: secs > 0 || mins > 0 ? secs.toString().padLeft(2, '0') : '');
  }

  @override
  void didUpdateWidget(TimeInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只在非焦點狀態下更新
    if (widget.value != oldWidget.value && 
        !_minutesFocusNode.hasFocus && 
        !_secondsFocusNode.hasFocus) {
      final totalSeconds = widget.value ?? 0;
      final mins = totalSeconds ~/ 60;
      final secs = totalSeconds % 60;
      _minutesController.text = mins > 0 ? mins.toString() : '';
      _secondsController.text = secs > 0 || mins > 0 ? secs.toString().padLeft(2, '0') : '';
    }
  }

  @override
  void dispose() {
    _minutesFocusNode.removeListener(_onFocusChange);
    _secondsFocusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _minutesFocusNode.dispose();
    }
    _secondsFocusNode.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // 當離開欄位時，格式化秒數為兩位數
    if (!_secondsFocusNode.hasFocus && _secondsController.text.isNotEmpty) {
      final secs = int.tryParse(_secondsController.text) ?? 0;
      // 秒數超過 59 時，自動進位到分鐘
      if (secs >= 60) {
        final extraMins = secs ~/ 60;
        final remainingSecs = secs % 60;
        final currentMins = int.tryParse(_minutesController.text) ?? 0;
        _minutesController.text = (currentMins + extraMins).toString();
        _secondsController.text = remainingSecs.toString().padLeft(2, '0');
        _notifyChange();
      } else {
        _secondsController.text = secs.toString().padLeft(2, '0');
      }
    }
  }

  void _notifyChange() {
    final mins = int.tryParse(_minutesController.text) ?? 0;
    final secs = int.tryParse(_secondsController.text) ?? 0;
    final totalSeconds = mins * 60 + secs;
    widget.onChanged(totalSeconds > 0 ? totalSeconds : null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Dialog 樣式（有邊框和標籤）
    if (widget.useOutlineBorder) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.labelText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.labelText!,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minutesController,
                  focusNode: _minutesFocusNode,
                  enabled: widget.enabled,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: '分',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3), // 最大 999 分鐘
                  ],
                  onChanged: (_) => _notifyChange(),
                  onSubmitted: (_) => _secondsFocusNode.requestFocus(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ':',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _secondsController,
                  focusNode: _secondsFocusNode,
                  enabled: widget.enabled,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '00',
                    suffixText: '秒',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  onChanged: (_) => _notifyChange(),
                ),
              ),
            ],
          ),
          // 顯示總秒數提示
          if (widget.value != null && widget.value! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '共 ${widget.value} 秒',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),
        ],
      );
    }

    // 內聯樣式（訓練執行頁面）- 完全仿照 _buildNumberInput 樣式
    // 分鐘和秒數各自獨立的輸入框，中間用冒號分隔
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = widget.isCompleted
        ? colorScheme.onSurface.withOpacity(0.5)
        : colorScheme.onSurface;
    final fillColor = widget.enabled
        ? (isDarkMode
            ? colorScheme.surface.withOpacity(0.5)
            : colorScheme.surface)
        : colorScheme.surface.withOpacity(0.3);

    final inputDecoration = InputDecoration(
      hintStyle: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        color: colorScheme.onSurface.withOpacity(0.3),
      ),
      filled: true,
      fillColor: fillColor,
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
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    );

    final textStyle = GoogleFonts.jetBrainsMono(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: textColor,
    );

    return Row(
      children: [
        // 分鐘輸入框
        Expanded(
          child: TextField(
            controller: _minutesController,
            focusNode: _minutesFocusNode,
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            style: textStyle,
            decoration: inputDecoration.copyWith(hintText: '0'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3), // 最大 999 分鐘
            ],
            onChanged: (_) => _notifyChange(),
            onSubmitted: (_) => _secondsFocusNode.requestFocus(),
          ),
        ),
        // 冒號
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            ':',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        // 秒數輸入框
        Expanded(
          child: TextField(
            controller: _secondsController,
            focusNode: _secondsFocusNode,
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            style: textStyle,
            decoration: inputDecoration.copyWith(hintText: '00'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (_) => _notifyChange(),
          ),
        ),
      ],
    );
  }
}

/// 時間輸入工具類
/// 
/// 提供時間格式化和解析的靜態方法
class TimeInputUtils {
  TimeInputUtils._();

  /// 將秒數格式化為 mm:ss 字串
  static String formatSeconds(int? seconds) {
    if (seconds == null || seconds <= 0) return '0:00';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// 將秒數格式化為人類可讀的時間字串
  /// 
  /// 例如：90 → "1 分 30 秒"，30 → "30 秒"
  static String formatSecondsReadable(int? seconds) {
    if (seconds == null || seconds <= 0) return '0 秒';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins == 0) return '$secs 秒';
    if (secs == 0) return '$mins 分';
    return '$mins 分 $secs 秒';
  }

  /// 解析時間字串為秒數
  /// 
  /// 支援格式：
  /// - "90" → 90 秒
  /// - "1:30" → 90 秒
  /// - "01:30" → 90 秒
  static int? parseTimeString(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length == 2) {
        final mins = int.tryParse(parts[0]) ?? 0;
        final secs = int.tryParse(parts[1]) ?? 0;
        return mins * 60 + secs;
      }
    }

    return int.tryParse(trimmed);
  }
}
