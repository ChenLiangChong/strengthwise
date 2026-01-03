/// 訓練執行權限檢查器
///
/// 判斷用戶是否可以修改、編輯、勾選完成等操作
class WorkoutExecutionPermissionChecker {
  final bool _isToday;
  final bool _isPastDate;
  final bool _isFutureDate;
  final bool _isCoachViewingTrainee;  // ⭐ 新增：是否為教練查看學員訓練
  
  WorkoutExecutionPermissionChecker({
    required bool isToday,
    required bool isPastDate,
    required bool isFutureDate,
    required bool isCoachViewingTrainee,  // ⭐ 新增參數
  }) : _isToday = isToday,
       _isPastDate = isPastDate,
       _isFutureDate = isFutureDate,
       _isCoachViewingTrainee = isCoachViewingTrainee;
  
  /// 檢查是否可以修改訓練
  /// 
  /// 如果是今天的訓練，允許修改（但教練不能幫學員打勾）
  bool canModify() {
    return _isToday && !_isPastDate && !_isFutureDate;
  }
  
  /// 檢查是否可以編輯（新增/刪除動作、調整重量組數）
  /// 
  /// - 過去的訓練不能編輯
  /// - 今天和未來的可以編輯
  /// - ⭐ 教練可以編輯學員的訓練（添加動作等）
  bool canEdit() {
    return !_isPastDate; // 只要不是過去的，都可以編輯（包括教練）
  }
  
  /// 檢查是否可以勾選完成
  /// 
  /// - 只有今天的訓練可以勾選完成
  /// - ⭐ 教練不能幫學員勾選完成（學員必須自己完成）
  bool canToggleCompletion() {
    if (_isCoachViewingTrainee) {
      return false;  // ⭐ 教練不能幫學員打勾
    }
    return _isToday; // 只有今天的訓練可以勾選完成
  }
  
  /// 檢查是否可以修改訓練時間
  /// 
  /// 不能修改過去訓練的時間
  bool canModifyTime() {
    return !_isPastDate;
  }
}

