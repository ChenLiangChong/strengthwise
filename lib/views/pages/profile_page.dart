import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_wrapper.dart';
import '../login_page.dart';
import 'profile_settings_page.dart';

class ProfilePage extends StatefulWidget {
  final AuthWrapper authWrapper;
  
  const ProfilePage({
    super.key, 
    required this.authWrapper,
  });
  
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  
  UserModel? _userProfile;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _avatarFile;
  
  // 表單控制器
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  
  String? _gender;
  bool _isCoach = false;
  bool _isStudent = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _displayNameController.dispose();
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    final userProfile = await _userService.getCurrentUserProfile();
    
    if (userProfile != null) {
      setState(() {
        _userProfile = userProfile;
        _displayNameController.text = userProfile.displayName ?? '';
        _nicknameController.text = userProfile.nickname ?? '';
        _gender = userProfile.gender;
        _heightController.text = userProfile.height?.toString() ?? '';
        _weightController.text = userProfile.weight?.toString() ?? '';
        _ageController.text = userProfile.age?.toString() ?? '';
        _isCoach = userProfile.isCoach ?? false;
        _isStudent = userProfile.isStudent ?? true;
      });
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    final success = await _userService.updateUserProfile(
      displayName: _displayNameController.text,
      nickname: _nicknameController.text,
      gender: _gender,
      height: _heightController.text.isNotEmpty ? double.parse(_heightController.text) : null,
      weight: _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
      age: _ageController.text.isNotEmpty ? int.parse(_ageController.text) : null,
      isCoach: _isCoach,
      isStudent: _isStudent,
      avatarFile: _avatarFile,
    );
    
    setState(() {
      _isSaving = false;
    });
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('個人資料已保存'))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失敗，請稍後再試'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.authWrapper.getCurrentUser();
    
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
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _userProfile?.photoURL != null 
                      ? NetworkImage(_userProfile!.photoURL!) 
                      : null,
                  child: _userProfile?.photoURL == null 
                      ? const Icon(Icons.person, size: 40, color: Colors.grey) 
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userProfile?.nickname ?? _userProfile?.displayName ?? _userProfile?.email ?? '用戶名稱',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_userProfile?.gender != null)
                        Text(
                          '性別: ${_userProfile!.gender}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      if (_userProfile?.age != null)
                        Text(
                          '年齡: ${_userProfile!.age} 歲',
                          style: TextStyle(
                            color: Colors.grey[600],
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
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: '登出',
                    onTap: () async {
                      await widget.authWrapper.signOut();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => LoginPage()),
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
        color: Colors.green,
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
      activeColor: Colors.green,
      onChanged: onChanged,
    );
  }
} 