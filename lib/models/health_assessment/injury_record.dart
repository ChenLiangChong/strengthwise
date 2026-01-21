import 'package:strengthwise/utils/datetime_utils.dart';

/// 傷病狀態列舉
enum InjuryStatus {
  acute('acute', '急性'),
  subacute('subacute', '亞急性'),
  chronic('chronic', '慢性'),
  postSurgery('post_surgery', '手術後');

  final String value;
  final String label;
  const InjuryStatus(this.value, this.label);

  static InjuryStatus fromString(String value) {
    return InjuryStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InjuryStatus.chronic,
    );
  }
}

/// 傷病記錄
class InjuryRecord {
  /// 部位（例如：右膝、左肩、腰椎）
  final String site;
  
  /// 傷病狀態
  final InjuryStatus status;
  
  /// 具體診斷（例如：前十字韌帶撕裂、椎間盤突出）
  final String? diagnosis;
  
  /// 功能限制（例如：避免跳躍動作、無法完全伸直）
  final String? limitations;
  
  /// 發生日期
  final DateTime? occurredDate;

  const InjuryRecord({
    required this.site,
    required this.status,
    this.diagnosis,
    this.limitations,
    this.occurredDate,
  });

  factory InjuryRecord.fromJson(Map<String, dynamic> json) {
    return InjuryRecord(
      site: json['site'] as String,
      status: InjuryStatus.fromString(json['status'] as String),
      diagnosis: json['diagnosis'] as String?,
      limitations: json['limitations'] as String?,
      occurredDate: json['occurred_date'] != null
          ? DateTimeUtils.parseIsoTimestamp(json['occurred_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'site': site,
      'status': status.value,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (limitations != null) 'limitations': limitations,
      if (occurredDate != null)
        'occurred_date': DateTimeUtils.formatToUtcIso(occurredDate!),
    };
  }

  @override
  String toString() => '$site (${status.label})';
}

