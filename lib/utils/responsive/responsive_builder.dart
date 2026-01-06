import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive_breakpoints.dart';

/// 響應式 Widget 建構器
///
/// 根據螢幕尺寸構建不同的 Widget
/// 支援手機、平板、桌面三種佈局
///
/// 使用範例：
/// ```dart
/// ResponsiveBuilder(
///   mobile: (context, constraints) => MobileLayout(),
///   tablet: (context, constraints) => TabletLayout(),
///   desktop: (context, constraints) => DesktopLayout(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  /// 手機佈局（必填，作為預設）
  final Widget Function(BuildContext context, BoxConstraints constraints)
      mobile;

  /// 平板佈局（可選）
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      tablet;

  /// 桌面佈局（可選）
  final Widget Function(BuildContext context, BoxConstraints constraints)?
      desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        if (ResponsiveBreakpoints.isDesktop(screenWidth) && desktop != null) {
          return desktop!(context, constraints);
        }

        if (ResponsiveBreakpoints.isTablet(screenWidth) && tablet != null) {
          return tablet!(context, constraints);
        }

        return mobile(context, constraints);
      },
    );
  }
}

/// 響應式條件 Widget
///
/// 根據螢幕尺寸顯示/隱藏 Widget
///
/// 使用範例：
/// ```dart
/// ResponsiveVisibility(
///   visible: ScreenType.tablet,
///   child: SideNavigation(),
/// )
/// ```
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;

  /// 在哪些螢幕類型顯示
  final List<ScreenType> visibleWhen;

  /// 在哪些螢幕類型隱藏
  final List<ScreenType> hiddenWhen;

  /// 隱藏時的替代 Widget（可選）
  final Widget? replacement;

  /// 是否維持佈局空間（使用 Visibility 而非條件渲染）
  final bool maintainSize;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleWhen = const [],
    this.hiddenWhen = const [],
    this.replacement,
    this.maintainSize = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currentType = ResponsiveBreakpoints.getScreenType(screenWidth);

    bool isVisible = true;

    if (visibleWhen.isNotEmpty) {
      isVisible = visibleWhen.contains(currentType);
    }

    if (hiddenWhen.isNotEmpty) {
      isVisible = !hiddenWhen.contains(currentType);
    }

    if (maintainSize) {
      return Visibility(
        visible: isVisible,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: child,
      );
    }

    return isVisible ? child : (replacement ?? const SizedBox.shrink());
  }
}

/// 響應式 Grid
///
/// 自動根據螢幕寬度調整列數
///
/// 使用範例：
/// ```dart
/// ResponsiveGrid(
///   mobileColumns: 1,
///   tabletColumns: 2,
///   desktopColumns: 3,
///   children: items.map((item) => ItemCard(item)).toList(),
/// )
/// ```
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;

  /// 手機列數
  final int mobileColumns;

  /// 平板列數
  final int tabletColumns;

  /// 桌面列數
  final int desktopColumns;

  /// 主軸間距
  final double mainAxisSpacing;

  /// 交叉軸間距
  final double crossAxisSpacing;

  /// 子項目長寬比（可選）
  final double? childAspectRatio;

  /// 內邊距
  final EdgeInsets padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int columns;
    if (ResponsiveBreakpoints.isDesktop(screenWidth)) {
      columns = desktopColumns;
    } else if (ResponsiveBreakpoints.isTablet(screenWidth)) {
      columns = tabletColumns;
    } else {
      columns = mobileColumns;
    }

    return Padding(
      padding: padding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio ?? 1,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// 響應式容器
///
/// 自動限制最大寬度並置中內容
///
/// 使用範例：
/// ```dart
/// ResponsiveContainer(
///   child: MyContent(),
/// )
/// ```
class ResponsiveContainer extends StatelessWidget {
  final Widget child;

  /// 最大寬度（預設 1200dp）
  final double maxWidth;

  /// 內邊距
  final EdgeInsets padding;

  /// 是否置中
  final bool center;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

