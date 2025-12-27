import 'package:flutter/material.dart';

/// 生日選擇器元件
class BirthdayPicker extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  const BirthdayPicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ??
              DateTime.now().subtract(const Duration(days: 365 * 25)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          helpText: '選擇生日',
          cancelText: '取消',
          confirmText: '確定',
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '生日',
          border: OutlineInputBorder(),
          helperText: '可選',
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate != null
              ? '${selectedDate!.year}年${selectedDate!.month}月${selectedDate!.day}日'
              : '點擊選擇生日',
          style: TextStyle(
            color: selectedDate != null
                ? Colors.black
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

