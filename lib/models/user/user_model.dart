import 'user_mapper.dart';

/// 使用者模型
///
/// 表示應用中的使用者資料，包含基本資料、角色權限和時間記錄
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? nickname;
  final String? gender;
  final double? height;
  final double? weight;
  final int? age;
  final DateTime? birthDate;  // 新增：從 user 集合遷移
  final bool isCoach;         // 統一欄位，替代 isTrainer
  final bool isStudent;       // 統一欄位，替代 isTrainee
  final String? bio;          // 新增：從 user 集合遷移
  final String? unitSystem;   // 新增：從 user 集合遷移
  final DateTime? profileCreatedAt;
  final DateTime? profileUpdatedAt;
  final DateTime? lastLogin;  // 新增：從 user 集合遷移

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.nickname,
    this.gender,
    this.height,
    this.weight,
    this.age,
    this.birthDate,
    this.isCoach = false,
    this.isStudent = true,
    this.bio,
    this.unitSystem,
    this.profileCreatedAt,
    this.profileUpdatedAt,
    this.lastLogin,
  });

  /// 從映射創建用戶（Firestore 格式，向後相容）
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserMapper.fromMap(map);
  }

  /// 從 Supabase 數據創建用戶（snake_case 欄位）
  factory UserModel.fromSupabase(Map<String, dynamic> json) {
    return UserMapper.fromSupabase(json);
  }

  /// 轉換為映射
  Map<String, dynamic> toMap() {
    return UserMapper.toMap(this);
  }
  
  // 创建包含新值的对象副本
  UserModel copyWith({
    String? displayName,
    String? photoURL,
    String? nickname,
    String? gender,
    double? height,
    double? weight,
    int? age,
    DateTime? birthDate,
    bool? isCoach,
    bool? isStudent,
    String? bio,
    String? unitSystem,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      birthDate: birthDate ?? this.birthDate,
      isCoach: isCoach ?? this.isCoach,
      isStudent: isStudent ?? this.isStudent,
      bio: bio ?? this.bio,
      unitSystem: unitSystem ?? this.unitSystem,
      profileCreatedAt: profileCreatedAt,
      profileUpdatedAt: DateTime.now(),
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}

