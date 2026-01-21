// ✅ 已響應式改造 (Phase 0) - 全螢幕繪圖頁，無需約束
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:strengthwise/views/pages/notes/widgets/annotation_painter.dart';

/// 照片標註頁面
///
/// 功能：
/// - 在照片上繪製圓圈
/// - 繪製箭頭
/// - 添加文字註解
/// - 儲存標註為結構化數據
class PhotoAnnotationPage extends StatefulWidget {
  final File photo;

  const PhotoAnnotationPage({
    Key? key,
    required this.photo,
  }) : super(key: key);

  @override
  State<PhotoAnnotationPage> createState() => _PhotoAnnotationPageState();
}

class _PhotoAnnotationPageState extends State<PhotoAnnotationPage> {
  // 標註工具
  AnnotationTool _currentTool = AnnotationTool.none;

  // 標註列表
  final List<Annotation> _annotations = [];

  // 當前繪製中的標註
  Annotation? _currentAnnotation;

  // 顏色
  Color _currentColor = Colors.red;

  // 照片尺寸
  ui.Image? _image;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  /// 載入照片
  Future<void> _loadImage() async {
    final bytes = await widget.photo.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    setState(() {
      _image = frame.image;
      _imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    });
  }

  /// 處理觸控開始
  void _onPanStart(DragStartDetails details, Size canvasSize) {
    if (_currentTool == AnnotationTool.none) return;

    final localPosition = _convertToImageCoordinates(
      details.localPosition,
      canvasSize,
    );

    setState(() {
      switch (_currentTool) {
        case AnnotationTool.circle:
          _currentAnnotation = CircleAnnotation(
            center: localPosition,
            radius: 0,
            color: _currentColor,
          );
          break;
        case AnnotationTool.arrow:
          _currentAnnotation = ArrowAnnotation(
            start: localPosition,
            end: localPosition,
            color: _currentColor,
          );
          break;
        case AnnotationTool.text:
          _showTextDialog(localPosition);
          break;
        case AnnotationTool.none:
          break;
      }
    });
  }

  /// 處理觸控移動
  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    if (_currentAnnotation == null) return;

    final localPosition = _convertToImageCoordinates(
      details.localPosition,
      canvasSize,
    );

    setState(() {
      if (_currentAnnotation is CircleAnnotation) {
        final circle = _currentAnnotation as CircleAnnotation;
        final radius = (localPosition - circle.center).distance;
        _currentAnnotation = circle.copyWith(radius: radius);
      } else if (_currentAnnotation is ArrowAnnotation) {
        final arrow = _currentAnnotation as ArrowAnnotation;
        _currentAnnotation = arrow.copyWith(end: localPosition);
      }
    });
  }

  /// 處理觸控結束
  void _onPanEnd(DragEndDetails details) {
    if (_currentAnnotation != null) {
      setState(() {
        _annotations.add(_currentAnnotation!);
        _currentAnnotation = null;
      });
    }
  }

  /// 轉換到照片座標
  Offset _convertToImageCoordinates(Offset screenOffset, Size canvasSize) {
    final imageSize = _imageSize;
    if (imageSize == null) return Offset.zero;

    // 計算縮放比例
    final scaleX = imageSize.width / canvasSize.width;
    final scaleY = imageSize.height / canvasSize.height;

    return Offset(
      screenOffset.dx * scaleX,
      screenOffset.dy * scaleY,
    );
  }

  /// 顯示文字輸入對話框
  Future<void> _showTextDialog(Offset position) async {
    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      barrierDismissible: false, // 🔧 修復：禁止點擊外部關閉
      builder: (context) => AlertDialog(
        title: const Text('添加文字註解'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '輸入文字...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('確定'),
          ),
        ],
      ),
    );

    if (text != null && text.isNotEmpty) {
      setState(() {
        _annotations.add(
          TextAnnotation(
            position: position,
            text: text,
            color: _currentColor,
          ),
        );
      });
    }
  }

  /// 撤銷上一個操作
  void _undo() {
    if (_annotations.isNotEmpty) {
      setState(() {
        _annotations.removeLast();
      });
    }
  }

  /// 清除所有操作
  void _clear() {
    setState(() {
      _annotations.clear();
      _currentAnnotation = null;
    });
  }

  /// 儲存標註
  void _save() {
    // TODO: 將標註轉換為 JSONB 格式並儲存
    Navigator.pop(context, _annotations);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('標註照片'),
        actions: [
          // 撤銷
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _annotations.isEmpty ? null : _undo,
            tooltip: '撤銷',
          ),
          // 清除
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _annotations.isEmpty ? null : _clear,
            tooltip: '清除全部',
          ),
          // 儲存
          TextButton(
            onPressed: _save,
            child: const Text('完成'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 照片與標註畫布
          Expanded(
            child: _image == null
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onPanStart: (details) => _onPanStart(
                          details,
                          Size(constraints.maxWidth, constraints.maxHeight),
                        ),
                        onPanUpdate: (details) => _onPanUpdate(
                          details,
                          Size(constraints.maxWidth, constraints.maxHeight),
                        ),
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          size:
                              Size(constraints.maxWidth, constraints.maxHeight),
                          painter: AnnotationPainter(
                            image: _image!,
                            annotations: _annotations,
                            currentAnnotation: _currentAnnotation,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 工具列
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 工具選擇
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolButton(
                      icon: Icons.circle_outlined,
                      label: '圓圈',
                      tool: AnnotationTool.circle,
                    ),
                    _buildToolButton(
                      icon: Icons.arrow_forward,
                      label: '箭頭',
                      tool: AnnotationTool.arrow,
                    ),
                    _buildToolButton(
                      icon: Icons.text_fields,
                      label: '文字',
                      tool: AnnotationTool.text,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 顏色選擇
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildColorButton(Colors.red),
                    _buildColorButton(Colors.blue),
                    _buildColorButton(Colors.green),
                    _buildColorButton(Colors.yellow),
                    _buildColorButton(Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建立工具按鈕
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required AnnotationTool tool,
  }) {
    final isSelected = _currentTool == tool;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: () {
            setState(() {
              _currentTool = tool;
            });
          },
          style: IconButton.styleFrom(
            backgroundColor:
                isSelected ? theme.colorScheme.primaryContainer : null,
            foregroundColor:
                isSelected ? theme.colorScheme.onPrimaryContainer : null,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 建立顏色按鈕
  Widget _buildColorButton(Color color) {
    final isSelected = _currentColor == color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentColor = color;
          });
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey,
              width: isSelected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// 標註工具類型
enum AnnotationTool {
  none,
  circle,
  arrow,
  text,
}

/// 標註基類
abstract class Annotation {
  final Color color;

  const Annotation({required this.color});

  Map<String, dynamic> toJson();
}

/// 圓圈標註
class CircleAnnotation extends Annotation {
  final Offset center;
  final double radius;

  const CircleAnnotation({
    required this.center,
    required this.radius,
    required Color color,
  }) : super(color: color);

  CircleAnnotation copyWith({
    Offset? center,
    double? radius,
    Color? color,
  }) {
    return CircleAnnotation(
      center: center ?? this.center,
      radius: radius ?? this.radius,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'circle',
      'center': {'x': center.dx, 'y': center.dy},
      'radius': radius,
      'color': color.toARGB32(),
    };
  }
}

/// 箭頭標註
class ArrowAnnotation extends Annotation {
  final Offset start;
  final Offset end;

  const ArrowAnnotation({
    required this.start,
    required this.end,
    required Color color,
  }) : super(color: color);

  ArrowAnnotation copyWith({
    Offset? start,
    Offset? end,
    Color? color,
  }) {
    return ArrowAnnotation(
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'arrow',
      'start': {'x': start.dx, 'y': start.dy},
      'end': {'x': end.dx, 'y': end.dy},
      'color': color.toARGB32(),
    };
  }
}

/// 文字標註
class TextAnnotation extends Annotation {
  final Offset position;
  final String text;

  const TextAnnotation({
    required this.position,
    required this.text,
    required Color color,
  }) : super(color: color);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'text',
      'position': {'x': position.dx, 'y': position.dy},
      'text': text,
      'color': color.toARGB32(),
    };
  }
}
