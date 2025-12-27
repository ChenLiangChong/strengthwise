import 'dart:async';
import '../../services/interfaces/i_auth_service.dart';

/// 身份驗證狀態監聽器
///
/// 負責監聽和處理身份驗證狀態變化
class AuthStateListener {
  StreamSubscription? _subscription;
  final Function() _onStateChanged;
  
  AuthStateListener({
    required IAuthService authService,
    required Function() onStateChanged,
  }) : _onStateChanged = onStateChanged;
  
  /// 設置定期檢查的狀態監聽器
  void setupPeriodicListener({Duration interval = const Duration(seconds: 30)}) {
    _subscription?.cancel();
    _subscription = Stream.periodic(interval).listen((_) {
      _onStateChanged();
    });
  }
  
  /// 取消監聽
  Future<void> cancel() async {
    await _subscription?.cancel();
    _subscription = null;
  }
  
  /// 釋放資源
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

