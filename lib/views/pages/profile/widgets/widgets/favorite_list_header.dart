import 'package:flutter/material.dart';

/// 收藏列表標題組件
class FavoriteListHeader extends StatelessWidget {
  final VoidCallback onManageTap;

  const FavoriteListHeader({
    Key? key,
    required this.onManageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          const Text(
            '我的收藏動作',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: onManageTap,
            icon: const Icon(Icons.settings, size: 20),
            tooltip: '管理收藏',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

