import 'package:flutter/material.dart';
import 'package:strengthwise/models/statistics_model.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/interfaces/i_favorites_service.dart';
import 'package:strengthwise/views/pages/profile/widgets/favorite_exercises_list.dart';
import 'package:strengthwise/views/pages/exercises/widgets/exercise_selection_navigator.dart';
import 'package:strengthwise/views/pages/exercises/exercise_strength_detail_page.dart';

/// 動作追蹤 Tab 頁面
///
/// 顯示動作的訓練進度記錄（整合收藏功能）
class StrengthProgressTab extends StatefulWidget {
  /// 用戶 ID
  final String userId;

  /// 統計數據
  final StatisticsData statisticsData;

  /// 時間範圍
  final TimeRange timeRange;

  /// 刷新回調
  final VoidCallback? onRefresh;

  const StrengthProgressTab({
    Key? key,
    required this.userId,
    required this.statisticsData,
    required this.timeRange,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<StrengthProgressTab> createState() => _StrengthProgressTabState();
}

class _StrengthProgressTabState extends State<StrengthProgressTab> {
  final IFavoritesService _favoritesService =
      serviceLocator<IFavoritesService>();
  bool _hasFavorites = false;
  int _refreshKey = 0; // 用於強制刷新 FavoriteExercisesList

  @override
  void initState() {
    super.initState();
    _checkFavorites();
  }

  @override
  void didUpdateWidget(StrengthProgressTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當時間範圍或用戶 ID 變化時，重新檢查收藏狀態
    if (oldWidget.timeRange != widget.timeRange ||
        oldWidget.userId != widget.userId) {
      _checkFavorites();
    }
  }

  /// 檢查是否有收藏並刷新列表
  Future<void> _checkFavorites() async {
    try {
      final favorites =
          await _favoritesService.getFavoriteExercises(widget.userId);
      if (mounted) {
        final hasChanged = _hasFavorites != favorites.isNotEmpty;
        setState(() {
          _hasFavorites = favorites.isNotEmpty;
          // ⭐ 優化：只有在收藏狀態改變時才更新 refreshKey
          if (hasChanged) {
            _refreshKey++;
          }
        });
      }
    } catch (e) {
      // 忽略錯誤
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果沒有力量進步數據，顯示選擇頁面
    if (widget.statisticsData.strengthProgress.isEmpty) {
      return ExerciseSelectionNavigator(
        userId: widget.userId,
        timeRange: widget.timeRange, // 傳入時間範圍
        onExerciseSelected: (exerciseId) {
          // 選擇動作後可以刷新數據
          widget.onRefresh?.call();
        },
      );
    }

    // 如果有收藏，顯示收藏列表；否則顯示分類導航
    if (_hasFavorites) {
      return _buildWithFavorites();
    } else {
      return _buildWithSelection();
    }
  }

  /// 建立帶收藏的視圖
  Widget _buildWithFavorites() {
    return FavoriteExercisesList(
      key: ValueKey(_refreshKey), // 使用 refreshKey 強制重建
      userId: widget.userId,
      timeRange: widget.timeRange,
      strengthProgress: widget.statisticsData.strengthProgress, // 傳入統計數據
      onExerciseTap: (exerciseId) {
        // 點擊收藏動作可以查看詳細
        _showExerciseDetails(exerciseId);
      },
      onAddMoreTap: () {
        // 導航到動作選擇頁面
        _showExerciseSelectionPage();
      },
    );
  }

  /// 顯示動作選擇頁面（全屏）
  void _showExerciseSelectionPage() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('選擇動作'),
          ),
          body: ExerciseSelectionNavigator(
            userId: widget.userId,
            timeRange: widget.timeRange, // 傳入時間範圍
            onExerciseSelected: (exercise) {
              // 導航到動作詳情頁面（v3.3+ 傳遞基本數據）
              Navigator.of(context)
                  .pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ExerciseStrengthDetailPage(
                    userId: widget.userId,
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.exerciseName,
                    timeRange: widget.timeRange,
                    exerciseData: exercise, // v3.3+ 傳遞基本數據
                  ),
                ),
              )
                  .then((_) {
                // 🐛 修復：只需要刷新收藏狀態，不需要重新查詢統計數據
                // 使用 post frame callback 確保在框架完成後刷新
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _checkFavorites();
                  }
                });
              });
            },
          ),
        ),
      ),
    )
        .then((_) {
      // 從選擇頁面返回後，重新檢查收藏狀態
      // 使用 post frame callback 確保在框架完成後刷新
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkFavorites();
        }
      });
    });
  }

  /// 建立帶選擇的視圖
  Widget _buildWithSelection() {
    return Column(
      children: [
        // 提示卡片
        Card(
          margin: const EdgeInsets.all(16),
          color: Colors.blue.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue),
                    SizedBox(width: 12),
                    Text(
                      '💪 查看動作進步',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '選擇動作，查看完整的訓練進度曲線和歷史記錄',
                ),
                const SizedBox(height: 4),
                Text(
                  '提示：點擊右上角星號可以收藏常用動作',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 分類導航
        Expanded(
          child: ExerciseSelectionNavigator(
            userId: widget.userId,
            timeRange: widget.timeRange, // 傳入時間範圍
            onExerciseSelected: (exercise) {
              // 導航到動作詳情頁面（v3.3+ 傳遞基本數據）
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => ExerciseStrengthDetailPage(
                    userId: widget.userId,
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.exerciseName,
                    timeRange: widget.timeRange,
                    exerciseData: exercise, // v3.3+ 傳遞基本數據
                  ),
                ),
              )
                  .then((_) {
                // 🐛 修復：只需要刷新收藏狀態，不需要重新查詢統計數據
                // 使用 post frame callback 確保在框架完成後刷新
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _checkFavorites();
                  }
                });
              });
            },
          ),
        ),
      ],
    );
  }

  /// 顯示動作詳情
  void _showExerciseDetails(String exerciseId) {
    // 從 strengthProgress 中找到動作名稱
    final progress = widget.statisticsData.strengthProgress.firstWhere(
      (p) => p.exerciseId == exerciseId,
      orElse: () => widget.statisticsData.strengthProgress.first,
    );

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => ExerciseStrengthDetailPage(
          userId: widget.userId,
          exerciseId: exerciseId,
          exerciseName: progress.exerciseName,
          timeRange: widget.timeRange,
        ),
      ),
    )
        .then((_) {
      // 🐛 修復：只需要刷新收藏狀態，不需要重新查詢統計數據
      // 使用 post frame callback 確保在框架完成後刷新
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkFavorites();
        }
      });
    });
  }
}
