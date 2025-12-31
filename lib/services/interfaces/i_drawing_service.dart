import '../../models/drawing_note_model.dart';

/// 繪圖服務 Interface（完全解耦合）
abstract class IDrawingService {
  /// 創建繪圖筆記（綁定到 Session Note）
  Future<DrawingNoteModel> createDrawing({
    required String sessionNoteId,
    required String templateType,
  });

  /// 保存繪圖筆記（更新 drawing_data JSONB）
  Future<void> saveDrawing(DrawingNoteModel drawing);

  /// 讀取繪圖筆記（從 Session Note，可指定模板類型）
  Future<DrawingNoteModel?> getDrawing(String sessionNoteId, {String? templateType});

  /// 刪除繪圖筆記
  Future<void> deleteDrawing(String drawingId);

  /// 匯出為圖片（返回 PNG bytes）
  Future<List<int>> exportToPng(DrawingNoteModel drawing);
}

