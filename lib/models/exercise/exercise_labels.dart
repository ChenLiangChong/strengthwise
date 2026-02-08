/// 動作分類標籤雙語對照（單一來源）
///
/// 所有 v5.0 列舉值的中英文顯示名稱集中管理。
/// 消費端透過 [resolve] 取得對應語系的標籤。
abstract final class ExerciseLabels {
  /// PPL 標籤
  static const ppl = <String, (String, String)>{
    'push': ('推', 'Push'),
    'pull': ('拉', 'Pull'),
    'legs': ('腿', 'Legs'),
    'core': ('核心', 'Core'),
    'cardio': ('有氧', 'Cardio'),
    'mobility': ('活動度', 'Mobility'),
  };

  /// 器材（19 種，對應 ref_equipment）
  static const equipment = <String, (String, String)>{
    'bodyweight': ('徒手訓練', 'Bodyweight'),
    'barbell': ('槓鈴', 'Barbell'),
    'ez_bar': ('W槓', 'EZ Bar'),
    'dumbbell': ('啞鈴', 'Dumbbell'),
    'kettlebell': ('壺鈴', 'Kettlebell'),
    'cable': ('纜繩', 'Cable'),
    'machine': ('固定式機械', 'Machine'),
    'smith_machine': ('史密斯機', 'Smith Machine'),
    'suspension': ('懸吊訓練', 'Suspension'),
    'resistance_band': ('彈力帶', 'Resistance Band'),
    'medicine_ball': ('藥球', 'Medicine Ball'),
    'battle_rope': ('戰繩', 'Battle Rope'),
    'sled': ('雪橇', 'Sled'),
    'vipr': ('火箭筒', 'ViPR'),
    'foam_roller': ('滾筒', 'Foam Roller'),
    'cardio_machine': ('心肺器材', 'Cardio Machine'),
    'ab_wheel': ('健腹輪', 'Ab Wheel'),
    'landmine': ('地雷管', 'Landmine'),
    'log_bar': ('滾木槓', 'Log Bar'),
  };

  /// 難度等級
  static const difficulty = <String, (String, String)>{
    'beginner': ('初級', 'Beginner'),
    'intermediate': ('中級', 'Intermediate'),
    'advanced': ('進階', 'Advanced'),
  };

  /// 動作類型（複合 / 孤立）
  static const mechanics = <String, (String, String)>{
    'compound': ('複合', 'Compound'),
    'isolation': ('孤立', 'Isolation'),
  };

  /// 肌群分區（6 個 parent group，對應 ref_muscle_groups.parent_group）
  static const muscleGroups = <String, (String, String)>{
    'chest': ('胸部', 'Chest'),
    'back': ('背部', 'Back'),
    'shoulders': ('肩部', 'Shoulders'),
    'arms': ('手臂', 'Arms'),
    'legs': ('腿部', 'Legs'),
    'core': ('核心', 'Core'),
  };

  /// 個別肌肉（26 個，對應 ref_muscle_groups 子項）
  static const muscles = <String, (String, String)>{
    'pec_major_clavicular': ('上胸', 'Upper Chest'),
    'pec_major_sternal': ('中下胸', 'Mid/Lower Chest'),
    'pec_minor': ('胸小肌', 'Pec Minor'),
    'serratus_anterior': ('前鋸肌', 'Serratus Anterior'),
    'lats': ('背闊肌', 'Lats'),
    'traps': ('斜方肌', 'Traps'),
    'rhomboids': ('菱形肌', 'Rhomboids'),
    'erector_spinae': ('豎脊肌', 'Erector Spinae'),
    'teres_major': ('大圓肌', 'Teres Major'),
    'front_delts': ('前三角肌', 'Front Delts'),
    'side_delts': ('中三角肌', 'Lateral Delts'),
    'rear_delts': ('後三角肌', 'Rear Delts'),
    'rotator_cuff': ('肩袖肌群', 'Rotator Cuff'),
    'biceps': ('二頭肌', 'Biceps'),
    'triceps': ('三頭肌', 'Triceps'),
    'brachialis': ('肱肌', 'Brachialis'),
    'forearms': ('前臂', 'Forearms'),
    'quads': ('股四頭肌', 'Quads'),
    'hamstrings': ('腿後肌', 'Hamstrings'),
    'glutes': ('臀部', 'Glutes'),
    'adductors': ('內收肌群', 'Adductors'),
    'calves': ('小腿', 'Calves'),
    'hip_flexors': ('髖屈肌', 'Hip Flexors'),
    'tibialis_anterior': ('脛前肌', 'Tibialis Anterior'),
    'abs': ('腹肌', 'Abs'),
    'obliques': ('腹斜肌', 'Obliques'),
  };

  /// primaryMuscle → parentGroup 對映
  static const muscleToGroup = <String, String>{
    'pec_major_clavicular': 'chest',
    'pec_major_sternal': 'chest',
    'pec_minor': 'chest',
    'serratus_anterior': 'chest',
    'lats': 'back',
    'traps': 'back',
    'rhomboids': 'back',
    'erector_spinae': 'back',
    'teres_major': 'back',
    'front_delts': 'shoulders',
    'side_delts': 'shoulders',
    'rear_delts': 'shoulders',
    'rotator_cuff': 'shoulders',
    'biceps': 'arms',
    'triceps': 'arms',
    'brachialis': 'arms',
    'forearms': 'arms',
    'quads': 'legs',
    'hamstrings': 'legs',
    'glutes': 'legs',
    'adductors': 'legs',
    'calves': 'legs',
    'hip_flexors': 'legs',
    'tibialis_anterior': 'legs',
    'abs': 'core',
    'obliques': 'core',
  };

  /// 依語系取得標籤（[isEn] 預設 false = 中文）
  ///
  /// 若 key 不存在於 map，回傳原始 key 作為 fallback。
  static String resolve(
    Map<String, (String, String)> map,
    String key, {
    bool isEn = false,
  }) =>
      isEn ? (map[key]?.$2 ?? key) : (map[key]?.$1 ?? key);
}
