// ✅ 已響應式改造 (Phase 2)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 導航項目定義
class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// 自適應導航框架
///
/// 根據螢幕尺寸自動切換導航模式：
/// - 手機 (< 720dp)：底部導航欄 [NavigationBar]
/// - 平板 (720-1023dp)：側邊導航軌 [NavigationRail]
/// - 桌面 (≥ 1024dp)：常駐側邊欄 [NavigationDrawer]
///
/// 使用範例：
/// ```dart
/// AdaptiveNavigationScaffold(
///   selectedIndex: _selectedIndex,
///   onDestinationSelected: (index) => setState(() => _selectedIndex = index),
///   destinations: [
///     NavigationItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: '首頁'),
///     NavigationItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: '我的'),
///   ],
///   body: _pages[_selectedIndex],
/// )
/// ```
class AdaptiveNavigationScaffold extends StatelessWidget {
  /// 目前選中的導航索引
  final int selectedIndex;

  /// 導航選擇回調
  final ValueChanged<int> onDestinationSelected;

  /// 導航項目列表
  final List<NavigationItem> destinations;

  /// 主要內容區域
  final Widget body;

  /// NavigationRail 是否展開顯示標籤（預設否，僅圖標）
  final bool railExtended;

  const AdaptiveNavigationScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.railExtended = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;

    // 根據螢幕類型選擇導航模式
    return switch (screenType) {
      // 手機：底部導航
      ScreenType.mobileSmall ||
      ScreenType.mobile ||
      ScreenType.mobileLarge =>
        _buildWithBottomNavigation(context),

      // 平板：側邊導航軌（僅圖標）
      ScreenType.tabletSmall ||
      ScreenType.tablet =>
        _buildWithNavigationRail(context, extended: false),

      // 大平板/桌面：側邊導航軌（帶標籤）
      ScreenType.tabletLarge ||
      ScreenType.desktop =>
        _buildWithNavigationRail(context, extended: true),
    };
  }

  /// 手機模式：底部導航欄
  Widget _buildWithBottomNavigation(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          onDestinationSelected(index);
        },
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        elevation: 3,
        destinations: destinations
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  /// 平板/桌面模式：側邊導航軌
  Widget _buildWithNavigationRail(BuildContext context,
      {bool extended = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Row(
        children: [
          // 側邊導航軌
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              HapticFeedback.selectionClick();
              onDestinationSelected(index);
            },
            extended: extended,
            minWidth: 72,
            minExtendedWidth: 160, // 縮窄：從 180 改為 160
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
            backgroundColor: colorScheme.surfaceContainerLow,
            indicatorColor: colorScheme.secondaryContainer,
            // 展開模式時顯示 Logo
            leading: extended
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'StrengthWise',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Icon(
                      Icons.fitness_center,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
            destinations: destinations
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          // 分隔線
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
          // 主要內容區域
          Expanded(child: body),
        ],
      ),
    );
  }

  /// 桌面模式：常駐側邊欄
  Widget _buildWithNavigationDrawer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Row(
        children: [
          // 常駐側邊欄
          NavigationDrawer(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              HapticFeedback.selectionClick();
              onDestinationSelected(index);
            },
            backgroundColor: colorScheme.surfaceContainerLow,
            indicatorColor: colorScheme.secondaryContainer,
            children: [
              // 頂部標題
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.md,
                  vertical: context.spacing.lg,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    SizedBox(width: context.spacing.sm),
                    Text(
                      'StrengthWise',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: colorScheme.outlineVariant),
              SizedBox(height: context.spacing.sm),
              // 導航項目
              ...destinations.map(
                (item) => NavigationDrawerDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                ),
              ),
            ],
          ),
          // 分隔線
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
          // 主要內容區域
          Expanded(child: body),
        ],
      ),
    );
  }
}
