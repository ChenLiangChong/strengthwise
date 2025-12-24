import 'package:flutter/material.dart';
import '../services/interfaces/i_auth_service.dart';
import '../services/service_locator.dart';
import 'login_page.dart';
import 'pages/home_page.dart';
import 'pages/booking_page.dart';
// import 'pages/records_page.dart'; // 教練-學員版本功能：訓練記錄（暫時隱藏）
import 'pages/profile_page.dart';
import 'pages/training_page.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _selectedIndex = 0;
  late final IAuthService _authService;
  
  // 不同頁面的Widget
  late final List<Widget> _widgetOptions;
  
  @override
  void initState() {
    super.initState();
    
    // 從服務定位器獲取認證服務
    _authService = serviceLocator<IAuthService>();
    
    _widgetOptions = <Widget>[
      // 首頁
      const HomePage(),
      // 預約頁面
      const BookingPage(),
      // 動作庫頁面改為訓練頁面
      const TrainingPage(),
      // 記錄頁面（教練-學員版本功能，暫時隱藏）
      // const RecordsPage(),
      // 個人頁面
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 檢查用戶是否已登入
    final userData = _authService.getCurrentUser();
    if (userData == null) {
      return const LoginPage();
    }
    
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首頁',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: '預約',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: '訓練',
          ),
          // 教練-學員版本功能：訓練記錄（暫時隱藏）
          // NavigationDestination(
          //   icon: Icon(Icons.note_alt_outlined),
          //   selectedIcon: Icon(Icons.note_alt),
          //   label: '記錄',
          // ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
} 