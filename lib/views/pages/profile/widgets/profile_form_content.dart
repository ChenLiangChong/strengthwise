import 'package:flutter/material.dart';
import 'dart:io';
import 'profile_avatar_editor.dart';
import 'gender_selector.dart';
import 'birthday_picker.dart';
import 'unit_system_selector.dart';
import 'profile_delete_account_button.dart';
import 'oauth_password_section.dart';

/// 個人資料表單內容
///
/// 純 UI 元件，所有狀態透過回調傳遞
class ProfileFormContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isFirstTimeSetup;
  final bool isOAuthUser;

  // 控制器
  final TextEditingController displayNameController;
  final TextEditingController nicknameController;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController bioController;

  // 狀態
  final String? photoURL;
  final File? avatarFile;
  final String? gender;
  final bool genderVisible;
  final DateTime? birthDate;
  final String unitSystem;
  final bool isSaving;

  // 回調
  final VoidCallback onPickImage;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<bool> onGenderVisibleChanged;
  final ValueChanged<DateTime?> onBirthDateChanged;
  final ValueChanged<String> onUnitSystemChanged;
  final VoidCallback onSave;

  // 控制是否顯示刪除帳號（改由外層控制位置）
  final bool showDeleteAccount;

  const ProfileFormContent({
    super.key,
    required this.formKey,
    required this.isFirstTimeSetup,
    required this.isOAuthUser,
    required this.displayNameController,
    required this.nicknameController,
    required this.heightController,
    required this.weightController,
    required this.bioController,
    required this.photoURL,
    required this.avatarFile,
    required this.gender,
    required this.genderVisible,
    required this.birthDate,
    required this.unitSystem,
    required this.isSaving,
    required this.onPickImage,
    required this.onGenderChanged,
    required this.onGenderVisibleChanged,
    required this.onBirthDateChanged,
    required this.onUnitSystemChanged,
    required this.onSave,
    this.showDeleteAccount = true, // 預設顯示
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFirstTimeSetup)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                '請完成您的個人資料設置，以便我們能夠為您提供更好的服務',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          // 頭像編輯器
          ProfileAvatarEditor(
            photoURL: photoURL,
            avatarFile: avatarFile,
            onPickImage: onPickImage,
          ),

          const SizedBox(height: 20),

          // 顯示名稱
          TextFormField(
            controller: displayNameController,
            decoration: const InputDecoration(
              labelText: '顯示名稱',
              border: OutlineInputBorder(),
              helperText: '這將顯示在您的個人資料頁面',
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '請輸入顯示名稱';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 昵稱
          TextFormField(
            controller: nicknameController,
            decoration: const InputDecoration(
              labelText: '昵稱',
              border: OutlineInputBorder(),
              helperText: '這將顯示在應用內的社交互動中',
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '請輸入昵稱';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 性別選擇
          GenderSelector(
            selectedGender: gender,
            onChanged: onGenderChanged,
          ),

          const SizedBox(height: 8),

          // 性別隱私設置
          SwitchListTile(
            title: const Text('對其他人顯示性別'),
            subtitle: Text(
              genderVisible ? '其他用戶可以看到您的性別' : '只有您自己能看到性別資訊',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            value: genderVisible,
            onChanged: onGenderVisibleChanged,
          ),

          const SizedBox(height: 16),

          // 身高
          TextFormField(
            controller: heightController,
            decoration: const InputDecoration(
              labelText: '身高 (cm) *',
              border: OutlineInputBorder(),
              helperText: '必填',
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '請輸入身高';
              }
              try {
                final height = double.parse(value);
                if (height <= 0 || height > 250) {
                  return '請輸入有效的身高 (0-250 cm)';
                }
              } catch (e) {
                return '請輸入有效的數字';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 體重
          TextFormField(
            controller: weightController,
            decoration: const InputDecoration(
              labelText: '體重 (kg) *',
              border: OutlineInputBorder(),
              helperText: '必填',
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '請輸入體重';
              }
              try {
                final weight = double.parse(value);
                if (weight <= 0 || weight > 300) {
                  return '請輸入有效的體重 (0-300 kg)';
                }
              } catch (e) {
                return '請輸入有效的數字';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 生日選擇
          BirthdayPicker(
            selectedDate: birthDate,
            onDateSelected: onBirthDateChanged,
            isRequired: true,
          ),

          const SizedBox(height: 16),

          // 個人簡介
          TextFormField(
            controller: bioController,
            decoration: const InputDecoration(
              labelText: '個人簡介',
              border: OutlineInputBorder(),
              helperText: '可選 - 介紹您自己，讓其他人更了解您',
              alignLabelWithHint: true,
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            maxLines: 4,
            maxLength: 200,
            keyboardType: TextInputType.multiline,
          ),

          const SizedBox(height: 16),

          // 單位系統
          UnitSystemSelector(
            selectedUnit: unitSystem,
            onChanged: (value) {
              if (value != null) onUnitSystemChanged(value);
            },
          ),

          const SizedBox(height: 30),

          // 保存按鈕
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isFirstTimeSetup ? '完成設置' : '保存資料',
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ),

          // OAuth 用戶密碼設置（僅在非首次設置時顯示）
          if (!isFirstTimeSetup && isOAuthUser) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const OAuthPasswordSection(),
          ],

          // 刪除帳號按鈕（僅在非首次設置且 showDeleteAccount 為 true 時顯示）
          if (!isFirstTimeSetup && showDeleteAccount) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              '危險區域',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '刪除帳號後，您的訓練記錄將被永久刪除且無法復原',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const ProfileDeleteAccountButton(),
          ],
        ],
      ),
    );
  }
}
