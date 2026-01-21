import 'package:flutter/foundation.dart';

/// 刪除帳號控制器接口
///
/// 處理刪除帳號業務邏輯
abstract class IDeleteAccountController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 是否正在刪除中
  bool get isDeleting;

  /// 錯誤訊息
  String? get errorMessage;

  /// 刪除結果
  Map<String, dynamic>? get deleteResult;

  // ==================== 操作方法 ====================

  /// 執行刪除帳號
  Future<bool> deleteAccount();

  /// 取得刪除統計資訊（用於顯示確認對話框）
  String getDeleteSummary();

  /// 清除錯誤訊息
  void clearError();

  /// 重置狀態
  void reset();
}
