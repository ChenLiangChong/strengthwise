import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/interfaces/i_auth_service.dart';
import '../../../services/interfaces/i_user_service.dart';
import '../../../services/service_locator.dart';
import '../../login_page.dart';
import 'profile_settings_page.dart';
import 'body_data_page.dart';
import '../statistics/statistics_page_v2.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_detail_card.dart';
import 'widgets/profile_menu_item.dart';
import 'widgets/profile_role_switch.dart';
import 'widgets/profile_theme_switcher.dart';
import 'widgets/profile_logout_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final IUserService _userService;
  late final IAuthService _authService;

  UserModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 從服務定位器獲取服務
    _userService = serviceLocator<IUserService>();
    _authService = serviceLocator<IAuthService>();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final userProfile = await _userService.getCurrentUserProfile();

    if (userProfile != null && mounted) {
      setState(() {
        _userProfile = userProfile;
      });
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 用戶資料卡片
            ProfileHeaderCard(
              userProfile: _userProfile,
              onEditProfile: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsPage(),
                  ),
                );
                _loadUserProfile();
              },
              onViewBodyData: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BodyDataPage(userProfile: _userProfile),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // 詳細資訊卡片
            if (_userProfile != null) ProfileDetailCard(userProfile: _userProfile!),

            const SizedBox(height: 24),
            
            // 功能菜單
            _buildMenuSection(context, colorScheme),

            const SizedBox(height: 24),

            // 主題切換
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: ProfileThemeSwitcher(),
              ),
            ),

            const SizedBox(height: 24),

            // 登出按鈕
            ProfileLogoutButton(
              onLogout: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }


  /// 功能菜單區塊
  Widget _buildMenuSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        // 我的統計
        ProfileMenuItem(
          icon: Icons.bar_chart,
          iconColor: colorScheme.primary,
          title: '我的統計',
          subtitle: '訓練數據與身體數據分析',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StatisticsPageV2(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        // 教練模式切換
        ProfileRoleSwitch(
          title: '教練模式',
          subtitle: '開啟教練功能',
          value: _userProfile?.isCoach ?? false,
          onChanged: (value) async {
            await _userService.toggleUserRole(value);
            _loadUserProfile();
          },
        ),
      ],
    );
  }
}
