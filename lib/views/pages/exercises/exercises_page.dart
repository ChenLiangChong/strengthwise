// v5.0 重構：統一篩選器 + 偏好設定 + 階層導航共存
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import '../../../models/exercise_model.dart';
import 'exercise_detail_page.dart';
import 'exercise_preferences_page.dart';
import '../../../controllers/interfaces/i_exercise_controller.dart';
import '../../../models/exercise/exercise_labels.dart';
import '../../../services/service_locator.dart';
import '../../../utils/notification_utils.dart';
import 'custom_exercises_page.dart';
import 'widgets/exercise_browse_cards.dart';
import 'widgets/exercise_search_bar.dart';
import 'widgets/exercise_ppl_chips.dart';
import 'widgets/exercise_filters_bar.dart';
import 'widgets/exercise_list_item.dart';
import 'widgets/exercise_list_header.dart';
import 'widgets/empty_exercise_state.dart';

/// 動作瀏覽頁面 - v5.0 統一篩選器架構
///
/// 主要導航：階層式分類（解剖學 / 動作模式）
/// 輔助篩選：搜尋文字、PPL、器材、難度、類型、爆發力
///
/// Step 0: 訓練類型（重量/心肺/活動度/自訂）
/// Step 1: 瀏覽模式（解剖學/動作模式）— 僅重量訓練
/// Step 2: 分區/分組（肌群分區 或 頂層動作模式）
/// Step 3: 子項目（具體肌群 或 子模式）
/// Step 4: 動作列表（結合階層 + 所有篩選器）
class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  late final IExerciseController _controller;

  // =========================================================================
  // 階層導航狀態
  // =========================================================================

  int _currentStep = 0;
  String? _selectedTrainingType; // 'resistance' / 'cardio' / 'mobility'
  String? _selectedBrowseMode; // 'anatomy' / 'pattern'
  String? _selectedMuscleGroup; // 肌群分區 ID
  String? _selectedMuscle; // 具體肌群 ID
  String? _selectedPatternGroup; // 頂層動作模式 ID
  String? _selectedSubPattern; // 子模式 ID

  // =========================================================================
  // 篩選器狀態（輔助過濾，不影響導航）
  // =========================================================================

  final _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _selectedPplTags = {};
  Timer? _debounceTimer;
  FilterState _filterState = const FilterState();

  // =========================================================================
  // 參照資料
  // =========================================================================

  List<Map<String, String>> _movementPatterns = [];
  List<Map<String, String>> _muscleGroups = [];
  List<Map<String, String>> _equipmentList = [];

  // =========================================================================
  // 統一結果集
  // =========================================================================

  List<Exercise> _exercises = [];
  bool _isLoading = true;

  /// 記住階層上下文（供篩選器變更時重新載入）
  List<String>? _lastMovementPatterns;
  String? _lastPrimaryMuscle;

  /// 搜尋文字模式：輸入搜尋文字時跳過階層直接顯示結果
  bool get _isSearchTextMode => _searchQuery.isNotEmpty;

  // =========================================================================
  // 生命週期
  // =========================================================================

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<IExerciseController>();
    _loadReferenceData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // =========================================================================
  // 資料載入
  // =========================================================================

  /// 載入參照資料
  Future<void> _loadReferenceData() async {
    try {
      final results = await Future.wait([
        _controller.getMovementPatterns(),
        _controller.getMuscleGroups(),
        _controller.getEquipmentList(),
      ]);

      if (mounted) {
        setState(() {
          _movementPatterns = results[0];
          _muscleGroups = results[1];
          _equipmentList = results[2];
          // ⭐ v5.0: 從偏好載入器材預設
          _filterState = _filterState.copyWith(
            selectedEquipment: Set<String>.from(_controller.myEquipment),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[動作瀏覽] 載入參照資料失敗: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        NotificationUtils.showError(context, '載入資料失敗，請重新開啟');
      }
    }
  }

  /// 統一動作載入（結合階層條件 + 所有篩選器）
  Future<void> _loadExercisesWithAllFilters({
    List<String>? movementPatterns,
    String? primaryMuscle,
  }) async {
    // 記住階層上下文
    if (movementPatterns != null) _lastMovementPatterns = movementPatterns;
    if (primaryMuscle != null) _lastPrimaryMuscle = primaryMuscle;

    setState(() => _isLoading = true);

    try {
      // 訓練類型排除：各自排除其他兩類
      List<String>? excludePpl;
      if (_selectedTrainingType == 'resistance') {
        excludePpl = ['cardio', 'mobility'];
      } else if (_selectedTrainingType == 'cardio') {
        excludePpl = ['mobility'];
      } else if (_selectedTrainingType == 'mobility') {
        excludePpl = ['cardio'];
      }

      final exercises = await _controller.searchExercisesAdvanced(
        // 階層條件
        movementPatterns: movementPatterns ?? _lastMovementPatterns,
        primaryMuscle: primaryMuscle ?? _lastPrimaryMuscle,
        // 篩選器
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        pplTags: _selectedPplTags.isNotEmpty ? _selectedPplTags.toList() : null,
        excludePplTags: excludePpl,
        equipmentSet: _filterState.selectedEquipment.isNotEmpty
            ? _filterState.selectedEquipment
            : null,
        difficultyLevel: _filterState.difficultyLevel,
        mechanicsType: _filterState.mechanicsType,
        isExplosive: _filterState.isExplosive,
        limit: 200,
      );

      if (mounted) {
        setState(() {
          _exercises = exercises;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[動作瀏覽] 載入動作失敗: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =========================================================================
  // 階層導航操作
  // =========================================================================

  void _selectTrainingType(BrowseCardItem item) {
    if (item.id == 'custom') {
      _navigateToCustomExercises();
      return;
    }

    setState(() => _selectedTrainingType = item.id);

    if (item.id == 'resistance') {
      // ⭐ v5.0: 跳過 Step 1，從偏好讀取瀏覽模式
      setState(() {
        _selectedBrowseMode = _controller.preferredBrowseMode;
        _currentStep = 2;
      });
    } else {
      // cardio / mobility → 直接載入動作列表
      setState(() => _currentStep = 4);
      _loadExercisesWithAllFilters(movementPatterns: [item.id]);
    }
  }

  void _selectBrowseMode(BrowseCardItem item) {
    setState(() {
      _selectedBrowseMode = item.id;
      _currentStep = 2;
    });
  }

  void _selectMuscleGroup(BrowseCardItem item) {
    setState(() {
      _selectedMuscleGroup = item.id;
      _currentStep = 3;
    });
  }

  void _selectMuscle(BrowseCardItem item) {
    setState(() {
      _selectedMuscle = item.id;
      _currentStep = 4;
    });
    _loadExercisesWithAllFilters(primaryMuscle: item.id);
  }

  void _selectPatternGroup(BrowseCardItem item) {
    final children = _movementPatterns
        .where((p) => p['parentId'] == item.id)
        .toList();

    if (children.isEmpty) {
      // 無子模式（lunge, carry）→ 直接顯示動作列表
      setState(() {
        _selectedPatternGroup = item.id;
        _currentStep = 4;
      });
      _loadExercisesWithAllFilters(movementPatterns: [item.id]);
    } else {
      setState(() {
        _selectedPatternGroup = item.id;
        _currentStep = 3;
      });
    }
  }

  void _selectSubPattern(BrowseCardItem item) {
    setState(() {
      _selectedSubPattern = item.id;
      _currentStep = 4;
    });

    if (item.id.startsWith('all_')) {
      final parentId = item.id.substring(4);
      final allIds = [parentId];
      allIds.addAll(
        _movementPatterns
            .where((p) => p['parentId'] == parentId)
            .map((p) => p['id'] ?? ''),
      );
      _loadExercisesWithAllFilters(movementPatterns: allIds);
    } else {
      _loadExercisesWithAllFilters(movementPatterns: [item.id]);
    }
  }

  void _navigateToCustomExercises() async {
    final selectedExercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomExercisesPage(),
      ),
    );

    if (selectedExercise != null && context.mounted) {
      // ignore: use_build_context_synchronously - context.mounted 已檢查
      Navigator.pop(context, selectedExercise);
    }
  }

  void _navigateBack() {
    setState(() {
      switch (_currentStep) {
        case 4:
          _exercises = [];
          _lastMovementPatterns = null;
          _lastPrimaryMuscle = null;
          if (_selectedTrainingType == 'cardio' ||
              _selectedTrainingType == 'mobility') {
            _selectedTrainingType = null;
            _currentStep = 0;
          } else if (_selectedBrowseMode == 'anatomy') {
            _selectedMuscle = null;
            _currentStep = 3;
          } else if (_selectedBrowseMode == 'pattern') {
            if (_selectedSubPattern != null) {
              _selectedSubPattern = null;
              _currentStep = 3;
            } else {
              _selectedPatternGroup = null;
              _currentStep = 2;
            }
          }
          break;
        case 3:
          if (_selectedBrowseMode == 'anatomy') {
            _selectedMuscleGroup = null;
          } else {
            _selectedPatternGroup = null;
          }
          _currentStep = 2;
          break;
        case 2:
          // ⭐ v5.0: 跳過 Step 1，回到 Step 0
          _selectedBrowseMode = null;
          _selectedTrainingType = null;
          _currentStep = 0;
          break;
        case 1:
          _selectedTrainingType = null;
          _currentStep = 0;
          break;
      }
    });
  }

  // =========================================================================
  // 篩選器處理
  // =========================================================================

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = query);

      if (_searchQuery.isNotEmpty) {
        // 搜尋文字：立即顯示結果
        _loadExercisesWithAllFilters();
      } else if (_currentStep == 4) {
        // 清空搜尋文字但在 Step 4：重新載入（用階層條件）
        _loadExercisesWithAllFilters();
      } else {
        // 清空搜尋文字且在早期 Step：清空結果
        setState(() => _exercises = []);
      }
    });
  }

  void _onPplTagChanged(Set<String> tags) {
    setState(() => _selectedPplTags = tags);
    // 只在 Step 4 或搜尋文字模式時重新載入
    if (_isSearchTextMode || _currentStep == 4) {
      _loadExercisesWithAllFilters();
    }
  }

  void _onFiltersChanged(FilterState filters) {
    setState(() => _filterState = filters);
    // 只在 Step 4 或搜尋文字模式時重新載入
    if (_isSearchTextMode || _currentStep == 4) {
      _loadExercisesWithAllFilters();
    }
  }

  /// 開啟偏好設定頁面
  Future<void> _openPreferences() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExercisePreferencesPage(
          controller: _controller,
          equipmentOptions: _equipmentList,
        ),
      ),
    );

    // 返回後同步偏好到篩選器
    if (mounted) {
      setState(() {
        _filterState = _filterState.copyWith(
          selectedEquipment: Set<String>.from(_controller.myEquipment),
        );
      });
    }
  }

  void _clearSearchQuery() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _exercises = [];
    });
    // 保留篩選器狀態（PPL/equipment 等）
    // 如果在 Step 4 回到搜尋前的階層
  }

  // =========================================================================
  // Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0 && !_isSearchTextMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_isSearchTextMode) {
            _clearSearchQuery();
          } else if (_currentStep > 0) {
            _navigateBack();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          leading: (_currentStep > 0 || _isSearchTextMode)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (_isSearchTextMode) {
                      _clearSearchQuery();
                    } else {
                      _navigateBack();
                    }
                  },
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: '動作庫設定',
              onPressed: _openPreferences,
            ),
          ],
        ),
        body: _isLoading && _movementPatterns.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : context.isMobile
                ? _buildMobileLayout()
                : _buildDesktopLayout(),
      ),
    );
  }

  /// 手機佈局：上下排列
  Widget _buildMobileLayout() {
    return Column(
      children: [
        ExerciseSearchBar(
          controller: _searchController,
          onChanged: _onSearchChanged,
        ),
        ExercisePplChips(
          selected: _selectedPplTags,
          onSelect: _onPplTagChanged,
        ),
        ExerciseFiltersBar(
          currentFilters: _filterState,
          equipmentOptions: _equipmentList,
          onFilterChanged: _onFiltersChanged,
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildMainContent(),
        ),
      ],
    );
  }

  /// 桌面佈局：左右排列（篩選在左，動作在右）
  Widget _buildDesktopLayout() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // 左側篩選面板
        SizedBox(
          width: 280,
          child: ColoredBox(
            color: colorScheme.surfaceContainerLowest,
            child: Column(
              children: [
                ExerciseSearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  padding: const EdgeInsets.all(16),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // PPL 快捷篩選（Wrap 排列）
                      ExercisePplChips(
                        selected: _selectedPplTags,
                        onSelect: _onPplTagChanged,
                        useWrap: true,
                      ),
                      const Divider(height: 1),
                      // 進階篩選（始終展開）
                      ExerciseFiltersBar(
                        currentFilters: _filterState,
                        equipmentOptions: _equipmentList,
                        onFilterChanged: _onFiltersChanged,
                        alwaysExpanded: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 分隔線
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        // 右側主內容
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildMainContent(),
        ),
      ],
    );
  }

  /// 主內容判斷
  Widget _buildMainContent() {
    // 搜尋文字模式：直接顯示結果
    if (_isSearchTextMode) {
      return _buildExerciseList(breadcrumb: '搜尋結果');
    }

    // 階層導航
    if (_currentStep < 4) {
      return _buildNavigationContent();
    }

    // Step 4：動作列表（結合階層 + 篩選器）
    return _buildExerciseList(breadcrumb: _getBreadcrumb());
  }

  String _getAppBarTitle() {
    if (_isSearchTextMode) return '搜尋動作';
    switch (_currentStep) {
      case 0:
        return '動作庫';
      case 1:
        return '瀏覽方式';
      case 2:
        return _selectedBrowseMode == 'anatomy' ? '選擇肌群' : '選擇動作模式';
      case 3:
        if (_selectedBrowseMode == 'anatomy') return '選擇目標肌群';
        return '選擇子模式';
      case 4:
        return '訓練動作';
      default:
        return '動作庫';
    }
  }

  // =========================================================================
  // 動作列表
  // =========================================================================

  Widget _buildExerciseList({required String breadcrumb}) {
    if (_exercises.isEmpty) {
      return const EmptyExerciseState();
    }
    return _buildExerciseListView(
      exercises: _exercises,
      breadcrumb: breadcrumb,
    );
  }

  // =========================================================================
  // 階層導航內容
  // =========================================================================

  Widget _buildNavigationContent() {
    switch (_currentStep) {
      case 0:
        return _buildTrainingTypeCards();
      case 1:
        return _buildBrowseModeCards();
      case 2:
        return _selectedBrowseMode == 'anatomy'
            ? _buildMuscleGroupCards()
            : _buildPatternGroupCards();
      case 3:
        return _selectedBrowseMode == 'anatomy'
            ? _buildMuscleCards()
            : _buildSubPatternCards();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Step 0：訓練類型選擇
  Widget _buildTrainingTypeCards() {
    const items = [
      BrowseCardItem(
        id: 'resistance',
        title: '重量訓練',
        subtitle: '自由重量、機械、徒手',
        icon: Icons.fitness_center,
      ),
      BrowseCardItem(
        id: 'cardio',
        title: '心肺訓練',
        subtitle: '跑步、飛輪、划船等',
        icon: Icons.monitor_heart_outlined,
      ),
      BrowseCardItem(
        id: 'mobility',
        title: '活動度訓練',
        subtitle: '伸展、滾筒放鬆、瑜伽',
        icon: Icons.self_improvement,
      ),
      BrowseCardItem(
        id: 'custom',
        title: '自訂動作',
        subtitle: '建立個人專屬動作',
        icon: Icons.edit_note,
      ),
    ];

    return ExerciseBrowseCards(
      items: items,
      title: '選擇訓練類型',
      onSelect: _selectTrainingType,
    );
  }

  /// Step 1：瀏覽模式選擇
  Widget _buildBrowseModeCards() {
    const items = [
      BrowseCardItem(
        id: 'anatomy',
        title: '解剖學視圖',
        subtitle: '按肌群找動作 —「練哪裡？」',
        icon: Icons.accessibility_new,
      ),
      BrowseCardItem(
        id: 'pattern',
        title: '動作模式視圖',
        subtitle: '按動作模式找 —「怎麼動？」',
        icon: Icons.swap_vert,
      ),
    ];

    return ExerciseBrowseCards(
      items: items,
      title: '瀏覽方式',
      breadcrumb: '重量訓練',
      onSelect: _selectBrowseMode,
    );
  }

  /// Step 2a：肌群分區選擇
  ///
  /// ref_muscle_groups 只有子肌群，沒有父群組 row，
  /// 需從 parent_group 欄位推導出父群組。
  Widget _buildMuscleGroupCards() {
    // 從子肌群推導出父群組（保留順序）
    final seen = <String>{};
    final parentGroupIds = <String>[];
    for (final g in _muscleGroups) {
      final pg = g['parentGroup'] ?? '';
      if (pg.isNotEmpty && seen.add(pg)) {
        parentGroupIds.add(pg);
      }
    }

    final items = parentGroupIds.map((groupId) {
      final childCount =
          _muscleGroups.where((g) => g['parentGroup'] == groupId).length;
      return BrowseCardItem(
        id: groupId,
        title: ExerciseLabels.resolve(ExerciseLabels.muscleGroups, groupId),
        subtitle: '$childCount 個目標肌群',
        icon: _muscleGroupIcons[groupId],
      );
    }).toList();

    return ExerciseBrowseCards(
      items: items,
      title: '選擇肌群分區',
      breadcrumb: '重量訓練 > 解剖學',
      onSelect: _selectMuscleGroup,
    );
  }

  /// Step 3a：具體肌群選擇
  Widget _buildMuscleCards() {
    final children = _muscleGroups
        .where((g) => g['parentGroup'] == _selectedMuscleGroup)
        .toList();

    final groupName = _selectedMuscleGroup != null
        ? ExerciseLabels.resolve(ExerciseLabels.muscleGroups, _selectedMuscleGroup!)
        : '';

    final items = children
        .map((muscle) => BrowseCardItem(
              id: muscle['id'] ?? '',
              title: muscle['nameZh'] ?? '',
            ))
        .toList();

    return ExerciseBrowseCards(
      items: items,
      title: '選擇目標肌群',
      breadcrumb: '重量訓練 > 解剖學 > $groupName',
      onSelect: _selectMuscle,
    );
  }

  /// Step 2b：頂層動作模式選擇
  Widget _buildPatternGroupCards() {
    final topPatterns = _movementPatterns
        .where((p) =>
            (p['parentId'] ?? '').isEmpty &&
            p['id'] != 'cardio' &&
            p['id'] != 'mobility')
        .toList();

    final items = topPatterns.map((pattern) {
      final id = pattern['id'] ?? '';
      final childCount =
          _movementPatterns.where((p) => p['parentId'] == id).length;
      final subtitle = childCount > 0 ? '$childCount 個子模式' : '直接瀏覽動作';
      return BrowseCardItem(
        id: id,
        title: pattern['nameZh'] ?? id,
        subtitle: subtitle,
        icon: _patternIcons[id],
      );
    }).toList();

    return ExerciseBrowseCards(
      items: items,
      title: '選擇動作模式',
      breadcrumb: '重量訓練 > 動作模式',
      onSelect: _selectPatternGroup,
    );
  }

  /// Step 3b：子模式選擇
  Widget _buildSubPatternCards() {
    final children = _movementPatterns
        .where((p) => p['parentId'] == _selectedPatternGroup)
        .toList();

    final groupMatch =
        _movementPatterns.cast<Map<String, String>?>().firstWhere(
              (p) => p?['id'] == _selectedPatternGroup,
              orElse: () => null,
            );
    final groupName = groupMatch?['nameZh'] ?? _selectedPatternGroup ?? '';

    final items = <BrowseCardItem>[
      BrowseCardItem(
        id: 'all_$_selectedPatternGroup',
        title: '全部$groupName',
        subtitle: '包含所有子模式',
        icon: Icons.select_all,
      ),
      ...children.map((pattern) => BrowseCardItem(
            id: pattern['id'] ?? '',
            title: pattern['nameZh'] ?? '',
          )),
    ];

    return ExerciseBrowseCards(
      items: items,
      title: '選擇子模式',
      breadcrumb: '重量訓練 > 動作模式 > $groupName',
      onSelect: _selectSubPattern,
    );
  }

  // =========================================================================
  // 共用動作列表元件
  // =========================================================================

  Widget _buildExerciseListView({
    required List<Exercise> exercises,
    required String breadcrumb,
  }) {
    final columns = context.listColumns;
    final padding = context.pagePadding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExerciseListHeader(
          selectionPath: breadcrumb,
          exerciseCount: exercises.length,
        ),
        Expanded(
          child: columns > 1
              ? GridView.builder(
                  padding: padding.copyWith(bottom: 96),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: context.spacing.md,
                    mainAxisSpacing: context.spacing.sm,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) =>
                      _buildExerciseItem(exercises[index]),
                )
              : ListView.builder(
                  padding: padding.copyWith(bottom: 96),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) =>
                      _buildExerciseItem(exercises[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildExerciseItem(Exercise exercise) {
    return ExerciseListItem(
      exercise: exercise,
      onTap: () async {
        final selectedExercise = await Navigator.push<Exercise>(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailPage(exercise: exercise),
          ),
        );
        if (selectedExercise != null && context.mounted) {
          // ignore: use_build_context_synchronously - context.mounted 已檢查
          Navigator.pop(context, selectedExercise);
        }
      },
      onSelect: () {
        Navigator.pop(context, exercise);
      },
    );
  }

  // =========================================================================
  // 輔助方法
  // =========================================================================

  String _getBreadcrumb() {
    final parts = <String>[];

    if (_selectedTrainingType == 'resistance') {
      parts.add('重量訓練');
    } else if (_selectedTrainingType == 'cardio') {
      parts.add('心肺訓練');
    } else if (_selectedTrainingType == 'mobility') {
      parts.add('活動度訓練');
    }

    if (_selectedBrowseMode == 'anatomy') {
      parts.add('解剖學');
      if (_selectedMuscleGroup != null) {
        parts.add(ExerciseLabels.resolve(
            ExerciseLabels.muscleGroups, _selectedMuscleGroup!));
      }
      if (_selectedMuscle != null) {
        final name = _findRefName(_muscleGroups, _selectedMuscle!);
        if (name != null) parts.add(name);
      }
    } else if (_selectedBrowseMode == 'pattern') {
      parts.add('動作模式');
      if (_selectedPatternGroup != null) {
        final name =
            _findRefName(_movementPatterns, _selectedPatternGroup!);
        if (name != null) parts.add(name);
      }
      if (_selectedSubPattern != null &&
          !_selectedSubPattern!.startsWith('all_')) {
        final name =
            _findRefName(_movementPatterns, _selectedSubPattern!);
        if (name != null) parts.add(name);
      }
    }

    return parts.join(' > ');
  }

  String? _findRefName(List<Map<String, String>> refData, String id) {
    final match = refData.cast<Map<String, String>?>().firstWhere(
          (item) => item?['id'] == id,
          orElse: () => null,
        );
    return match?['nameZh'];
  }

  static const _muscleGroupIcons = <String, IconData>{
    'chest': Icons.expand,
    'back': Icons.airline_seat_recline_normal,
    'shoulders': Icons.accessibility_new,
    'arms': Icons.front_hand,
    'legs': Icons.directions_walk,
    'core': Icons.shield_outlined,
  };

  static const _patternIcons = <String, IconData>{
    'push': Icons.arrow_upward,
    'pull': Icons.arrow_downward,
    'squat': Icons.download_rounded,
    'hinge': Icons.sync_alt,
    'lunge': Icons.directions_walk,
    'core': Icons.shield_outlined,
    'carry': Icons.transfer_within_a_station,
  };
}
