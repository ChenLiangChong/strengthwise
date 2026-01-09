// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/datetime_utils.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';

/// 訓練計劃卡片元件
///
/// 顯示訓練計劃的詳細資訊，包括：
/// - 計劃標題
/// - 計劃類型（🏃 自主訓練、📋 教練安排、📍 上課）
/// - 完成狀態
/// - 訓練時間
/// - 動作數量
/// - 訓練進度
/// - 操作按鈕（編輯、刪除、開始訓練）
///
/// =====================================================================
/// ⭐ v3.1 學員視角 - 訓練計劃卡片權限
/// =====================================================================
///
/// | 類型 | 刪除計畫 | 編輯計畫 |
/// |------|---------|---------|
/// | 🏃 個人 | ✅ | ✅ |
/// | 📋 教練安排 | ❌ | ✅ |
/// | 📍 上課 | ❌ | ❌ |
///
/// **日期限制（最高優先級）**：
/// - 過去的訓練計畫：❌ 只能看（不能編輯、刪除）
/// - 已完成的訓練計畫：❌ 不能編輯
///
/// **類型判斷規則**：
/// 1. 有 `appointmentId` → 📍 上課
/// 2. `creatorId != traineeId` → 📋 教練安排
/// 3. 其他 → 🏃 個人
/// =====================================================================
class TrainingPlanCard extends StatelessWidget {
  /// 訓練計劃資料
  final Map<String, dynamic> training;

  /// 當前用戶 ID
  final String? currentUserId;

  /// 執行訓練計劃回調（自主訓練/教練安排）
  final void Function(String planId)? onExecute;

  /// 編輯訓練計劃回調
  final void Function(String planId, DateTime scheduledDate)? onEdit;

  /// 刪除訓練計劃回調
  final void Function(String planId, String planTitle)? onDelete;

  // =====================================================================
  // ⭐ Phase 3.1-B 新增參數
  // =====================================================================

  /// 學員名稱（教練視角顯示）
  final String? studentName;

  /// ⭐ v3.1.1: 教練名稱（學員視角顯示）
  final String? coachName;

  /// 進入課程回調（上課類型）→ SessionModePage
  final void Function(String planId, String? appointmentId)? onEnterSession;

  /// 填寫問卷回調（學員課前填問卷）→ ReadinessFormPage
  final void Function(String? appointmentId)? onFillReadiness;

  /// 是否顯示填問卷按鈕（課前 1hr 內，學員限定）
  final bool showReadinessButton;

  /// 是否為首頁卡片模式（簡化顯示）
  final bool isHomeCard;

  const TrainingPlanCard({
    super.key,
    required this.training,
    this.currentUserId,
    this.onExecute,
    this.onEdit,
    this.onDelete,
    // ⭐ Phase 3.1-B 新增
    this.studentName,
    this.coachName, // ⭐ v3.1.1
    this.onEnterSession,
    this.onFillReadiness,
    this.showReadinessButton = false,
    this.isHomeCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final planId = training['id'] as String;
    final title = training['title'] ?? '未命名訓練';
    final description = training['description'] ?? '';
    final planType = training['planType'] as String? ?? 'self';
    final exercises = training['exercises'] as List<dynamic>? ?? [];
    final completed = training['completed'] as bool? ?? false;
    final isCoachView = training['isCoachView'] as bool? ?? false;

    // ⭐ v3.1 修復：檢測是否為「只有預約沒有訓練計畫」的課程
    final dataType = training['dataType'] as String? ?? 'plan';
    final isSessionOnly = dataType == 'session_only';

    // 訓練計劃創建者和受訓者資訊
    final traineeId = training['trainee_id'] as String?;
    final creatorId = training['creator_id'] as String?;
    // ⭐ v3.1: Session Mode 關聯的預約 ID
    final appointmentId = training['appointment_id'] as String?;

    // 判斷訓練計劃是否為過去的
    final scheduledDate = _parseScheduledDate(training['scheduled_date']);
    final isPastPlan = _isPastDate(scheduledDate);
    final timeInfo = _formatTimeInfo(scheduledDate);

    // ⭐ v3.1: 根據 appointmentId、creatorId、traineeId 判斷計劃類型
    final trainingCategory = _getTrainingCategory(
      appointmentId: appointmentId,
      traineeId: traineeId,
      creatorId: creatorId,
    );

    // 根據完成狀態和計劃類別設置顏色和文字
    final typeInfo = _getTypeInfo(context, completed, trainingCategory);

    // 計算進度
    final progressInfo = _calculateProgress(exercises);

    return Card(
      margin: EdgeInsets.symmetric(
        vertical: context.spacing.sm,
        horizontal: context.spacing.xs,
      ),
      child: InkWell(
        onTap: onExecute != null ? () => onExecute!(planId) : null,
        child: Padding(
          padding: context.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⭐ v3.1: 計算編輯和刪除權限
              // 標題和類型標籤
              _buildHeader(
                context,
                title,
                typeInfo,
                isPastPlan,
                completed,
                planId,
                scheduledDate,
                canDelete: _canDelete(
                    creatorId, currentUserId, isPastPlan, trainingCategory),
                canEdit: _canEdit(isPastPlan, completed, trainingCategory),
              ),

              // ⭐ v3.1.1: 顯示教練/學員名稱（根據視角）
              // 教練視角顯示學員名稱，學員視角顯示教練名稱
              if (isCoachView &&
                  studentName != null &&
                  studentName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      studentName!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ] else if (!isCoachView &&
                  coachName != null &&
                  coachName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.school, // 教練圖標
                      size: 16,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      coachName!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // 描述
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 8),

              // 時間資訊
              _buildInfoRow(
                context,
                Icons.access_time,
                timeInfo,
              ),

              const SizedBox(height: 4),

              // 動作數量（或「尚未建立訓練計畫」提示）
              if (isSessionOnly)
                _buildInfoRow(
                  context,
                  Icons.schedule,
                  '教練尚未建立訓練計畫',
                  color: Theme.of(context).colorScheme.tertiary,
                )
              else
                _buildInfoRow(
                  context,
                  Icons.fitness_center,
                  '${exercises.length} 個動作',
                ),

              // 教練/學員資訊
              if (planType == 'trainer' &&
                  !isCoachView &&
                  currentUserId == traineeId) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  context,
                  Icons.person,
                  '教練安排的計劃',
                ),
              ],

              if (isCoachView && currentUserId == creatorId) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  context,
                  Icons.person,
                  '已分配給學員',
                ),
              ],

              // 進度條（只有預約的課程不顯示進度條）
              if (!isSessionOnly) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressInfo.progress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation(
                    completed
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],

              // 完成狀態和操作按鈕
              const SizedBox(height: 4),
              _buildActionRow(
                context,
                planId: planId,
                appointmentId: appointmentId,
                completed: completed,
                trainingCategory: trainingCategory,
                typeInfo: typeInfo,
                progressInfo: progressInfo,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ⭐ v3.1: 判斷是否可以刪除訓練計畫
  ///
  /// - 自主：創建者可刪除
  /// - 教練安排：不能刪除
  /// - 上課：不能刪除
  bool _canDelete(String? creatorId, String? currentUserId, bool isPastPlan,
      _TrainingCategory category) {
    if (isPastPlan) return false;
    // 上課類型：不能刪除
    if (category == _TrainingCategory.session) return false;
    // 教練安排：學員不能刪除
    if (category == _TrainingCategory.coach) return false;
    // 自主：如果 creatorId 為 null（舊記錄），預設可以刪除（向後相容）
    if (creatorId == null) return true;
    // 只有創建者可以刪除
    return currentUserId == creatorId;
  }

  /// ⭐ v3.1: 判斷是否可以編輯訓練計畫
  bool _canEdit(bool isPastPlan, bool completed, _TrainingCategory category) {
    if (isPastPlan) return false;
    if (completed) return false;
    // 上課類型：不能編輯（只能在 Session Mode 中編輯）
    if (category == _TrainingCategory.session) return false;
    return true;
  }

  /// 構建標題列（包含標題、類型標籤、編輯和刪除按鈕）
  Widget _buildHeader(
    BuildContext context,
    String title,
    _TypeInfo typeInfo,
    bool isPastPlan,
    bool completed,
    String planId,
    DateTime? scheduledDate, {
    required bool canDelete,
    required bool canEdit,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),

        // 類型標籤
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: typeInfo.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            typeInfo.text,
            style: TextStyle(
              color: typeInfo.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),

        // ⭐ v3.1: 編輯按鈕（根據權限顯示）
        if (canEdit && onEdit != null && scheduledDate != null)
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () => onEdit!(planId, scheduledDate),
            tooltip: '編輯訓練計畫',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

        // ⭐ v3.1: 刪除按鈕（根據權限顯示）
        if (canDelete && onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.red,
            onPressed: () => onDelete!(planId, title),
            tooltip: '刪除訓練計畫',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  /// 構建資訊列（圖示 + 文字）
  Widget _buildInfoRow(BuildContext context, IconData icon, String text,
      {Color? color}) {
    final displayColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: displayColor,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: displayColor,
          ),
        ),
      ],
    );
  }

  /// 解析排程日期
  DateTime? _parseScheduledDate(dynamic scheduledDateData) {
    if (scheduledDateData == null) return null;

    try {
      return DateTimeUtils.parseIsoTimestamp(scheduledDateData); // ⭐ 統一工具類
    } catch (e) {
      return null;
    }
  }

  /// 判斷是否為過去的日期
  bool _isPastDate(DateTime? date) {
    if (date == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planDate = DateTime(date.year, date.month, date.day);

    return planDate.isBefore(today);
  }

  /// 格式化時間資訊（v2.1: 支援時間範圍）
  String _formatTimeInfo(DateTime? scheduledDate) {
    if (scheduledDate == null) return '全天';

    // ⭐ v2.1: 檢查是否有結束時間
    final trainingEndTime = training['trainingEndTime'];

    // 只顯示時間部分，如果有
    if (scheduledDate.hour != 0 || scheduledDate.minute != 0) {
      final startTime = '${scheduledDate.hour.toString().padLeft(2, '0')}:'
          '${scheduledDate.minute.toString().padLeft(2, '0')}';

      // ⭐ v2.1: 如果有結束時間，顯示範圍
      if (trainingEndTime != null) {
        try {
          final endTime =
              DateTimeUtils.parseIsoTimestamp(trainingEndTime); // ⭐ 統一工具類
          final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:'
              '${endTime.minute.toString().padLeft(2, '0')}';

          // 計算時長
          final duration = endTime.difference(scheduledDate);
          final hours = duration.inHours;
          final minutes = duration.inMinutes % 60;

          String durationStr = '';
          if (hours > 0) {
            durationStr = '$hours 小時';
            if (minutes > 0) {
              durationStr += ' $minutes 分鐘';
            }
          } else {
            durationStr = '$minutes 分鐘';
          }

          return '$startTime - $endTimeStr ($durationStr)';
        } catch (e) {
          // 解析失敗，只顯示開始時間
          return startTime;
        }
      }

      return startTime;
    }

    return '全天';
  }

  /// ⭐ v3.1: 判斷訓練計劃類別
  ///
  /// 優先級：session > coach > self
  /// - session: 有 appointmentId（上課）
  /// - coach: creatorId ≠ traineeId（教練安排）
  /// - self: 其他（自主）
  _TrainingCategory _getTrainingCategory({
    String? appointmentId,
    String? traineeId,
    String? creatorId,
  }) {
    // 有 appointmentId → 上課
    if (appointmentId != null && appointmentId.isNotEmpty) {
      return _TrainingCategory.session;
    }
    // creatorId ≠ traineeId → 教練安排
    if (creatorId != null && traineeId != null && creatorId != traineeId) {
      return _TrainingCategory.coach;
    }
    // 其他 → 自主
    return _TrainingCategory.self;
  }

  /// 獲取類型資訊（顏色和文字）
  _TypeInfo _getTypeInfo(
      BuildContext context, bool completed, _TrainingCategory category) {
    if (completed) {
      // 已完成的訓練顯示 Secondary 色「已完成」標籤
      return _TypeInfo(
        Theme.of(context).colorScheme.secondary,
        '已完成',
      );
    } else {
      // 未完成的訓練根據類別顯示
      switch (category) {
        case _TrainingCategory.session:
          // ⭐ v3.1: 上課 - 使用 error 色調（紅色系）突顯
          return _TypeInfo(
            Theme.of(context).colorScheme.error,
            '📍 上課',
          );
        case _TrainingCategory.coach:
          // 教練安排 - 使用 tertiary 色
          return _TypeInfo(
            Theme.of(context).colorScheme.tertiary,
            '📋 教練安排',
          );
        case _TrainingCategory.self:
          // 自主 - 使用 primary 色
          return _TypeInfo(
            Theme.of(context).colorScheme.primary,
            '🏃 自主',
          );
      }
    }
  }

  /// 計算訓練進度
  _ProgressInfo _calculateProgress(List<dynamic> exercises) {
    final total = exercises.length;
    final completed = exercises.where((e) => e['completed'] == true).length;
    final progress = total > 0 ? completed / total : 0.0;

    return _ProgressInfo(total, completed, progress);
  }

  // =====================================================================
  // ⭐ Phase 3.1-B: 操作按鈕區域
  // =====================================================================

  /// 構建操作按鈕區域
  ///
  /// 根據訓練類型和角色顯示不同按鈕：
  /// - 📍 上課（學員）：[填問卷] [進入課程]
  /// - 📍 上課（教練）：[開始課程] [查看狀態]
  /// - 🏃 自主 / 📋 教練安排：[開始訓練]
  Widget _buildActionRow(
    BuildContext context, {
    required String planId,
    required String? appointmentId,
    required bool completed,
    required _TrainingCategory trainingCategory,
    required _TypeInfo typeInfo,
    required _ProgressInfo progressInfo,
  }) {
    final isCoachView = training['isCoachView'] as bool? ?? false;
    final isSessionType = trainingCategory == _TrainingCategory.session;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 左側：進度狀態
        Text(
          completed
              ? '已完成'
              : '進行中: ${progressInfo.completed}/${progressInfo.total}',
          style: TextStyle(
            color: completed
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),

        // 右側：操作按鈕
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ⭐ 上課類型的按鈕
            if (isSessionType) ...[
              // 學員視角：填問卷按鈕（課前 1hr 內）→ ReadinessFormPage
              if (!isCoachView &&
                  showReadinessButton &&
                  onFillReadiness != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () => onFillReadiness!(appointmentId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.tertiary,
                    ),
                    child: const Text('填問卷'),
                  ),
                ),

              // 進入/開始課程按鈕 → SessionModePage
              if (onEnterSession != null)
                FilledButton(
                  onPressed: () => onEnterSession!(planId, appointmentId),
                  style: FilledButton.styleFrom(
                    backgroundColor: typeInfo.color,
                  ),
                  child: Text(isCoachView ? '開始課程' : '進入課程'),
                ),
            ]

            // ⭐ 自主訓練 / 教練安排 的按鈕 → WorkoutExecutionPage
            else if (onExecute != null)
              OutlinedButton(
                onPressed: () => onExecute!(planId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: typeInfo.color,
                ),
                child: Text(completed ? '查看訓練' : '開始訓練'),
              ),
          ],
        ),
      ],
    );
  }
}

/// ⭐ v3.1: 訓練計劃類別
enum _TrainingCategory {
  self, // 自主：完全控制
  coach, // 教練安排：不能刪除計畫/動作/組數
  session, // 上課：只能看
}

/// 類型資訊（私有類別）
class _TypeInfo {
  final Color color;
  final String text;

  _TypeInfo(this.color, this.text);
}

/// 進度資訊（私有類別）
class _ProgressInfo {
  final int total;
  final int completed;
  final double progress;

  _ProgressInfo(this.total, this.completed, this.progress);
}
