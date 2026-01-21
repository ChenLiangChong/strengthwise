/// SOAP 筆記模型
/// 
/// Phase 3: 視覺化筆記系統
/// SOAP 格式（醫療與教練領域標準）
class SoapNoteModel {
  /// S (Subjective): 主觀描述
  /// 學員的主觀感受與陳述
  final String? subjective;

  /// O (Objective): 客觀觀察
  /// 教練的客觀觀察（動作、姿勢等）
  final String? objective;

  /// A (Assessment): 評估
  /// 教練的專業評估與分析
  final String? assessment;

  /// P (Plan): 計劃
  /// 下一步訓練計劃與調整
  final String? plan;

  const SoapNoteModel({
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
  });

  /// 從 JSON 創建實例
  factory SoapNoteModel.fromJson(Map<String, dynamic> json) {
    return SoapNoteModel(
      subjective: json['subjective'] as String?,
      objective: json['objective'] as String?,
      assessment: json['assessment'] as String?,
      plan: json['plan'] as String?,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      if (subjective != null) 'subjective': subjective,
      if (objective != null) 'objective': objective,
      if (assessment != null) 'assessment': assessment,
      if (plan != null) 'plan': plan,
    };
  }

  /// 創建副本
  SoapNoteModel copyWith({
    String? subjective,
    String? objective,
    String? assessment,
    String? plan,
  }) {
    return SoapNoteModel(
      subjective: subjective ?? this.subjective,
      objective: objective ?? this.objective,
      assessment: assessment ?? this.assessment,
      plan: plan ?? this.plan,
    );
  }

  /// 是否為空
  bool get isEmpty {
    final s = subjective;
    final o = objective;
    final a = assessment;
    final p = plan;
    return (s == null || s.isEmpty) &&
        (o == null || o.isEmpty) &&
        (a == null || a.isEmpty) &&
        (p == null || p.isEmpty);
  }

  /// 是否完整（所有欄位都填寫）
  bool get isComplete {
    final s = subjective;
    final o = objective;
    final a = assessment;
    final p = plan;
    return s != null &&
        s.isNotEmpty &&
        o != null &&
        o.isNotEmpty &&
        a != null &&
        a.isNotEmpty &&
        p != null &&
        p.isNotEmpty;
  }

  @override
  String toString() {
    return 'SoapNoteModel(subjective: $subjective, objective: $objective, assessment: $assessment, plan: $plan)';
  }
}

