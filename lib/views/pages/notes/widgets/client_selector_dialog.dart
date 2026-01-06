import 'package:flutter/material.dart';
import 'package:strengthwise/controllers/coaching_relationship_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/services/service_locator.dart';

/// 學員選擇對話框
/// 
/// 功能：
/// - 顯示教練的所有學員
/// - 選擇學員後返回 clientId
class ClientSelectorDialog extends StatefulWidget {
  const ClientSelectorDialog({Key? key}) : super(key: key);

  @override
  State<ClientSelectorDialog> createState() => _ClientSelectorDialogState();
}

class _ClientSelectorDialogState extends State<ClientSelectorDialog> {
  late final CoachingRelationshipController _controller;
  late final IAuthController _authController;
  bool _isLoading = true;
  List<UserModel> _clients = [];

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<CoachingRelationshipController>();
    _authController = serviceLocator<IAuthController>();
    _loadClients();
  }

  /// 載入學員列表
  Future<void> _loadClients() async {
    final currentUser = _authController.user;
    if (currentUser == null) return;

    setState(() => _isLoading = true);
    
    try {
      await _controller.loadCoachClients(
        currentUser.uid,
        status: 'active', // 只顯示活躍學員
      );
      
      setState(() {
        _clients = _controller.clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入學員失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('選擇學員'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _clients.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '尚無學員',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '請先在「學員管理」中邀請學員',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _clients.length,
                    itemBuilder: (context, index) {
                      final client = _clients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            client.displayName?.substring(0, 1).toUpperCase() ?? '?',
                          ),
                        ),
                        title: Text(
                          client.displayName ?? '未知學員',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          client.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context, client.uid);
                        },
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

