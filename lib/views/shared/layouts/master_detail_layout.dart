// ✅ P3 響應式分欄佈局
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// Master-Detail 分欄佈局
///
/// 根據螢幕尺寸自動切換：
/// - 手機 (<720dp)：只顯示 master，detail 透過 Push 進入
/// - 平板/桌面 (≥720dp)：左右分欄顯示
///
/// 使用範例：
/// ```dart
/// MasterDetailLayout(
///   master: ListView(...),
///   detail: selectedItem != null
///       ? DetailPage(item: selectedItem)
///       : EmptyDetailState(),
///   masterWidth: 350,
/// )
/// ```
class MasterDetailLayout extends StatelessWidget {
  /// 左側列表區域（Master）
  final Widget master;

  /// 右側詳情區域（Detail）
  /// null 時顯示空狀態提示
  final Widget? detail;

  /// 左側列表寬度（僅平板/桌面模式生效）
  final double masterWidth;

  /// 分隔線顏色
  final Color? dividerColor;

  /// 空詳情狀態時顯示的 Widget
  final Widget? emptyDetailState;

  const MasterDetailLayout({
    super.key,
    required this.master,
    this.detail,
    this.masterWidth = 350,
    this.dividerColor,
    this.emptyDetailState,
  });

  @override
  Widget build(BuildContext context) {
    // 手機模式：只顯示 master
    if (context.isMobile) {
      return master;
    }

    // 平板/桌面模式：左右分欄
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // 左側：Master 列表
        SizedBox(
          width: masterWidth,
          child: master,
        ),

        // 分隔線
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: dividerColor ?? colorScheme.outlineVariant,
        ),

        // 右側：Detail 詳情
        Expanded(
          child: detail ?? _buildEmptyState(context),
        ),
      ],
    );
  }

  /// 空詳情狀態
  Widget _buildEmptyState(BuildContext context) {
    if (emptyDetailState != null) {
      return emptyDetailState!;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '選擇一個項目查看詳情',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
