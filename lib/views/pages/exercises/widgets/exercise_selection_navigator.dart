// ⭐ MVVM 重構：移除 Service 直接調用，改用 Controller
import 'package:flutter/material.dart';
import 'package:strengthwise/models/favorite_exercise_model.dart';
import 'package:strengthwise/models/statistics/time_range.dart';
import 'package:strengthwise/controllers/exercise_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_statistics_controller.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'widgets/selection_breadcrumb.dart';
import 'widgets/selection_list.dart';
import 'widgets/exercise_list_view.dart';

/// 3 層分類導航組件（用於選擇有訓練記錄的動作）
///
/// 層級結構：
/// - 第 1 層：訓練類型（心肺、活動度、阻力訓練、自訂）
/// - 第 2 層：身體部位（bodyPart）
/// - 第 3 層：動作列表
///
/// 優化：一次性批量查詢所有數據，後續用客戶端過濾
class ExerciseSelectionNavigator extends StatefulWidget {
  final String userId;
  final Function(ExerciseWithRecord exercise)? onExerciseSelected;
  final TimeRange? timeRange; // 時間範圍過濾（可選）

  const ExerciseSelectionNavigator({
    Key? key,
    required this.userId,
    this.onExerciseSelected,
    this.timeRange,
  }) : super(key: key);

  @override
  State<ExerciseSelectionNavigator> createState() =>
      _ExerciseSelectionNavigatorState();
}

class _ExerciseSelectionNavigatorState
    extends State<ExerciseSelectionNavigator> {
  // ⭐ MVVM 重構：改用 Controller
  final ExerciseController _exerciseController =
      serviceLocator<ExerciseController>();
  final IStatisticsController _statisticsController =
      serviceLocator<IStatisticsController>();

  // 層級：0=訓練類型, 1=身體部位, 2=動作列表
  int _currentStep = 0;

  String? _selectedTrainingType;
  String? _selectedBodyPart;

  // ⭐ 一次性載入的完整數據（避免重複查詢）
  List<ExerciseWithRecord> _allExercises = [];

  Set<String> _favoriteIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void didUpdateWidget(ExerciseSelectionNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當時間範圍改變時，重新載入所有數據
    if (oldWidget.timeRange != widget.timeRange) {
      _resetAndReload();
    }
  }

  /// 重置選擇並重新載入
  void _resetAndReload() {
    setState(() {
      _currentStep = 0;
      _selectedTrainingType = null;
      _selectedBodyPart = null;
    });
    _loadAllData();
  }

  /// ⭐ 一次性載入所有數據（收藏 + 動作列表）
  /// ⭐ MVVM 重構：透過 Controller 載入
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      // 並行載入收藏和動作數據（透過 Controller）
      final results = await Future.wait([
        _exerciseController.getFavoriteExerciseIds(widget.userId),
        _statisticsController.getExercisesWithRecords(
          widget.userId,
          timeRange: widget.timeRange,
        ),
      ]);

      final favoriteIds = (results[0] as List<String>).toSet();
      final exercises = results[1] as List<ExerciseWithRecord>;

      // 標記收藏狀態
      final exercisesWithFavorites = exercises.map((e) {
        return ExerciseWithRecord(
          exerciseId: e.exerciseId,
          exerciseName: e.exerciseName,
          bodyPart: e.bodyPart,
          trainingType: e.trainingType,
          lastTrainingDate: e.lastTrainingDate,
          maxWeight: e.maxWeight,
          totalSets: e.totalSets,
          isFavorite: favoriteIds.contains(e.exerciseId),
          isCustom: e.isCustom,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _favoriteIds = favoriteIds;
          _allExercises = exercisesWithFavorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NotificationUtils.showError(context, '載入失敗: $e');
      }
    }
  }

  /// 獲取第 1 層：訓練類型列表（客戶端過濾）
  List<String> _getTrainingTypes() {
    final typesSet = <String>{};
    bool hasCustomExercises = false;

    for (var exercise in _allExercises) {
      if (exercise.isCustom) {
        // 自訂動作歸入「自訂」分類
        hasCustomExercises = true;
      } else {
        // 非自訂動作按 trainingType 分類
        if (exercise.trainingType.isNotEmpty) {
          typesSet.add(exercise.trainingType);
        }
      }
    }

    final typesList = typesSet.toList()..sort();
    if (hasCustomExercises) {
      typesList.add('自訂');
    }

    return typesList;
  }

  /// 獲取第 2 層：身體部位列表（客戶端過濾）
  List<String> _getBodyParts() {
    final filtered = _filterByTrainingType(_allExercises, _selectedTrainingType);
    final partsSet = <String>{};

    for (var exercise in filtered) {
      if (exercise.bodyPart.isNotEmpty) {
        partsSet.add(exercise.bodyPart);
      }
    }

    return partsSet.toList()..sort();
  }

  /// 獲取第 3 層：動作列表（客戶端過濾）
  List<ExerciseWithRecord> _getExercises() {
    var filtered = _filterByTrainingType(_allExercises, _selectedTrainingType);

    if (_selectedBodyPart != null) {
      filtered = filtered.where((e) => e.bodyPart == _selectedBodyPart).toList();
    }

    return filtered;
  }

  /// 按訓練類型過濾（與 Service 層邏輯一致）
  List<ExerciseWithRecord> _filterByTrainingType(
    List<ExerciseWithRecord> exercises,
    String? trainingType,
  ) {
    if (trainingType == null) return exercises;

    if (trainingType == '自訂') {
      return exercises.where((e) => e.isCustom).toList();
    } else {
      return exercises
          .where((e) => e.trainingType == trainingType && !e.isCustom)
          .toList();
    }
  }

  /// 切換收藏狀態
  /// ⭐ v3.5: MVVM 重構 - 透過 Controller 操作
  Future<void> _toggleFavorite(ExerciseWithRecord exercise) async {
    try {
      final isFavorite = _favoriteIds.contains(exercise.exerciseId);
      bool success;

      if (isFavorite) {
        // ⭐ v3.5: 透過 Controller 移除收藏
        success = await _exerciseController.removeFavorite(
          userId: widget.userId,
          exerciseId: exercise.exerciseId,
        );
        if (success && mounted) {
          setState(() => _favoriteIds.remove(exercise.exerciseId));
        }
      } else {
        // ⭐ v3.5: 透過 Controller 添加收藏
        success = await _exerciseController.addFavorite(
          userId: widget.userId,
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          bodyPart: exercise.bodyPart,
        );
        if (success && mounted) {
          setState(() => _favoriteIds.add(exercise.exerciseId));
        }
      }

      if (!success && mounted) {
        NotificationUtils.showError(
            context, _exerciseController.errorMessage ?? '操作失敗');
        return;
      }

      // 更新列表中的收藏狀態
      if (mounted) {
        _updateExerciseFavoriteStatus(exercise.exerciseId);
      }
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, '操作失敗: $e');
      }
    }
  }

  /// 更新動作的收藏狀態
  void _updateExerciseFavoriteStatus(String exerciseId) {
    setState(() {
      _allExercises = _allExercises.map((e) {
        if (e.exerciseId == exerciseId) {
          return ExerciseWithRecord(
            exerciseId: e.exerciseId,
            exerciseName: e.exerciseName,
            bodyPart: e.bodyPart,
            trainingType: e.trainingType,
            lastTrainingDate: e.lastTrainingDate,
            maxWeight: e.maxWeight,
            totalSets: e.totalSets,
            isFavorite: _favoriteIds.contains(e.exerciseId),
            isCustom: e.isCustom,
          );
        }
        return e;
      }).toList();
    });
  }

  /// 返回上一層
  void _navigateBack() {
    setState(() {
      switch (_currentStep) {
        case 1: // 從身體部位返回訓練類型
          _selectedTrainingType = null;
          _currentStep = 0;
          break;
        case 2: // 從動作列表返回身體部位
          _selectedBodyPart = null;
          _currentStep = 1;
          break;
      }
    });
  }

  /// 獲取麵包屑文字
  String _getBreadcrumbText() {
    final parts = <String>[];
    if (_selectedTrainingType != null) parts.add(_selectedTrainingType!);
    if (_selectedBodyPart != null) parts.add(_selectedBodyPart!);
    return parts.join(' > ');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 麵包屑導航
        if (_currentStep > 0)
          SelectionBreadcrumb(
            breadcrumbText: _getBreadcrumbText(),
            onBack: _navigateBack,
          ),

        // 內容區域
        Expanded(
          child: _buildCurrentStep(),
        ),
      ],
    );
  }

  /// 建立當前步驟的 UI
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: // 第 1 層：訓練類型
        final trainingTypes = _getTrainingTypes();
        return SelectionList(
          title: '💡 提示',
          subtitle: '選擇你想追蹤的動作，查看訓練進度！\n你可以標記常用動作為「收藏」快速查看',
          items: trainingTypes,
          onSelect: (value) {
            setState(() {
              _selectedTrainingType = value;
              _currentStep = 1;
            });
          },
        );

      case 1: // 第 2 層：身體部位
        final bodyParts = _getBodyParts();
        return SelectionList(
          title: '選擇身體部位',
          subtitle: '已選擇：$_selectedTrainingType',
          items: bodyParts,
          onSelect: (value) {
            setState(() {
              _selectedBodyPart = value;
              _currentStep = 2;
            });
          },
        );

      case 2: // 第 3 層：動作列表
        final exercises = _getExercises();
        return ExerciseListView(
          exercises: exercises,
          onExerciseSelected: widget.onExerciseSelected,
          onToggleFavorite: _toggleFavorite,
        );

      default:
        return const Center(child: Text('開發中...'));
    }
  }
}
