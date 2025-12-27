import 'package:flutter/material.dart';
import '../../../models/note_model.dart';
import '../../../controllers/interfaces/i_note_controller.dart';
import '../../../services/core/error_handling_service.dart';
import '../../../services/service_locator.dart';
import '../../../utils/notification_utils.dart';
import 'widgets/note_title_field.dart';
import 'widgets/note_text_editor.dart';
import 'widgets/drawing_area.dart';
import 'widgets/drawing_toolbar.dart';

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
          NoteTitleField(
            controller: _titleController,
            enabled: !_isSaving,
          ),
          
          // 內容區域
          Expanded(
            child: _isDrawing
                ? DrawingArea(
                    drawingPoints: _drawingPoints,
                    isDrawing: _isDrawing,
                    onAddDrawingPoint: _addDrawingPoint,
                  )
                : NoteTextEditor(
                    controller: _contentController,
                    enabled: !_isSaving,
                  ),
          ),
        ],
      ),
      // 繪圖模式的工具欄
      bottomNavigationBar: _isDrawing
          ? DrawingToolbar(
              currentColor: _currentColor,
              currentStrokeWidth: _currentStrokeWidth,
              onClearDrawing: _clearDrawing,
              onColorChanged: (color) {
                setState(() {
                  _currentColor = color;
                });
              },
              onStrokeWidthChanged: (width) {
                setState(() {
                  _currentStrokeWidth = width;
                });
              },
            )
          : null,
    );
  }
} 