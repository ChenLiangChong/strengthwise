import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/models/readiness/daily_readiness_model.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/models/session_note/soap_note_model.dart';
import 'package:strengthwise/models/session_note/visual_element_model.dart';
import 'package:strengthwise/services/interfaces/i_readiness_service.dart';
import 'package:strengthwise/services/interfaces/i_session_note_service.dart';
import 'package:strengthwise/services/interfaces/i_workout_service.dart';
import 'package:strengthwise/services/interfaces/i_appointment_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/realtime/session_realtime_service.dart';

/// Session Mode 控制器
///
/// 管理教練上課模式的所有狀態與邏輯
///
/// =====================================================================
/// ⭐ v3.1 Session Mode 權限矩陣
/// =====================================================================
///
/// ## 教練模式 (isCoachMode = true)
///
/// | 時間段 | 創建/刪除計畫 | 編輯（新增/刪除動作組數） | 打勾 | 編輯筆記 |
/// |--------|-------------|------------------------|------|---------|
/// | 上課前 | ✅ | ✅ | ❌ | ✅ |
/// | 上課中～+4hr | ✅ | ✅ | ✅ | ✅ |
/// | +4hr 後 | ❌ | ❌ | ❌ | ✅ |
///
/// ## 學員模式 (isCoachMode = false)
///
/// - 只能查看課程資訊
/// - 只能填寫課前準備度問卷
/// - 不能編輯任何內容
///
/// ## 時間窗口定義
///
/// - `canEditPlan`: 課程結束後 4 小時內可創建/編輯計畫
/// - `canMarkSet`: 課程開始 → 課程結束後 4 小時（即「上課中～+4hr」）
/// - `canEditNotes`: 教練模式下永遠可以
/// =====================================================================
class SessionModeController extends ChangeNotifier {
  final IReadinessService _readinessService;
  final ISessionNoteService _sessionNoteService;
  final IWorkoutService _workoutService;
  final IAppointmentService _appointmentService;
  final SessionRealtimeService _realtimeService;

  // ============================================================
  // 基本資訊
  // ============================================================

  /// 預約 ID
  final String appointmentId;

  /// 學員 ID
  final String clientId;

  /// 學員名稱
  final String clientName;

  /// 課程開始時間
  final DateTime sessionStartTime;

  /// 課程結束時間
  final DateTime sessionEndTime;

  /// 訓練計畫 ID
  String? workoutPlanId;

  /// 是否為教練模式 ⭐ v3.1
  ///
  /// - true: 教練端，可編輯
  /// - false: 學員端，只能查看和填問卷
  final bool isCoachMode;

  // ============================================================
  // 狀態
  // ============================================================

  /// 載入中
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// 課前問卷
  DailyReadinessModel? _readiness;
  DailyReadinessModel? get readiness => _readiness;

  /// SOAP 填寫狀態
  Map<String, bool> _soapStatus = {
    'subjective': false,
    'objective': false,
    'assessment': false,
    'plan': false,
  };
  Map<String, bool> get soapStatus => _soapStatus;

  /// 當前 SOAP 內容
  SoapNoteModel? _currentSoap;
  SoapNoteModel? get currentSoap => _currentSoap;

  /// 課程筆記 ID（用於更新和繪圖連接）
  String? _sessionNoteId;
  String? get sessionNoteId => _sessionNoteId;

  /// 完整的課程筆記 Model（用於更新）
  SessionNoteModel? _sessionNote;

  /// ⭐ v3.1: 視覺元素（照片、繪圖）
  List<VisualElementModel> get visualElements =>
      _sessionNote?.visualElements ?? [];

  /// ⭐ v3.1: 快速標籤
  List<String> get quickTags => _sessionNote?.quickTags ?? [];

  /// ⭐ v3.1: 更新快速標籤
  Future<void> updateQuickTags(List<String> tags) async {
    if (_sessionNote == null) return;

    try {
      final updatedNote = _sessionNote!.copyWith(quickTags: tags);
      await _sessionNoteService.updateNote(updatedNote);
      _sessionNote = updatedNote;
      notifyListeners();
      debugPrint('[SESSION_MODE] 快速標籤更新成功: $tags');
    } catch (e) {
      debugPrint('[SESSION_MODE] 快速標籤更新失敗: $e');
    }
  }

  /// SOAP 自動儲存防抖計時器
  Timer? _soapSaveTimer;

  /// ⭐ v3.1: Realtime 訂閱 ID
  String? _sessionNoteRealtimeId;

  /// 是否有訓練計畫
  bool get hasWorkoutPlan => workoutPlanId != null;

  /// 是否可以結束課程（課程開始後）
  bool get canEndSession {
    final now = DateTime.now();
    return now.isAfter(sessionStartTime);
  }

  /// 課程結束後 4 小時的截止時間
  DateTime get _editDeadline => sessionEndTime.add(const Duration(hours: 4));

  /// 是否在可打勾時間內（課程開始後 → 結束後 4 小時）
  bool get isWithinMarkWindow {
    final now = DateTime.now();
    return now.isAfter(sessionStartTime) && now.isBefore(_editDeadline);
  }

  /// 是否在可編輯計畫時間內（現在 → 課程結束後 4 小時）
  /// 教練可以預先準備課程內容
  bool get isWithinEditWindow {
    final now = DateTime.now();
    return now.isBefore(_editDeadline);
  }

  /// 是否可以打勾 ⭐ v3.1
  ///
  /// 條件：
  /// 1. 必須是教練模式（學員不能打勾）
  /// 2. 必須在打勾時間窗口內（課程開始 → 結束後 4 小時）
  bool get canMarkSet {
    final result = isCoachMode && isWithinMarkWindow;
    debugPrint(
        '[SESSION_MODE] canMarkSet=$result (isCoachMode=$isCoachMode, isWithinMarkWindow=$isWithinMarkWindow)');
    debugPrint(
        '[SESSION_MODE] sessionStartTime=$sessionStartTime, sessionEndTime=$sessionEndTime, _editDeadline=$_editDeadline');
    debugPrint('[SESSION_MODE] now=${DateTime.now()}');
    return result;
  }

  /// 是否可以編輯訓練計畫（創建/刪除/新增動作/刪除動作/新增組數/刪除組數/修改重量次數）⭐ v3.1
  ///
  /// 條件：
  /// 1. 必須是教練模式（學員不能編輯）
  /// 2. 必須在編輯時間窗口內（現在 → 課程結束後 4 小時）
  /// ✅ 教練可以提前準備課程內容
  bool get canEditPlan => isCoachMode && isWithinEditWindow;

  /// 是否可以編輯筆記 ⭐ v3.1
  ///
  /// 條件：只要是教練就可以編輯（不受時間窗口限制）
  bool get canEditNotes => isCoachMode;

  SessionModeController({
    required this.appointmentId,
    required this.clientId,
    required this.clientName,
    required this.sessionStartTime,
    required this.sessionEndTime,
    this.workoutPlanId,
    this.isCoachMode = true,
    IReadinessService? readinessService,
    ISessionNoteService? sessionNoteService,
    IWorkoutService? workoutService,
    IAppointmentService? appointmentService,
    SessionRealtimeService? realtimeService,
  })  : _readinessService =
            readinessService ?? serviceLocator<IReadinessService>(),
        _sessionNoteService =
            sessionNoteService ?? serviceLocator<ISessionNoteService>(),
        _workoutService = workoutService ?? serviceLocator<IWorkoutService>(),
        _appointmentService =
            appointmentService ?? serviceLocator<IAppointmentService>(),
        _realtimeService =
            realtimeService ?? serviceLocator<SessionRealtimeService>() {
    _loadData();
  }

  /// 載入所有資料
  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadReadiness(),
        _loadSessionNote(),
        _loadWorkoutPlan(), // ⭐ v3.1: 載入訓練計畫
      ]);
    } catch (e) {
      debugPrint('Session Mode 載入資料失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 載入課前問卷
  Future<void> _loadReadiness() async {
    try {
      _readiness = await _readinessService.getByAppointmentId(appointmentId);
    } catch (e) {
      debugPrint('載入課前問卷失敗: $e');
    }
  }

  /// 載入訓練計畫 ⭐ v3.1
  Future<void> _loadWorkoutPlan() async {
    try {
      final plan =
          await _workoutService.getRecordByAppointmentId(appointmentId);
      if (plan != null) {
        workoutPlanId = plan.id;
        debugPrint('載入訓練計畫成功: ${plan.id}');
      }
    } catch (e) {
      debugPrint('載入訓練計畫失敗: $e');
    }
  }

  /// 載入課程筆記（檢查 SOAP 狀態）
  ///
  /// ⭐ v3.1: 如果筆記不存在，自動創建一個新的
  Future<void> _loadSessionNote() async {
    try {
      final notesList = await _sessionNoteService.getNotesByAppointment(
        appointmentId: appointmentId,
      );
      if (notesList.isNotEmpty) {
        _sessionNote = notesList.first;
        _sessionNoteId = _sessionNote!.id;
        _currentSoap = _sessionNote!.soap;
        // 檢查 SOAP 各欄位是否已填寫
        _soapStatus = {
          'subjective': _sessionNote!.soap?.subjective?.isNotEmpty ?? false,
          'objective': _sessionNote!.soap?.objective?.isNotEmpty ?? false,
          'assessment': _sessionNote!.soap?.assessment?.isNotEmpty ?? false,
          'plan': _sessionNote!.soap?.plan?.isNotEmpty ?? false,
        };
        debugPrint('[SESSION_MODE] 載入課程筆記成功: $_sessionNoteId');
        // ⭐ v3.1: 訂閱 Realtime 更新
        _subscribeToSessionNote();
      } else {
        // ⭐ v3.1: 筆記不存在，自動創建
        debugPrint('[SESSION_MODE] 找不到課程筆記，自動創建新的...');
        await _createSessionNote();
      }
    } catch (e) {
      debugPrint('載入課程筆記失敗: $e');
    }
  }

  /// ⭐ v3.1: 訂閱課程筆記的 Realtime 更新
  void _subscribeToSessionNote() {
    if (_sessionNoteId == null) return;

    // 取消舊的訂閱
    if (_sessionNoteRealtimeId != null) {
      _realtimeService.unsubscribe(_sessionNoteRealtimeId!);
    }

    _sessionNoteRealtimeId = _realtimeService.subscribeToSessionNote(
      sessionNoteId: _sessionNoteId!,
      onUpdate: _onSessionNoteUpdated,
    );
  }

  /// ⭐ v3.1: 當收到 Realtime 更新時重新載入筆記
  Future<void> _onSessionNoteUpdated() async {
    debugPrint('[SESSION_MODE] 收到 session_note Realtime 更新');

    try {
      final notesList = await _sessionNoteService.getNotesByAppointment(
        appointmentId: appointmentId,
      );

      if (notesList.isNotEmpty) {
        _sessionNote = notesList.first;
        _currentSoap = _sessionNote!.soap;
        debugPrint('[SESSION_MODE] 筆記已重新載入');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SESSION_MODE] 重新載入筆記失敗: $e');
    }
  }

  /// ⭐ v3.1: 自動創建課程筆記
  Future<void> _createSessionNote() async {
    try {
      // 使用課程時間作為筆記標題
      final dateStr = '${sessionStartTime.month}/${sessionStartTime.day}';
      final timeStr =
          '${sessionStartTime.hour.toString().padLeft(2, '0')}:${sessionStartTime.minute.toString().padLeft(2, '0')}';

      // 取得當前用戶（教練）ID（透過 interface）
      final authController = serviceLocator<IAuthController>();
      final coachId = authController.user?.uid;

      final noteToCreate = SessionNoteModel(
        id: '', // Service 會生成 UUID
        title: '$dateStr $timeStr 課程筆記',
        clientId: clientId,
        coachId: coachId,
        appointmentId: appointmentId,
        createdAt: sessionStartTime, // 使用課程開始時間
        updatedAt: DateTime.now(),
      );

      final newNote = await _sessionNoteService.createNote(noteToCreate);

      _sessionNote = newNote;
      _sessionNoteId = newNote.id;
      _currentSoap = newNote.soap;
      _soapStatus = {
        'subjective': false,
        'objective': false,
        'assessment': false,
        'plan': false,
      };

      debugPrint('[SESSION_MODE] 自動創建課程筆記成功: $_sessionNoteId');
    } catch (e) {
      debugPrint('[SESSION_MODE] 自動創建課程筆記失敗: $e');
    }
  }

  /// 更新 SOAP 內容
  void updateSoap(SoapNoteModel soap) {
    _currentSoap = soap;
    _soapStatus = {
      'subjective': soap.subjective?.isNotEmpty ?? false,
      'objective': soap.objective?.isNotEmpty ?? false,
      'assessment': soap.assessment?.isNotEmpty ?? false,
      'plan': soap.plan?.isNotEmpty ?? false,
    };
    notifyListeners();

    // 自動儲存（防抖）
    _autoSaveSoap();
  }

  /// 自動儲存 SOAP（防抖 2 秒）
  void _autoSaveSoap() {
    // 取消之前的計時器
    _soapSaveTimer?.cancel();

    // 2 秒防抖：用戶停止輸入 2 秒後才保存
    _soapSaveTimer = Timer(const Duration(seconds: 2), () async {
      await _saveSoapToSupabase();
    });
  }

  /// 實際儲存 SOAP 到 Supabase
  ///
  /// ⭐ v3.1: 先從資料庫載入最新狀態，避免覆蓋繪圖
  Future<void> _saveSoapToSupabase() async {
    if (_sessionNoteId == null || _currentSoap == null) return;

    try {
      // ⭐ 先從資料庫重新載入最新狀態（包含可能新增的繪圖）
      final latestNotes = await _sessionNoteService.getNotesByAppointment(
        appointmentId: appointmentId,
      );

      if (latestNotes.isEmpty) {
        debugPrint('[SESSION_MODE] ⚠️ 找不到課程筆記，跳過保存');
        return;
      }

      final latestNote = latestNotes.first;

      // 使用最新狀態的 copyWith，只更新 SOAP
      final updatedNote = latestNote.copyWith(soap: _currentSoap);
      await _sessionNoteService.updateNote(updatedNote);

      // 更新本地快取
      _sessionNote = updatedNote;
      debugPrint('[SESSION_MODE] SOAP 自動儲存成功');
    } catch (e) {
      debugPrint('[SESSION_MODE] SOAP 自動儲存失敗: $e');
    }
  }

  /// 立即儲存 SOAP（用於離開頁面時）
  Future<void> saveSoapNow() async {
    _soapSaveTimer?.cancel();
    await _saveSoapToSupabase();
  }

  /// 結束課程
  Future<void> endSession() async {
    try {
      // 先保存 SOAP
      await saveSoapNow();
      // 更新預約狀態為 completed
      await _appointmentService.completeAppointment(appointmentId);
    } catch (e) {
      debugPrint('結束課程失敗: $e');
      rethrow;
    }
  }

  /// 重新載入資料
  Future<void> refresh() async {
    await _loadData();
  }

  /// ⭐ v3.1: 添加照片到課程筆記
  ///
  /// [storagePath] 照片在 Storage 的路徑
  Future<void> addPhotoToNote(String storagePath) async {
    if (_sessionNote == null) {
      debugPrint('[SESSION_MODE] ⚠️ 無法添加照片：session_note 不存在');
      return;
    }

    try {
      debugPrint('[SESSION_MODE] 📷 添加照片到課程筆記');
      debugPrint('   storagePath: $storagePath');
      debugPrint('   sessionNoteId: ${_sessionNote!.id}');

      // 取得現有的 visual_elements
      final existingElements = List<Map<String, dynamic>>.from(
        _sessionNote!.visualElements.map((e) => e.toJson()).toList(),
      );

      // 添加新照片元素
      existingElements.add({
        'type': 'photo',
        'storage_path': storagePath,
      });

      // 更新到資料庫
      final updatedNote = _sessionNote!.copyWith(
        visualElements: existingElements
            .map((e) => VisualElementModel.fromJson(e))
            .toList(),
      );

      await _sessionNoteService.updateNote(updatedNote);
      _sessionNote = updatedNote;

      debugPrint('[SESSION_MODE] ✅ 照片添加成功');
      notifyListeners();
    } catch (e) {
      debugPrint('[SESSION_MODE] ❌ 添加照片失敗: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // 取消防抖計時器
    _soapSaveTimer?.cancel();
    // 立即保存未儲存的 SOAP
    _saveSoapToSupabase();
    // ⭐ v3.1: 取消 Realtime 訂閱
    if (_sessionNoteRealtimeId != null) {
      _realtimeService.unsubscribe(_sessionNoteRealtimeId!);
    }
    super.dispose();
  }
}
