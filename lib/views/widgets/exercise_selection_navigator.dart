import 'package:flutter/material.dart';
import '../../models/favorite_exercise_model.dart';
import '../../services/interfaces/i_favorites_service.dart';
import '../../services/interfaces/i_statistics_service.dart';
import '../../services/service_locator.dart';
import '../../utils/notification_utils.dart';

/// 5 層分類導航組件（用於選擇有訓練記錄的動作）
///
/// 只顯示使用者有訓練記錄的動作，支持收藏功能
class ExerciseSelectionNavigator extends StatefulWidget {
  final String userId;
  final Function(ExerciseWithRecord exercise)? onExerciseSelected;

  const ExerciseSelectionNavigator({
    Key? key,
    required this.userId,
    this.onExerciseSelected,
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

  /// 載入收藏列表
  Future<void> _loadFavorites() async {
    try {
      final ids = await _favoritesService.getFavoriteExerciseIds(widget.userId);
      setState(() => _favoriteIds = ids.toSet());
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
      );

      // 從動作中提取訓練類型（去重）
      final typesSet = <String>{};
      
      for (var exercise in exercises) {
        if (exercise.trainingType.isNotEmpty) {
          typesSet.add(exercise.trainingType);
        }
      }
      
      // 如果沒有找到任何訓練類型，顯示預設選項
      if (typesSet.isEmpty) {
        typesSet.addAll(['重訓', '有氧', '伸展']);
      }

      if (mounted) {
        setState(() {
          _trainingTypes = typesSet.toList()..sort();
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
      );

      final partsSet = <String>{};
      for (var exercise in exercises) {
        if (exercise.bodyPart.isNotEmpty) {
          partsSet.add(exercise.bodyPart);
        }
      }

      setState(() {
        _bodyParts = partsSet.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
        );
      }).toList();

      setState(() {
        _exercises = exercisesWithFavorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        NotificationUtils.showError(context, '載入動作失敗: $e');
      }
    }
  }

  /// 切換收藏狀態
  Future<void> _toggleFavorite(ExerciseWithRecord exercise) async {
    try {
      if (_favoriteIds.contains(exercise.exerciseId)) {
        await _favoritesService.removeFavorite(
            widget.userId, exercise.exerciseId);
        setState(() => _favoriteIds.remove(exercise.exerciseId));
      } else {
        await _favoritesService.addFavorite(
          widget.userId,
          exercise.exerciseId,
          exercise.exerciseName,
          exercise.bodyPart,
        );
        setState(() => _favoriteIds.add(exercise.exerciseId));
      }

      // 更新列表中的收藏狀態
      setState(() {
        _exercises = _exercises.map((e) {
          if (e.exerciseId == exercise.exerciseId) {
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
    } catch (e) {
      if (mounted) {
        NotificationUtils.showError(context, '操作失敗: $e');
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 麵包屑導航
        if (_currentStep > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateBack,
                  iconSize: 20,
                ),
                Expanded(
                  child: Text(
                    _getBreadcrumbText(),
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
        return _buildSelection(
          title: '💡 提示',
          subtitle: '選擇你想追蹤的動作，查看力量進步！\n你可以標記常用動作為「收藏」快速查看',
          items: _trainingTypes,
          onSelect: (value) {
            setState(() => _selectedTrainingType = value);
            _loadBodyParts();
          },
        );
      case 1:
        return _buildSelection(
          title: '選擇身體部位',
          subtitle: '已選擇：$_selectedTrainingType',
          items: _bodyParts,
          onSelect: (value) {
            setState(() => _selectedBodyPart = value);
            _loadExercises(); // 簡化：直接載入動作
          },
        );
      case 4:
        return _buildExerciseList();
      default:
        return const Center(child: Text('開發中...'));
    }
  }

  /// 建立選擇列表
  Widget _buildSelection({
    required String title,
    String? subtitle,
    required List<String> items,
    required Function(String) onSelect,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('沒有可選項目'),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 16),
        ],
        ...items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onSelect(item),
              ),
            )),
      ],
    );
  }

  /// 建立動作列表
  Widget _buildExerciseList() {
    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('沒有找到動作'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '📊 選擇動作',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '💡 數字表示你有訓練記錄的動作數量',
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        ..._exercises.map((exercise) => _buildExerciseCard(exercise)),
      ],
    );
  }

  /// 建立動作卡片
  Widget _buildExerciseCard(ExerciseWithRecord exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onExerciseSelected?.call(exercise),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exerciseName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '最後訓練: ${exercise.formattedLastTrainingDate}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      exercise.isFavorite ? Icons.star : Icons.star_border,
                      color: exercise.isFavorite
                          ? Colors.amber
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => _toggleFavorite(exercise),
                    tooltip: exercise.isFavorite ? '取消收藏' : '收藏',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getBodyPartColor(exercise.bodyPart).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      exercise.bodyPart,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getBodyPartColor(exercise.bodyPart),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '最大重量: ${exercise.formattedMaxWeight}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 獲取麵包屑文字
  String _getBreadcrumbText() {
    final parts = <String>[];
    if (_selectedTrainingType != null) parts.add(_selectedTrainingType!);
    if (_selectedBodyPart != null) parts.add(_selectedBodyPart!);
    return parts.join(' > ');
  }

  /// 根據身體部位返回顏色
  Color _getBodyPartColor(String bodyPart) {
    if (bodyPart.contains('胸')) return Colors.red;
    if (bodyPart.contains('背')) return Colors.blue;
    if (bodyPart.contains('腿')) return Theme.of(context).colorScheme.secondary;
    if (bodyPart.contains('肩')) return Theme.of(context).colorScheme.primary;
    if (bodyPart.contains('手')) return Theme.of(context).colorScheme.primary;
    if (bodyPart.contains('核心') || bodyPart.contains('腹')) return Colors.teal;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}
