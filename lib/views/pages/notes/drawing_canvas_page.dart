// ✅ 已響應式改造 (Phase 0) - 全螢幕繪圖頁
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/interfaces/i_drawing_controller.dart';
import 'package:strengthwise/models/drawing_note_model.dart';
import 'package:strengthwise/views/painters/drawing_canvas_painter.dart';
import 'package:strengthwise/views/pages/notes/widgets/drawing_toolbar.dart';

/// 繪圖畫布頁面（主頁面）
class DrawingCanvasPage extends StatefulWidget {
  final String sessionNoteId;
  final String templateType;

  const DrawingCanvasPage({
    super.key,
    required this.sessionNoteId,
    required this.templateType,
  });

  @override
  State<DrawingCanvasPage> createState() => _DrawingCanvasPageState();
}

class _DrawingCanvasPageState extends State<DrawingCanvasPage> {
  late IDrawingController _controller;
  final TransformationController _transformationController =
      TransformationController();
  bool _isViewMode = false; // 查看模式（縮放）vs 繪圖模式

  @override
  void initState() {
    super.initState();
    _controller = context.read<IDrawingController>();

    // 載入或創建繪圖
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDrawing();
    });
  }

  Future<void> _initializeDrawing() async {
    debugPrint('[DRAWING_CANVAS] 🎨 初始化繪圖');
    debugPrint('[DRAWING_CANVAS] 🆔 筆記 ID: ${widget.sessionNoteId}');
    debugPrint('[DRAWING_CANVAS] 📋 要求的模板類型: ${widget.templateType}');

    // 先嘗試載入現有繪圖（指定模板類型）
    await _controller.loadDrawing(widget.sessionNoteId,
        templateType: widget.templateType);

    // 如果沒有現有繪圖，創建新的
    if (_controller.currentDrawing == null) {
      debugPrint('[DRAWING_CANVAS] ℹ️ 找不到現有繪圖（模板: ${widget.templateType}），創建新的');
      await _controller.createDrawing(
        sessionNoteId: widget.sessionNoteId,
        templateType: widget.templateType,
      );
      debugPrint('[DRAWING_CANVAS] ✅ 創建完成：${_controller.currentDrawing?.id}');
    } else {
      final drawing = _controller.currentDrawing;
      debugPrint('[DRAWING_CANVAS] ✅ 載入現有繪圖：${drawing?.id}');
      debugPrint('[DRAWING_CANVAS] 📋 繪圖的模板類型: ${drawing?.templateType}');
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練筆記繪圖'),
        actions: [
          // 模式切換按鈕
          IconButton(
            icon: Icon(_isViewMode ? Icons.edit : Icons.zoom_in),
            onPressed: () {
              setState(() {
                _isViewMode = !_isViewMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isViewMode ? '查看模式（可縮放）' : '繪圖模式'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: _isViewMode ? '切換到繪圖模式' : '切換到查看模式',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              debugPrint('[DRAWING_CANVAS] 💾 開始保存...');
              debugPrint('[DRAWING_CANVAS] 📋 sessionNoteId: ${widget.sessionNoteId}');
              debugPrint('[DRAWING_CANVAS] 📋 templateType: ${widget.templateType}');
              debugPrint('[DRAWING_CANVAS] 📋 currentDrawing: ${_controller.currentDrawing?.id}');
              
              await _controller.saveDrawing();
              
              debugPrint('[DRAWING_CANVAS] ✅ 保存完成');
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已保存')),
                );
              }
            },
            tooltip: '保存',
          ),
        ],
      ),
      body: Consumer<IDrawingController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Text(
                controller.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (controller.currentDrawing == null) {
            return const Center(child: Text('載入繪圖失敗'));
          }

          return Column(
            children: [
              // 繪圖畫布
              Expanded(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  panEnabled: _isViewMode, // 查看模式才能平移
                  scaleEnabled: _isViewMode, // 查看模式才能縮放
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 獲取畫布尺寸
                      final canvasSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );

                      return GestureDetector(
                        // 繪圖模式才響應手勢
                        onPanStart: _isViewMode
                            ? null
                            : (details) {
                                if (controller.currentTool ==
                                    DrawingTool.eraser) {
                                  controller.eraseAt(
                                    details.localPosition,
                                    controller.currentStrokeWidth * 2,
                                  );
                                } else {
                                  controller.startDrawing(
                                    details.localPosition,
                                    canvasSize, // 傳遞畫布尺寸
                                  );
                                }
                              },
                        onPanUpdate: _isViewMode
                            ? null
                            : (details) {
                                if (controller.currentTool ==
                                    DrawingTool.eraser) {
                                  controller.eraseAt(
                                    details.localPosition,
                                    controller.currentStrokeWidth * 2,
                                  );
                                } else {
                                  controller
                                      .continueDrawing(details.localPosition);
                                }
                              },
                        onPanEnd: _isViewMode
                            ? null
                            : (details) {
                                controller.endDrawing();
                              },
                        child: RepaintBoundary(
                          child: Container(
                            color: Colors.white,
                            child: Stack(
                              children: [
                                // 底圖層（不可編輯，不會被擦除）
                                Positioned.fill(
                                  child: Image.asset(
                                    _getTemplateAssetPath(
                                      controller.currentDrawing?.templateType ?? widget.templateType,
                                    ),
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                                // 繪圖層
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: DrawingCanvasPainter(
                                      drawing: controller.currentDrawing,
                                      currentLayerIndex:
                                          controller.currentLayerIndex,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // 工具列（繪圖模式才顯示）
              if (!_isViewMode)
                DrawingToolbar(
                  currentTool: controller.currentTool,
                  currentColor: controller.currentColor,
                  currentStrokeWidth: controller.currentStrokeWidth,
                  onToolChanged: controller.setTool,
                  onColorChanged: controller.setColor,
                  onStrokeWidthChanged: controller.setStrokeWidth,
                  onUndo: controller.undo,
                  onRedo: controller.redo,
                  onClear: controller.clearCurrentLayer,
                  canUndo: controller.canUndo,
                  canRedo: controller.canRedo,
                ),
            ],
          );
        },
      ),
    );
  }

  String _getTemplateAssetPath(String templateType) {
    switch (templateType) {
      case 'note1':
        return 'assets/templates/note1.png';
      case 'note2':
        return 'assets/templates/note2.png';
      case 'note3':
        return 'assets/templates/note3.png';
      case 'note4':
        return 'assets/templates/note4.png';
      default:
        return 'assets/templates/note1.png';
    }
  }
}
