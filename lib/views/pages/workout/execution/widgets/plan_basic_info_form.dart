import 'package:flutter/material.dart';

/// 計劃基本信息表單
class PlanBasicInfoForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String? selectedPlanType;
  final List<String> planTypes;
  final ValueChanged<String?> onPlanTypeChanged;

  const PlanBasicInfoForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.selectedPlanType,
    required this.planTypes,
    required this.onPlanTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '計畫名稱',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: '訓練類型',
            border: OutlineInputBorder(),
          ),
          value: selectedPlanType,
          items: planTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: onPlanTypeChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: '計畫描述（可選）',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}

