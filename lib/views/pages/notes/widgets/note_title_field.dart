import 'package:flutter/material.dart';

/// 筆記標題輸入框元件
class NoteTitleField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const NoteTitleField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: '標題',
          border: OutlineInputBorder(),
        ),
        enabled: enabled,
      ),
    );
  }
}

