import 'exercise_model.dart';

/// 訓練動作配置模型
///
/// 表示用戶訓練計劃中的一個具體動作配置，包含組數、次數和重量等信息
class WorkoutExercise {
  final String id;               // 唯一標識符
  final String exerciseId;       // 關聯的動作ID
  final String name;             // 動作名稱
  final String? actionName;      // 動作名稱別名
  final String equipment;        // 所需器材
  final List<String> bodyParts;  // 鍛鍊部位
  final int sets;                // 組數
  final int reps;                // 次數（預設值，如果沒有 setTargets）
  final double weight;           // 重量(kg)（預設值，如果沒有 setTargets）
  final int restTime;            // 休息時間（秒）
  final String notes;            // 備註
  final bool isCompleted;        // 是否完成
  final List<Map<String, dynamic>>? setTargets; // 每組的詳細目標（教練功能）

  /// 創建一個訓練動作配置實例
  WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.name,
    this.actionName,
    required this.equipment,
    required this.bodyParts,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restTime,
    this.notes = '',
    this.isCompleted = false,
    this.setTargets, // 可選：每組的詳細目標
  });

  /// 從標準動作模型創建訓練動作配置
  /// 
  /// 使用標準的預設值初始化新的訓練動作配置
  factory WorkoutExercise.fromExercise(Exercise exercise) {
    return WorkoutExercise(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseId: exercise.id,
      name: exercise.name,
      actionName: exercise.actionName,
      equipment: exercise.equipment,
      bodyParts: exercise.bodyParts,
      sets: 4, // 預設值（調整為 4 組）
      reps: 10, // 預設值
      weight: 0, // 預設值
      restTime: 90, // 預設休息時間 90 秒
    );
  }

  /// 轉換為 JSON 數據格式
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'exerciseId': exerciseId,
      'name': name,
      'actionName': actionName,
      'equipment': equipment,
      'bodyParts': bodyParts,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'restTime': restTime,
      'notes': notes,
      'isCompleted': isCompleted,
    };
    
    // 如果有每組的詳細目標，則包含它
    if (setTargets != null && setTargets!.isNotEmpty) {
      json['setTargets'] = setTargets;
    }
    
    return json;
  }

  /// 從 JSON 創建對象
  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseId: json['exerciseId'] ?? '',
      name: json['name'] ?? '',
      actionName: json['actionName'],
      equipment: json['equipment'] ?? '',
      bodyParts: List<String>.from(json['bodyParts'] ?? []),
      sets: json['sets'] ?? 3,
      reps: json['reps'] ?? 10,
      weight: (json['weight'] ?? 0).toDouble(),
      restTime: json['restTime'] ?? 60,
      notes: json['notes'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      setTargets: json['setTargets'] != null 
          ? List<Map<String, dynamic>>.from(json['setTargets'])
          : null,
    );
  }

  /// 從 Firestore 數據創建對象
  factory WorkoutExercise.fromFirestore(Map<String, dynamic> data) {
    return WorkoutExercise(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseId: data['exerciseId'] ?? '',
      name: data['name'] ?? '',
      actionName: data['actionName'],
      equipment: data['equipment'] ?? '',
      bodyParts: List<String>.from(data['bodyParts'] ?? []),
      sets: data['sets'] ?? 3,
      reps: data['reps'] ?? 10,
      weight: (data['weight'] ?? 0).toDouble(),
      restTime: data['restTime'] ?? 60,
      notes: data['notes'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      setTargets: data['setTargets'] != null 
          ? List<Map<String, dynamic>>.from(data['setTargets'])
          : null,
    );
  }
  
  /// 轉換為 Firestore 可用的數據格式
  Map<String, dynamic> toFirestore() {
    return toJson();
  }

  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  WorkoutExercise copyWith({
    String? id,
    String? exerciseId,
    String? name,
    String? actionName,
    String? equipment,
    List<String>? bodyParts,
    int? sets,
    int? reps,
    double? weight,
    int? restTime,
    String? notes,
    bool? isCompleted,
    List<Map<String, dynamic>>? setTargets,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      actionName: actionName ?? this.actionName,
      equipment: equipment ?? this.equipment,
      bodyParts: bodyParts ?? this.bodyParts,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTime: restTime ?? this.restTime,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      setTargets: setTargets ?? this.setTargets,
    );
  }
  
  /// 更新完成狀態
  WorkoutExercise toggleCompletion() {
    return copyWith(isCompleted: !isCompleted);
  }
  
  @override
  String toString() => 'WorkoutExercise(id: $id, name: $name, sets: $sets, reps: $reps)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutExercise && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
} 