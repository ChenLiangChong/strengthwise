import 'package:flutter/material.dart';
import '../../models/drawing_note_model.dart';

/// 繪圖控制器接口
abstract class IDrawingController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 當前繪圖
  DrawingNoteModel? get currentDrawing;

  /// 當前圖層索引
  int get currentLayerIndex;

  /// 當前工具
  DrawingTool get currentTool;

  /// 當前顏色
  Color get currentColor;

  /// 當前筆觸寬度
  double get currentStrokeWidth;

  /// 當前透明度
  double get currentOpacity;

  /// 載入中狀態
  bool get isLoading;

  /// 錯誤訊息
  String? get errorMessage;

  /// 當前圖層
  DrawingLayer? get currentLayer;

  /// 是否可撤銷
  bool get canUndo;

  /// 是否可重做
  bool get canRedo;

  // ==================== 初始化繪圖 ====================

  /// 創建新繪圖（綁定到 Session Note）
  Future<void> createDrawing({
    required String sessionNoteId,
    required String templateType,
  });

  /// 載入現有繪圖
  Future<void> loadDrawing(String sessionNoteId, {String? templateType});

  // ==================== 繪圖操作 ====================

  /// 開始繪製（觸控按下）
  void startDrawing(Offset position, [Size? canvasSize]);

  /// 繼續繪製（觸控移動）
  void continueDrawing(Offset position);

  /// 結束繪製（觸控放開）
  void endDrawing();

  /// 擦除
  void eraseAt(Offset position, double eraserRadius);

  // ==================== 工具設定 ====================

  void setTool(DrawingTool tool);
  void setColor(Color color);
  void setStrokeWidth(double width);
  void setOpacity(double opacity);

  // ==================== 圖層管理 ====================

  void setCurrentLayer(int index);
  void addLayer(String name);
  void removeLayer(int index);
  void toggleLayerVisibility(int index);

  // ==================== 撤銷/重做 ====================

  void undo();
  void redo();

  // ==================== 儲存 ====================

  /// 保存繪圖
  Future<void> saveDrawing();

  /// 清空畫布（只清空當前圖層）
  void clearCurrentLayer();
}
