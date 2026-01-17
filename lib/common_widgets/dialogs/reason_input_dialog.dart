import 'package:flutter/material.dart';

/// ⭐ v3.9: 通用原因輸入對話框
/// 正確管理 TextEditingController 生命週期，避免 dispose 後被使用
class ReasonInputDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final String cancelText;
  final String confirmText;
  final Color? confirmColor;

  const ReasonInputDialog({
    super.key,
    required this.title,
    required this.hintText,
    this.cancelText = '取消',
    this.confirmText = '確定',
    this.confirmColor,
  });

  /// 顯示對話框並返回輸入的原因
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String hintText,
    String cancelText = '取消',
    String confirmText = '確定',
    Color? confirmColor,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReasonInputDialog(
        title: title,
        hintText: hintText,
        cancelText: cancelText,
        confirmText: confirmText,
        confirmColor: confirmColor,
      ),
    );
  }

  @override
  State<ReasonInputDialog> createState() => _ReasonInputDialogState();
}

class _ReasonInputDialogState extends State<ReasonInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final confirmColor = widget.confirmColor ?? Theme.of(context).colorScheme.error;
    
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('請說明原因：'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(widget.cancelText),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _controller.text.trim()),
          style: FilledButton.styleFrom(
            backgroundColor: confirmColor,
          ),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
