import 'package:flutter/material.dart';
import '../../../models/exercise_model.dart';
import 'exercise_detail_page.dart';
import '../../../services/interfaces/i_exercise_service.dart';
import '../../../services/service_locator.dart';
import '../../../utils/notification_utils.dart';
import 'custom_exercises_page.dart';
import 'widgets/exercise_filter_step.dart';
import 'widgets/exercise_list_item.dart';
import 'widgets/exercise_list_header.dart';
import 'widgets/empty_exercise_state.dart';

/// 動作瀏覽頁面 - 使用專業 5 層分類結構
/// 1. 訓練類型 (trainingType) -> 2. 身體部位 (bodyPart) -> 3. 特定肌群 (specificMuscle)
/// -> 4. 器材類別 (equipmentCategory) -> 5. 器材子類別 (equipmentSubcategory)
class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  _ExercisesPageState createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  bool _isLoading = true;
  
  // 注入 ExerciseService
  late final IExerciseService _exerciseService;

  // 新的 5 層分類選擇
  String? _selectedTrainingType; // 訓練類型
  String? _selectedBodyPart; // 身體部位（主要肌群）
  String? _selectedSpecificMuscle; // 特定肌群
  String? _selectedEquipmentCategory; // 器材類別
  String? _selectedEquipmentSubcategory; // 器材子類別

  // 各層級的選項列表
  List<String> _trainingTypes = [];
  List<String> _bodyParts = [];
  List<String> _specificMuscles = [];
  List<String> _equipmentCategories = [];
  List<String> _equipmentSubcategories = [];
  List<Exercise> _exercises = [];
  
  // ⚡ 快取所有動作（一次載入，避免重複查詢）
  List<Exercise> _allExercisesCache = [];

  int _currentStep =
      0; // 當前導航步驟：0=訓練類型, 1=身體部位, 2=特定肌群, 3=器材類別, 4=器材子類別, 5=動作列表

  @override
  void initState() {
    super.initState();
    
    // 初始化 ExerciseService
    _exerciseService = serviceLocator<IExerciseService>();
    
    _logDebug('應用啟動：載入訓練類型...');

    // 載入訓練類型
    _loadTrainingTypes();
  }

  void _logDebug(String message) {
    print('[動作瀏覽] $message');
  }

  /// 第1層：載入訓練類型
  Future<void> _loadTrainingTypes() async {
    setState(() {
      _isLoading = true;
      _currentStep = 0;
    });

    try {
      _logDebug('開始載入訓練類型...');

      // 使用 ExerciseService 取得訓練類型
      final types = await _exerciseService.getExerciseTypes();
      
      _logDebug('成功載入 ${types.length} 個訓練類型: ${types.join(", ")}');

      setState(() {
        _trainingTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      _logDebug('載入訓練類型失敗: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        NotificationUtils.showError(context, '載入訓練類型失敗: $e');
      }
    }
  }

  /// 第2層：載入身體部位（只顯示有動作的部位）
  Future<void> _loadBodyParts() async {
    setState(() {
      _isLoading = true;
      _currentStep = 1;
    });

    try {
      _logDebug('開始載入身體部位，選擇的訓練類型: $_selectedTrainingType');

      // 建構篩選條件，取得所有符合訓練類型的動作
      final filters = <String, String>{};
      if (_selectedTrainingType != null && _selectedTrainingType!.isNotEmpty) {
        filters['type'] = _selectedTrainingType!;
      }
      
      // 使用 getExercisesByFilters 取得動作列表
      final exercises = await _exerciseService.getExercisesByFilters(filters);
      
      // 從動作列表中提取唯一的身體部位
      final partsSet = <String>{};
      for (var exercise in exercises) {
        if (exercise.bodyPart.isNotEmpty) {
          partsSet.add(exercise.bodyPart);
        }
      }
      
      final parts = partsSet.toList()..sort();
      _logDebug('成功載入 ${parts.length} 個身體部位（來自 ${exercises.length} 個動作）');

      setState(() {
        _bodyParts = parts;
        _isLoading = false;
      });
    } catch (e) {
      _logDebug('載入身體部位失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 第3層：載入特定肌群
  Future<void> _loadSpecificMuscles() async {
    setState(() {
      _isLoading = true;
      _currentStep = 2;
    });

    try {
      _logDebug('開始載入特定肌群，身體部位: $_selectedBodyPart');

      // 建構篩選條件
      final filters = <String, String>{};
      if (_selectedTrainingType != null) {
        filters['type'] = _selectedTrainingType!;
      }
      if (_selectedBodyPart != null) {
        filters['bodyPart'] = _selectedBodyPart!;
      }
      
      // 取得動作列表
      final exercises = await _exerciseService.getExercisesByFilters(filters);
      
      // 提取唯一的特定肌群
      final musclesSet = <String>{};
      for (var exercise in exercises) {
        if (exercise.specificMuscle.isNotEmpty) {
          musclesSet.add(exercise.specificMuscle);
        }
      }

      final muscles = musclesSet.toList()..sort();
      _logDebug('成功載入 ${muscles.length} 個特定肌群');

      setState(() {
        _specificMuscles = muscles;
        _isLoading = false;
      });

      // 如果沒有特定肌群，直接載入器材類別
      if (muscles.isEmpty) {
        _logDebug('沒有特定肌群，直接載入器材類別');
        _loadEquipmentCategories();
      }
    } catch (e) {
      _logDebug('載入特定肌群失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 第4層：載入器材類別
  Future<void> _loadEquipmentCategories() async {
    setState(() {
      _isLoading = true;
      _currentStep = 3;
    });

    try {
      _logDebug('開始載入器材類別');

      // 建構篩選條件
      final filters = <String, String>{};
      if (_selectedTrainingType != null) {
        filters['type'] = _selectedTrainingType!;
      }
      if (_selectedBodyPart != null) {
        filters['bodyPart'] = _selectedBodyPart!;
      }
      
      // 取得動作列表
      final exercises = await _exerciseService.getExercisesByFilters(filters);

      // 客戶端過濾並提取器材類別
      final categoriesSet = <String>{};
      for (var exercise in exercises) {
        // 如果選擇了特定肌群，進行過濾
        if (_selectedSpecificMuscle != null && 
            exercise.specificMuscle != _selectedSpecificMuscle) {
          continue;
        }

        if (exercise.equipmentCategory.isNotEmpty) {
          categoriesSet.add(exercise.equipmentCategory);
        }
      }

      final categories = categoriesSet.toList()..sort();
      _logDebug('成功載入 ${categories.length} 個器材類別');

      setState(() {
        _equipmentCategories = categories;
        _isLoading = false;
      });

      // 如果沒有器材類別，直接載入動作列表
      if (categories.isEmpty) {
        _logDebug('沒有器材類別，直接載入動作列表');
        _loadExercises();
      }
    } catch (e) {
      _logDebug('載入器材類別失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 第5層：載入器材子類別（可選）
  Future<void> _loadEquipmentSubcategories() async {
    setState(() {
      _isLoading = true;
      _currentStep = 4;
    });

    try {
      _logDebug('開始載入器材子類別');

      // 建構篩選條件
      final filters = <String, String>{};
      if (_selectedTrainingType != null) {
        filters['type'] = _selectedTrainingType!;
      }
      if (_selectedBodyPart != null) {
        filters['bodyPart'] = _selectedBodyPart!;
      }
      
      // 取得動作列表
      final exercises = await _exerciseService.getExercisesByFilters(filters);

      // 客戶端過濾並提取器材子類別
      final subcategoriesSet = <String>{};
      for (var exercise in exercises) {
        // 過濾特定肌群
        if (_selectedSpecificMuscle != null && 
            exercise.specificMuscle != _selectedSpecificMuscle) {
          continue;
        }

        // 過濾器材類別
        if (_selectedEquipmentCategory != null && 
            exercise.equipmentCategory != _selectedEquipmentCategory) {
          continue;
        }

        if (exercise.equipmentSubcategory.isNotEmpty) {
          subcategoriesSet.add(exercise.equipmentSubcategory);
        }
      }

      final subcategories = subcategoriesSet.toList()..sort();
      _logDebug('成功載入 ${subcategories.length} 個器材子類別');

      setState(() {
        _equipmentSubcategories = subcategories;
        _isLoading = false;
      });

      // 如果沒有子類別，直接載入動作列表
      if (subcategories.isEmpty) {
        _logDebug('沒有器材子類別，直接載入動作列表');
        _loadExercises();
      }
    } catch (e) {
      _logDebug('載入器材子類別失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 最終：根據所有條件載入動作列表
  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _currentStep = 5;
    });

    try {
      _logDebug('開始載入最終動作列表');
      _logDebug(
          '篩選條件：訓練類型=$_selectedTrainingType, 身體部位=$_selectedBodyPart, 特定肌群=$_selectedSpecificMuscle, 器材類別=$_selectedEquipmentCategory, 器材子類別=$_selectedEquipmentSubcategory');

      // 建構篩選條件
      final filters = <String, String>{};
      if (_selectedTrainingType != null) {
        filters['type'] = _selectedTrainingType!;
      }
      if (_selectedBodyPart != null) {
        filters['bodyPart'] = _selectedBodyPart!;
      }
      
      // 取得動作列表
      var exercises = await _exerciseService.getExercisesByFilters(filters);

      // 客戶端過濾其他條件
      exercises = exercises.where((exercise) {
        // 過濾特定肌群
        if (_selectedSpecificMuscle != null && 
            exercise.specificMuscle != _selectedSpecificMuscle) {
          return false;
        }

        // 過濾器材類別
        if (_selectedEquipmentCategory != null && 
            exercise.equipmentCategory != _selectedEquipmentCategory) {
          return false;
        }

        // 過濾器材子類別
        if (_selectedEquipmentSubcategory != null && 
            exercise.equipmentSubcategory != _selectedEquipmentSubcategory) {
          return false;
        }

        return true;
      }).toList();

      _logDebug('成功載入 ${exercises.length} 個動作');

      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      _logDebug('載入動作列表失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0, // 只有在第一層才允許直接返回
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          // 如果沒有 pop 且不在第一層，執行階層返回
          _navigateBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _navigateToCustomExercises,
              tooltip: '自定義動作',
            ),
          ],
          leading: _currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateBack,
                )
              : null,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildCurrentStep(),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 0:
        return '選擇訓練類型';
      case 1:
        return '選擇身體部位';
      case 2:
        return '選擇特定肌群';
      case 3:
        return '選擇器材類別';
      case 4:
        return '選擇器材子類別';
      case 5:
        return '訓練動作列表';
      default:
        return '訓練動作庫';
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
      Navigator.pop(context, selectedExercise);
    }
  }

  void _navigateBack() {
    setState(() {
      switch (_currentStep) {
        case 1: // 返回到訓練類型
          _selectedTrainingType = null;
          _currentStep = 0;
          break;
        case 2: // 返回到身體部位
          _selectedBodyPart = null;
          _selectedSpecificMuscle = null;
          _currentStep = 1;
          _loadBodyParts();
          break;
        case 3: // 返回到特定肌群
          _selectedSpecificMuscle = null;
          _selectedEquipmentCategory = null;
          _currentStep = 2;
          _loadSpecificMuscles();
          break;
        case 4: // 返回到器材類別
          _selectedEquipmentCategory = null;
          _selectedEquipmentSubcategory = null;
          _currentStep = 3;
          _loadEquipmentCategories();
          break;
        case 5: // 返回到器材子類別或器材類別
          if (_selectedEquipmentSubcategory != null) {
            _selectedEquipmentSubcategory = null;
            _currentStep = 4;
            _loadEquipmentSubcategories();
          } else if (_selectedEquipmentCategory != null) {
            _selectedEquipmentCategory = null;
            _currentStep = 3;
            _loadEquipmentCategories();
          } else if (_selectedSpecificMuscle != null) {
            _selectedSpecificMuscle = null;
            _currentStep = 2;
            _loadSpecificMuscles();
          } else {
            _selectedBodyPart = null;
            _currentStep = 1;
            _loadBodyParts();
          }
          break;
      }
    });
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildSelection(
          title: '請選擇訓練類型:',
          items: _trainingTypes,
          selectedValue: _selectedTrainingType,
          onSelect: (value) {
            setState(() => _selectedTrainingType = value);
            _loadBodyParts();
          },
        );
      case 1:
        return _buildSelection(
          title: '請選擇身體部位:',
          subtitle: '已選擇：$_selectedTrainingType',
          items: _bodyParts,
          selectedValue: _selectedBodyPart,
          onSelect: (value) {
            setState(() => _selectedBodyPart = value);
            _loadSpecificMuscles();
          },
        );
      case 2:
        return _buildSelection(
          title: '請選擇特定肌群:',
          subtitle: _getSelectionPathText(),
          items: _specificMuscles,
          selectedValue: _selectedSpecificMuscle,
          onSelect: (value) {
            setState(() => _selectedSpecificMuscle = value);
            _loadEquipmentCategories();
          },
          showSkipButton: true,
          onSkip: _loadEquipmentCategories,
        );
      case 3:
        return _buildSelection(
          title: '請選擇器材類別:',
          subtitle: _getSelectionPathText(),
          items: _equipmentCategories,
          selectedValue: _selectedEquipmentCategory,
          onSelect: (value) {
            setState(() => _selectedEquipmentCategory = value);
            _loadEquipmentSubcategories();
          },
          showSkipButton: true,
          onSkip: _loadExercises,
        );
      case 4:
        return _buildSelection(
          title: '請選擇器材子類別:',
          subtitle: _getSelectionPathText(),
          items: _equipmentSubcategories,
          selectedValue: _selectedEquipmentSubcategory,
          onSelect: (value) {
            setState(() => _selectedEquipmentSubcategory = value);
            _loadExercises();
          },
          showSkipButton: true,
          onSkip: _loadExercises,
        );
      case 5:
        return _buildExerciseList();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelection({
    required String title,
    String? subtitle,
    required List<String> items,
    String? selectedValue,
    required Function(String) onSelect,
    bool showSkipButton = false,
    VoidCallback? onSkip,
  }) {
    return ExerciseFilterStep(
      title: title,
      subtitle: subtitle,
      items: items,
      selectedValue: selectedValue,
      onSelect: onSelect,
      showSkipButton: showSkipButton,
      onSkip: onSkip,
    );
  }

  String _getSelectionPathText() {
    List<String> parts = [];
    if (_selectedTrainingType != null) parts.add(_selectedTrainingType!);
    if (_selectedBodyPart != null) parts.add(_selectedBodyPart!);
    if (_selectedSpecificMuscle != null) parts.add(_selectedSpecificMuscle!);
    if (_selectedEquipmentCategory != null)
      parts.add(_selectedEquipmentCategory!);
    if (_selectedEquipmentSubcategory != null)
      parts.add(_selectedEquipmentSubcategory!);

    return parts.isEmpty ? '' : '已選擇：${parts.join(' > ')}';
  }

  Widget _buildExerciseList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 頭部（選擇路徑和數量）
        ExerciseListHeader(
          selectionPath: _getSelectionPathText(),
          exerciseCount: _exercises.length,
        ),

        // 動作列表或空狀態
        Expanded(
          child: _exercises.isEmpty
              ? const EmptyExerciseState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return ExerciseListItem(
                      exercise: exercise,
                      selectedBodyPart: _selectedBodyPart,
                      selectedSpecificMuscle: _selectedSpecificMuscle,
                      selectedEquipmentCategory: _selectedEquipmentCategory,
                      selectedEquipmentSubcategory: _selectedEquipmentSubcategory,
                      onTap: () async {
                        final selectedExercise = await Navigator.push<Exercise>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExerciseDetailPage(exercise: exercise),
                          ),
                        );
                        if (selectedExercise != null && context.mounted) {
                          Navigator.pop(context, selectedExercise);
                        }
                      },
                      onSelect: () {
                        Navigator.pop(context, exercise);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
