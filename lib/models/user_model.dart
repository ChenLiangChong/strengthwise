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
  final bool isCoach;
  final bool isStudent;
  final DateTime? profileCreatedAt;
  final DateTime? profileUpdatedAt;

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
    this.isCoach = false,
    this.isStudent = true,
    this.profileCreatedAt,
    this.profileUpdatedAt,
  });

  // 從映射創建用戶
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
      isCoach: map['isCoach'] ?? false,
      isStudent: map['isStudent'] ?? true,
      profileCreatedAt: map['profileCreatedAt'] != null ? 
          (map['profileCreatedAt'] is DateTime ? 
              map['profileCreatedAt'] : 
              DateTime.fromMillisecondsSinceEpoch(map['profileCreatedAt'].millisecondsSinceEpoch)) : null,
      profileUpdatedAt: map['profileUpdatedAt'] != null ? 
          (map['profileUpdatedAt'] is DateTime ? 
              map['profileUpdatedAt'] : 
              DateTime.fromMillisecondsSinceEpoch(map['profileUpdatedAt'].millisecondsSinceEpoch)) : null,
    );
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
      'isCoach': isCoach,
      'isStudent': isStudent,
      'profileCreatedAt': profileCreatedAt,
      'profileUpdatedAt': profileUpdatedAt,
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
    bool? isCoach,
    bool? isStudent,
  }) {
    return UserModel(
      uid: this.uid,
      email: this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      isCoach: isCoach ?? this.isCoach,
      isStudent: isStudent ?? this.isStudent,
      profileCreatedAt: this.profileCreatedAt,
      profileUpdatedAt: DateTime.now(),
    );
  }
} 