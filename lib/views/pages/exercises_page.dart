import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/exercise_model.dart';
import 'exercise_detail_page.dart';
import '../../services/exercise_cache_service.dart';
import 'custom_exercises_page.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  _ExercisesPageState createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  bool _isLoading = true;
  String? _selectedType;
  String? _selectedBodyPart;
  String? _selectedLevel1;
  String? _selectedLevel2;
  String? _selectedLevel3;
  String? _selectedLevel4;
  String? _selectedLevel5;
  List<String> _exerciseTypes = [];
  List<String> _bodyParts = [];
  List<String> _level1Categories = [];
  List<String> _level2Categories = [];
  List<String> _level3Categories = [];
  List<String> _level4Categories = [];
  List<String> _level5Categories = [];
  List<Exercise> _exercises = [];
  
  int _currentStep = 0; // 當前導航步驟：0=類型, 1=身體部位, 2=level1, 3=level2...

  @override
  void initState() {
    super.initState();
    // 清除所有緩存，確保每次啟動應用時獲取最新數據
    _logDebug('應用啟動：正在清除所有緩存...');
    
    // 強制清除所有緩存，包括 SharedPreferences 和 Firestore 緩存
    ExerciseCacheService.clearCache().then((_) {
      _logDebug('緩存清除完成，開始加載訓練類型');
      _loadExerciseTypes();
    }).catchError((error) {
      _logDebug('緩存清除失敗: $error');
      // 即使緩存清除失敗，也繼續加載資料
      _loadExerciseTypes();
    });
  }
  
  // 用於調試的輔助方法
  void _logDebug(String message) {
    print('[DEBUG] $message');
  }
  
  // 載入訓練類型
  Future<void> _loadExerciseTypes() async {
    setState(() {
      _isLoading = true;
      _currentStep = 0;
    });
    
    try {
      _logDebug('開始載入訓練類型...');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('exerciseTypes')
          .orderBy('name')
          .get(const GetOptions(source: Source.server));
      
      List<String> types = [];
      for (var doc in querySnapshot.docs) {
        types.add(doc['name'] as String);
      }
      
      _logDebug('成功載入 ${types.length} 個訓練類型');
      
      setState(() {
        _exerciseTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      _logDebug('載入訓練類型失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 載入身體部位
  Future<void> _loadBodyParts() async {
    setState(() {
      _isLoading = true;
      _currentStep = 1;
    });
    
    try {
      _logDebug('開始載入身體部位，選擇的訓練類型: $_selectedType');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bodyParts')
          .orderBy('name')
          .get(const GetOptions(source: Source.server));
      
      List<String> parts = [];
      for (var doc in querySnapshot.docs) {
        parts.add(doc['name'] as String);
      }
      
      _logDebug('成功載入 ${parts.length} 個身體部位');
      
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
  
  // 通用載入分類方法
  Future<void> _loadCategories(int level) async {
    setState(() {
      _isLoading = true;
      _currentStep = level + 1;
    });
    
    _logDebug('開始載入Level$level分類');
    _logDebug('目前選擇條件: type=$_selectedType, bodyPart=$_selectedBodyPart');
    _logDebug('目前選擇層級: L1=$_selectedLevel1, L2=$_selectedLevel2, L3=$_selectedLevel3, L4=$_selectedLevel4, L5=$_selectedLevel5');
    
    // 先檢查是否有緩存
    final cacheKey = 'level${level}_${_selectedType ?? ""}_${_selectedBodyPart ?? ""}_${_selectedLevel1 ?? ""}_${_selectedLevel2 ?? ""}_${_selectedLevel3 ?? ""}_${_selectedLevel4 ?? ""}';
    _logDebug('緩存鍵: $cacheKey');
    
    // 首先检查是否应该强制从Firestore加载
    bool forceLoad = false;
    
    // 先清除该级别的旧缓存，确保获取新数据
    await ExerciseCacheService.clearCacheForKey('cat_$cacheKey');
    _logDebug('已清除当前层级缓存');
    
    // 直接从Firestore获取数据，跳过缓存
    try {
      // 構建基於層級的查詢
      _logDebug('從Firestore查詢Level$level分類');
      Query query = FirebaseFirestore.instance.collection('exercise');
      
      // 總是添加類型過濾條件，這是基本條件
      if (_selectedType != null && _selectedType!.isNotEmpty) {
        query = query.where('type', isEqualTo: _selectedType);
        _logDebug('添加基本查詢條件: type=$_selectedType');
      }
      
      // 總是添加身體部位過濾條件，這是基本條件
      if (_selectedBodyPart != null && _selectedBodyPart!.isNotEmpty) {
        query = query.where('bodyParts', arrayContains: _selectedBodyPart);
        _logDebug('添加基本查詢條件: bodyParts包含$_selectedBodyPart');
      }
      
      // 根據當前要查詢的層級，添加所有前置層級的條件
      if (level >= 2 && _selectedLevel1 != null && _selectedLevel1!.isNotEmpty) {
        query = query.where('level1', isEqualTo: _selectedLevel1);
        _logDebug('添加層級條件: level1=$_selectedLevel1');
      }
      
      if (level >= 3 && _selectedLevel2 != null && _selectedLevel2!.isNotEmpty) {
        query = query.where('level2', isEqualTo: _selectedLevel2);
        _logDebug('添加層級條件: level2=$_selectedLevel2');
      }
      
      if (level >= 4 && _selectedLevel3 != null && _selectedLevel3!.isNotEmpty) {
        query = query.where('level3', isEqualTo: _selectedLevel3);
        _logDebug('添加層級條件: level3=$_selectedLevel3');
      }
      
      if (level >= 5 && _selectedLevel4 != null && _selectedLevel4!.isNotEmpty) {
        query = query.where('level4', isEqualTo: _selectedLevel4);
        _logDebug('添加層級條件: level4=$_selectedLevel4');
      }
      
      // 執行查詢，獲取文檔 - 使用 Source.SERVER 確保從服務器獲取最新數據
      final querySnapshot = await query.get(const GetOptions(source: Source.server));
      _logDebug('查詢到 ${querySnapshot.docs.length} 個文檔');
      
      // 輸出一些文檔信息以供調試
      if (querySnapshot.docs.isNotEmpty) {
        final sampleDoc = querySnapshot.docs.first;
        _logDebug('樣本文檔內容: id=${sampleDoc.id}, type=${sampleDoc['type']}, 層級=${sampleDoc['level1'] ?? ""}/${sampleDoc['level2'] ?? ""}/${sampleDoc['level3'] ?? ""}/${sampleDoc['level4'] ?? ""}/${sampleDoc['level5'] ?? ""}');
      }
      
      // 從所有符合條件的文檔中提取目標層級的唯一值
      Set<String> categories = {};
      for (var doc in querySnapshot.docs) {
        final fieldName = 'level$level';
        final category = doc[fieldName] as String? ?? '';
        if (category.isNotEmpty) {
          categories.add(category);
        }
      }
      
      _logDebug('提取出 ${categories.length} 個不同的Level$level分類值: ${categories.join(", ")}');
      
      // 更新狀態
      setState(() {
        switch (level) {
          case 1:
            _level1Categories = categories.toList()..sort();
            // 儲存到緩存
            ExerciseCacheService.cacheCategories(cacheKey, _level1Categories);
            break;
          case 2:
            _level2Categories = categories.toList()..sort();
            // 儲存到緩存
            ExerciseCacheService.cacheCategories(cacheKey, _level2Categories);
            break;
          case 3:
            _level3Categories = categories.toList()..sort();
            // 儲存到緩存
            ExerciseCacheService.cacheCategories(cacheKey, _level3Categories);
            break;
          case 4:
            _level4Categories = categories.toList()..sort();
            // 儲存到緩存
            ExerciseCacheService.cacheCategories(cacheKey, _level4Categories);
            break;
          case 5:
            _level5Categories = categories.toList()..sort();
            // 儲存到緩存
            ExerciseCacheService.cacheCategories(cacheKey, _level5Categories);
            break;
        }
        
        _isLoading = false;
        
        // 如果該層級沒有分類，直接加載最終動作列表
        if (categories.isEmpty) {
          _logDebug('沒有發現層級 $level 的分類，直接載入動作列表');
          _loadFinalExercises();
        }
      });
    } catch (e) {
      _logDebug('載入分類失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 根據最後一級分類載入動作
  Future<void> _loadFinalExercises() async {
    setState(() {
      _isLoading = true;
      _currentStep = 7;
    });
    
    // 构建缓存键，确保与所有的筛选条件关联
    final cacheKey = 'exercises_${_selectedType ?? ""}_${_selectedBodyPart ?? ""}_${_selectedLevel1 ?? ""}_${_selectedLevel2 ?? ""}_${_selectedLevel3 ?? ""}_${_selectedLevel4 ?? ""}_${_selectedLevel5 ?? ""}';
    _logDebug('最終動作緩存鍵: $cacheKey');
    
    // 清除该查询的旧缓存
    await ExerciseCacheService.clearCacheForKey('ex_$cacheKey');
    _logDebug('已清除最終動作緩存');
    
    try {
      _logDebug('從Firestore查詢最終動作');
      Query query = FirebaseFirestore.instance.collection('exercise');
      
      // 添加所有筛选条件
      if (_selectedType != null && _selectedType!.isNotEmpty) {
        query = query.where('type', isEqualTo: _selectedType);
        _logDebug('添加查詢條件: type=$_selectedType');
      }
      
      if (_selectedBodyPart != null && _selectedBodyPart!.isNotEmpty) {
        query = query.where('bodyParts', arrayContains: _selectedBodyPart);
        _logDebug('添加查詢條件: bodyParts包含$_selectedBodyPart');
      }
      
      if (_selectedLevel1 != null && _selectedLevel1!.isNotEmpty) {
        query = query.where('level1', isEqualTo: _selectedLevel1);
        _logDebug('添加查詢條件: level1=$_selectedLevel1');
      }
      
      if (_selectedLevel2 != null && _selectedLevel2!.isNotEmpty) {
        query = query.where('level2', isEqualTo: _selectedLevel2);
        _logDebug('添加查詢條件: level2=$_selectedLevel2');
      }
      
      if (_selectedLevel3 != null && _selectedLevel3!.isNotEmpty) {
        query = query.where('level3', isEqualTo: _selectedLevel3);
        _logDebug('添加查詢條件: level3=$_selectedLevel3');
      }
      
      if (_selectedLevel4 != null && _selectedLevel4!.isNotEmpty) {
        query = query.where('level4', isEqualTo: _selectedLevel4);
        _logDebug('添加查詢條件: level4=$_selectedLevel4');
      }
      
      if (_selectedLevel5 != null && _selectedLevel5!.isNotEmpty) {
        query = query.where('level5', isEqualTo: _selectedLevel5);
        _logDebug('添加查詢條件: level5=$_selectedLevel5');
      }
      
      // 执行查询 - 强制使用 Source.SERVER 绕过缓存
      final querySnapshot = await query.get(const GetOptions(source: Source.server));
      _logDebug('查詢到 ${querySnapshot.docs.length} 個最終動作');
      
      List<Exercise> exercises = [];
      for (var doc in querySnapshot.docs) {
        try {
          final exercise = Exercise.fromFirestore(doc);
          _logDebug('處理動作: ID=${exercise.id}, name=${exercise.name}, actionName=${exercise.actionName}');
          exercises.add(exercise);
        } catch (e) {
          _logDebug('解析動作失敗: ${doc.id} - $e');
        }
      }
      
      // 缓存结果供将来使用
      if (exercises.isNotEmpty) {
        ExerciseCacheService.cacheExercises(cacheKey, exercises);
      }
      
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      _logDebug('載入最終動作失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
  
  String _getAppBarTitle() {
    switch (_currentStep) {
      case 0:
        return '選擇訓練類型';
      case 1:
        return '選擇身體部位';
      case 2:
        return '選擇第一層分類';
      case 3:
        return '選擇第二層分類';
      case 4:
        return '選擇第三層分類';
      case 5:
        return '選擇第四層分類';
      case 6:
        return '選擇第五層分類';
      case 7:
        return '訓練動作列表';
      default:
        return '訓練動作庫';
    }
  }
  
  void _navigateToCustomExercises() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomExercisesPage(),
      ),
    );
  }
  
  void _navigateBack() {
    setState(() {
      switch (_currentStep) {
        case 1: // 返回到訓練類型選擇
          _selectedType = null;
          _currentStep = 0;
          break;
        case 2: // 返回到身體部位選擇
          _selectedBodyPart = null;
          _currentStep = 1;
          break;
        case 3: // 返回到level1選擇
          _selectedLevel1 = null;
          _currentStep = 2;
          break;
        case 4: // 返回到level2選擇
          _selectedLevel2 = null;
          _currentStep = 3;
          break;
        case 5: // 返回到level3選擇
          _selectedLevel3 = null;
          _currentStep = 4;
          break;
        case 6: // 返回到level4選擇
          _selectedLevel4 = null;
          _currentStep = 5;
          break;
        case 7: // 從最終動作列表返回
          if (_selectedLevel5 != null) {
            _selectedLevel5 = null;
            _currentStep = 6;
          } else if (_selectedLevel4 != null) {
            _selectedLevel4 = null;
            _currentStep = 5;
          } else if (_selectedLevel3 != null) {
            _selectedLevel3 = null;
            _currentStep = 4;
          } else if (_selectedLevel2 != null) {
            _selectedLevel2 = null;
            _currentStep = 3;
          } else if (_selectedLevel1 != null) {
            _selectedLevel1 = null;
            _currentStep = 2;
          } else {
            _selectedBodyPart = null;
            _currentStep = 1;
          }
          break;
      }
    });
  }
  
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildTypeSelection();
      case 1:
        return _buildBodyPartSelection();
      case 2:
        return _buildLevel1Selection();
      case 3:
        return _buildLevel2Selection();
      case 4:
        return _buildLevel3Selection();
      case 5:
        return _buildLevel4Selection();
      case 6:
        return _buildLevel5Selection();
      case 7:
        return _buildExerciseList();
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '請選擇訓練類型:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _exerciseTypes.length,
            itemBuilder: (context, index) {
              final type = _exerciseTypes[index];
              final isSelected = type == _selectedType;
              
              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text(
                    type,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                    });
                    _loadBodyParts();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildBodyPartSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '已選擇訓練類型: $_selectedType',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '請選擇身體部位:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _bodyParts.length,
            itemBuilder: (context, index) {
              final bodyPart = _bodyParts[index];
              final isSelected = bodyPart == _selectedBodyPart;
              
              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text(
                    bodyPart,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    setState(() {
                      _selectedBodyPart = bodyPart;
                    });
                    _loadCategories(1);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategorySelectionList(List<String> categories, String header, String selectedValue, Function(String) onSelectCategory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getSelectionPathText(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                header,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        if (categories.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '沒有找到符合條件的分類',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '請嘗試選擇其他條件',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text('查看所有符合條件的訓練'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      _loadFinalExercises();
                    },
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedValue;
                
                return Card(
                  elevation: isSelected ? 4 : 1,
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    title: Text(
                      category,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => onSelectCategory(category),
                  ),
                );
              },
            ),
          ),
        if (categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('跳過分類，直接顯示所有動作'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                _loadFinalExercises();
              },
            ),
          ),
      ],
    );
  }
  
  String _getSelectionPathText() {
    List<String> parts = [];
    if (_selectedType != null) parts.add(_selectedType!);
    if (_selectedBodyPart != null) parts.add(_selectedBodyPart!);
    if (_selectedLevel1 != null) parts.add(_selectedLevel1!);
    if (_selectedLevel2 != null) parts.add(_selectedLevel2!);
    if (_selectedLevel3 != null) parts.add(_selectedLevel3!);
    if (_selectedLevel4 != null) parts.add(_selectedLevel4!);
    if (_selectedLevel5 != null) parts.add(_selectedLevel5!);
    
    return '已選擇: ${parts.join(' > ')}';
  }
  
  Widget _buildLevel1Selection() {
    return _buildCategorySelectionList(
      _level1Categories,
      '請選擇第一層分類:',
      _selectedLevel1 ?? '',
      (category) {
        setState(() {
          _selectedLevel1 = category;
        });
        _loadCategories(2);
      }
    );
  }
  
  Widget _buildLevel2Selection() {
    return _buildCategorySelectionList(
      _level2Categories,
      '請選擇第二層分類:',
      _selectedLevel2 ?? '',
      (category) {
        setState(() {
          _selectedLevel2 = category;
        });
        _loadCategories(3);
      }
    );
  }
  
  Widget _buildLevel3Selection() {
    return _buildCategorySelectionList(
      _level3Categories,
      '請選擇第三層分類:',
      _selectedLevel3 ?? '',
      (category) {
        setState(() {
          _selectedLevel3 = category;
        });
        _loadCategories(4);
      }
    );
  }
  
  Widget _buildLevel4Selection() {
    return _buildCategorySelectionList(
      _level4Categories,
      '請選擇第四層分類:',
      _selectedLevel4 ?? '',
      (category) {
        setState(() {
          _selectedLevel4 = category;
        });
        _loadCategories(5);
      }
    );
  }
  
  Widget _buildLevel5Selection() {
    return _buildCategorySelectionList(
      _level5Categories,
      '請選擇第五層分類:',
      _selectedLevel5 ?? '',
      (category) {
        setState(() {
          _selectedLevel5 = category;
        });
        _loadFinalExercises();
      }
    );
  }
  
  Widget _buildExerciseList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getSelectionPathText(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '符合條件的訓練動作:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        Expanded(
          child: _exercises.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '沒有找到符合條件的訓練動作',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '請嘗試選擇其他條件',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  
                  // 優先使用actionName，如果為空則使用name
                  final displayName = (exercise.actionName != null && exercise.actionName!.isNotEmpty) 
                      ? exercise.actionName! 
                      : exercise.name;
                  
                  // 獲取所有非空的身體部位
                  final bodyParts = exercise.bodyParts.where((part) => part.isNotEmpty).toList();
                  final bodyPartsText = bodyParts.isNotEmpty ? bodyParts.join(', ') : '無指定部位';
                  
                  // 獲取器材信息，如果為空則顯示"徒手"
                  final equipment = exercise.equipment.isNotEmpty ? exercise.equipment : '徒手';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('訓練部位: $bodyPartsText'),
                            Text('所需器材: $equipment'),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 添加選擇按鈕
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                            tooltip: '選擇此動作',
                            onPressed: () {
                              // 直接返回所選動作
                              Navigator.pop(context, exercise);
                            },
                          ),
                          const Icon(Icons.info_outline),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExerciseDetailPage(exercise: exercise),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
  
  void _navigateToExerciseDetail(Exercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailPage(exercise: exercise),
      ),
    );
  }
} 