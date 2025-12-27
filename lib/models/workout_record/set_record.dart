/// 組數記錄模型
///
/// 表示一個運動組的詳細數據，包含次數、重量等信息
class SetRecord {
  final int setNumber;        // 組數編號
  final int reps;             // 重複次數
  final double weight;        // 重量(kg)
  final int restTime;         // 休息時間(秒)
  final bool completed;       // 是否完成
  final String note;          // 該組的備註

  /// 創建一個組數記錄實例
  SetRecord({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.restTime,
    this.completed = false,
    this.note = '',
  });

  /// 轉換為 JSON 數據格式
  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'restTime': restTime,
      'completed': completed,
      'note': note,
    };
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
  }) {
    return SetRecord(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTime: restTime ?? this.restTime,
      completed: completed ?? this.completed,
      note: note ?? this.note,
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

