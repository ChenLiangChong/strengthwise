import 'package:flutter/material.dart';
import 'package:strengthwise/utils/immutable_list.dart';
import '../models/drawing_note_model.dart';
import '../services/interfaces/i_drawing_service.dart';
import '../services/core/error_handling_service.dart';
import 'interfaces/i_drawing_controller.dart';

/// 繪圖控制器（完全解耦合）
class DrawingController extends ChangeNotifier implements IDrawingController {
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

  // 撤銷/重做堆疊（使用 ImmutableList 確保狀態管理正確）
  ImmutableList<DrawingNoteModel> _undoStack = ImmutableList();
  ImmutableList<DrawingNoteModel> _redoStack = ImmutableList();

  // ==================== Getters ====================
  @override
  DrawingNoteModel? get currentDrawing => _currentDrawing;
  @override
  int get currentLayerIndex => _currentLayerIndex;
  @override
  DrawingTool get currentTool => _currentTool;
  @override
  Color get currentColor => _currentColor;
  @override
  double get currentStrokeWidth => _currentStrokeWidth;
  @override
  double get currentOpacity => _currentOpacity;
  @override
  bool get isLoading => _isLoading;
  @override
  String? get errorMessage => _errorMessage;
  @override
  DrawingLayer? get currentLayer =>
      _currentDrawing?.layers[_currentLayerIndex];
  @override
  bool get canUndo => _undoStack.isNotEmpty;
  @override
  bool get canRedo => _redoStack.isNotEmpty;

  // ==================== 初始化繪圖 ====================
  /// 創建新繪圖（綁定到 Session Note）
  @override
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
      _undoStack = ImmutableList();
      _redoStack = ImmutableList();
    } catch (e) {
      _errorService.logError('創建繪圖失敗: $e', type: 'DrawingControllerError');
      _errorMessage = '創建繪圖失敗';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 載入現有繪圖
  @override
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
            debugPrint('[DRAWING_CONTROLLER] ✅ 從暫存區載入成功：繪圖 ID=${tempDrawing.id}');
            debugPrint('[DRAWING_CONTROLLER] 📐 圖層數量: ${tempDrawing.layers.length}');
            _currentLayerIndex = 0;
            _undoStack = ImmutableList();
            _redoStack = ImmutableList();
            return; // 提前返回
          }
        }
        debugPrint('[DRAWING_CONTROLLER] ℹ️ 暫存區找不到繪圖，創建新的');
      } else {
        // 從資料庫載入
        final loadedDrawing = await _drawingService.getDrawing(sessionNoteId, templateType: templateType);
        _currentDrawing = loadedDrawing;

        if (loadedDrawing != null) {
          debugPrint('[DRAWING_CONTROLLER] ✅ 從資料庫載入成功：繪圖 ID=${loadedDrawing.id}');
        } else {
          debugPrint('[DRAWING_CONTROLLER] ⚠️ 找不到繪圖');
        }
      }
      
      _currentLayerIndex = 0;
      _undoStack = ImmutableList();
      _redoStack = ImmutableList();
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
  @override
  void startDrawing(Offset position, [Size? canvasSize]) {
    final drawing = _currentDrawing;
    final layer = currentLayer;
    if (drawing == null || layer == null) return;

    // 首次繪製時記錄畫布尺寸
    if (canvasSize != null &&
        (drawing.canvasWidth == 800.0 || drawing.canvasHeight == 600.0)) {
      debugPrint('[DRAWING_CONTROLLER] 📐 記錄畫布尺寸: ${canvasSize.width} x ${canvasSize.height}');
      _currentDrawing = drawing.copyWith(
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
    final updatedLayer = layer.copyWith(
      strokes: [...layer.strokes, newStroke],
    );

    _updateLayer(_currentLayerIndex, updatedLayer);
  }

  /// 繼續繪製（觸控移動）
  @override
  void continueDrawing(Offset position) {
    final layer = currentLayer;
    if (_currentDrawing == null || layer == null) return;
    if (layer.strokes.isEmpty) return;

    // 取得最後一筆
    final lastStroke = layer.strokes.last;

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
    final updatedStrokes = [...layer.strokes];
    updatedStrokes[updatedStrokes.length - 1] = updatedStroke;

    final updatedLayer = layer.copyWith(strokes: updatedStrokes);
    _updateLayer(_currentLayerIndex, updatedLayer);
  }

  /// 結束繪製（觸控放開）
  @override
  void endDrawing() {
    // 自動保存
    saveDrawing();
  }

  /// 擦除（只擦除當前圖層，底圖層 isLocked=true 不受影響）
  @override
  void eraseAt(Offset position, double eraserRadius) {
    final layer = currentLayer;
    if (_currentDrawing == null || layer == null) return;
    if (layer.isLocked) return; // 底圖層鎖定，不可擦除

    _saveToUndoStack();

    final updatedStrokes = <DrawingStroke>[];

    for (final stroke in layer.strokes) {
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

    final updatedLayer = layer.copyWith(strokes: updatedStrokes);
    _updateLayer(_currentLayerIndex, updatedLayer);
    saveDrawing();
  }

  // ==================== 工具設定 ====================
  @override
  void setTool(DrawingTool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  @override
  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  @override
  void setStrokeWidth(double width) {
    _currentStrokeWidth = width;
    notifyListeners();
  }

  @override
  void setOpacity(double opacity) {
    _currentOpacity = opacity;
    notifyListeners();
  }

  // ==================== 圖層管理 ====================
  @override
  void setCurrentLayer(int index) {
    final drawing = _currentDrawing;
    if (drawing != null && index < drawing.layers.length) {
      _currentLayerIndex = index;
      notifyListeners();
    }
  }

  @override
  void addLayer(String name) {
    final drawing = _currentDrawing;
    if (drawing == null) return;

    _saveToUndoStack();

    final newLayer = DrawingLayer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      isVisible: true,
      isLocked: false,
      strokes: [],
    );

    final updatedDrawing = drawing.copyWith(
      layers: [...drawing.layers, newLayer],
    );
    _currentDrawing = updatedDrawing;

    _currentLayerIndex = updatedDrawing.layers.length - 1;
    notifyListeners();
    saveDrawing();
  }

  @override
  void removeLayer(int index) {
    final drawing = _currentDrawing;
    if (drawing == null || drawing.layers.length <= 1) return;

    _saveToUndoStack();

    final updatedLayers = [...drawing.layers];
    updatedLayers.removeAt(index);

    _currentDrawing = drawing.copyWith(layers: updatedLayers);

    if (_currentLayerIndex >= updatedLayers.length) {
      _currentLayerIndex = updatedLayers.length - 1;
    }

    notifyListeners();
    saveDrawing();
  }

  @override
  void toggleLayerVisibility(int index) {
    final drawing = _currentDrawing;
    if (drawing == null) return;

    final layer = drawing.layers[index];
    final updatedLayer = layer.copyWith(isVisible: !layer.isVisible);

    _updateLayer(index, updatedLayer);
    saveDrawing();
  }

  // ==================== 撤銷/重做 ====================
  @override
  void undo() {
    final drawing = _currentDrawing;
    if (!canUndo || drawing == null) return;

    _redoStack = _redoStack.add(drawing);
    _currentDrawing = _undoStack.last;
    _undoStack = _undoStack.removeLast();
    notifyListeners();
    saveDrawing();
  }

  @override
  void redo() {
    final drawing = _currentDrawing;
    if (!canRedo || drawing == null) return;

    _undoStack = _undoStack.add(drawing);
    _currentDrawing = _redoStack.last;
    _redoStack = _redoStack.removeLast();
    notifyListeners();
    saveDrawing();
  }

  void _saveToUndoStack() {
    final drawing = _currentDrawing;
    if (drawing != null) {
      _undoStack = _undoStack.add(drawing);
      _redoStack = ImmutableList(); // 清空重做堆疊
    }
  }

  // ==================== 儲存 ====================
  /// 保存繪圖（自動重試 3 次，使用指數退避）
  @override
  Future<void> saveDrawing() async {
    final drawing = _currentDrawing;
    if (drawing == null) return;

    // ⭐ 暫存模式：臨時 ID 保存到靜態暫存區
    if (drawing.sessionNoteId.startsWith('temp-')) {
      _temporaryDrawings[drawing.sessionNoteId] = drawing;
      debugPrint('[DRAWING_CONTROLLER] 💾 繪圖已暫存到記憶體: ${drawing.sessionNoteId}');
      debugPrint('[DRAWING_CONTROLLER] 📦 暫存區大小: ${_temporaryDrawings.length}');
      return; // 跳過資料庫保存
    }

    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        await _drawingService.saveDrawing(drawing);
        
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
    final drawing = _currentDrawing;
    if (drawing == null) return;

    final updatedLayers = [...drawing.layers];
    updatedLayers[index] = updatedLayer;

    _currentDrawing = drawing.copyWith(layers: updatedLayers);
    notifyListeners();
  }

  /// 清空畫布（只清空當前圖層）
  @override
  void clearCurrentLayer() {
    final layer = currentLayer;
    if (_currentDrawing == null || layer == null) return;
    if (layer.isLocked) return;

    _saveToUndoStack();

    final updatedLayer = layer.copyWith(strokes: []);
    _updateLayer(_currentLayerIndex, updatedLayer);
    saveDrawing();
  }
}

