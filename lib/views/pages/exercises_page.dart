import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/exercise_model.dart';
import 'exercise_detail_page.dart';
import '../../services/exercise_cache_service.dart';

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
  
  int _currentStep = 0; // 當前導航步驟：0=類型, 1=部位, 2=level1, 3=level2...

  @override
  void initState() {
    super.initState();
    // 清除所有緩存，確保每次啟動應用時獲取最新數據
    _logDebug('應用啟動：正在清除所有緩存...');
    
    // 強制清除所有緩存，包括 SharedPreferences 和 Firestore 緩存
    ExerciseCacheService.clearAllCaches().then((_) {
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
    _logDebug('目前選擇條件: type=${_selectedType}, bodyPart=${_selectedBodyPart}');
    _logDebug('目前選擇層級: L1=${_selectedLevel1}, L2=${_selectedLevel2}, L3=${_selectedLevel3}, L4=${_selectedLevel4}, L5=${_selectedLevel5}');
    
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
        _logDebug('添加基本查詢條件: type=${_selectedType}');
      }
      
      // 總是添加身體部位過濾條件，這是基本條件
      if (_selectedBodyPart != null && _selectedBodyPart!.isNotEmpty) {
        query = query.where('bodyParts', arrayContains: _selectedBodyPart);
        _logDebug('添加基本查詢條件: bodyParts包含${_selectedBodyPart}');
      }
      
      // 根據當前要查詢的層級，添加所有前置層級的條件
      if (level >= 2 && _selectedLevel1 != null && _selectedLevel1!.isNotEmpty) {
        query = query.where('level1', isEqualTo: _selectedLevel1);
        _logDebug('添加層級條件: level1=${_selectedLevel1}');
      }
      
      if (level >= 3 && _selectedLevel2 != null && _selectedLevel2!.isNotEmpty) {
        query = query.where('level2', isEqualTo: _selectedLevel2);
        _logDebug('添加層級條件: level2=${_selectedLevel2}');
      }
      
      if (level >= 4 && _selectedLevel3 != null && _selectedLevel3!.isNotEmpty) {
        query = query.where('level3', isEqualTo: _selectedLevel3);
        _logDebug('添加層級條件: level3=${_selectedLevel3}');
      }
      
      if (level >= 5 && _selectedLevel4 != null && _selectedLevel4!.isNotEmpty) {
        query = query.where('level4', isEqualTo: _selectedLevel4);
        _logDebug('添加層級條件: level4=${_selectedLevel4}');
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
            ExerciseCacheService.cacheCategories('${cacheKey}', _level1Categories);
            break;
          case 2:
            _level2Categories = categories.toList()..sort();
            // 儲存到緩存
            ExerciseCacheService.cacheCategories('${cacheKey}', _level2Categories);
            break;
          case 3:
            _level3Categories = categories.toList()..sort();
            // 儲存到緩存
            ExerciseCacheService.cacheCategories('${cacheKey}', _level3Categories);
            break;
          case 4:
            _level4Categories = categories.toList()..sort();
            // 儲存到緩存
            ExerciseCacheService.cacheCategories('${cacheKey}', _level4Categories);
            break;
          case 5:
            _level5Categories = categories.toList()..sort();
            // 儲存到緩存
            ExerciseCacheService.cacheCategories('${cacheKey}', _level5Categories);
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
        _logDebug('添加查詢條件: type=${_selectedType}');
      }
      
      if (_selectedBodyPart != null && _selectedBodyPart!.isNotEmpty) {
        query = query.where('bodyParts', arrayContains: _selectedBodyPart);
        _logDebug('添加查詢條件: bodyParts包含${_selectedBodyPart}');
      }
      
      if (_selectedLevel1 != null && _selectedLevel1!.isNotEmpty) {
        query = query.where('level1', isEqualTo: _selectedLevel1);
        _logDebug('添加查詢條件: level1=${_selectedLevel1}');
      }
      
      if (_selectedLevel2 != null && _selectedLevel2!.isNotEmpty) {
        query = query.where('level2', isEqualTo: _selectedLevel2);
        _logDebug('添加查詢條件: level2=${_selectedLevel2}');
      }
      
      if (_selectedLevel3 != null && _selectedLevel3!.isNotEmpty) {
        query = query.where('level3', isEqualTo: _selectedLevel3);
        _logDebug('添加查詢條件: level3=${_selectedLevel3}');
      }
      
      if (_selectedLevel4 != null && _selectedLevel4!.isNotEmpty) {
        query = query.where('level4', isEqualTo: _selectedLevel4);
        _logDebug('添加查詢條件: level4=${_selectedLevel4}');
      }
      
      if (_selectedLevel5 != null && _selectedLevel5!.isNotEmpty) {
        query = query.where('level5', isEqualTo: _selectedLevel5);
        _logDebug('添加查詢條件: level5=${_selectedLevel5}');
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
    // 獲取完整的導航路徑
    final fullTitle = _getFullTitle();
    
    return Scaffold(
      appBar: AppBar(
        title: _currentStep == 0 
            ? const Text('訓練動作庫') 
            : Text(fullTitle, overflow: TextOverflow.ellipsis),
        leading: _currentStep > 0 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _navigateBack();
                },
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCurrentStep(),
    );
  }
  
  Widget _buildTitle() {
    // 使用完整標題替代原有簡單標題
    return Text(_getFullTitle(), overflow: TextOverflow.ellipsis);
  }
  
  // 獲取完整標題
  String _getFullTitle() {
    if (_currentStep == 0) return '訓練動作庫';
    
    List<String> parts = [];
    if (_selectedType != null && _selectedType!.isNotEmpty) parts.add(_selectedType!);
    if (_selectedBodyPart != null && _selectedBodyPart!.isNotEmpty) parts.add(_selectedBodyPart!);
    if (_selectedLevel1 != null && _selectedLevel1!.isNotEmpty) parts.add(_selectedLevel1!);
    if (_selectedLevel2 != null && _selectedLevel2!.isNotEmpty) parts.add(_selectedLevel2!);
    if (_selectedLevel3 != null && _selectedLevel3!.isNotEmpty) parts.add(_selectedLevel3!);
    if (_selectedLevel4 != null && _selectedLevel4!.isNotEmpty) parts.add(_selectedLevel4!);
    if (_selectedLevel5 != null && _selectedLevel5!.isNotEmpty) parts.add(_selectedLevel5!);
    
    return parts.join(' > ');
  }
  
  void _navigateBack() {
    setState(() {
      switch (_currentStep) {
        case 1:
          _selectedType = null;
          _loadExerciseTypes();
          break;
        case 2:
          _selectedBodyPart = null;
          _loadBodyParts();
          break;
        case 3:
          _selectedLevel1 = null;
          _loadCategories(1);
          break;
        case 4:
          _selectedLevel2 = null;
          _loadCategories(2);
          break;
        case 5:
          _selectedLevel3 = null;
          _loadCategories(3);
          break;
        case 6:
          _selectedLevel4 = null;
          _loadCategories(4);
          break;
        case 7:
          if (_selectedLevel5 != null) {
            _selectedLevel5 = null;
            _loadCategories(5);
          } else if (_selectedLevel4 != null) {
            _selectedLevel4 = null;
            _loadCategories(4);
          } else if (_selectedLevel3 != null) {
            _selectedLevel3 = null;
            _loadCategories(3);
          } else if (_selectedLevel2 != null) {
            _selectedLevel2 = null;
            _loadCategories(2);
          } else if (_selectedLevel1 != null) {
            _selectedLevel1 = null;
            _loadCategories(1);
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
    return ListView.builder(
      itemCount: _exerciseTypes.length,
      itemBuilder: (context, index) {
        final type = _exerciseTypes[index];
        return ListTile(
          title: Text(type),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedType = type;
            });
            _loadBodyParts();
          },
        );
      },
    );
  }
  
  Widget _buildBodyPartSelection() {
    return ListView.builder(
      itemCount: _bodyParts.length,
      itemBuilder: (context, index) {
        final part = _bodyParts[index];
        return ListTile(
          title: Text(part),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedBodyPart = part;
            });
            _loadCategories(1);
          },
        );
      },
    );
  }
  
  Widget _buildLevel1Selection() {
    if (_level1Categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('沒有找到分類', 
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('請確認數據庫中是否有相關動作',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _level1Categories.length,
      itemBuilder: (context, index) {
        final category = _level1Categories[index];
        return ListTile(
          title: Text(category),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedLevel1 = category;
            });
            _loadCategories(2);
          },
        );
      },
    );
  }
  
  Widget _buildLevel2Selection() {
    if (_level2Categories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFinalExercises();
      });
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('沒有找到更多分類，正在載入動作...', 
                style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _level2Categories.length,
      itemBuilder: (context, index) {
        final category = _level2Categories[index];
        return ListTile(
          title: Text(category),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedLevel2 = category;
            });
            _loadCategories(3);
          },
        );
      },
    );
  }
  
  Widget _buildLevel3Selection() {
    if (_level3Categories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFinalExercises();
      });
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('沒有找到更多分類，正在載入動作...', 
                style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _level3Categories.length,
      itemBuilder: (context, index) {
        final category = _level3Categories[index];
        return ListTile(
          title: Text(category),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedLevel3 = category;
            });
            _loadCategories(4);
          },
        );
      },
    );
  }
  
  Widget _buildLevel4Selection() {
    if (_level4Categories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFinalExercises();
      });
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('沒有找到更多分類，正在載入動作...', 
                style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _level4Categories.length,
      itemBuilder: (context, index) {
        final category = _level4Categories[index];
        return ListTile(
          title: Text(category),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedLevel4 = category;
            });
            _loadCategories(5);
          },
        );
      },
    );
  }
  
  Widget _buildLevel5Selection() {
    if (_level5Categories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFinalExercises();
      });
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('沒有找到更多分類，正在載入動作...', 
                style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _level5Categories.length,
      itemBuilder: (context, index) {
        final category = _level5Categories[index];
        return ListTile(
          title: Text(category),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedLevel5 = category;
            });
            _loadFinalExercises();
          },
        );
      },
    );
  }
  
  Widget _buildExerciseList() {
    if (_exercises.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('沒有找到符合條件的訓練動作', 
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('請嘗試選擇其他分類或返回上一層',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _exercises.length,
      itemBuilder: (context, index) => _exercises.isNotEmpty && index < _exercises.length ? 
        _buildExerciseItem(_exercises[index]) : const SizedBox.shrink(),
    );
  }
  
  Widget _buildExerciseItem(Exercise exercise) {
    // 調試信息：輸出完整的exercise對象數據
    _logDebug('構建運動項目: ID=${exercise.id}');
    _logDebug('數據詳情：name=${exercise.name}, actionName=${exercise.actionName}');
    _logDebug('數據詳情：type=${exercise.type}, bodyParts=${exercise.bodyParts}');
    _logDebug('數據詳情：各層級：L1=${exercise.level1}, L2=${exercise.level2}, L3=${exercise.level3}');
    
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _logDebug('點擊了運動項目: ${exercise.name} (actionName: ${exercise.actionName}) (ID: ${exercise.id})');
          try {
            _logDebug('嘗試導航到詳情頁...');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDetailPage(exercise: exercise),
              ),
            );
            _logDebug('導航成功完成');
          } catch (e) {
            _logDebug('導航失敗: $e');
            _logDebug('導航失敗堆棧: ${StackTrace.current}');
          }
        },
      ),
    );
  }
} 