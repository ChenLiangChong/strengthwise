/// 訓練執行權限檢查器
///
/// 判斷用戶是否可以修改、編輯、勾選完成等操作
class WorkoutExecutionPermissionChecker {
  final bool _isToday;
  final bool _isPastDate;
  final bool _isFutureDate;
  
  WorkoutExecutionPermissionChecker({
    required bool isToday,
    required bool isPastDate,
    required bool isFutureDate,
  }) : _isToday = isToday,
       _isPastDate = isPastDate,
       _isFutureDate = isFutureDate;
  
  /// 檢查是否可以修改訓練
  /// 
  /// 如果是今天的訓練，允許修改
  bool canModify() {
    return _isToday && !_isPastDate && !_isFutureDate;
  }
  
  /// 檢查是否可以編輯（新增/刪除動作、調整重量組數）
  /// 
  /// 過去的訓練不能編輯，今天和未來的可以編輯
  bool canEdit() {
    return !_isPastDate; // 只要不是過去的，都可以編輯
  }
  
  /// 檢查是否可以勾選完成
  /// 
  /// 只有今天的訓練可以勾選完成
  bool canToggleCompletion() {
    return _isToday; // 只有今天的訓練可以勾選完成
  }
  
  /// 檢查是否可以修改訓練時間
  /// 
  /// 不能修改過去訓練的時間
  bool canModifyTime() {
    return !_isPastDate;
  }
}

