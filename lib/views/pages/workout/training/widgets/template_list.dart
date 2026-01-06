// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/models/workout_template_model.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'template_card.dart';

/// 模板列表元件
///
/// 響應式設計：
/// - 小螢幕：單欄列表
/// - 平板/桌面：雙欄網格
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
    final columns = context.listColumns;
    final padding = context.pagePadding;

    // 大螢幕使用網格佈局
    if (columns > 1) {
      return GridView.builder(
        padding: padding.copyWith(bottom: 96),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: context.spacing.md,
          mainAxisSpacing: context.spacing.md,
          childAspectRatio: 1.6, // 卡片寬高比
        ),
        itemCount: templates.length,
        itemBuilder: (context, index) => _buildCard(templates[index]),
      );
    }

    // 小螢幕使用列表佈局
    return ListView.builder(
      padding: padding.copyWith(bottom: 96),
      itemCount: templates.length,
      itemBuilder: (context, index) => _buildCard(templates[index]),
    );
  }

  Widget _buildCard(WorkoutTemplate template) {
    return TemplateCard(
      template: template,
      onTap: () => onTemplateTap(template),
      onMoreMenu: () => onMoreMenu(template),
      onCreateToday: () => onCreateToday(template),
      onCreateScheduled: () => onCreateScheduled(template),
    );
  }
}
