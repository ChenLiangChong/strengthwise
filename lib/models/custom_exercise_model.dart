/// 用戶自定義訓練動作模型
///
/// 用於表示用戶創建的自定義訓練動作。這些動作只對創建它們的用戶可見。
class CustomExercise {
  final String id;
  final String name;      // 動作名稱
  final String userId;    // 創建者ID
  final DateTime createdAt;

  /// 創建一個自定義訓練動作實例
  CustomExercise({
    required this.id,
    required this.name,
    required this.userId,
    required this.createdAt,
  });

  /// 從 Supabase 數據創建對象（snake_case 欄位）
  factory CustomExercise.fromSupabase(Map<String, dynamic> json) {
    return CustomExercise(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      userId: json['user_id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
  
  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  CustomExercise copyWith({
    String? id,
    String? name,
    String? userId,
    DateTime? createdAt,
  }) {
    return CustomExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// 轉換為 JSON 數據格式
  /// 
  /// 用於本地存儲或在非 Firestore 環境中傳輸數據
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
  
  /// 從 JSON 數據創建對象
  factory CustomExercise.fromJson(Map<String, dynamic> json) {
    return CustomExercise(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt']) 
          : DateTime.now(),
    );
  }
  
  @override
  String toString() => 'CustomExercise(id: $id, name: $name)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomExercise &&
        other.id == id &&
        other.name == name &&
        other.userId == userId;
  }
  
  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ userId.hashCode;
} 