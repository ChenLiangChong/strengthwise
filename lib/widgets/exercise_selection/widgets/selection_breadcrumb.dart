import 'package:flutter/material.dart';

/// 選擇導航麵包屑組件
class SelectionBreadcrumb extends StatelessWidget {
  final String breadcrumbText;
  final VoidCallback onBack;

  const SelectionBreadcrumb({
    Key? key,
    required this.breadcrumbText,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
            iconSize: 20,
          ),
          Expanded(
            child: Text(
              breadcrumbText,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

