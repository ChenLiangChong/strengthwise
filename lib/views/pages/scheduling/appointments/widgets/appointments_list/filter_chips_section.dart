import 'package:flutter/material.dart';
import 'package:strengthwise/models/appointment_model.dart';

/// 狀態篩選器組件
class FilterChipsSection extends StatelessWidget {
  final AppointmentStatus? selectedStatus;
  final Function(AppointmentStatus?) onStatusSelected;

  const FilterChipsSection({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(context, null, '全部'),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              AppointmentStatus.requested,
              '待確認',
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              AppointmentStatus.confirmed,
              '已確認',
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              AppointmentStatus.completed,
              '已完成',
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              AppointmentStatus.cancelled,
              '已取消',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    AppointmentStatus? status,
    String label,
  ) {
    final isSelected = status == selectedStatus;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onStatusSelected(selected ? status : null);
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }
}

