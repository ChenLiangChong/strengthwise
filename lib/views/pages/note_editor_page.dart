import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';

class NoteEditorPage extends StatefulWidget {
  final Note? note;
  final Function(Note) onSave;

  const NoteEditorPage({
    Key? key,
    this.note,
    required this.onSave,
  }) : super(key: key);

  @override
  _NoteEditorPageState createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  
  late Note _currentNote;
  List<DrawingPointUI> _currentDrawing = [];
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 3.0;
  double _eraserStrokeWidth = 15.0;
  bool _isModified = false;
  bool _isErasing = false;
  List<List<DrawingPointUI>> _drawingHistory = [];
  final List<double> _eraserSizes = [10.0, 20.0, 30.0, 40.0, 50.0];
  Timer? _autoSaveTimer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 如果傳入了筆記，編輯現有筆記，否則創建新筆記
    if (widget.note != null) {
      _currentNote = widget.note!;
    } else {
      _currentNote = Note(
        id: 'note_${DateTime.now().millisecondsSinceEpoch}',
        title: '新筆記',
        textContent: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    
    _titleController = TextEditingController(text: _currentNote.title);
    _contentController = TextEditingController(text: _currentNote.textContent);
    
    // 加載繪圖數據
    if (_currentNote.drawingPoints != null) {
      _currentDrawing = _currentNote.drawingPoints!.map((point) {
        return DrawingPointUI(
          point.offset,
          Paint()
            ..color = point.color
            ..strokeWidth = point.strokeWidth
            ..strokeCap = StrokeCap.round,
        );
      }).toList();
    }
    
    // 如果有現有繪圖數據，添加到歷史記錄
    if (_currentDrawing.isNotEmpty) {
      _drawingHistory.add(List.from(_currentDrawing));
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    // 取消可能正在進行的自動保存
    _autoSaveTimer?.cancel();
    
    // 更新筆記數據
    _currentNote.title = _titleController.text;
    _currentNote.textContent = _contentController.text;
    _currentNote.updatedAt = DateTime.now();
    
    // 轉換繪圖數據
    if (_currentDrawing.isNotEmpty) {
      _currentNote.drawingPoints = _currentDrawing.map((point) {
        return DrawingPoint(
          offset: point.offset,
          color: point.paint.color,
          strokeWidth: point.paint.strokeWidth,
        );
      }).toList();
    }
    
    // 調用保存回調
    widget.onSave(_currentNote);
    
    // 重置修改標記並關閉頁面
    _isModified = false;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titleController.text),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.text_fields), text: '文字'),
              Tab(icon: Icon(Icons.draw), text: '繪圖'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildTextEditor(),
            _buildDrawingCanvas(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextEditor() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: '筆記標題',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _isModified = true;
              });
              _triggerAutoSave();
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: TextField(
              controller: _contentController,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: '開始輸入筆記內容...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (value) {
                setState(() {
                  _isModified = true;
                });
                _triggerAutoSave();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingCanvas() {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            setState(() {
              _isModified = true;
              
              if (_isErasing) {
                _currentDrawing.add(
                  DrawingPointUI(
                    details.localPosition,
                    Paint()
                      ..color = Colors.white
                      ..strokeWidth = _eraserStrokeWidth
                      ..strokeCap = StrokeCap.round,
                  ),
                );
              } else {
                _currentDrawing.add(
                  DrawingPointUI(
                    details.localPosition,
                    Paint()
                      ..color = _currentColor
                      ..strokeWidth = _currentStrokeWidth
                      ..strokeCap = StrokeCap.round,
                  ),
                );
              }
            });
          },
          onPanUpdate: (details) {
            setState(() {
              if (_isErasing) {
                _currentDrawing.add(
                  DrawingPointUI(
                    details.localPosition,
                    Paint()
                      ..color = Colors.white
                      ..strokeWidth = _eraserStrokeWidth
                      ..strokeCap = StrokeCap.round,
                  ),
                );
              } else {
                _currentDrawing.add(
                  DrawingPointUI(
                    details.localPosition,
                    Paint()
                      ..color = _currentColor
                      ..strokeWidth = _currentStrokeWidth
                      ..strokeCap = StrokeCap.round,
                  ),
                );
              }
            });
          },
          onPanEnd: (details) {
            setState(() {
              _currentDrawing.add(DrawingPointUI.empty);
              // 當繪圖結束時保存當前狀態
              _saveDrawingState();
              // 觸發自動保存
              _triggerAutoSave();
            });
          },
          child: CustomPaint(
            painter: DrawingPainter(points: _currentDrawing),
            size: Size.infinite,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildColorSelector(Colors.black),
                _buildColorSelector(Colors.red),
                _buildColorSelector(Colors.blue),
                _buildColorSelector(Colors.green),
                
                const SizedBox(width: 16),
                
                // 撤銷按鈕
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: _drawingHistory.length > 0 ? _undoDrawing : null,
                ),
                
                // 橡皮擦按鈕
                IconButton(
                  icon: Icon(_isErasing ? Icons.edit_off : Icons.edit),
                  color: _isErasing ? Colors.red : null,
                  onPressed: _toggleEraser,
                ),
                
                if (_isErasing)
                  IconButton(
                    icon: const Icon(Icons.line_weight),
                    onPressed: _showEraserSizeOptions,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.line_weight),
                    onPressed: _showStrokeWidthDialog,
                  ),
                
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      _currentDrawing.clear();
                      _drawingHistory.clear();
                      _isModified = true;
                    });
                    _triggerAutoSave();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector(Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _currentColor == color ? Colors.grey[600]! : Colors.grey[300]!,
            width: _currentColor == color ? 2 : 1,
          ),
        ),
      ),
    );
  }

  void _showStrokeWidthDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double selectedWidth = _currentStrokeWidth;
        
        return AlertDialog(
          title: const Text('選擇筆觸粗細'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: selectedWidth,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: selectedWidth.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        selectedWidth = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: selectedWidth,
                    width: 100,
                    color: _currentColor,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStrokeWidth = selectedWidth;
                });
                Navigator.pop(context);
              },
              child: const Text('確認'),
            ),
          ],
        );
      },
    );
  }

  // 切換橡皮擦模式，點擊時顯示大小選擇
  void _toggleEraser() {
    if (!_isErasing) {
      // 如果當前不是橡皮擦模式，切換模式並顯示選擇對話框
      setState(() {
        _isErasing = true;
      });
      _showEraserSizeOptions(); // 顯示橡皮擦大小選擇
    } else {
      // 如果當前是橡皮擦模式，直接切換回繪圖模式
      setState(() {
        _isErasing = false;
      });
    }
    _triggerAutoSave();
  }

  // 顯示橡皮擦大小選擇選項
  void _showEraserSizeOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 150,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '選擇橡皮擦大小',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _eraserSizes.map((size) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _eraserStrokeWidth = size;
                          });
                          Navigator.pop(context);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _eraserStrokeWidth == size 
                                      ? Colors.blue 
                                      : Colors.grey[400]!,
                                  width: _eraserStrokeWidth == size ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('${size.toInt()}'),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (!_isModified) return true;
    
    // 顯示確認對話框
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認離開'),
        content: const Text('你有未保存的修改，確定要離開嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('離開'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // 保存當前繪圖狀態到歷史記錄
  void _saveDrawingState() {
    if (_currentDrawing.isNotEmpty) {
      _drawingHistory.add(List.from(_currentDrawing));
      // 限制歷史記錄數量，防止內存過度使用
      if (_drawingHistory.length > 20) {
        _drawingHistory.removeAt(0);
      }
    }
  }

  // 撤銷上一步繪圖操作
  void _undoDrawing() {
    if (_drawingHistory.length > 1) {
      setState(() {
        _drawingHistory.removeLast();
        _currentDrawing = List.from(_drawingHistory.last);
        _isModified = true;
      });
      _triggerAutoSave();
    } else if (_drawingHistory.length == 1) {
      setState(() {
        _currentDrawing = [];
        _drawingHistory = [];
        _isModified = true;
      });
      _triggerAutoSave();
    }
  }

  // 添加新方法：觸發自動保存（帶防抖功能）
  void _triggerAutoSave() {
    // 取消現有計時器
    _autoSaveTimer?.cancel();
    
    // 設置新計時器，1.5秒後執行保存
    _autoSaveTimer = Timer(Duration(milliseconds: 1500), () {
      _autoSaveNote();
    });
  }

  // 添加新方法：執行自動保存
  Future<void> _autoSaveNote() async {
    if (_isSaving || !_isModified) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // 更新筆記數據
      _currentNote.title = _titleController.text;
      _currentNote.textContent = _contentController.text;
      _currentNote.updatedAt = DateTime.now();
      
      // 轉換繪圖數據
      if (_currentDrawing.isNotEmpty) {
        _currentNote.drawingPoints = _currentDrawing.map((point) {
          return DrawingPoint(
            offset: point.offset,
            color: point.paint.color,
            strokeWidth: point.paint.strokeWidth,
          );
        }).toList();
      }
      
      // 調用保存回調（但不關閉頁面）
      widget.onSave(_currentNote);
      
      // 重置修改標記
      _isModified = false;
    } catch (e) {
      print('自動保存失敗: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

// 繪圖點數據類 - 使用Flutter UI元素
class DrawingPointUI {
  final Offset offset;
  final Paint paint;
  
  DrawingPointUI(this.offset, this.paint);
  
  // 表示一筆結束
  static DrawingPointUI get empty => DrawingPointUI(
    const Offset(-1, -1),
    Paint()
      ..strokeCap = StrokeCap.round,
  );
  
  bool get isEnd => offset.dx == -1 && offset.dy == -1;
}

// 繪圖畫布
class DrawingPainter extends CustomPainter {
  final List<DrawingPointUI> points;
  
  DrawingPainter({required this.points});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      
      if (current.isEnd || next.isEnd) continue;
      
      canvas.drawLine(current.offset, next.offset, current.paint);
    }
  }
  
  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
} 