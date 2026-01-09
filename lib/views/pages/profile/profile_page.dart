// ✅ 已響應式改造 (Phase 0)
// ⭐ v3.2: 重置功能引導
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/profile_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/core/onboarding_service.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/auth/login_page.dart';
import 'package:strengthwise/views/pages/profile/profile_settings_page.dart';
import 'package:strengthwise/views/pages/profile/body_data_page.dart';
import 'package:strengthwise/views/pages/profile/coach_profile_view_page.dart';
import 'package:strengthwise/views/pages/statistics/statistics_page_v2.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_header_card.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_detail_card.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_menu_item.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_theme_switcher.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_logout_button.dart';

/// 個人檔案頁面
///
/// 響應式設計：子組件已適配多尺寸螢幕
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ⭐ v3.2 修復：使用 .value 避免自動 dispose 單例 controller
    return ChangeNotifierProvider.value(
      value: serviceLocator<ProfileController>()..loadUserProfile(),
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
    final padding = context.pagePadding;

    if (controller.isLoading && controller.userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: padding,
        child: Center(
          // 大螢幕限制最大寬度
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
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

                SizedBox(height: context.spacing.lg),

                // 詳細資訊卡片
                if (controller.userProfile != null)
                  ProfileDetailCard(userProfile: controller.userProfile!),

                // ⭐ v2.9: 教練公開檔案入口（僅教練可見）
                if (controller.userProfile?.isCoach == true) ...[
                  SizedBox(height: context.spacing.md),
                  _buildCoachProfileCard(context, colorScheme),
                ],

                SizedBox(height: context.spacing.lg),

                // 功能菜單
                _buildMenuSection(context, colorScheme, controller),

                SizedBox(height: context.spacing.lg),

                // 主題切換
                Card(
                  child: Padding(
                    padding: context.cardPadding,
                    child: const ProfileThemeSwitcher(),
                  ),
                ),

                SizedBox(height: context.spacing.lg),

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
        ),
      ),
    );
  }

  /// ⭐ v2.9: 教練公開檔案入口卡片
  Widget _buildCoachProfileCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.badge_outlined,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: const Text('教練公開檔案'),
        subtitle: const Text('查看您的專業資訊'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CoachProfileViewPage(isOwner: true),
            ),
          );
        },
      ),
    );
  }

  /// 功能菜單區塊
  Widget _buildMenuSection(
    BuildContext context,
    ColorScheme colorScheme,
    ProfileController controller,
  ) {
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
        
        // ⭐ v3.2: 重置功能引導
        ProfileMenuItem(
          icon: Icons.refresh,
          iconColor: colorScheme.tertiary,
          title: '重置功能引導',
          subtitle: '重新顯示功能介紹提示',
          onTap: () => _resetOnboarding(context),
        ),
      ],
    );
  }

  /// ⭐ v3.2: 重置功能引導（Coach Mark）
  Future<void> _resetOnboarding(BuildContext context) async {
    // 確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置功能引導'),
        content: const Text('確定要重置所有功能引導嗎？\n下次進入各頁面時會重新顯示提示。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('重置'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final onboardingService = serviceLocator<OnboardingService>();
      await onboardingService.initialize();
      await onboardingService.resetAllCoachMarks();
      
      if (context.mounted) {
        NotificationUtils.showSuccess(context, '功能引導已重置');
      }
    } catch (e) {
      if (context.mounted) {
        NotificationUtils.showError(context, '重置失敗');
      }
    }
  }
}
