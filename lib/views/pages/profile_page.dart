import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/interfaces/i_auth_service.dart';
import '../../services/interfaces/i_user_service.dart';
import '../../services/service_locator.dart';
import '../../controllers/theme_controller.dart';
import '../login_page.dart';
import 'profile_settings_page.dart';
import 'profile/body_data_page.dart';
import 'statistics_page_v2.dart';

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
            // 🆕 優化後的用戶資料卡片
            _buildProfileHeader(context, colorScheme),

            const SizedBox(height: 24),

            // 🆕 詳細資訊卡片（重新設計）
            if (_userProfile != null) _buildDetailedInfoCard(context, colorScheme),

            const SizedBox(height: 24),
            
            // 功能菜單
            _buildMenuSection(context, colorScheme),

            const SizedBox(height: 24),

            // 主題切換
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildThemeSwitcher(context),
              ),
            ),

            const SizedBox(height: 24),

            // 登出按鈕
            _buildLogoutButton(context, colorScheme),
          ],
        ),
      ),
    );
  }

  /// 🆕 優化後的個人資料卡片頭部
  Widget _buildProfileHeader(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                // 🆕 大頭像（80x80）
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: colorScheme.surfaceVariant,
                      backgroundImage: _userProfile?.photoURL != null
                          ? NetworkImage(_userProfile!.photoURL!)
                          : null,
                      child: _userProfile?.photoURL == null
                          ? Icon(Icons.person,
                              size: 45,
                              color: colorScheme.onSurfaceVariant)
                          : null,
                    ),
                    // 🆕 角色標籤（教練標記）
                    if (_userProfile?.isCoach ?? false)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.star,
                            size: 14,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🆕 名稱 + 角色標籤
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _userProfile?.nickname ??
                                  _userProfile?.displayName ??
                                  _userProfile?.email ??
                                  '用戶名稱',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 🆕 角色標籤
                          if (_userProfile?.isCoach ?? false)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '教練',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_userProfile?.isStudent ?? true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 14,
                                    color: colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '學員',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 🆕 基本資訊（年齡、性別）
                      Row(
                        children: [
                          if (_userProfile?.age != null) ...[
                            Icon(Icons.cake,
                                size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              '${_userProfile!.age} 歲',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (_userProfile?.age != null &&
                              _userProfile?.gender != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '·',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          if (_userProfile?.gender != null) ...[
                            Icon(
                              _userProfile!.gender == '男'
                                  ? Icons.male
                                  : Icons.female,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _userProfile!.gender!,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // 個人簡介
                      if (_userProfile?.bio != null &&
                          _userProfile!.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _userProfile!.bio!,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 🆕 快捷按鈕
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsPage(),
                        ),
                      );
                      _loadUserProfile();
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('編輯資料'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:                   FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BodyDataPage(userProfile: _userProfile),
                        ),
                      );
                    },
                    icon: const Icon(Icons.show_chart, size: 18),
                    label: const Text('身體數據'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🆕 詳細資訊卡片（重新設計）
  Widget _buildDetailedInfoCard(BuildContext context, ColorScheme colorScheme) {
    final isMetric = _userProfile!.unitSystem != 'imperial';
    
    // 計算 BMI
    double? bmi;
    String? bmiCategory;
    String? heightText;
    String? weightText;
    
    if (_userProfile!.height != null && _userProfile!.weight != null) {
      if (isMetric) {
        // 公制：cm, kg
        heightText = '${_userProfile!.height} cm';
        weightText = '${_userProfile!.weight} kg';
        
        final heightInMeters = _userProfile!.height! / 100;
        bmi = _userProfile!.weight! / (heightInMeters * heightInMeters);
      } else {
        // 英制：feet & inches, lb
        // 假設資料庫儲存的是公制，需要轉換
        final heightInInches = _userProfile!.height! / 2.54;
        final feet = (heightInInches / 12).floor();
        final inches = (heightInInches % 12).round();
        heightText = '$feet\' $inches"';
        
        final weightInLbs = (_userProfile!.weight! * 2.20462).toStringAsFixed(1);
        weightText = '$weightInLbs lb';
        
        // BMI 計算（使用英制單位）
        bmi = (_userProfile!.weight! * 703) / (heightInInches * heightInInches);
      }
      
      // BMI 分類（WHO 標準，適用於公制和英制）
      if (bmi < 18.5) {
        bmiCategory = '過輕';
      } else if (bmi < 24) {
        bmiCategory = '正常';
      } else if (bmi < 27) {
        bmiCategory = '過重';
      } else {
        bmiCategory = '肥胖';
      }
    } else if (_userProfile!.height != null) {
      // 只有身高
      if (isMetric) {
        heightText = '${_userProfile!.height} cm';
      } else {
        final heightInInches = _userProfile!.height! / 2.54;
        final feet = (heightInInches / 12).floor();
        final inches = (heightInInches % 12).round();
        heightText = '$feet\' $inches"';
      }
    } else if (_userProfile!.weight != null) {
      // 只有體重
      if (isMetric) {
        weightText = '${_userProfile!.weight} kg';
      } else {
        final weightInLbs = (_userProfile!.weight! * 2.20462).toStringAsFixed(1);
        weightText = '$weightInLbs lb';
      }
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '詳細資訊',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 🆕 基本資料區塊
            if (heightText != null || weightText != null || bmi != null) ...[
              _buildSectionHeader(context, '👤 基本資料', colorScheme),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (heightText != null)
                      _buildInfoRow('身高', heightText),
                    if (weightText != null) ...[
                      if (heightText != null) const Divider(height: 16),
                      _buildInfoRow('體重', weightText),
                    ],
                    if (bmi != null) ...[
                      const Divider(height: 16),
                      _buildInfoRow(
                        'BMI',
                        '${bmi.toStringAsFixed(1)} ($bmiCategory)',
                        valueColor: bmiCategory == '正常'
                            ? Colors.green
                            : bmiCategory == '過輕'
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 🆕 偏好設定區塊
            _buildSectionHeader(context, '⚙️ 偏好設定', colorScheme),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    '單位系統',
                    isMetric ? '公制 (cm, kg)' : '英制 (ft, lb)',
                  ),
                  const Divider(height: 16),
                  _buildInfoRow(
                    '角色',
                    [
                      if (_userProfile!.isCoach) '教練',
                      if (_userProfile!.isStudent) '學員',
                    ].join(' / '),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🆕 區段標題
  Widget _buildSectionHeader(
      BuildContext context, String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// 🆕 功能菜單區塊
  Widget _buildMenuSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        // 🆕 我的統計（連結到統計頁面）
        _buildMenuItem(
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
        _buildRoleMenuItem(
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

  /// 🆕 登出按鈕
  Widget _buildLogoutButton(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await _authService.signOut();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          }
        },
        icon: Icon(Icons.logout, color: colorScheme.error),
        label: Text(
          '登出',
          style: TextStyle(color: colorScheme.error),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRoleMenuItem({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        value: value,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 主題切換組件
  /// 
  /// 提供三種模式切換：淺色、深色、跟隨系統
  /// 使用 SegmentedButton 符合 Material 3 設計規範
  Widget _buildThemeSwitcher(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.palette_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              '外觀主題',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.wb_sunny, size: 18),
                label: Text('淺色'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.nightlight_round, size: 18),
                label: Text('深色'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.phone_android, size: 18),
                label: Text('系統'),
              ),
            ],
            selected: {themeController.themeMode},
            onSelectionChanged: (Set<ThemeMode> newSelection) {
              themeController.setThemeMode(newSelection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.comfortable,
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.primary;
                  }
                  return colorScheme.surface;
                },
              ),
              foregroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return colorScheme.onPrimary;
                  }
                  return colorScheme.onSurface;
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            themeController.themeMode == ThemeMode.system
                ? '當前跟隨系統設定'
                : '當前使用${themeController.themeModeName}',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
