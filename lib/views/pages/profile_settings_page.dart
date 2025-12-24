import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user_model.dart';
import '../../services/interfaces/i_user_service.dart';
import '../../services/service_locator.dart';
import '../main_home_page.dart';

class ProfileSettingsPage extends StatefulWidget {
  final bool isFirstTimeSetup;
  
  const ProfileSettingsPage({
    super.key,
    this.isFirstTimeSetup = false,
  });

  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late final IUserService _userService;
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
  final TextEditingController _bioController = TextEditingController();  // 新增：個人簡介
  
  String? _gender;
  DateTime? _birthDate;  // 新增：生日
  String _unitSystem = 'metric';  // 新增：單位系統（預設公制）
  bool _isCoach = false;
  bool _isStudent = true;

  @override
  void initState() {
    super.initState();
    _userService = serviceLocator<IUserService>();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _displayNameController.dispose();
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _bioController.dispose();  // 新增
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
        _bioController.text = userProfile.bio ?? '';  // 新增：個人簡介
        _birthDate = userProfile.birthDate;  // 新增：生日
        _unitSystem = userProfile.unitSystem ?? 'metric';  // 新增：單位系統
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
    
    // 檢查必填欄位
    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇性別'))
      );
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
      birthDate: _birthDate,  // 新增：生日
      bio: _bioController.text.isNotEmpty ? _bioController.text : null,  // 新增：個人簡介
      unitSystem: _unitSystem,  // 新增：單位系統
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
      
      // 如果是首次設置，完成後導航到主頁
      if (widget.isFirstTimeSetup) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainHomePage()),
        );
      } else {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失敗，請稍後再試'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstTimeSetup ? '完成您的個人資料' : '編輯個人資料'),
        // 如果是首次設置，禁用返回按鈕
        automaticallyImplyLeading: !widget.isFirstTimeSetup,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isFirstTimeSetup)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    '請完成您的個人資料設置，以便我們能夠為您提供更好的服務',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              
              // 頭像部分
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      backgroundImage: _avatarFile != null 
                          ? FileImage(_avatarFile!) 
                          : (_userProfile?.photoURL != null 
                              ? NetworkImage(_userProfile!.photoURL!) as ImageProvider 
                              : null),
                      child: _avatarFile == null && _userProfile?.photoURL == null
                          ? Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.onSurfaceVariant)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 顯示名稱
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: '顯示名稱',
                  border: OutlineInputBorder(),
                  helperText: '這將顯示在您的個人資料頁面',
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
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '昵稱',
                  border: OutlineInputBorder(),
                  helperText: '這將顯示在應用內的社交互動中',
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
              const Text('性別', style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  Radio<String>(
                    value: '男',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                  const Text('男'),
                  const SizedBox(width: 20),
                  Radio<String>(
                    value: '女',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                  const Text('女'),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 身高
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: '身高 (cm)',
                  border: OutlineInputBorder(),
                  helperText: '可選',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      final height = double.parse(value);
                      if (height <= 0 || height > 250) {
                        return '請輸入有效的身高 (0-250 cm)';
                      }
                    } catch (e) {
                      return '請輸入有效的數字';
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // 體重
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: '體重 (kg)',
                  border: OutlineInputBorder(),
                  helperText: '可選',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      final weight = double.parse(value);
                      if (weight <= 0 || weight > 300) {
                        return '請輸入有效的體重 (0-300 kg)';
                      }
                    } catch (e) {
                      return '請輸入有效的數字';
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // 年齡
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: '年齡',
                  border: OutlineInputBorder(),
                  helperText: '可選',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    try {
                      final age = int.parse(value);
                      if (age <= 0 || age > 120) {
                        return '請輸入有效的年齡 (1-120)';
                      }
                    } catch (e) {
                      return '請輸入有效的數字';
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // 生日
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    helpText: '選擇生日',
                    cancelText: '取消',
                    confirmText: '確定',
                  );
                  if (picked != null && picked != _birthDate) {
                    setState(() {
                      _birthDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '生日',
                    border: OutlineInputBorder(),
                    helperText: '可選',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _birthDate != null
                        ? '${_birthDate!.year}年${_birthDate!.month}月${_birthDate!.day}日'
                        : '點擊選擇生日',
                    style: TextStyle(
                      color: _birthDate != null ? Colors.black : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 個人簡介
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: '個人簡介',
                  border: OutlineInputBorder(),
                  helperText: '可選 - 介紹您自己，讓其他人更了解您',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 200,
                keyboardType: TextInputType.multiline,
              ),
              
              const SizedBox(height: 16),
              
              // 單位系統選擇
              const Text('單位系統', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Radio<String>(
                    value: 'metric',
                    groupValue: _unitSystem,
                    onChanged: (value) {
                      setState(() {
                        _unitSystem = value!;
                      });
                    },
                  ),
                  const Text('公制 (kg, cm)'),
                  const SizedBox(width: 20),
                  Radio<String>(
                    value: 'imperial',
                    groupValue: _unitSystem,
                    onChanged: (value) {
                      setState(() {
                        _unitSystem = value!;
                      });
                    },
                  ),
                  const Text('英制 (lb, in)'),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 用戶角色選擇
              const Text('我的角色', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              SwitchListTile(
                title: const Text('我是教練'),
                subtitle: const Text('您可以創建訓練計劃並指導學員'),
                value: _isCoach,
                onChanged: (bool value) {
                  setState(() {
                    _isCoach = value;
                  });
                },
              ),
              
              SwitchListTile(
                title: const Text('我是學員'),
                subtitle: const Text('您可以參加訓練並追蹤進度'),
                value: _isStudent,
                onChanged: (bool value) {
                  setState(() {
                    _isStudent = value;
                  });
                },
              ),
              
              const SizedBox(height: 30),
              
              // 保存按鈕
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.isFirstTimeSetup ? '完成設置' : '保存資料', 
                            style: const TextStyle(fontSize: 18)
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 