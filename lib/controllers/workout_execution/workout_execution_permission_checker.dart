/// 訓練執行權限檢查器
///
/// 判斷用戶是否可以修改、編輯、勾選完成等操作
/// 
/// v2.9.1 權限矩陣：
/// ⭐ 過去的訓練一律不能修改、刪除、打勾（任何人）
/// - canEdit(): 修改重量/次數/新增動作 → 今天和未來可以
/// - canDelete(): 刪除動作/計畫 → 今天和未來，只有創建者可以
/// - canToggleCompletion(): 打勾 → 只有自己今天的訓練可以
class WorkoutExecutionPermissionChecker {
  final bool _isToday;
  final bool _isPastDate;
  final bool _isFutureDate;
  final bool _isCoachViewingTrainee;  // 教練查看學員訓練（不管誰創建）
  final bool _isViewingOthersCreatedPlan;  // ⭐ 查看別人創建的計畫
  
  WorkoutExecutionPermissionChecker({
    required bool isToday,
    required bool isPastDate,
    required bool isFutureDate,
    required bool isCoachViewingTrainee,
    required bool isViewingOthersCreatedPlan,  // ⭐ 新增參數
  }) : _isToday = isToday,
       _isPastDate = isPastDate,
       _isFutureDate = isFutureDate,
       _isCoachViewingTrainee = isCoachViewingTrainee,
       _isViewingOthersCreatedPlan = isViewingOthersCreatedPlan;
  
  /// 檢查是否可以修改訓練（打勾用）
  /// 
  /// 只有今天的訓練可以修改狀態
  bool canModify() {
    return _isToday && !_isPastDate && !_isFutureDate;
  }
  
  /// 檢查是否可以編輯（修改重量/次數/新增動作/新增組數）
  /// 
  /// - 過去的訓練不能編輯
  /// - 今天和未來的可以編輯
  /// - ⭐ 所有人都可以編輯（包括學員編輯教練創建的）
  bool canEdit() {
    return !_isPastDate;
  }
  
  /// ⭐ 檢查是否可以刪除（刪除動作/刪除計畫）
  /// 
  /// - 過去的訓練不能刪除
  /// - 只有創建者可以刪除自己創建的計畫
  /// - 學員不能刪除教練創建的動作或計畫
  bool canDelete() {
    if (_isPastDate) return false;
    if (_isViewingOthersCreatedPlan) return false;  // ⭐ 不能刪除別人創建的
    return true;
  }
  
  /// 檢查是否可以勾選完成
  /// 
  /// - 只有今天的訓練可以勾選完成
  /// - ⭐ 教練不能幫學員勾選完成
  /// - ⭐ 未來的訓練不能打勾
  bool canToggleCompletion() {
    if (_isCoachViewingTrainee) return false;  // 教練不能幫學員打勾
    if (_isFutureDate) return false;  // 未來不能打勾
    return _isToday;  // 只有今天可以打勾
  }
  
  /// 檢查是否可以修改訓練時間
  bool canModifyTime() {
    return !_isPastDate;
  }
}

