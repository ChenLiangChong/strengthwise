import 'package:flutter/material.dart';
import '../services/interfaces/i_auth_service.dart';
import '../services/service_locator.dart';
import 'login_page.dart';
import 'pages/home_page.dart';
import 'pages/booking_page.dart';
import 'pages/records_page.dart';
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
      // 記錄頁面
      const RecordsPage(),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '首頁',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: '預約',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: '訓練',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.note_alt),
              label: '記錄',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '我的',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
} 