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
    setState(() {
      _isLoading = true;
    });

    final userProfile = await _userService.getCurrentUserProfile();

    if (userProfile != null) {
      setState(() {
        _userProfile = userProfile;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 用戶資料頭部
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  backgroundImage: _userProfile?.photoURL != null
                      ? NetworkImage(_userProfile!.photoURL!)
                      : null,
                  child: _userProfile?.photoURL == null
                      ? Icon(Icons.person,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userProfile?.nickname ??
                            _userProfile?.displayName ??
                            _userProfile?.email ??
                            '用戶名稱',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_userProfile?.gender != null)
                        Text(
                          '性別: ${_userProfile!.gender}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (_userProfile?.age != null)
                        Text(
                          '年齡: ${_userProfile!.age} 歲',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (_userProfile?.bio != null &&
                          _userProfile!.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            _userProfile!.bio!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    // 導航到個人資料設置頁面
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfileSettingsPage(),
                      ),
                    );
                    // 返回後重新加載資料
                    _loadUserProfile();
                  },
                ),
              ],
            ),

            // 新增：詳細資訊卡片
            if (_userProfile != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '詳細資訊',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      if (_userProfile!.birthDate != null)
                        _buildInfoRow(
                          '生日',
                          '${_userProfile!.birthDate!.year}/${_userProfile!.birthDate!.month}/${_userProfile!.birthDate!.day}',
                        ),
                      if (_userProfile!.height != null)
                        _buildInfoRow('身高', '${_userProfile!.height} cm'),
                      if (_userProfile!.weight != null)
                        _buildInfoRow('體重', '${_userProfile!.weight} kg'),
                      if (_userProfile!.unitSystem != null)
                        _buildInfoRow(
                          '單位系統',
                          _userProfile!.unitSystem == 'metric' ? '公制' : '英制',
                        ),
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
              ),
            ],

            const SizedBox(height: 30),
            // 功能菜單
            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(
                    icon: Icons.calendar_today,
                    title: '訓練記錄',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.photo_library,
                    title: '照片牆',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.note,
                    title: '訓練備忘錄',
                    onTap: () {},
                  ),
                  const Divider(),
                  _buildRoleMenuItem(
                    title: '教練模式',
                    value: _userProfile?.isCoach ?? false,
                    onChanged: (value) async {
                      // 切換教練角色
                      await _userService.toggleUserRole(value);
                      _loadUserProfile();
                    },
                  ),
                  const Divider(),
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: '編輯個人資料',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsPage(),
                        ),
                      );
                      _loadUserProfile();
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.data_usage,
                    title: '身體數據',
                    onTap: () {},
                  ),
                  const Divider(),
                  // 主題切換選項
                  _buildThemeSwitcher(context),
                  const Divider(),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: '登出',
                    onTap: () async {
                      await _authService.signOut();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildRoleMenuItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      onChanged: onChanged,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
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
      ),
    );
  }
}
