import 'package:flutter/material.dart';
import '../../services/auth_wrapper.dart';
import '../login_page.dart';

class ProfilePage extends StatelessWidget {
  final AuthWrapper authWrapper;
  
  const ProfilePage({
    super.key, 
    required this.authWrapper,
  });

  @override
  Widget build(BuildContext context) {
    final userData = authWrapper.getCurrentUser();
    
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
                  backgroundImage: NetworkImage(
                    userData?['photoURL'] ?? 'https://via.placeholder.com/80'
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData?['displayName'] ?? userData?['email'] ?? '用戶名稱',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${userData?['uid']?.substring(0, 8) ?? '12345678'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // 編輯資料功能
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
                  _buildMenuItem(
                    icon: Icons.share,
                    title: '分享訓練',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.watch,
                    title: '智能手錶支援',
                    onTap: () {},
                  ),
                  const Divider(),
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: '設定',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.feedback,
                    title: '意見回饋',
                    onTap: () {},
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
                      await authWrapper.signOut();
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
} 