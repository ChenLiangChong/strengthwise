import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:strengthwise/utils/datetime_utils.dart';
import '../models/drawing_note_model.dart';
import 'interfaces/i_drawing_service.dart';

/// 繪圖服務 Supabase 實現
class DrawingServiceSupabase implements IDrawingService {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  DrawingServiceSupabase(this._supabase);

  @override
  Future<DrawingNoteModel> createDrawing({
    required String sessionNoteId,
    required String templateType,
  }) async {
    debugPrint('[DRAWING_SERVICE] 🆕 開始創建新繪圖');
    debugPrint('[DRAWING_SERVICE] 🆔 筆記 ID: $sessionNoteId');
    debugPrint('[DRAWING_SERVICE] 📋 模板類型: $templateType');
    
    final now = DateTime.now();
    final drawing = DrawingNoteModel(
      id: _uuid.v4(),
      sessionNoteId: sessionNoteId,
      templateType: templateType,
      layers: [
        // 預設創建一個繪圖層（底圖層由 UI 渲染，不存儲）
        DrawingLayer(
          id: _uuid.v4(),
          name: '繪圖層 1',
          isVisible: true,
          isLocked: false,
          strokes: [],
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
    
    debugPrint('[DRAWING_SERVICE] 🆔 生成繪圖 ID: ${drawing.id}');

    // ⭐ 暫存模式：臨時 ID 不保存到資料庫
    if (sessionNoteId.startsWith('temp-')) {
      debugPrint('[DRAWING_SERVICE] 💾 臨時 Session ID，不保存到資料庫');
      return drawing; // 直接返回繪圖對象，不查詢和更新資料庫
    }

    // 讀取現有的 content
    final response = await _supabase
        .from('session_notes')
        .select('content')
        .eq('id', sessionNoteId)
        .maybeSingle();

    final Map<String, dynamic> content = response?['content'] ?? {};
    final List<dynamic> visualElements = List.from(content['visual_elements'] ?? []);
    
    debugPrint('[DRAWING_SERVICE] 📦 現有視覺元素數量: ${visualElements.length}');

    // 添加新的 drawing 到 visual_elements
    visualElements.add({
      'type': 'drawing',
      'template_type': templateType,
      'drawing_data': drawing.toJson(),
      'created_at': DateTimeUtils.formatToUtcIso(now),
      'updated_at': DateTimeUtils.formatToUtcIso(now),
    });
    
    debugPrint('[DRAWING_SERVICE] ➕ 添加後視覺元素數量: ${visualElements.length}');

    content['visual_elements'] = visualElements;

    // 更新 session_notes.content
    await _supabase.from('session_notes').update({
      'content': content,
    }).eq('id', sessionNoteId);
    
    debugPrint('[DRAWING_SERVICE] ✅ 繪圖創建並保存成功');

    return drawing;
  }

  @override
  Future<void> saveDrawing(DrawingNoteModel drawing) async {
    debugPrint('[DRAWING_SERVICE] 🎨 開始保存繪圖');
    debugPrint('[DRAWING_SERVICE] 🆔 筆記 ID: ${drawing.sessionNoteId}');
    debugPrint('[DRAWING_SERVICE] 📋 模板類型: ${drawing.templateType}');
    debugPrint('[DRAWING_SERVICE] 🆔 繪圖 ID: ${drawing.id}');
    
    // ⭐ 暫存模式：如果 sessionNoteId 是臨時 ID，不保存到資料庫
    if (drawing.sessionNoteId.startsWith('temp-')) {
      debugPrint('[DRAWING_SERVICE] 💾 臨時繪圖，不保存到資料庫（Session ID: ${drawing.sessionNoteId}）');
      return; // 跳過資料庫操作
    }
    
    final updatedDrawing = drawing.copyWith(
      updatedAt: DateTime.now(),
    );

    // 讀取現有的 content
    final response = await _supabase
        .from('session_notes')
        .select('content')
        .eq('id', drawing.sessionNoteId)
        .maybeSingle();

    final Map<String, dynamic> content = response?['content'] ?? {};
    final List<dynamic> visualElements = List.from(content['visual_elements'] ?? []);
    
    debugPrint('[DRAWING_SERVICE] 📦 現有視覺元素數量: ${visualElements.length}');

    // 找到並更新現有的 drawing（根據 drawing.id 唯一識別）
    bool found = false;
    for (int i = 0; i < visualElements.length; i++) {
      if (visualElements[i]['type'] == 'drawing' &&
          visualElements[i]['drawing_data'] != null) {
        final existingDrawingId = visualElements[i]['drawing_data']['id'] as String?;
        
        // 根據繪圖的唯一 ID 判斷是否為同一個繪圖
        if (existingDrawingId == drawing.id) {
          debugPrint('[DRAWING_SERVICE] 🔄 找到現有繪圖（ID: ${drawing.id}），更新中...');
          visualElements[i] = {
            'type': 'drawing',
            'template_type': updatedDrawing.templateType,
            'drawing_data': updatedDrawing.toJson(),
            'created_at': visualElements[i]['created_at'] ?? DateTimeUtils.formatToUtcIso(updatedDrawing.createdAt),
            'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
          };
          found = true;
          break;
        }
      }
    }

    // 如果找不到，添加新的
    if (!found) {
      debugPrint('[DRAWING_SERVICE] ➕ 添加新繪圖');
      visualElements.add({
        'type': 'drawing',
        'template_type': updatedDrawing.templateType,
        'drawing_data': updatedDrawing.toJson(),
        'created_at': DateTimeUtils.formatToUtcIso(updatedDrawing.createdAt),
        'updated_at': DateTimeUtils.formatToUtcIso(updatedDrawing.updatedAt),
      });
    }

    content['visual_elements'] = visualElements;
    
    debugPrint('[DRAWING_SERVICE] 📦 更新後視覺元素數量: ${visualElements.length}');

    // 更新 session_notes.content
    await _supabase.from('session_notes').update({
      'content': content,
    }).eq('id', drawing.sessionNoteId);
    
    debugPrint('[DRAWING_SERVICE] ✅ 繪圖保存成功');
  }

  @override
  Future<DrawingNoteModel?> getDrawing(String sessionNoteId, {String? templateType}) async {
    // ⭐ 暫存模式：臨時 ID 不查詢資料庫
    if (sessionNoteId.startsWith('temp-')) {
      debugPrint('[DRAWING_SERVICE] 💾 臨時 Session ID，從暫存區載入');
      return null; // 返回 null，Controller 會創建新繪圖
    }
    
    final response = await _supabase
        .from('session_notes')
        .select('content')
        .eq('id', sessionNoteId)
        .maybeSingle();

    if (response == null || response['content'] == null) {
      return null;
    }

    final content = response['content'] as Map<String, dynamic>;
    final visualElements = content['visual_elements'] as List<dynamic>?;

    if (visualElements == null || visualElements.isEmpty) {
      return null;
    }

    // 找到符合條件的 drawing 元素
    for (final element in visualElements) {
      if (element['type'] == 'drawing' && element['drawing_data'] != null) {
        // 如果指定了 templateType，則必須匹配
        if (templateType != null && element['template_type'] != templateType) {
          continue;
        }
        
        final drawing = DrawingNoteModel.fromJson(
          element['drawing_data'] as Map<String, dynamic>,
        );
        
        // ⭐ 修正 sessionNoteId：使用當前筆記的真實 ID（而非 JSON 中保存的舊值）
        final correctedDrawing = drawing.copyWith(sessionNoteId: sessionNoteId);
        debugPrint('[DRAWING_SERVICE] ✅ 載入繪圖成功，修正 sessionNoteId: $sessionNoteId');
        
        return correctedDrawing;
      }
    }

    return null;
  }

  @override
  Future<void> deleteDrawing(String drawingId) async {
    // 從所有 session_notes 中找到並刪除該 drawing
    // 注意：這需要先查詢所有可能的筆記
    final response = await _supabase
        .from('session_notes')
        .select('id, content')
        .not('content->visual_elements', 'is', null);

    for (final note in response as List<dynamic>) {
      final content = note['content'] as Map<String, dynamic>;
      final visualElements = content['visual_elements'] as List<dynamic>?;

      if (visualElements != null) {
        // 移除匹配的 drawing
        final filtered = visualElements.where((element) {
          return !(element['type'] == 'drawing' &&
              element['drawing_data']?['id'] == drawingId);
        }).toList();

        if (filtered.length != visualElements.length) {
          // 有刪除，更新資料庫
          content['visual_elements'] = filtered;
          await _supabase.from('session_notes').update({
            'content': content,
          }).eq('id', note['id']);
        }
      }
    }
  }

  @override
  Future<List<int>> exportToPng(DrawingNoteModel drawing) async {
    // TODO: 實作 PNG 匯出（使用 Flutter 的 Picture.toImage）
    throw UnimplementedError('PNG 匯出功能尚未實作');
  }
}

