import 'package:flutter/foundation.dart';
import 'package:strengthwise/models/readiness/daily_readiness_model.dart';
import 'package:strengthwise/services/interfaces/i_readiness_service.dart';
import 'package:strengthwise/services/interfaces/i_auth_service.dart';
import 'package:strengthwise/services/service_locator.dart';

/// 課前問卷控制器
///
/// 管理學員問卷填寫狀態與提交邏輯
class ReadinessController extends ChangeNotifier {
  final IReadinessService _readinessService;
  final IAuthService _authService;

  /// 關聯的預約 ID
  final String? appointmentId;

  /// 載入中狀態
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 提交中狀態
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  /// 當前問卷指標
  ReadinessMetrics _metrics;
  ReadinessMetrics get metrics => _metrics;

  /// 錯誤訊息
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 已存在的問卷 ID（用於更新）
  String? _existingId;

  ReadinessController({
    this.appointmentId,
    IReadinessService? readinessService,
    IAuthService? authService,
  })  : _readinessService = readinessService ?? serviceLocator<IReadinessService>(),
        _authService = authService ?? serviceLocator<IAuthService>(),
        _metrics = ReadinessMetrics.empty() {
    _loadExistingReadiness();
  }

  /// 載入現有問卷（如果已填過）
  Future<void> _loadExistingReadiness() async {
    if (appointmentId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final existing = await _readinessService.getByAppointmentId(appointmentId!);
      if (existing != null) {
        _existingId = existing.id;
        _metrics = existing.metrics;
      }
    } catch (e) {
      debugPrint('載入現有問卷失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // 設置各項指標
  // ============================================================

  /// 設置睡眠品質（1-5）
  void setSleepQuality(int value) {
    _metrics = _metrics.copyWith(sleepQuality: value.clamp(1, 5));
    notifyListeners();
  }

  /// 設置睡眠時數（3-12）
  void setSleepHours(double value) {
    _metrics = _metrics.copyWith(sleepHours: value.clamp(3.0, 12.0));
    notifyListeners();
  }

  /// 設置肌肉痠痛程度（1-5）
  void setSoreness(int value) {
    _metrics = _metrics.copyWith(soreness: value.clamp(1, 5));
    notifyListeners();
  }

  /// 設置心理壓力程度（1-5）
  void setStress(int value) {
    _metrics = _metrics.copyWith(stress: value.clamp(1, 5));
    notifyListeners();
  }

  /// 設置能量水平（1-5）
  void setEnergyLevel(int value) {
    _metrics = _metrics.copyWith(energyLevel: value.clamp(1, 5));
    notifyListeners();
  }

  /// 設置備註
  void setNotes(String value) {
    _metrics = _metrics.copyWith(notes: value.isEmpty ? null : value);
    // 不需要 notifyListeners，TextField 自己管理狀態
  }

  // ============================================================
  // 計算與提交
  // ============================================================

  /// 計算預覽分數（用於即時顯示）
  Map<String, dynamic> calculatePreviewScore() {
    return _readinessService.calculateReadinessScore(_metrics);
  }

  /// 提交問卷
  Future<void> submitReadiness() async {
    final currentUser = _authService.getCurrentUser();
    final userId = currentUser?['uid'] as String?; // ⭐ v3.1: 修正 key 名稱
    if (userId == null) {
      throw Exception('用戶未登入');
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final readiness = DailyReadinessModel.create(
        userId: userId,
        appointmentId: appointmentId,
        logDate: DateTime.now(),
      ).copyWith(metrics: _metrics);

      if (_existingId != null) {
        // 更新現有問卷
        await _readinessService.updateReadiness(
          readiness.copyWith(id: _existingId),
        );
      } else {
        // 建立新問卷
        await _readinessService.createReadiness(readiness);
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}

