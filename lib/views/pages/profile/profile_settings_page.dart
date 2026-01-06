// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:strengthwise/controllers/profile_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/views/pages/home/main_home_page.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_form_content.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_delete_account_button.dart';
import 'package:strengthwise/views/pages/profile/coach_profile_form_page.dart';

/// 個人資料設置頁面
///
/// 響應式設計：表單區域限制最大寬度 600dp
///
/// 完全解耦架構：
/// - View 層：只負責 UI 邏輯和事件分發
/// - Controller 層：透過 Provider 提供狀態
/// - 最小元件：表單內容拆成獨立 Widget
class ProfileSettingsPage extends StatefulWidget {
  final bool isFirstTimeSetup;

  const ProfileSettingsPage({
    super.key,
    this.isFirstTimeSetup = false,
  });

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late final ProfileController _controller;
  final _formKey = GlobalKey<FormState>();

  // 本地狀態（不屬於全局狀態）
  File? _avatarFile;
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _gender;
  bool _genderVisible = true;
  DateTime? _birthDate;
  String _unitSystem = 'metric';
  bool _isCoach = false;
  bool _isStudent = true;

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<ProfileController>();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// 載入用戶資料
  Future<void> _loadUserProfile() async {
    await _controller.loadUserProfile();

    final userProfile = _controller.userProfile;
    if (userProfile != null && mounted) {
      setState(() {
        _displayNameController.text = userProfile.displayName ?? '';
        _nicknameController.text = userProfile.nickname ?? '';
        _gender = userProfile.gender;
        _genderVisible = userProfile.genderVisible;
        _heightController.text = userProfile.height?.toString() ?? '';
        _weightController.text = userProfile.weight?.toString() ?? '';
        _bioController.text = userProfile.bio ?? '';
        _birthDate = userProfile.birthDate;
        _unitSystem = userProfile.unitSystem ?? 'metric';

        if (!widget.isFirstTimeSetup) {
          _isCoach = userProfile.isCoach;
          _isStudent = userProfile.isStudent;
        }
      });
    }
  }

  /// 選擇照片
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  /// 保存個人資料
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 檢查必填欄位
    if (_gender == null) {
      NotificationUtils.showWarning(context, '請選擇性別');
      return;
    }

    if (_heightController.text.isEmpty) {
      NotificationUtils.showWarning(context, '請填寫身高');
      return;
    }

    if (_weightController.text.isEmpty) {
      NotificationUtils.showWarning(context, '請填寫體重');
      return;
    }

    if (_birthDate == null) {
      NotificationUtils.showWarning(context, '請選擇生日');
      return;
    }

    // 使用 Controller 保存
    final success = await _controller.updateUserProfile(
      displayName: _displayNameController.text,
      nickname: _nicknameController.text,
      gender: _gender,
      genderVisible: _genderVisible,
      height: double.parse(_heightController.text),
      weight: double.parse(_weightController.text),
      birthDate: _birthDate,
      bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      unitSystem: _unitSystem,
      isCoach: widget.isFirstTimeSetup ? false : _isCoach,
      isStudent: widget.isFirstTimeSetup ? true : _isStudent,
      avatarFile: _avatarFile,
    );

    if (!mounted) return;

    if (success) {
      NotificationUtils.showSuccess(context, '個人資料已保存');

      // 首次設置完成後跳轉主頁
      if (widget.isFirstTimeSetup) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainHomePage()),
        );
      } else {
        Navigator.of(context).pop();
      }
    } else {
      NotificationUtils.showError(
        context,
        _controller.errorMessage ?? '保存失敗，請稍後再試',
      );
    }
  }

  /// ⭐ v2.9: 首次開啟教練模式時引導填寫教練檔案
  void _promptCoachProfileSetup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('成為教練！'),
          content: const Text('您已成功開啟教練模式。現在請填寫您的教練公開檔案，讓學員認識您。'),
          actions: <Widget>[
            TextButton(
              child: const Text('稍後再說'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            FilledButton(
              child: const Text('立即填寫'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoachProfileFormPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileController>.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isFirstTimeSetup ? '完成您的個人資料' : '編輯個人資料'),
          automaticallyImplyLeading: !widget.isFirstTimeSetup,
        ),
        body: Consumer<ProfileController>(
          builder: (context, controller, child) {
            // 首次載入顯示 Loading
            if (controller.isLoading && controller.userProfile == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: context.pagePadding,
              child: Center(
                // ✅ 表單區域限制最大寬度 600dp
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 基本資料表單（刪除帳號由外層控制位置）
                      ProfileFormContent(
                    formKey: _formKey,
                    isFirstTimeSetup: widget.isFirstTimeSetup,
                    isOAuthUser: controller.isOAuthUser,
                    displayNameController: _displayNameController,
                    nicknameController: _nicknameController,
                    heightController: _heightController,
                    weightController: _weightController,
                    bioController: _bioController,
                    photoURL: controller.userProfile?.photoURL,
                    avatarFile: _avatarFile,
                    gender: _gender,
                    genderVisible: _genderVisible,
                    birthDate: _birthDate,
                    unitSystem: _unitSystem,
                    isSaving: controller.isLoading,
                    onPickImage: _pickImage,
                    onGenderChanged: (value) => setState(() => _gender = value),
                    onGenderVisibleChanged: (value) =>
                        setState(() => _genderVisible = value),
                    onBirthDateChanged: (value) =>
                        setState(() => _birthDate = value),
                    onUnitSystemChanged: (value) =>
                        setState(() => _unitSystem = value),
                    onSave: _saveProfile,
                    showDeleteAccount: false, // 刪除帳號移到最後
                  ),

                      // ⭐ v2.9: 教練設定區塊（僅非首次設置時顯示）
                      if (!widget.isFirstTimeSetup) ...[
                        SizedBox(height: context.spacing.xl),
                        const Divider(),
                        SizedBox(height: context.spacing.md),
                        Text(
                          '教練功能',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        SizedBox(height: context.spacing.sm),
                        Text(
                          '開啟教練模式以使用教練中心功能',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                        SizedBox(height: context.spacing.md),

                        // 教練模式開關
                        SwitchListTile(
                          title: const Text('教練模式'),
                          subtitle: const Text('開啟後可在課程頁面看到教練中心'),
                          value: controller.userProfile?.isCoach ?? false,
                          onChanged: (value) async {
                            final success =
                                await controller.toggleCoachRole(value);
                            if (mounted && success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(value ? '已開啟教練模式' : '已關閉教練模式'),
                                ),
                              );
                              // 首次開啟教練模式時引導填寫教練檔案
                              if (value && mounted) {
                                _promptCoachProfileSetup(context);
                              }
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                        ),

                        // 教練公開檔案入口（僅教練可見）
                        if (controller.userProfile?.isCoach == true) ...[
                          SizedBox(height: context.spacing.sm),
                          ListTile(
                            leading: Icon(
                              Icons.badge_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('教練公開檔案'),
                            subtitle: const Text('管理您的專業資訊與專長'),
                            trailing: const Icon(Icons.chevron_right),
                            contentPadding: EdgeInsets.zero,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CoachProfileFormPage(),
                                ),
                              );
                            },
                          ),
                        ],

                        // 刪除帳號區塊（放在最後）
                        SizedBox(height: context.spacing.xl),
                        const Divider(),
                        SizedBox(height: context.spacing.md),
                        Text(
                          '危險區域',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                        ),
                        SizedBox(height: context.spacing.sm),
                        Text(
                          '刪除帳號後，您的訓練記錄將被永久刪除且無法復原',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                        SizedBox(height: context.spacing.md),
                        const ProfileDeleteAccountButton(),
                        SizedBox(height: context.spacing.xl),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
