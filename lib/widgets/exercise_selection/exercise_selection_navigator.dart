import 'package:flutter/material.dart';
import '../../models/favorite_exercise_model.dart';
import '../../models/statistics/time_range.dart';
import '../../services/interfaces/i_favorites_service.dart';
import '../../services/interfaces/i_statistics_service.dart';
import '../../services/service_locator.dart';
import '../../utils/notification_utils.dart';
import 'widgets/selection_breadcrumb.dart';
import 'widgets/selection_list.dart';
import 'widgets/exercise_list_view.dart';

/// 5 層分類導航組件（用於選擇有訓練記錄的動作）
///
/// 只顯示使用者有訓練記錄的動作，支持收藏功能
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
  final IFavoritesService _favoritesService =
      serviceLocator<IFavoritesService>();
  final IStatisticsService _statisticsService =
      serviceLocator<IStatisticsService>();

  int _currentStep = 0; // 0=訓練類型, 1=身體部位, 2=特定肌群, 3=器材類別, 4=動作列表

  String? _selectedTrainingType;
  String? _selectedBodyPart;
  String? _selectedSpecificMuscle;
  String? _selectedEquipmentCategory;

  List<String> _trainingTypes = [];
  List<String> _bodyParts = [];
  List<ExerciseWithRecord> _exercises = [];

  Set<String> _favoriteIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadTrainingTypes();
  }

  @override
  void didUpdateWidget(ExerciseSelectionNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當時間範圍改變時，重新載入當前層級的數據
    if (oldWidget.timeRange != widget.timeRange) {
      _reloadCurrentStep();
    }
  }

  /// 重新載入當前層級的數據
  void _reloadCurrentStep() {
    switch (_currentStep) {
      case 0: // 訓練類型
        _loadTrainingTypes();
        break;
      case 1: // 身體部位
        _loadBodyParts();
        break;
      case 4: // 動作列表
        _loadExercises();
        break;
    }
  }

  /// 載入收藏列表
  Future<void> _loadFavorites() async {
    try {
      final ids = await _favoritesService.getFavoriteExerciseIds(widget.userId);
      if (mounted) {
        setState(() => _favoriteIds = ids.toSet());
      }
    } catch (e) {
      // 忽略錯誤
    }
  }

  /// 第1層：載入訓練類型
  Future<void> _loadTrainingTypes() async {
    setState(() {
      _isLoading = true;
      _currentStep = 0;
    });

    try {
      // 獲取所有有記錄的動作
      final exercises = await _statisticsService.getExercisesWithRecords(
        widget.userId,
        timeRange: widget.timeRange,
      );

      // 從動作中提取訓練類型（去重）
      final typesSet = <String>{};
      
      for (var exercise in exercises) {
        if (exercise.trainingType.isNotEmpty) {
          typesSet.add(exercise.trainingType);
        }
      }
      
      // 將訓練類型轉為列表並排序
      final typesList = typesSet.toList()..sort();
      
      // 始終添加「自訂」選項（方便用戶查看所有自訂動作）
      if (!typesList.contains('自訂')) {
        typesList.add('自訂');
      }

      if (mounted) {
        setState(() {
          _trainingTypes = typesList;
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

  /// 第2層：載入身體部位
  Future<void> _loadBodyParts() async {
    setState(() {
      _isLoading = true;
      _currentStep = 1;
    });

    try {
      final exercises = await _statisticsService.getExercisesWithRecords(
        widget.userId,
        trainingType: _selectedTrainingType,
        timeRange: widget.timeRange,
      );

      final partsSet = <String>{};
      for (var exercise in exercises) {
        if (exercise.bodyPart.isNotEmpty) {
          partsSet.add(exercise.bodyPart);
        }
      }

      if (mounted) {
        setState(() {
          _bodyParts = partsSet.toList()..sort();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 第5層：載入動作列表
  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _currentStep = 4;
    });

    try {
      final exercises = await _statisticsService.getExercisesWithRecords(
        widget.userId,
        trainingType: _selectedTrainingType,
        bodyPart: _selectedBodyPart,
        specificMuscle: _selectedSpecificMuscle,
        equipmentCategory: _selectedEquipmentCategory,
        timeRange: widget.timeRange,
      );

      // 標記收藏狀態
      final exercisesWithFavorites = exercises.map((exercise) {
        return ExerciseWithRecord(
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          bodyPart: exercise.bodyPart,
          trainingType: exercise.trainingType,
          lastTrainingDate: exercise.lastTrainingDate,
          maxWeight: exercise.maxWeight,
          totalSets: exercise.totalSets,
          isFavorite: _favoriteIds.contains(exercise.exerciseId),
          isCustom: exercise.isCustom,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _exercises = exercisesWithFavorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        NotificationUtils.showError(context, '載入動作失敗: $e');
      }
    }
  }

  /// 切換收藏狀態
  Future<void> _toggleFavorite(ExerciseWithRecord exercise) async {
    try {
      final isFavorite = _favoriteIds.contains(exercise.exerciseId);
      
      if (isFavorite) {
        await _favoritesService.removeFavorite(widget.userId, exercise.exerciseId);
        if (mounted) {
          setState(() => _favoriteIds.remove(exercise.exerciseId));
        }
      } else {
        await _favoritesService.addFavorite(
          widget.userId,
          exercise.exerciseId,
          exercise.exerciseName,
          exercise.bodyPart,
        );
        if (mounted) {
          setState(() => _favoriteIds.add(exercise.exerciseId));
        }
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
      _exercises = _exercises.map((e) {
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
        case 1:
          _selectedTrainingType = null;
          _currentStep = 0;
          break;
        case 2:
          _selectedBodyPart = null;
          _currentStep = 1;
          _loadBodyParts();
          break;
        case 4:
          _selectedBodyPart = null;
          _currentStep = 1;
          _loadBodyParts();
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
      case 0:
        return SelectionList(
          title: '💡 提示',
          subtitle: '選擇你想追蹤的動作，查看力量進步！\n你可以標記常用動作為「收藏」快速查看',
          items: _trainingTypes,
          onSelect: (value) {
            setState(() => _selectedTrainingType = value);
            _loadBodyParts();
          },
        );
      case 1:
        return SelectionList(
          title: '選擇身體部位',
          subtitle: '已選擇：$_selectedTrainingType',
          items: _bodyParts,
          onSelect: (value) {
            setState(() => _selectedBodyPart = value);
            _loadExercises();
          },
        );
      case 4:
        return ExerciseListView(
          exercises: _exercises,
          onExerciseSelected: widget.onExerciseSelected,
          onToggleFavorite: _toggleFavorite,
        );
      default:
        return const Center(child: Text('開發中...'));
    }
  }
}

