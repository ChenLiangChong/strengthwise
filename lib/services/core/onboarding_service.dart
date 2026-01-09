import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Onboarding 引導服務
///
/// 追蹤用戶已完成的 Coach Mark 引導狀態，使用 Hive 本地存儲
/// 
/// v3.2 重構：改用 Coach Mark 情境式引導
/// - 每個功能點獨立追蹤
/// - 第一次進入頁面時觸發
/// - 可在設定中重置
class OnboardingService {
  static const String _boxName = 'onboarding_status';
  
  // ========================================
  // Coach Mark Keys（v3.2）
  // ========================================
  
  // 所有用戶基本引導
  static const String keyBookingPage = 'coach_mark_booking_page';
  static const String keyBookingPageCoachTab = 'coach_mark_booking_page_coach_tab';
  static const String keyHomePage = 'coach_mark_home_page';
  static const String keyTrainingPage = 'coach_mark_training_page';
  static const String keyWorkoutPlanCreate = 'coach_mark_workout_plan_create';
  static const String keyClientHub = 'coach_mark_client_hub';
  static const String keyClientCoachDetail = 'coach_mark_client_coach_detail';
  static const String keyClientAvailability = 'coach_mark_client_availability';
  
  // 教練額外引導
  static const String keyCoachHub = 'coach_mark_coach_hub';
  static const String keyCoachClientDetail = 'coach_mark_coach_client_detail';
  static const String keyCoachSlots = 'coach_mark_coach_slots';
  
  // 舊版 keys（保留相容性）
  static const String keyAskedCoachMode = 'asked_coach_mode';
  
  /// 所有 Coach Mark keys 列表（用於重置）
  static const List<String> allCoachMarkKeys = [
    keyBookingPage,
    keyBookingPageCoachTab,
    keyHomePage,
    keyTrainingPage,
    keyWorkoutPlanCreate,
    keyClientHub,
    keyClientCoachDetail,
    keyClientAvailability,
    keyCoachHub,
    keyCoachClientDetail,
    keyCoachSlots,
  ];
  
  Box? _box;
  
  /// 初始化服務
  Future<void> initialize() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
      } else {
        _box = await Hive.openBox(_boxName);
      }
      
      if (kDebugMode) {
        print('[OnboardingService] ✅ 初始化完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OnboardingService] ⚠️ 初始化失敗: $e');
      }
    }
  }
  
  /// 確保 Box 已開啟
  Future<Box> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      await initialize();
    }
    return _box!;
  }
  
  // ========================================
  // Coach Mark 通用方法
  // ========================================
  
  /// 檢查某個 Coach Mark 是否已完成
  Future<bool> isCoachMarkCompleted(String key) async {
    try {
      final box = await _ensureBox();
      return box.get(key, defaultValue: false) as bool;
    } catch (e) {
      if (kDebugMode) {
        print('[OnboardingService] ⚠️ 讀取 Coach Mark 狀態失敗 ($key): $e');
      }
      return false;
    }
  }
  
  /// 標記某個 Coach Mark 已完成
  Future<void> markCoachMarkCompleted(String key) async {
    try {
      final box = await _ensureBox();
      await box.put(key, true);
      
      if (kDebugMode) {
        print('[OnboardingService] ✅ Coach Mark 已完成: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OnboardingService] ⚠️ 標記 Coach Mark 失敗 ($key): $e');
      }
    }
  }
  
  /// 檢查並標記 Coach Mark（如果未完成則返回 true，同時標記完成）
  /// 用於「首次進入時顯示」的邏輯
  Future<bool> shouldShowCoachMark(String key) async {
    final completed = await isCoachMarkCompleted(key);
    if (!completed) {
      await markCoachMarkCompleted(key);
      return true;
    }
    return false;
  }
  
  // ========================================
  // 教練模式詢問（保留）
  // ========================================
  
  /// 檢查是否已詢問過教練模式
  Future<bool> hasAskedCoachMode() async {
    try {
      final box = await _ensureBox();
      return box.get(keyAskedCoachMode, defaultValue: false) as bool;
    } catch (e) {
      if (kDebugMode) {
        print('[OnboardingService] ⚠️ 讀取教練模式詢問狀態失敗: $e');
      }
      return false;
    }
  }
  
  /// 標記已詢問過教練模式
  Future<void> markAskedCoachMode() async {
    try {
      final box = await _ensureBox();
      await box.put(keyAskedCoachMode, true);
      
      if (kDebugMode) {
        print('[OnboardingService] ✅ 教練模式詢問已標記');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OnboardingService] ⚠️ 標記教練模式詢問失敗: $e');
      }
    }
  }
  
  // ========================================
  // 重置（設定頁面用）
  // ========================================
  
  /// 重置所有 Coach Mark 狀態
  Future<void> resetAllCoachMarks() async {
    try {
      final box = await _ensureBox();
      
      for (final key in allCoachMarkKeys) {
        await box.put(key, false);
      }
      
      // 注意：不重置 keyAskedCoachMode，避免重複詢問
      
      if (kDebugMode) {
        print('[OnboardingService] ✅ 所有 Coach Mark 已重置');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OnboardingService] ⚠️ 重置 Coach Mark 失敗: $e');
      }
    }
  }
  
  /// 重置單個 Coach Mark
  Future<void> resetCoachMark(String key) async {
    try {
      final box = await _ensureBox();
      await box.put(key, false);
      
      if (kDebugMode) {
        print('[OnboardingService] ✅ Coach Mark 已重置: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[OnboardingService] ⚠️ 重置 Coach Mark 失敗 ($key): $e');
      }
    }
  }
  
  // ========================================
  // 舊版方法（保留相容性，將被移除）
  // ========================================
  
  @Deprecated('使用 resetAllCoachMarks() 替代')
  Future<void> resetAllOnboarding() async {
    await resetAllCoachMarks();
  }
}
