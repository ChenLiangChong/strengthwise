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

  // 從映射創建用戶
  // 支援向後相容：isTrainer→isCoach, isTrainee→isStudent, createdAt→profileCreatedAt
  factory UserModel.fromMap(Map<String, dynamic> map) {
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
      birthDate: _parseTimestamp(map['birthDate']),
      // 向後相容：優先使用 isCoach，否則使用舊的 isTrainer
      isCoach: map['isCoach'] ?? map['isTrainer'] ?? false,
      // 向後相容：優先使用 isStudent，否則使用舊的 isTrainee
      isStudent: map['isStudent'] ?? map['isTrainee'] ?? true,
      bio: map['bio'],
      unitSystem: map['unitSystem'],
      // 向後相容：優先使用 profileCreatedAt，否則使用舊的 createdAt
      profileCreatedAt: _parseTimestamp(map['profileCreatedAt'] ?? map['createdAt']),
      profileUpdatedAt: _parseTimestamp(map['profileUpdatedAt']),
      lastLogin: _parseTimestamp(map['lastLogin']),
    );
  }

  /// 解析時間戳記（支援多種格式）
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is int) {
      // Unix 時間戳記（毫秒）
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp.runtimeType.toString() == 'Timestamp') {
      // Firebase Timestamp
      return DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
    }
    
    return null;
  }

  // 轉換為映射
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'nickname': nickname,
      'gender': gender,
      'height': height,
      'weight': weight,
      'age': age,
      'birthDate': birthDate,
      'isCoach': isCoach,
      'isStudent': isStudent,
      'bio': bio,
      'unitSystem': unitSystem,
      'profileCreatedAt': profileCreatedAt,
      'profileUpdatedAt': profileUpdatedAt,
      'lastLogin': lastLogin,
    };
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