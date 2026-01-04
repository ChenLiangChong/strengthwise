/// 教練證照模型
/// 
/// 用於結構化儲存教練的專業證照資訊
class CertificationModel {
  /// 發證機構
  final String organization;
  
  /// 證照名稱
  final String name;
  
  /// 取得年份
  final int? year;

  CertificationModel({
    required this.organization,
    required this.name,
    this.year,
  });

  /// 從 JSON Map 建立
  factory CertificationModel.fromJson(Map<String, dynamic> json) {
    return CertificationModel(
      organization: json['org'] as String? ?? '',
      name: json['name'] as String? ?? '',
      year: json['year'] as int?,
    );
  }

  /// 轉換為 JSON Map（用於儲存到 JSONB）
  Map<String, dynamic> toJson() {
    return {
      'org': organization,
      'name': name,
      if (year != null) 'year': year,
    };
  }

  /// 顯示用的完整名稱
  String get displayName {
    if (year != null) {
      return '$organization $name ($year)';
    }
    return '$organization $name';
  }

  /// 簡短顯示
  String get shortName {
    if (organization.isNotEmpty && name.isNotEmpty) {
      return '$organization - $name';
    }
    return name.isNotEmpty ? name : organization;
  }

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CertificationModel &&
        other.organization == organization &&
        other.name == name &&
        other.year == year;
  }

  @override
  int get hashCode => Object.hash(organization, name, year);

  /// 複製並修改
  CertificationModel copyWith({
    String? organization,
    String? name,
    int? year,
  }) {
    return CertificationModel(
      organization: organization ?? this.organization,
      name: name ?? this.name,
      year: year ?? this.year,
    );
  }
}

/// 常見證照發證機構（供 UI 選擇用）
class CertificationOrganization {
  static const List<String> common = [
    'NASM',      // National Academy of Sports Medicine
    'ACE',       // American Council on Exercise
    'NSCA',      // National Strength and Conditioning Association
    'ISSA',      // International Sports Sciences Association
    'ACSM',      // American College of Sports Medicine
    'AFAA',      // Athletics and Fitness Association of America
    'NCSF',      // National Council on Strength & Fitness
    'AASFP',     // 亞洲運動及體適能專業學院
    'FISAF',     // Federation of International Sports Aerobics and Fitness
    '中華民國體適能協會',
    '其他',
  ];
}

