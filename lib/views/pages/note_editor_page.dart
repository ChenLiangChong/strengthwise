import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../controllers/interfaces/i_note_controller.dart';
import '../../services/error_handling_service.dart';
import '../../services/service_locator.dart';
import '../../utils/notification_utils.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note;
  
  const NoteEditorPage({
    super.key,
    this.note,
  });

  @override
  _NoteEditorPageState createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final INoteController _controller;
  late final ErrorHandlingService _errorService;
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  List<DrawingPoint>? _drawingPoints;
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 3.0;
  bool _isDrawing = false;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // 從服務定位器獲取控制器和服務
    _controller = serviceLocator<INoteController>();
    _errorService = serviceLocator<ErrorHandlingService>();
    
    // 初始化筆記內容
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.textContent;
      _drawingPoints = widget.note!.drawingPoints;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  Future<void> _saveNote() async {
    // 驗證標題不能為空
    if (_titleController.text.trim().isEmpty) {
      NotificationUtils.showWarning(context, '請輸入筆記標題');
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final now = DateTime.now();
      
      // 創建或更新筆記
      if (widget.note == null) {
        // 創建新筆記
        await _controller.createNote(
          _titleController.text.trim(),
          _contentController.text,
          _drawingPoints,
        );
      } else {
        // 更新現有筆記
        final updatedNote = Note(
          id: widget.note!.id,
          title: _titleController.text.trim(),
          textContent: _contentController.text,
          drawingPoints: _drawingPoints,
          createdAt: widget.note!.createdAt,
          updatedAt: now,
        );
        
        await _controller.updateNote(updatedNote);
      }
      
      if (!mounted) return;
      
      // 返回true表示成功保存
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });
      
      _errorService.handleError(context, e, customMessage: '保存筆記失敗');
    }
  }
  
  void _toggleDrawingMode() {
    setState(() {
      _isDrawing = !_isDrawing;
    });
  }
  
  void _clearDrawing() {
    setState(() {
      _drawingPoints = null;
    });
  }
  
  void _addDrawingPoint(Offset offset, PointerEvent event) {
    if (!_isDrawing) return;
    
    setState(() {
      _drawingPoints ??= [];
      _drawingPoints!.add(DrawingPoint(
        offset: offset,
        color: _currentColor,
        strokeWidth: _currentStrokeWidth,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? '新建筆記' : '編輯筆記'),
        actions: [
          // 繪圖模式切換按鈕
          IconButton(
            icon: Icon(_isDrawing ? Icons.edit : Icons.draw),
            tooltip: _isDrawing ? '切換到文本模式' : '切換到繪圖模式',
            onPressed: _toggleDrawingMode,
          ),
          // 保存按鈕
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存筆記',
            onPressed: _isSaving ? null : _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          // 標題輸入框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '標題',
                border: OutlineInputBorder(),
              ),
              enabled: !_isSaving,
            ),
          ),
          
          // 內容區域
          Expanded(
            child: _isDrawing
                ? _buildDrawingArea()
                : _buildTextEditor(),
          ),
        ],
      ),
      // 繪圖模式的工具欄
      bottomNavigationBar: _isDrawing ? _buildDrawingToolbar() : null,
    );
  }
  
  Widget _buildTextEditor() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _contentController,
        decoration: const InputDecoration(
          labelText: '內容',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        enabled: !_isSaving,
      ),
    );
  }
  
  Widget _buildDrawingArea() {
    return Stack(
      children: [
        // 繪圖區域
        Listener(
          onPointerDown: (event) => _addDrawingPoint(event.localPosition, event),
          onPointerMove: (event) => _addDrawingPoint(event.localPosition, event),
          child: CustomPaint(
            painter: DrawingPainter(_drawingPoints),
            size: Size.infinite,
          ),
        ),
        
        // 顯示繪圖指示
        if (_isDrawing)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '繪圖模式：使用手指在畫面上繪圖',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildDrawingToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 清空繪圖
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空繪圖',
            onPressed: _clearDrawing,
          ),
          // 線條顏色選擇
          _buildColorCircle(Colors.black),
          _buildColorCircle(Colors.red),
          _buildColorCircle(Colors.blue),
          _buildColorCircle(Theme.of(context).colorScheme.secondary),
          // 線條粗細選擇
          DropdownButton<double>(
            value: _currentStrokeWidth,
            items: [1.0, 3.0, 5.0, 8.0, 12.0]
                .map((width) => DropdownMenuItem<double>(
                      value: width,
                      child: Text('${width.toInt()} px'),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentStrokeWidth = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildColorCircle(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentColor = color;
        });
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
                  color: _currentColor == color ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.outlineVariant,
            width: _currentColor == color ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

/// 繪圖板的自定義繪製器
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint>? points;
  
  DrawingPainter(this.points);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (points == null || points!.isEmpty) return;
    
    for (final point in points!) {
      canvas.drawCircle(point.offset, point.strokeWidth / 2, point.paint);
      
      // 如果點超過一個，則繪製線段連接它們
      for (int i = 0; i < points!.length - 1; i++) {
        if (i < points!.length - 1) {
          final p1 = points![i];
          final p2 = points![i + 1];
          canvas.drawLine(p1.offset, p2.offset, p1.paint);
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.points != points;
  }
} 