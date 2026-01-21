import 'package:flutter/foundation.dart';
import '../../models/readiness/daily_readiness_model.dart';
import '../../models/session_note/soap_note_model.dart';
import '../../models/session_note/visual_element_model.dart';

/// Session Mode 控制器接口
///
/// 定義與教練上課模式相關的業務邏輯操作。
/// ⭐ v4.0: 架構優化 - 補充 Interface 以支援 Mock 測試
abstract class ISessionModeController extends ChangeNotifier {
  // ==================== 基本資訊 ====================

  /// 預約 ID
  String get appointmentId;

  /// 學員 ID
  String get clientId;

  /// 學員名稱
  String get clientName;

  /// 課程開始時間
  DateTime get sessionStartTime;

  /// 課程結束時間
  DateTime get sessionEndTime;

  /// 訓練計畫 ID
  String? get workoutPlanId;

  /// 是否為教練模式
  bool get isCoachMode;

  // ==================== 狀態 Getters ====================

  /// 載入中狀態
  bool get isLoading;

  /// 課前問卷
  DailyReadinessModel? get readiness;

  /// SOAP 填寫狀態
  Map<String, bool> get soapStatus;

  /// 當前 SOAP 內容
  SoapNoteModel? get currentSoap;

  /// 課程筆記 ID
  String? get sessionNoteId;

  /// 視覺元素（照片、繪圖）
  List<VisualElementModel> get visualElements;

  /// 快速標籤
  List<String> get quickTags;

  // ==================== 計算屬性 ====================

  /// 是否有訓練計畫
  bool get hasWorkoutPlan;

  /// 是否可以結束課程
  bool get canEndSession;

  /// 編輯截止時間
  DateTime get editDeadline;

  /// 課程是否已結束
  bool get isSessionEnded;

  /// 課程是否已完成（從 appointment 查詢）
  bool get isSessionCompleted;

  /// 剩餘編輯時間（分鐘）
  int get remainingEditMinutes;

  /// 是否在可打勾時間內
  bool get isWithinMarkWindow;

  /// 是否在可編輯計畫時間內
  bool get isWithinEditWindow;

  /// 是否可以打勾
  bool get canMarkSet;

  /// 是否可以編輯訓練計畫
  bool get canEditPlan;

  /// 是否可以編輯筆記
  bool get canEditNotes;

  // ==================== 操作方法 ====================

  /// 更新快速標籤
  Future<void> updateQuickTags(List<String> tags);

  /// 更新 SOAP 內容
  void updateSoap(SoapNoteModel soap);

  /// 立即儲存 SOAP
  Future<void> saveSoapNow();

  /// 結束課程
  Future<void> endSession();

  /// 重新載入資料
  Future<void> refresh();

  /// 添加照片到課程筆記
  Future<void> addPhotoToNote(String storagePath);

  /// 釋放資源
  @override
  void dispose();
}
