import 'user_model.dart';
import 'user_timestamp_parser.dart';

/// 使用者數據映射器
///
/// 負責在不同數據格式（Map、Supabase）之間轉換 UserModel
class UserMapper {
  /// 從 Map 創建用戶（Firestore 格式，向後相容）
  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      nickname: map['nickname'],
      gender: map['gender'],
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      age: map['age'],
      birthDate: UserTimestampParser.parse(map['birthDate']),
      // 向後相容：優先使用 isCoach，否則使用舊的 isTrainer
      isCoach: map['isCoach'] ?? map['isTrainer'] ?? false,
      // 向後相容：優先使用 isStudent，否則使用舊的 isTrainee
      isStudent: map['isStudent'] ?? map['isTrainee'] ?? true,
      bio: map['bio'],
      unitSystem: map['unitSystem'],
      // 向後相容：優先使用 profileCreatedAt，否則使用舊的 createdAt
      profileCreatedAt: UserTimestampParser.parse(
        map['profileCreatedAt'] ?? map['createdAt']
      ),
      profileUpdatedAt: UserTimestampParser.parse(map['profileUpdatedAt']),
      lastLogin: UserTimestampParser.parse(map['lastLogin']),
    );
  }

  /// 從 Supabase 數據創建用戶（snake_case 欄位）
  static UserModel fromSupabase(Map<String, dynamic> json) {
    return UserModel(
      uid: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'],
      photoURL: json['photo_url'],
      nickname: json['nickname'],
      gender: json['gender'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      age: json['age'],
      birthDate: UserTimestampParser.parse(json['birth_date']),
      isCoach: json['is_coach'] ?? false,
      isStudent: json['is_student'] ?? true,
      bio: json['bio'],
      unitSystem: json['unit_system'],
      profileCreatedAt: UserTimestampParser.parse(json['profile_created_at']),
      profileUpdatedAt: UserTimestampParser.parse(json['profile_updated_at']),
      lastLogin: UserTimestampParser.parse(json['last_login']),
    );
  }

  /// 轉換為 Map（用於存儲）
  static Map<String, dynamic> toMap(UserModel user) {
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'nickname': user.nickname,
      'gender': user.gender,
      'height': user.height,
      'weight': user.weight,
      'age': user.age,
      'birthDate': user.birthDate,
      'isCoach': user.isCoach,
      'isStudent': user.isStudent,
      'bio': user.bio,
      'unitSystem': user.unitSystem,
      'profileCreatedAt': user.profileCreatedAt,
      'profileUpdatedAt': user.profileUpdatedAt,
      'lastLogin': user.lastLogin,
    };
  }
}

