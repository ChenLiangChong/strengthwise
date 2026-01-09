// ✅ 已響應式改造 (Phase 0)
// ⭐ v3.2: 移除 Carousel，Coach Mark 在各子頁面觸發
import 'package:flutter/material.dart';
import 'package:strengthwise/views/pages/relationships/role_coach/coach_hub_page.dart';
import 'package:strengthwise/views/pages/relationships/role_client/client_hub_page.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/controllers/profile_controller.dart';
import 'package:strengthwise/services/service_locator.dart';

/// 訓練中心 Hub 頁面
///
/// 統一入口，導向：
/// 1. 教練中心（有教練身份）
/// 2. 學員中心（所有人都有）
///
/// ⭐ v3.1-B 修復：改用 serviceLocator + ListenableBuilder，
/// 避免 ProviderNotFoundException
class TrainingHubPage extends StatefulWidget {
  const TrainingHubPage({super.key});

  @override
  State<TrainingHubPage> createState() => _TrainingHubPageState();
}

class _TrainingHubPageState extends State<TrainingHubPage> {
  late final ProfileController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<ProfileController>();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await _controller.loadUserProfile();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final isCoach = _controller.userProfile?.isCoach ?? false;
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('訓練中心'),
            automaticallyImplyLeading: false, // 不顯示返回箭頭
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Padding(
                    padding: context.pagePadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        // 標題說明
                        Text(
                          '選擇功能',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '根據您的角色進入對應功能',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                        const SizedBox(height: 48),

                        // 教練中心入口（有教練身份）
                        if (isCoach) ...[
                          _buildHubCard(
                            context: context,
                            title: '教練中心',
                            subtitle: '學員管理、時段設定、預約管理',
                            icon: Icons.business_center,
                            color: Colors.blue,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CoachHubPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 學員中心入口（所有人都有）
                        _buildHubCard(
                          context: context,
                          title: '學員中心',
                          subtitle: '我的教練、預約課程、課程筆記',
                          icon: Icons.school,
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClientHubPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 48),

                        // 提示訊息
                        if (!isCoach)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '想要啟用教練功能？\n請到「設定」中開啟教練模式',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.8),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 構建功能卡片
  Widget _buildHubCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 圖示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),

              // 文字
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),

              // 箭頭
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
