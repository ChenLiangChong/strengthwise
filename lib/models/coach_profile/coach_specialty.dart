/// 教練專長標籤枚舉
/// 
/// 支援預定義標籤，自定義標籤使用 "custom:" 前綴儲存
enum CoachSpecialty {
  // ========== 體態管理 ==========
  weightLoss('weight_loss', '減重'),
  hypertrophy('hypertrophy', '增肌'),
  bodyRecomposition('body_recomposition', '體態雕塑'),
  bodybuildingPrep('bodybuilding_prep', '健美備賽'),

  // ========== 運動表現 ==========
  strengthConditioning('strength_conditioning', '肌力與體能'),
  olympicLifting('olympic_lifting', '舉重'),
  powerlifting('powerlifting', '力量舉'),
  marathonTraining('marathon_training', '馬拉松訓練'),
  golfFitness('golf_fitness', '高爾夫體能'),

  // ========== 特殊族群 ==========
  seniorFitness('senior_fitness', '銀髮族體適能'),
  prePostNatal('pre_post_natal', '產前/產後訓練'),
  youthFitness('youth_fitness', '青少年體適能'),

  // ========== 健康矯正 ==========
  correctiveExercise('corrective_exercise', '矯正運動'),
  lowerBackPain('lower_back_pain', '下背痛管理'),
  postRehab('post_rehab', '傷後回歸'),
  diabetesManagement('diabetes_management', '糖尿病運動管理'),

  // ========== 身心靈 ==========
  yoga('yoga', '瑜伽'),
  pilates('pilates', '彼拉提斯'),
  functionalTraining('functional_training', '功能性訓練'),
  kettlebell('kettlebell', '壺鈴');

  final String value;
  final String label;

  const CoachSpecialty(this.value, this.label);

  /// 從字串值轉換為枚舉
  /// 
  /// 若為自定義標籤（custom: 前綴），返回 null
  static CoachSpecialty? fromString(String value) {
    // 自定義標籤不在枚舉中
    if (value.startsWith('custom:')) {
      return null;
    }
    
    try {
      return CoachSpecialty.values.firstWhere(
        (e) => e.value == value,
      );
    } catch (_) {
      return null;
    }
  }

  /// 取得標籤的顯示名稱
  /// 
  /// 支援預定義標籤和自定義標籤
  static String getLabel(String value) {
    if (value.startsWith('custom:')) {
      // 自定義標籤：移除前綴
      return value.substring(7);
    }
    
    final specialty = fromString(value);
    return specialty?.label ?? value;
  }

  /// 檢查是否為自定義標籤
  static bool isCustom(String value) {
    return value.startsWith('custom:');
  }

  /// 建立自定義標籤的儲存值
  static String createCustomValue(String label) {
    return 'custom:$label';
  }
}

/// 專長標籤分類（用於 UI 分組顯示）
enum SpecialtyCategory {
  bodyComposition('體態管理', [
    CoachSpecialty.weightLoss,
    CoachSpecialty.hypertrophy,
    CoachSpecialty.bodyRecomposition,
    CoachSpecialty.bodybuildingPrep,
  ]),
  performance('運動表現', [
    CoachSpecialty.strengthConditioning,
    CoachSpecialty.olympicLifting,
    CoachSpecialty.powerlifting,
    CoachSpecialty.marathonTraining,
    CoachSpecialty.golfFitness,
  ]),
  specialPopulations('特殊族群', [
    CoachSpecialty.seniorFitness,
    CoachSpecialty.prePostNatal,
    CoachSpecialty.youthFitness,
  ]),
  healthCorrection('健康矯正', [
    CoachSpecialty.correctiveExercise,
    CoachSpecialty.lowerBackPain,
    CoachSpecialty.postRehab,
    CoachSpecialty.diabetesManagement,
  ]),
  mindBody('身心靈', [
    CoachSpecialty.yoga,
    CoachSpecialty.pilates,
    CoachSpecialty.functionalTraining,
    CoachSpecialty.kettlebell,
  ]);

  final String label;
  final List<CoachSpecialty> specialties;

  const SpecialtyCategory(this.label, this.specialties);
}

