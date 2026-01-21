import 'package:flutter/foundation.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/service_locator.dart';
import 'interfaces/i_delete_account_controller.dart';

/// 刪除帳號控制器
///
/// 職責：
/// - 處理刪除帳號業務邏輯
/// - 提供刪除前的資料統計
/// - 管理刪除狀態
class DeleteAccountController extends ChangeNotifier implements IDeleteAccountController {
  final IUserService _userService;
  
  bool _isDeleting = false;
  String? _errorMessage;
  Map<String, dynamic>? _deleteResult;

  DeleteAccountController({
    IUserService? userService,
  }) : _userService = userService ?? serviceLocator<IUserService>();

  /// 是否正在刪除中
  @override
  bool get isDeleting => _isDeleting;

  /// 錯誤訊息
  @override
  String? get errorMessage => _errorMessage;

  /// 刪除結果
  @override
  Map<String, dynamic>? get deleteResult => _deleteResult;

  /// 執行刪除帳號
  /// 
  /// 返回：
  /// - true: 刪除成功
  /// - false: 刪除失敗
  @override
  Future<bool> deleteAccount() async {
    _isDeleting = true;
    _errorMessage = null;
    _deleteResult = null;
    notifyListeners();

    try {
      _logDebug('開始刪除帳號...');

      final result = await _userService.deleteUserAccount();
      
      _deleteResult = result;
      
      if (result['success'] == true) {
        _logDebug('帳號刪除成功');
        _isDeleting = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? '刪除帳號失敗';
        _logError('帳號刪除失敗: $_errorMessage');
        _isDeleting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '刪除帳號時發生錯誤：$e';
      _logError(_errorMessage!);
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  /// 取得刪除統計資訊（用於顯示確認對話框）
  @override
  String getDeleteSummary() {
    if (_deleteResult == null) {
      return '將刪除您的帳號及所有關聯資料';
    }

    final deleted = _deleteResult!['deleted'] as Map<String, dynamic>?;
    final preserved = _deleteResult!['preserved'] as Map<String, dynamic>?;

    final summary = StringBuffer();
    summary.writeln('將刪除：');
    
    if (deleted != null) {
      if (deleted['coaching_relationships'] != null && deleted['coaching_relationships'] > 0) {
        summary.writeln('• 教練學員關係：${deleted['coaching_relationships']} 筆');
      }
      if (deleted['appointments'] != null && deleted['appointments'] > 0) {
        summary.writeln('• 預約記錄：${deleted['appointments']} 筆');
      }
      if (deleted['workout_plans_trainee'] != null && deleted['workout_plans_trainee'] > 0) {
        summary.writeln('• 訓練記錄：${deleted['workout_plans_trainee']} 筆');
      }
      if (deleted['workout_templates'] != null && deleted['workout_templates'] > 0) {
        summary.writeln('• 訓練模板：${deleted['workout_templates']} 筆');
      }
      summary.writeln('• 身體數據、統計資料等');
    }

    if (preserved != null && preserved.isNotEmpty) {
      summary.writeln('\n將保留：');
      if (preserved['custom_exercises'] != null && preserved['custom_exercises'] > 0) {
        summary.writeln('• 自訂動作：${preserved['custom_exercises']} 個');
      }
      if (preserved['workout_plans_as_coach'] != null && preserved['workout_plans_as_coach'] > 0) {
        summary.writeln('• 您為學員建立的訓練：${preserved['workout_plans_as_coach']} 筆');
      }
    }

    return summary.toString();
  }

  /// 清除錯誤訊息
  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 重置狀態
  @override
  void reset() {
    _isDeleting = false;
    _errorMessage = null;
    _deleteResult = null;
    notifyListeners();
  }

  /// 偵錯日誌
  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('[DELETE_ACCOUNT_CONTROLLER] $message');
    }
  }

  /// 錯誤日誌
  void _logError(String message) {
    if (kDebugMode) {
      debugPrint('[DELETE_ACCOUNT_CONTROLLER ERROR] $message');
    }
  }
}

