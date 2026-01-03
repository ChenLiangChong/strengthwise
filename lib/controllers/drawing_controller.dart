import 'package:flutter/material.dart';
import '../models/drawing_note_model.dart';
import '../services/interfaces/i_drawing_service.dart';
import '../services/core/error_handling_service.dart';

/// 繪圖控制器（完全解耦合）
class DrawingController extends ChangeNotifier {
  final IDrawingService _drawingService;
  final ErrorHandlingService _errorService;

  DrawingController(
    this._drawingService,
    this._errorService,
  );

  // ==================== 靜態暫存區（新建模式）====================
  /// ⭐ 臨時繪圖暫存區（sessionNoteId -> DrawingNoteModel）
  static final Map<String, DrawingNoteModel> _temporaryDrawings = {};
  
  /// 獲取臨時繪圖（用於保存筆記時）
  static DrawingNoteModel? getTemporaryDrawing(String sessionNoteId) {
    return _temporaryDrawings[sessionNoteId];
  }
  
  /// 設置臨時繪圖（用於載入現有繪圖到暫存）
  static void setTemporaryDrawing(String sessionNoteId, DrawingNoteModel drawing) {
    _temporaryDrawings[sessionNoteId] = drawing;
    debugPrint('[DRAWING_CONTROLLER] 💾 設置臨時繪圖: $sessionNoteId');
  }
  
  /// 清除臨時繪圖（保存成功後）
  static void clearTemporaryDrawing(String sessionNoteId) {
    _temporaryDrawings.remove(sessionNoteId);
    debugPrint('[DRAWING_CONTROLLER] 🗑️ 清除臨時繪圖: $sessionNoteId');
  }

  // ==================== 狀態管理 ====================
  DrawingNoteModel? _currentDrawing;
  int _currentLayerIndex = 0;
  DrawingTool _currentTool = DrawingTool.pencil;
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 3.0;
  double _currentOpacity = 1.0;
  bool _isLoading = false;
  String? _errorMessage;

  // 撤銷/重做堆疊
  final List<DrawingNoteModel> _undoStack = [];
  final List<DrawingNoteModel> _redoStack = [];

  // ==================== Getters ====================
  DrawingNoteModel? get currentDrawing => _currentDrawing;
  int get currentLayerIndex => _currentLayerIndex;
  DrawingTool get currentTool => _currentTool;
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  double get currentOpacity => _currentOpacity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DrawingLayer? get currentLayer =>
      _currentDrawing?.layers[_currentLayerIndex];
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // ==================== 初始化繪圖 ====================
  /// 創建新繪圖（綁定到 Session Note）
  Future<void> createDrawing({
    required String sessionNoteId,
    required String templateType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentDrawing = await _drawingService.createDrawing(
        sessionNoteId: sessionNoteId,
        templateType: templateType,
      );
      _currentLayerIndex = 0;
      _undoStack.clear();
      _redoStack.clear();
    } catch (e) {
      _errorService.logError('創建繪圖失敗: $e', type: 'DrawingControllerError');
      _errorMessage = '創建繪圖失敗';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 載入現有繪圖
  Future<void> loadDrawing(String sessionNoteId, {String? templateType}) async {
    debugPrint('[DRAWING_CONTROLLER] 📖 嘗試載入繪圖');
    debugPrint('[DRAWING_CONTROLLER] 🆔 筆記 ID: $sessionNoteId');
    debugPrint('[DRAWING_CONTROLLER] 📋 模板類型: $templateType');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ⭐ 優先檢查靜態暫存區（臨時 ID）
      if (sessionNoteId.startsWith('temp-')) {
        final tempDrawing = _temporaryDrawings[sessionNoteId];
        if (tempDrawing != null) {
          // 檢查模板類型是否匹配
          if (templateType == null || tempDrawing.templateType == templateType) {
            _currentDrawing = tempDrawing;
            debugPrint('[DRAWING_CONTROLLER] ✅ 從暫存區載入成功：繪圖 ID=${_currentDrawing!.id}');
            debugPrint('[DRAWING_CONTROLLER] 📐 圖層數量: ${_currentDrawing!.layers.length}');
            _currentLayerIndex = 0;
            _undoStack.clear();
            _redoStack.clear();
            return; // 提前返回
          }
        }
        debugPrint('[DRAWING_CONTROLLER] ℹ️ 暫存區找不到繪圖，創建新的');
      } else {
        // 從資料庫載入
        _currentDrawing = await _drawingService.getDrawing(sessionNoteId, templateType: templateType);
        
        if (_currentDrawing != null) {
          debugPrint('[DRAWING_CONTROLLER] ✅ 從資料庫載入成功：繪圖 ID=${_currentDrawing!.id}');
        } else {
          debugPrint('[DRAWING_CONTROLLER] ⚠️ 找不到繪圖');
        }
      }
      
      _currentLayerIndex = 0;
      _undoStack.clear();
      _redoStack.clear();
    } catch (e) {
      debugPrint('[DRAWING_CONTROLLER] ❌ 載入失敗: $e');
      _errorService.logError('載入繪圖失敗: $e', type: 'DrawingControllerError');
      _errorMessage = '載入繪圖失敗';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== 繪圖操作 ====================
  /// 開始繪製（觸控按下）
  void startDrawing(Offset position, [Size? canvasSize]) {
    if (_currentDrawing == null || currentLayer == null) return;

    // 首次繪製時記錄畫布尺寸
    if (canvasSize != null && 
        (_currentDrawing!.canvasWidth == 800.0 || _currentDrawing!.canvasHeight == 600.0)) {
      debugPrint('[DRAWING_CONTROLLER] 📐 記錄畫布尺寸: ${canvasSize.width} x ${canvasSize.height}');
      _currentDrawing = _currentDrawing!.copyWith(
        canvasWidth: canvasSize.width,
        canvasHeight: canvasSize.height,
      );
    }

    // 保存當前狀態到撤銷堆疊
    _saveToUndoStack();

    // 創建新筆劃
    final newStroke = DrawingStroke(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: [
        DrawingPoint(
          x: position.dx,
          y: position.dy,
        ),
      ],
      color: _currentColor,
      strokeWidth: _currentStrokeWidth,
      opacity: _currentOpacity,
      tool: _currentTool,
    );

    // 添加到當前圖層
    final updatedLayer = currentLayer!.copyWith(
      strokes: [...currentLayer!.strokes, newStroke],
    );

    _updateLayer(_currentLayerIndex, updatedLayer);
  }

  /// 繼續繪製（觸控移動）
  void continueDrawing(Offset position) {
    if (_currentDrawing == null || currentLayer == null) return;
    if (currentLayer!.strokes.isEmpty) return;

    // 取得最後一筆
    final lastStroke = currentLayer!.strokes.last;

    // 添加新點
    final updatedStroke = DrawingStroke(
      id: lastStroke.id,
      points: [
        ...lastStroke.points,
        DrawingPoint(
          x: position.dx,
          y: position.dy,
        ),
      ],
      color: lastStroke.color,
      strokeWidth: lastStroke.strokeWidth,
      opacity: lastStroke.opacity,
      tool: lastStroke.tool,
    );

    // 更新圖層
    final updatedStrokes = [...currentLayer!.strokes];
    updatedStrokes[updatedStrokes.length - 1] = updatedStroke;

    final updatedLayer = currentLayer!.copyWith(strokes: updatedStrokes);
    _updateLayer(_currentLayerIndex, updatedLayer);
  }

  /// 結束繪製（觸控放開）
  void endDrawing() {
    // 自動保存
    saveDrawing();
  }

  /// 擦除（只擦除當前圖層，底圖層 isLocked=true 不受影響）
  void eraseAt(Offset position, double eraserRadius) {
    if (_currentDrawing == null || currentLayer == null) return;
    if (currentLayer!.isLocked) return; // 底圖層鎖定，不可擦除

    _saveToUndoStack();

    final updatedStrokes = <DrawingStroke>[];

    for (final stroke in currentLayer!.strokes) {
      final filteredPoints = <DrawingPoint>[];

      for (final point in stroke.points) {
        final distance = (Offset(point.x, point.y) - position).distance;
        if (distance > eraserRadius) {
          filteredPoints.add(point);
        }
      }

      // 如果筆劃還有剩餘點，保留
      if (filteredPoints.isNotEmpty) {
        updatedStrokes.add(
          DrawingStroke(
            id: stroke.id,
            points: filteredPoints,
            color: stroke.color,
            strokeWidth: stroke.strokeWidth,
            opacity: stroke.opacity,
            tool: stroke.tool,
          ),
        );
      }
    }

    final updatedLayer = currentLayer!.copyWith(strokes: updatedStrokes);
    _updateLayer(_currentLayerIndex, updatedLayer);
    saveDrawing();
  }

  // ==================== 工具設定 ====================
  void setTool(DrawingTool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _currentStrokeWidth = width;
    notifyListeners();
  }

  void setOpacity(double opacity) {
    _currentOpacity = opacity;
    notifyListeners();
  }

  // ==================== 圖層管理 ====================
  void setCurrentLayer(int index) {
    if (_currentDrawing != null && index < _currentDrawing!.layers.length) {
      _currentLayerIndex = index;
      notifyListeners();
    }
  }

  void addLayer(String name) {
    if (_currentDrawing == null) return;

    _saveToUndoStack();

    final newLayer = DrawingLayer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      isVisible: true,
      isLocked: false,
      strokes: [],
    );

    _currentDrawing = _currentDrawing!.copyWith(
      layers: [..._currentDrawing!.layers, newLayer],
    );

    _currentLayerIndex = _currentDrawing!.layers.length - 1;
    notifyListeners();
    saveDrawing();
  }

  void removeLayer(int index) {
    if (_currentDrawing == null || _currentDrawing!.layers.length <= 1) return;

    _saveToUndoStack();

    final updatedLayers = [..._currentDrawing!.layers];
    updatedLayers.removeAt(index);

    _currentDrawing = _currentDrawing!.copyWith(layers: updatedLayers);

    if (_currentLayerIndex >= updatedLayers.length) {
      _currentLayerIndex = updatedLayers.length - 1;
    }

    notifyListeners();
    saveDrawing();
  }

  void toggleLayerVisibility(int index) {
    if (_currentDrawing == null) return;

    final layer = _currentDrawing!.layers[index];
    final updatedLayer = layer.copyWith(isVisible: !layer.isVisible);

    _updateLayer(index, updatedLayer);
    saveDrawing();
  }

  // ==================== 撤銷/重做 ====================
  void undo() {
    if (!canUndo) return;

    _redoStack.add(_currentDrawing!);
    _currentDrawing = _undoStack.removeLast();
    notifyListeners();
    saveDrawing();
  }

  void redo() {
    if (!canRedo) return;

    _undoStack.add(_currentDrawing!);
    _currentDrawing = _redoStack.removeLast();
    notifyListeners();
    saveDrawing();
  }

  void _saveToUndoStack() {
    if (_currentDrawing != null) {
      _undoStack.add(_currentDrawing!);
      _redoStack.clear(); // 清空重做堆疊
    }
  }

  // ==================== 儲存 ====================
  /// 保存繪圖（自動重試 3 次，使用指數退避）
  Future<void> saveDrawing() async {
    if (_currentDrawing == null) return;

    // ⭐ 暫存模式：臨時 ID 保存到靜態暫存區
    if (_currentDrawing!.sessionNoteId.startsWith('temp-')) {
      _temporaryDrawings[_currentDrawing!.sessionNoteId] = _currentDrawing!;
      debugPrint('[DRAWING_CONTROLLER] 💾 繪圖已暫存到記憶體: ${_currentDrawing!.sessionNoteId}');
      debugPrint('[DRAWING_CONTROLLER] 📦 暫存區大小: ${_temporaryDrawings.length}');
      return; // 跳過資料庫保存
    }

    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        await _drawingService.saveDrawing(_currentDrawing!);
        
        // ✅ 成功：清除錯誤訊息
        if (_errorMessage != null) {
          _errorMessage = null;
          notifyListeners();
        }
        return; // 成功，退出重試循環
      } catch (e) {
        attempt++;
        
        // 記錄錯誤
        _errorService.logError(
          '保存繪圖失敗 (嘗試 $attempt/$maxRetries): $e',
          type: 'DrawingControllerError',
        );

        if (attempt >= maxRetries) {
          // ❌ 最終失敗：顯示錯誤訊息
          _errorMessage = '保存繪圖失敗，請檢查網路連線';
          notifyListeners();
          break;
        } else {
          // ⏳ 重試：使用指數退避（200ms, 400ms, 800ms）
          final delayMs = 200 * (1 << (attempt - 1));
          debugPrint('[DRAWING_CONTROLLER] 🔄 ${delayMs}ms 後重試...');
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }
    }
  }

  // ==================== 輔助方法 ====================
  void _updateLayer(int index, DrawingLayer updatedLayer) {
    if (_currentDrawing == null) return;

    final updatedLayers = [..._currentDrawing!.layers];
    updatedLayers[index] = updatedLayer;

    _currentDrawing = _currentDrawing!.copyWith(layers: updatedLayers);
    notifyListeners();
  }

  /// 清空畫布（只清空當前圖層）
  void clearCurrentLayer() {
    if (_currentDrawing == null || currentLayer == null) return;
    if (currentLayer!.isLocked) return;

    _saveToUndoStack();

    final updatedLayer = currentLayer!.copyWith(strokes: []);
    _updateLayer(_currentLayerIndex, updatedLayer);
    saveDrawing();
  }
}

