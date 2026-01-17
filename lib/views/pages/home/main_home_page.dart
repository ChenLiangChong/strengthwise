// ✅ 已響應式改造 (Phase 2)
// ⚡ v3.1.1: LazyIndexedStack 優化啟動速度
// ⭐ v3.2: 移除 Carousel，改用 Coach Mark + CurrentPageProvider
import 'package:flutter/material.dart';
import 'package:strengthwise/views/pages/home/home_page.dart';
import 'package:strengthwise/views/pages/scheduling/booking/booking_page.dart';
import 'package:strengthwise/views/pages/profile/profile_page.dart';
import 'package:strengthwise/views/pages/workout/training/training_page.dart';
import 'package:strengthwise/views/pages/relationships/hub/training_hub_page.dart';
import 'package:strengthwise/views/shared/navigation/adaptive_navigation_scaffold.dart';
import 'package:strengthwise/views/widgets/lazy_indexed_stack.dart';
import 'package:strengthwise/views/widgets/current_page_provider.dart';

/// 主頁面 - 包含底部/側邊自適應導航
///
/// 根據螢幕尺寸自動切換導航模式：
/// - 手機 (< 720dp)：底部導航欄
/// - 平板 (720-1023dp)：側邊導航軌（僅圖標）
/// - 桌面 (≥ 1024dp)：常駐側邊欄（圖標+文字）
class MainHomePage extends StatefulWidget {
  /// 初始 Tab 索引（用於通知點擊導航）
  /// - 0: 首頁
  /// - 1: 行事曆
  /// - 2: 訓練
  /// - 3: 課程
  /// - 4: 我的
  final int initialIndex;
  
  /// ⭐ v3.9: 行事曆內部 Tab 索引
  /// - 0: 🎓 我的（個人行事曆）
  /// - 1: 🏋️ 教練（教練身份）
  final int bookingTabIndex;
  
  const MainHomePage({
    super.key,
    this.initialIndex = 0,
    this.bookingTabIndex = 0,
  });

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  late int _selectedIndex;

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
  /// ⭐ v3.9: 使用 late final 確保只創建一次
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    
    // ⭐ v3.9: 在 initState 中初始化頁面列表，確保只創建一次
    _pages = [
      const HomePage(),
      BookingPage(initialTabIndex: widget.bookingTabIndex),
      const TrainingPage(),
      const TrainingHubPage(),
      const ProfilePage(),
    ];
  }

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
      // ⭐ v3.2: 使用 CurrentPageProvider 傳遞當前頁面索引
      // 讓子頁面知道自己是否是當前顯示的頁面（用於 Coach Mark 觸發控制）
      body: CurrentPageProvider(
        currentIndex: _selectedIndex,
        // ⚡ v3.1.1: 使用 LazyIndexedStack 延遲初始化
        // 只初始化當前頁面，其他頁面等用戶切換時才載入
        // 大幅減少首次進入主頁面的載入時間
        child: LazyIndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
    );
  }
}
