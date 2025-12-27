import 'package:flutter/material.dart';

/// 角色選擇區塊元件
class RoleSelector extends StatelessWidget {
  final bool isCoach;
  final bool isStudent;
  final ValueChanged<bool> onCoachChanged;
  final ValueChanged<bool> onStudentChanged;

  const RoleSelector({
    super.key,
    required this.isCoach,
    required this.isStudent,
    required this.onCoachChanged,
    required this.onStudentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('我的角色',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('我是教練'),
          subtitle: const Text('您可以創建訓練計劃並指導學員'),
          value: isCoach,
          onChanged: onCoachChanged,
        ),
        SwitchListTile(
          title: const Text('我是學員'),
          subtitle: const Text('您可以參加訓練並追蹤進度'),
          value: isStudent,
          onChanged: onStudentChanged,
        ),
      ],
    );
  }
}

