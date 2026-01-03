import 'package:flutter/material.dart';
import '../../../utils/notification_utils.dart';

/// 查看更多按鈕組件
class FavoriteViewMoreButton extends StatelessWidget {
  final VoidCallback? onTap;

  const FavoriteViewMoreButton({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            if (onTap != null) {
              onTap!();
            } else {
              NotificationUtils.showWarning(context, '請設置 onAddMoreTap 回調');
            }
          },
          icon: const Icon(Icons.search),
          label: const Text('查看更多動作記錄'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

