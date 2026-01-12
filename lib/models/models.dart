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

/// 追蹤模式（v3.2+）
export 'tracking_mode.dart';

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

// ========== Phase 2: 教練學員系統 ==========

/// 教練-學員綁定關係
export 'coaching_relationship_model.dart';

/// 預約系統
export 'appointment_model.dart';
export 'availability_slot_model.dart';

/// 學員時間偏好
export 'client_availability_model.dart';

// ========== Phase 3: 視覺化筆記系統 ==========

/// 課程筆記
export 'session_note/session_note_model.dart';
export 'session_note/soap_note_model.dart';
export 'session_note/visual_element_model.dart';

// ========== v3.0: 課前問卷系統 ==========

/// 每日準備度問卷
export 'readiness/daily_readiness_model.dart';

/// 動作歷史記錄（Session Mode PREV）
export 'exercise_history_record.dart';

