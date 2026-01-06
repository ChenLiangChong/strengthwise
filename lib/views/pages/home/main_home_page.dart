// ✅ 已響應式改造 (Phase 2)
import 'package:flutter/material.dart';
import 'package:strengthwise/views/pages/home/home_page.dart';
import 'package:strengthwise/views/pages/scheduling/booking/booking_page.dart';
import 'package:strengthwise/views/pages/profile/profile_page.dart';
import 'package:strengthwise/views/pages/workout/training/training_page.dart';
import 'package:strengthwise/views/pages/relationships/hub/training_hub_page.dart';
import 'package:strengthwise/views/shared/navigation/adaptive_navigation_scaffold.dart';

/// 主頁面 - 包含底部/側邊自適應導航
///
/// 根據螢幕尺寸自動切換導航模式：
/// - 手機 (< 720dp)：底部導航欄
/// - 平板 (720-1023dp)：側邊導航軌（僅圖標）
/// - 桌面 (≥ 1024dp)：常駐側邊欄（圖標+文字）
class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _selectedIndex = 0;

  /// 導航項目定義
  static const List<NavigationItem> _destinations = [
    NavigationItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: '首頁',
    ),
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      label: '行事曆',
    ),
    NavigationItem(
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
      label: '訓練',
    ),
    NavigationItem(
      icon: Icons.hub_outlined,
      selectedIcon: Icons.hub,
      label: '課程',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: '我的',
    ),
  ];

  /// 頁面列表（使用 IndexedStack 保持狀態）
  static const List<Widget> _pages = [
    HomePage(),
    BookingPage(),
    TrainingPage(),
    TrainingHubPage(),
    ProfilePage(),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      destinations: _destinations,
      // 使用 IndexedStack 保持所有頁面狀態
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }
}
