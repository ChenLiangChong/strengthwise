import 'package:flutter/material.dart';
import 'selection_empty_state.dart';
import 'selection_header.dart';

/// 選擇列表組件
class SelectionList extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String> items;
  final Function(String) onSelect;

  const SelectionList({
    Key? key,
    required this.title,
    this.subtitle,
    required this.items,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SelectionEmptyState(subtitle: subtitle);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (title.isNotEmpty) ...[
          SelectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 16),
        ],
        ...items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onSelect(item),
              ),
            )),
      ],
    );
  }
}

