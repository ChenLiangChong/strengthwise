import 'package:strengthwise/models/coach_profile/certification_model.dart';
import 'package:strengthwise/models/coach_profile/coach_specialty.dart';
import 'package:strengthwise/utils/datetime_utils.dart';

/// 教練公開檔案模型
/// 
/// 與 users 表 1:1 關聯，儲存教練的專業資訊
class CoachProfileModel {
  /// 教練 ID（與 users.id 相同）
  final String id;

  /// 顯示名稱（品牌名）
  final String? displayName;

  /// 專業頭銜（一句話描述，max 160 chars）
  final String? headline;

  /// 專業介紹（詳細背景）
  final String? bio;

  /// 專長標籤列表
  /// 
  /// 預定義標籤使用 CoachSpecialty.value
  /// 自定義標籤使用 "custom:標籤名" 格式
  final List<String> specialties;

  /// 證照列表
  final List<CertificationModel> certifications;

  /// 從業年資
  final int yearsExperience;

  /// 語言能力
  final List<String> languages;

  /// 建立時間
  final DateTime? createdAt;

  /// 更新時間
  final DateTime? updatedAt;

  // ========== 未來計劃欄位（暫不使用） ==========
  
  /// 服務模式
  final List<String> serviceTypes;

  /// 最低時薪
  final int? hourlyRateMin;

  /// 最高時薪
  final int? hourlyRateMax;

  /// 幣別
  final String currency;

  /// 是否提供免費諮詢
  final bool offersFreeConsultation;

  /// 審核狀態
  final String verifiedStatus;

  /// URL slug
  final String? slug;

  CoachProfileModel({
    required this.id,
    this.displayName,
    this.headline,
    this.bio,
    this.specialties = const [],
    this.certifications = const [],
    this.yearsExperience = 0,
    this.languages = const ['zh-TW'],
    this.createdAt,
    this.updatedAt,
    // 未來計劃欄位
    this.serviceTypes = const [],
    this.hourlyRateMin,
    this.hourlyRateMax,
    this.currency = 'TWD',
    this.offersFreeConsultation = false,
    this.verifiedStatus = 'pending',
    this.slug,
  });

  /// 從 Supabase 數據建立模型
  factory CoachProfileModel.fromSupabase(Map<String, dynamic> json) {
    // 解析專長標籤
    final specialtiesJson = json['specialties'];
    final List<String> specialties = [];
    if (specialtiesJson is List) {
      for (final item in specialtiesJson) {
        if (item is String) {
          specialties.add(item);
        }
      }
    }

    // 解析證照列表
    final certificationsJson = json['certifications'];
    final List<CertificationModel> certifications = [];
    if (certificationsJson is List) {
      for (final item in certificationsJson) {
        if (item is Map<String, dynamic>) {
          certifications.add(CertificationModel.fromJson(item));
        }
      }
    }

    // 解析語言
    final languagesJson = json['languages'];
    final List<String> languages = [];
    if (languagesJson is List) {
      for (final item in languagesJson) {
        if (item is String) {
          languages.add(item);
        }
      }
    }

    // 解析服務模式
    final serviceTypesJson = json['service_types'];
    final List<String> serviceTypes = [];
    if (serviceTypesJson is List) {
      for (final item in serviceTypesJson) {
        if (item is String) {
          serviceTypes.add(item);
        }
      }
    }

    return CoachProfileModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      specialties: specialties,
      certifications: certifications,
      yearsExperience: json['years_experience'] as int? ?? 0,
      languages: languages.isEmpty ? ['zh-TW'] : languages,
      createdAt: DateTimeUtils.parseIsoTimestamp(json['created_at']),
      updatedAt: DateTimeUtils.parseIsoTimestamp(json['updated_at']),
      // 未來計劃欄位
      serviceTypes: serviceTypes,
      hourlyRateMin: json['hourly_rate_min'] as int?,
      hourlyRateMax: json['hourly_rate_max'] as int?,
      currency: json['currency'] as String? ?? 'TWD',
      offersFreeConsultation: json['offers_free_consultation'] as bool? ?? false,
      verifiedStatus: json['verified_status'] as String? ?? 'pending',
      slug: json['slug'] as String?,
    );
  }

  /// 轉換為 Supabase 儲存格式
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'headline': headline,
      'bio': bio,
      'specialties': specialties,
      'certifications': certifications.map((c) => c.toJson()).toList(),
      'years_experience': yearsExperience,
      'languages': languages,
      // 未來計劃欄位（保留預設值）
      'service_types': serviceTypes,
      if (hourlyRateMin != null) 'hourly_rate_min': hourlyRateMin,
      if (hourlyRateMax != null) 'hourly_rate_max': hourlyRateMax,
      'currency': currency,
      'offers_free_consultation': offersFreeConsultation,
      'verified_status': verifiedStatus,
      if (slug != null) 'slug': slug,
    };
  }

  /// 轉換為更新用 Map（不含 id 和時間戳）
  Map<String, dynamic> toUpdateMap() {
    return {
      'display_name': displayName,
      'headline': headline,
      'bio': bio,
      'specialties': specialties,
      'certifications': certifications.map((c) => c.toJson()).toList(),
      'years_experience': yearsExperience,
      'languages': languages,
    };
  }

  /// 複製並修改
  CoachProfileModel copyWith({
    String? displayName,
    String? headline,
    String? bio,
    List<String>? specialties,
    List<CertificationModel>? certifications,
    int? yearsExperience,
    List<String>? languages,
    List<String>? serviceTypes,
    int? hourlyRateMin,
    int? hourlyRateMax,
    String? currency,
    bool? offersFreeConsultation,
    String? verifiedStatus,
    String? slug,
  }) {
    return CoachProfileModel(
      id: id,
      displayName: displayName ?? this.displayName,
      headline: headline ?? this.headline,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      certifications: certifications ?? this.certifications,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      languages: languages ?? this.languages,
      createdAt: createdAt,
      updatedAt: updatedAt,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      hourlyRateMin: hourlyRateMin ?? this.hourlyRateMin,
      hourlyRateMax: hourlyRateMax ?? this.hourlyRateMax,
      currency: currency ?? this.currency,
      offersFreeConsultation: offersFreeConsultation ?? this.offersFreeConsultation,
      verifiedStatus: verifiedStatus ?? this.verifiedStatus,
      slug: slug ?? this.slug,
    );
  }

  /// 取得專長標籤的顯示名稱列表
  List<String> get specialtyLabels {
    return specialties.map((s) => CoachSpecialty.getLabel(s)).toList();
  }

  /// 檢查檔案是否已填寫基本資料
  bool get isProfileComplete {
    return displayName?.isNotEmpty == true &&
        bio?.isNotEmpty == true &&
        specialties.isNotEmpty;
  }

  /// 建立空白教練檔案（用於新教練）
  factory CoachProfileModel.empty(String coachId) {
    return CoachProfileModel(
      id: coachId,
      languages: ['zh-TW'],
    );
  }

  @override
  String toString() {
    return 'CoachProfileModel(id: $id, displayName: $displayName, specialties: ${specialties.length})';
  }
}

