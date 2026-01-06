/// 訓練執行權限檢查器
///
/// 判斷用戶是否可以修改、編輯、勾選完成等操作
///
/// =====================================================================
/// ⭐ v3.1 完整權限矩陣
/// =====================================================================
///
/// ## 一、日期限制（最高優先級）
///
/// | 日期 | 訓練計劃卡片 | 訓練執行頁面 |
/// |------|-------------|-------------|
/// | 過去 | ❌ 只能看 | ❌ 只能看 |
/// | 今天 | 依類型權限 | 依類型權限 |
/// | 未來 | 可編輯/刪除，不能打勾/開始 | 可編輯/新增/刪除，不能打勾/開始 |
///
/// ## 二、學員視角 - 訓練計劃卡片
///
/// | 類型 | 刪除計畫 |
/// |------|---------|
/// | 個人 | ✅ |
/// | 教練安排 | ❌ |
/// | 上課 | ❌ |
///
/// ## 三、學員視角 - 訓練執行頁面
///
/// | 類型 | 新增動作 | 新增組數 | 調整重量/次數 | 刪除動作 | 減少組數 | 打勾 | 開始訓練 |
/// |------|---------|---------|--------------|---------|---------|------|---------|
/// | 個人 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
/// | 教練安排 | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ |
/// | 上課 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
///
/// ## 四、教練視角 - 幫學員建立的計畫
///
/// | 操作 | 自己創建的 | 其他教練創建的 |
/// |------|-----------|---------------|
/// | 編輯/新增/刪除 | ✅ | ❌ |
/// | 開始訓練 | ❌ | ❌ |
/// | 打勾 | ❌ | ❌ |
///
/// ## 五、教練視角 - Session Mode 上課計畫
///
/// | 時間段 | 創建/刪除計畫 | 編輯（新增/刪除動作組數） | 打勾 |
/// |--------|-------------|------------------------|------|
/// | 上課前 | ✅ | ✅ | ❌ |
/// | 上課中～+4hr | ✅ | ✅ | ✅ |
/// | +4hr 後 | ❌ | ❌ | ❌ |
///
/// =====================================================================
class WorkoutExecutionPermissionChecker {
  final bool _isToday;
  final bool _isPastDate;
  final bool _isFutureDate;
  final bool _isCoachViewingTrainee; // 教練查看學員訓練（不管誰創建）
  final bool _isViewingOthersCreatedPlan; // 查看別人創建的計畫（學員看教練建的 或 教練看其他教練建的）
  final bool _isSessionPlan; // ⭐ v3.1: 上課類型（有 appointmentId）

  WorkoutExecutionPermissionChecker({
    required bool isToday,
    required bool isPastDate,
    required bool isFutureDate,
    required bool isCoachViewingTrainee,
    required bool isViewingOthersCreatedPlan,
    bool isSessionPlan = false,
  })  : _isToday = isToday,
        _isPastDate = isPastDate,
        _isFutureDate = isFutureDate,
        _isCoachViewingTrainee = isCoachViewingTrainee,
        _isViewingOthersCreatedPlan = isViewingOthersCreatedPlan,
        _isSessionPlan = isSessionPlan;

  /// 檢查是否可以修改訓練狀態（打勾用）
  bool canModify() {
    if (_isSessionPlan) return false;
    return _isToday && !_isPastDate && !_isFutureDate;
  }

  /// 檢查是否可以編輯（修改重量/次數）
  ///
  /// - 自主、教練安排（學員視角）：可以
  /// - 上課類型：不行
  /// - 教練視角：只能編輯自己創建的
  bool canEdit() {
    if (_isSessionPlan) return false;
    if (_isPastDate) return false;
    // 教練查看學員訓練時，只能編輯自己創建的
    if (_isCoachViewingTrainee && _isViewingOthersCreatedPlan) return false;
    return true;
  }

  /// ⭐ v3.1: 檢查是否可以新增（新增動作/新增組數）
  ///
  /// - 自主、教練安排（學員視角）：可以
  /// - 上課類型：不行
  /// - 教練視角：只能對自己創建的新增
  bool canAdd() {
    if (_isSessionPlan) return false;
    if (_isPastDate) return false;
    // 教練查看學員訓練時，只能對自己創建的新增
    if (_isCoachViewingTrainee && _isViewingOthersCreatedPlan) return false;
    return true;
  }

  /// ⭐ v3.1: 檢查是否可以刪除/減少（刪除動作/減少組數/刪除計畫）
  ///
  /// - 自主：可以
  /// - 教練安排（學員視角）：不可以
  /// - 上課：不可以
  /// - 教練視角：只能刪除自己創建的
  bool canDelete() {
    if (_isPastDate) return false;
    if (_isSessionPlan) return false;
    if (_isViewingOthersCreatedPlan) return false; // 不能刪除別人創建的
    return true;
  }

  /// 檢查是否可以勾選完成
  ///
  /// - 自主、教練安排（學員視角）：今天可以
  /// - 上課（學員視角）：不可以（只能在 Session Mode 由教練執行）
  /// - 上課（教練視角）：可以（Session Mode 執行）
  /// - 教練視角（非上課）：不可以（不能幫學員打勾）
  bool canToggleCompletion() {
    // ⭐ v3.1: 上課類型特殊處理
    if (_isSessionPlan) {
      // 教練可以在 Session Mode 中打勾
      if (_isCoachViewingTrainee) return _isToday && !_isFutureDate;
      // 學員不能打勾
      return false;
    }
    if (_isCoachViewingTrainee) return false; // 教練不能幫學員打勾（非上課類型）
    if (_isFutureDate) return false;
    return _isToday;
  }

  /// ⭐ v3.1: 檢查是否可以開始訓練（計時）
  ///
  /// - 自主、教練安排（學員視角）：今天可以
  /// - 上課（學員視角）：不可以（只能在 Session Mode 由教練執行）
  /// - 上課（教練視角）：可以（Session Mode 執行）
  /// - 教練視角（非上課）：不可以
  bool canStartTraining() {
    // ⭐ v3.1: 上課類型特殊處理
    if (_isSessionPlan) {
      // 教練可以在 Session Mode 中開始訓練
      if (_isCoachViewingTrainee) return _isToday && !_isFutureDate;
      // 學員不能開始訓練
      return false;
    }
    if (_isCoachViewingTrainee) return false; // 教練不能幫學員開始訓練（非上課類型）
    if (_isFutureDate) return false;
    return _isToday;
  }

  /// 檢查是否可以修改訓練時間
  bool canModifyTime() {
    if (_isSessionPlan) return false;
    return !_isPastDate;
  }
}
