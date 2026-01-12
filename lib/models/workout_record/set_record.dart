/// 組數記錄模型
///
/// 表示一個運動組的詳細數據，包含次數、重量等信息
/// 
/// 支援多種追蹤模式：
/// - weight_reps: 重量(kg) × 次數（預設，重訓）
/// - weight_time: 重量(kg) × 時間(秒)（農夫走路）
/// - reps_only: 僅次數（波比跳）
/// - time_only: 僅時間(秒)（棒式、HIIT）
/// - distance_time: 距離(m) + 時間(秒)（跑步機、划船機）
/// - calories: 卡路里(kcal)（風扇車）
class SetRecord {
  final int setNumber;        // 組數編號
  final int reps;             // 重複次數
  final double weight;        // 重量(kg)
  final int restTime;         // 休息時間(秒)
  final bool completed;       // 是否完成
  final String note;          // 該組的備註
  
  // v3.2+ 新增欄位（選填）- 支援多元追蹤模式
  final int? time;            // 時間(秒) - UI 顯示分:秒
  final double? distance;     // 距離(公尺) - UI 顯示 m 或 km
  final double? calories;     // 熱量(大卡 kcal)

  /// 創建一個組數記錄實例
  SetRecord({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.restTime,
    this.completed = false,
    this.note = '',
    this.time,
    this.distance,
    this.calories,
  });

  /// 轉換為 JSON 數據格式
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'restTime': restTime,
      'completed': completed,
      'note': note,
    };
    
    // 只有非 null 的新欄位才加入 JSON
    if (time != null) json['time'] = time;
    if (distance != null) json['distance'] = distance;
    if (calories != null) json['calories'] = calories;
    
    return json;
  }
  
  /// 從 JSON 數據創建對象
  factory SetRecord.fromJson(Map<String, dynamic> json) {
    return SetRecord(
      setNumber: json['setNumber'] ?? 0,
      reps: json['reps'] ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      restTime: json['restTime'] ?? 0,
      completed: json['completed'] ?? false,
      note: json['note'] ?? '',
      // v3.2+ 新增欄位
      time: json['time'] as int?,
      distance: (json['distance'] as num?)?.toDouble(),
      calories: (json['calories'] as num?)?.toDouble(),
    );
  }

  /// 從 Firestore 數據創建對象
  factory SetRecord.fromFirestore(Map<String, dynamic> data) {
    return SetRecord(
      setNumber: data['setNumber'] ?? 0,
      reps: data['reps'] ?? 0,
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      restTime: data['restTime'] ?? 0,
      completed: data['completed'] ?? false,
      note: data['note'] ?? '',
      // v3.2+ 新增欄位
      time: data['time'] as int?,
      distance: (data['distance'] as num?)?.toDouble(),
      calories: (data['calories'] as num?)?.toDouble(),
    );
  }

  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  SetRecord copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    int? restTime,
    bool? completed,
    String? note,
    int? time,
    double? distance,
    double? calories,
  }) {
    return SetRecord(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTime: restTime ?? this.restTime,
      completed: completed ?? this.completed,
      note: note ?? this.note,
      time: time ?? this.time,
      distance: distance ?? this.distance,
      calories: calories ?? this.calories,
    );
  }
  
  /// 增加重複次數
  SetRecord incrementReps([int increment = 1]) {
    return copyWith(reps: reps + increment);
  }
  
  /// 減少重複次數
  SetRecord decrementReps([int decrement = 1]) {
    final newReps = reps - decrement;
    return copyWith(reps: newReps > 0 ? newReps : 1);
  }
  
  /// 增加重量
  SetRecord incrementWeight([double increment = 2.5]) {
    return copyWith(weight: weight + increment);
  }
  
  /// 減少重量
  SetRecord decrementWeight([double decrement = 2.5]) {
    final newWeight = weight - decrement;
    return copyWith(weight: newWeight > 0 ? newWeight : 0);
  }
  
  /// 標記為已完成
  SetRecord markAsCompleted() {
    return copyWith(completed: true);
  }
  
  /// 標記為未完成
  SetRecord markAsIncomplete() {
    return copyWith(completed: false);
  }
  
  /// 更新備註
  SetRecord updateNote(String newNote) {
    return copyWith(note: newNote);
  }
  
  @override
  String toString() => 'SetRecord(set: $setNumber, reps: $reps, weight: $weight)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetRecord && other.setNumber == setNumber;
  }
  
  @override
  int get hashCode => setNumber.hashCode;
}

