// StrengthWise Models - 統一導出文件
//
// 使用指南：
// - 優先使用具體的模組導入（如 import '../models/user/user_model.dart'）
// - 只在需要多個模型時使用此文件
//
// 架構說明：
// - 每個領域都有獨立的子文件夾和對應的 export 文件
// - 此文件統一導出所有子模組，便於統一導入

// ========== 核心模型 ==========

/// 使用者模型
export 'user/user_model.dart';

/// 訓練動作模型
export 'exercise/exercise.dart';
export 'exercise/exercise_type_enum.dart';

/// 自訂動作模型
export 'custom_exercise/custom_exercise.dart';

/// 身體數據記錄
export 'body_data/body_data_record.dart';

// ========== 訓練計劃相關 ==========

/// 訓練計劃模板
export 'workout_template/workout_template.dart';
export 'workout_template/workout_exercise.dart';
export 'workout_template/plan_type_enum.dart';

// ========== 訓練記錄相關 ==========

/// 訓練記錄
export 'workout_record/workout_record.dart';
export 'workout_record/exercise_record.dart';
export 'workout_record/set_record.dart';

// ========== 統計相關 ==========

/// 統計數據
export 'statistics/statistics_data.dart';
export 'statistics/time_range.dart';
export 'statistics/training_frequency.dart';
export 'statistics/training_volume.dart';
export 'statistics/body_part_stats.dart';
export 'statistics/training_type_stats.dart';
export 'statistics/equipment_stats.dart';
export 'statistics/personal_record.dart';
export 'statistics/strength_progress.dart';
export 'statistics/muscle_group_balance.dart';
export 'statistics/training_calendar.dart';
export 'statistics/completion_rate.dart';
export 'statistics/training_suggestion.dart';

// ========== 筆記相關 ==========

/// 筆記
export 'note/note.dart';
export 'note/drawing_point.dart';

// ========== 收藏相關 ==========

/// 收藏動作
export 'favorite/favorite_exercise.dart';
export 'favorite/exercise_with_record.dart';

