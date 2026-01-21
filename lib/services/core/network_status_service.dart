// ⚡ v3.1.1: 網路狀態監聽服務
//
// 偵測網路連線狀態，提供即時狀態更新
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 網路狀態服務
///
/// 功能：
/// - 偵測當前網路連線類型（WiFi、行動網路、無網路）
/// - 監聽網路狀態變化
/// - 提供 Stream 供 UI 訂閱
class NetworkStatusService extends ChangeNotifier {
  static final NetworkStatusService _instance = NetworkStatusService._internal();
  factory NetworkStatusService() => _instance;
  NetworkStatusService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// 當前網路狀態
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// 當前連線類型
  ConnectivityResult _connectionType = ConnectivityResult.none;
  ConnectivityResult get connectionType => _connectionType;

  /// 是否已初始化
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 初始化服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // ⚠️ Windows 平台的 connectivity_plus 有已知 bug，跳過監聽
    if (Platform.isWindows) {
      _isOnline = true;
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('[NetworkStatus] ⚠️ Windows 平台跳過網路監聽（已知問題）');
      }
      return;
    }

    try {
      // 取得當前網路狀態
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);

      // 監聽網路狀態變化
      _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('[NetworkStatus] ✅ 初始化完成，當前狀態: ${_isOnline ? "在線" : "離線"}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NetworkStatus] ⚠️ 初始化失敗: $e');
      }
      // 初始化失敗時預設為在線（避免誤報）
      _isOnline = true;
      _isInitialized = true;
    }
  }

  /// 更新網路狀態
  void _updateStatus(List<ConnectivityResult> results) {
    // 取得主要連線類型（優先 WiFi > Mobile > Ethernet）
    final primaryResult = results.isNotEmpty ? results.first : ConnectivityResult.none;
    
    final wasOnline = _isOnline;
    _connectionType = primaryResult;
    _isOnline = primaryResult != ConnectivityResult.none;

    // 狀態變化時通知監聽者
    if (wasOnline != _isOnline) {
      if (kDebugMode) {
        debugPrint('[NetworkStatus] 🔄 狀態變更: ${_isOnline ? "在線" : "離線"} ($primaryResult)');
      }
      notifyListeners();
    }
  }

  /// 手動檢查網路狀態
  Future<bool> checkConnectivity() async {
    // Windows 平台跳過檢查
    if (Platform.isWindows) return true;

    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      return _isOnline;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NetworkStatus] ⚠️ 檢查連線失敗: $e');
      }
      return true; // 錯誤時預設在線
    }
  }

  /// 取得連線類型的中文描述
  String get connectionTypeDescription {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return '行動網路';
      case ConnectivityResult.ethernet:
        return '有線網路';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return '藍牙';
      case ConnectivityResult.other:
        return '其他';
      case ConnectivityResult.none:
        return '無網路';
    }
  }

  /// 釋放資源
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
