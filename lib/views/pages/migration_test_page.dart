import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/service_locator.dart';
import '../../services/interfaces/i_user_service.dart';
import '../../services/user_migration_validator.dart';
import '../../services/user_migration_service.dart';

/// 遷移測試頁面（僅開發用）
///
/// 用於測試和驗證使用者資料遷移功能
class MigrationTestPage extends StatefulWidget {
  const MigrationTestPage({super.key});

  @override
  State<MigrationTestPage> createState() => _MigrationTestPageState();
}

class _MigrationTestPageState extends State<MigrationTestPage> {
  final UserMigrationValidator _validator = UserMigrationValidator();
  final UserMigrationService _migrationService =
      serviceLocator<UserMigrationService>();
  final IUserService _userService = serviceLocator<IUserService>();

  String? _currentUserId;
  Map<String, dynamic>? _validationResult;
  Map<String, dynamic>? _comparisonResult;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      _loadUserProfile();
    } else {
      setState(() {
        _statusMessage = '請先登入';
      });
    }
  }

  Future<void> _loadUserProfile() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '載入中...';
    });

    try {
      final profile = await _userService.getCurrentUserProfile();
      setState(() {
        _userModel = profile;
        _isLoading = false;
        _statusMessage = profile != null ? '載入成功' : '載入失敗';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '載入錯誤: $e';
      });
    }
  }

  Future<void> _testValidation() async {
    if (_currentUserId == null) {
      _showMessage('請先登入');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '驗證中...';
    });

    try {
      final result = await _validator.validateMigration(_currentUserId!);
      setState(() {
        _validationResult = result;
        _isLoading = false;
        _statusMessage = result['passed'] == true ? '驗證通過' : '驗證失敗';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '驗證錯誤: $e';
      });
    }
  }

  Future<void> _testMigration() async {
    if (_currentUserId == null) {
      _showMessage('請先登入');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '執行遷移中...';
    });

    try {
      final needsMigration =
          await _migrationService.needsMigration(_currentUserId!);

      if (!needsMigration) {
        setState(() {
          _isLoading = false;
          _statusMessage = '不需要遷移（可能已遷移或沒有舊資料）';
        });
        return;
      }

      final success = await _migrationService.migrateUserData(_currentUserId!);
      setState(() {
        _isLoading = false;
        _statusMessage = success ? '遷移成功' : '遷移失敗';
      });

      // 重新載入用戶資料
      await _loadUserProfile();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '遷移錯誤: $e';
      });
    }
  }

  Future<void> _compareData() async {
    if (_currentUserId == null) {
      _showMessage('請先登入');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '比較資料中...';
    });

    try {
      final comparison = await _validator.compareOldAndNewData(_currentUserId!);
      setState(() {
        _comparisonResult = comparison;
        _isLoading = false;
        _statusMessage = '比較完成';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '比較錯誤: $e';
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('遷移測試頁面'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 用戶資訊卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '當前用戶資訊',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_currentUserId != null)
                      Text('UID: $_currentUserId')
                    else
                      const Text('未登入'),
                    const SizedBox(height: 8),
                    if (_userModel != null) ...[
                      Text('Email: ${_userModel!.email}'),
                      Text('Display Name: ${_userModel!.displayName ?? "無"}'),
                      Text('Nickname: ${_userModel!.nickname ?? "無"}'),
                      Text('isCoach: ${_userModel!.isCoach}'),
                      Text('isStudent: ${_userModel!.isStudent}'),
                      Text('Bio: ${_userModel!.bio ?? "無"}'),
                      Text('Unit System: ${_userModel!.unitSystem ?? "無"}'),
                      Text('Last Login: ${_userModel!.lastLogin ?? "無"}'),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 狀態訊息
            if (_statusMessage != null)
              Card(
                color: _statusMessage!.contains('成功') ||
                        _statusMessage!.contains('通過')
                    ? Colors.green[100]
                    : Colors.orange[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 測試按鈕
            ElevatedButton(
              onPressed: _isLoading ? null : _loadUserProfile,
              child: const Text('重新載入用戶資料'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testValidation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('驗證遷移狀態'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testMigration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('執行遷移（測試用）'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _compareData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: const Text('比較新舊資料'),
            ),

            // 載入指示器
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),

            // 驗證結果
            if (_validationResult != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '驗證結果: ${_validationResult!['passed'] == true ? "✅ 通過" : "❌ 失敗"}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_validationResult!['checks'] != null)
                        ...(_validationResult!['checks']
                                as Map<String, dynamic>)
                            .entries
                            .map((entry) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    '${entry.key}: ${entry.value['status']} - ${entry.value['message']}',
                                    style: TextStyle(
                                      color: entry.value['status'] == 'passed'
                                          ? Colors.green
                                          : entry.value['status'] == 'failed'
                                              ? Colors.red
                                              : Colors.orange,
                                    ),
                                  ),
                                ))
                            .toList(),
                    ],
                  ),
                ),
              ),
            ],

            // 比較結果
            if (_comparisonResult != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '新舊資料比較',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('舊資料存在: ${_comparisonResult!['oldDataExists']}'),
                      Text('新資料存在: ${_comparisonResult!['newDataExists']}'),
                      if (_comparisonResult!['fieldMapping'] != null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '欄位映射:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...(_comparisonResult!['fieldMapping']
                                as Map<String, dynamic>)
                            .entries
                            .map((entry) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                          '  舊值: ${entry.value['old'] ?? "無"}'),
                                      Text(
                                          '  新值: ${entry.value['new'] ?? "無"}'),
                                      Text(
                                        '  匹配: ${entry.value['match'] == true ? "✅" : "❌"}',
                                        style: TextStyle(
                                          color: entry.value['match'] == true
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
