import 'package:flutter/material.dart';
import '../../../../models/workout_template_model.dart';
import 'template_card.dart';

/// 模板列表元件
class TemplateList extends StatelessWidget {
  final List<WorkoutTemplate> templates;
  final Function(WorkoutTemplate) onTemplateTap;
  final Function(WorkoutTemplate) onMoreMenu;
  final Function(WorkoutTemplate) onCreateToday;
  final Function(WorkoutTemplate) onCreateScheduled;

  const TemplateList({
    super.key,
    required this.templates,
    required this.onTemplateTap,
    required this.onMoreMenu,
    required this.onCreateToday,
    required this.onCreateScheduled,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 96, // 增加底部填充，避免被 FAB 遮擋
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return TemplateCard(
          template: template,
          onTap: () => onTemplateTap(template),
          onMoreMenu: () => onMoreMenu(template),
          onCreateToday: () => onCreateToday(template),
          onCreateScheduled: () => onCreateScheduled(template),
        );
      },
    );
  }
}

