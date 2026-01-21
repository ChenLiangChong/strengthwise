import 'package:flutter/foundation.dart';
import '../../models/readiness/daily_readiness_model.dart';

/// 課前問卷控制器接口
///
/// 管理學員問卷填寫狀態與提交邏輯
abstract class IReadinessController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 載入中狀態
  bool get isLoading;

  /// 提交中狀態
  bool get isSubmitting;

  /// 當前問卷指標
  ReadinessMetrics get metrics;

  /// 錯誤訊息
  String? get errorMessage;

  /// 關聯的預約 ID
  String? get appointmentId;

  // ==================== 設置各項指標 ====================

  /// 設置睡眠品質（1-5）
  void setSleepQuality(int value);

  /// 設置睡眠時數（3-12）
  void setSleepHours(double value);

  /// 設置肌肉痠痛程度（1-5）
  void setSoreness(int value);

  /// 設置心理壓力程度（1-5）
  void setStress(int value);

  /// 設置能量水平（1-5）
  void setEnergyLevel(int value);

  /// 設置備註
  void setNotes(String value);

  // ==================== 計算與提交 ====================

  /// 計算預覽分數（用於即時顯示）
  Map<String, dynamic> calculatePreviewScore();

  /// 提交問卷
  Future<void> submitReadiness();
}
