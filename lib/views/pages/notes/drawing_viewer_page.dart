import 'package:flutter/material.dart';
import 'package:strengthwise/models/drawing_note_model.dart';
import 'package:strengthwise/views/painters/drawing_canvas_painter.dart';

/// 繪圖查看器頁面（只讀模式）
/// 
/// 功能：
/// - 顯示底圖 + 繪圖內容
/// - 只能查看，不能編輯
/// - 支援縮放與平移
class DrawingViewerPage extends StatefulWidget {
  /// 繪圖數據
  final Map<String, dynamic> drawingData;
  
  /// 底圖類型
  final String templateType;

  const DrawingViewerPage({
    Key? key,
    required this.drawingData,
    required this.templateType,
  }) : super(key: key);

  @override
  State<DrawingViewerPage> createState() => _DrawingViewerPageState();
}

class _DrawingViewerPageState extends State<DrawingViewerPage> {
  late DrawingNoteModel _drawing;
  final TransformationController _transformationController = 
      TransformationController();

  @override
  void initState() {
    super.initState();
    // 從 Map 轉換為 DrawingNoteModel
    _drawing = DrawingNoteModel.fromJson(widget.drawingData);
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
        title: const Text('查看繪圖'),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          // 重置縮放
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            onPressed: () {
              setState(() {
                _transformationController.value = Matrix4.identity();
              });
            },
            tooltip: '重置縮放',
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          // 提示欄
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[300]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '只讀模式 • 雙指縮放/拖動查看',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[300],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 繪圖畫布（只讀）
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(100),
              child: Center(
                child: Container(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      // 底圖層（不可編輯）
                      Positioned.fill(
                        child: Image.asset(
                          _getTemplateAssetPath(widget.templateType),
                          fit: BoxFit.contain,
                        ),
                      ),
                      // 繪圖層（只顯示）
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DrawingCanvasPainter(
                            drawing: _drawing,
                            currentLayerIndex: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // 底部資訊欄
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTemplateName(widget.templateType),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_drawing.layers.length} 個圖層 • ${_getTotalStrokesCount()} 個筆劃',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 獲取底圖資源路徑
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

  /// 獲取底圖名稱
  String _getTemplateName(String templateType) {
    switch (templateType) {
      case 'note1':
        return '三視圖（前/側/背）';
      case 'note2':
        return '前視圖';
      case 'note3':
        return '側視圖';
      case 'note4':
        return '背視圖';
      default:
        return '底圖';
    }
  }

  /// 獲取總筆劃數
  int _getTotalStrokesCount() {
    int count = 0;
    for (final layer in _drawing.layers) {
      count += layer.strokes.length;
    }
    return count;
  }
}

