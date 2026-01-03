import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/profile_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/auth/login_page.dart';
import 'package:strengthwise/views/pages/profile/profile_settings_page.dart';
import 'package:strengthwise/views/pages/profile/body_data_page.dart';
import 'package:strengthwise/views/pages/statistics/statistics_page_v2.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_header_card.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_detail_card.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_menu_item.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_role_switch.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_theme_switcher.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_logout_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => serviceLocator<ProfileController>()..loadUserProfile(),
      child: const _ProfilePageContent(),
    );
  }
}

class _ProfilePageContent extends StatelessWidget {
  const _ProfilePageContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final colorScheme = Theme.of(context).colorScheme;

    if (controller.isLoading && controller.userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 用戶資料卡片
            ProfileHeaderCard(
              userProfile: controller.userProfile,
              onEditProfile: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileSettingsPage(),
                  ),
                );
                controller.loadUserProfile();
              },
              onViewBodyData: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BodyDataPage(userProfile: controller.userProfile),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // 詳細資訊卡片
            if (controller.userProfile != null)
              ProfileDetailCard(userProfile: controller.userProfile!),

            const SizedBox(height: 24),

            // 功能菜單
            _buildMenuSection(context, colorScheme, controller),

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
                await controller.signOut();
                if (context.mounted) {
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
  Widget _buildMenuSection(
    BuildContext context,
    ColorScheme colorScheme,
    ProfileController controller,
  ) {
    final isCoach = controller.userProfile?.isCoach ?? false;

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
          subtitle: '開啟教練功能（課程頁面顯示教練中心）',
          value: isCoach,
          onChanged: (value) async {
            final success = await controller.toggleCoachRole(value);
            
            // 顯示提示訊息
            if (context.mounted && success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value 
                      ? '✅ 已開啟教練模式\n請到「課程」頁面進入教練中心' 
                      : '✅ 已關閉教練模式\n教練功能已隱藏'
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
