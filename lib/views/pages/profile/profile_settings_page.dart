import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:strengthwise/controllers/profile_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/home/main_home_page.dart';
import 'package:strengthwise/views/pages/profile/widgets/profile_form_content.dart';

/// 個人資料設置頁面
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
              padding: const EdgeInsets.all(16.0),
              child: ProfileFormContent(
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
              ),
            );
          },
        ),
      ),
    );
  }
}
