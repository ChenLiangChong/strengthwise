import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/drawing_note_model.dart';

/// DrawingNoteModel 及其巢狀類別測試
void main() {
  group('DrawingPoint', () {
    test('應該正確建立實例', () {
      const point = DrawingPoint(x: 100.0, y: 200.0, pressure: 0.8);

      expect(point.x, 100.0);
      expect(point.y, 200.0);
      expect(point.pressure, 0.8);
    });

    test('pressure 預設值為 1.0', () {
      const point = DrawingPoint(x: 0, y: 0);

      expect(point.pressure, 1.0);
    });

    test('fromJson 應該正確解析', () {
      final json = {'x': 50.0, 'y': 75.0, 'pressure': 0.5};
      final point = DrawingPoint.fromJson(json);

      expect(point.x, 50.0);
      expect(point.y, 75.0);
      expect(point.pressure, 0.5);
    });

    test('fromJson 缺少 pressure 時使用預設值', () {
      final json = {'x': 50.0, 'y': 75.0};
      final point = DrawingPoint.fromJson(json);

      expect(point.pressure, 1.0);
    });

    test('toJson 應該正確轉換', () {
      const point = DrawingPoint(x: 100.0, y: 200.0, pressure: 0.8);
      final json = point.toJson();

      expect(json['x'], 100.0);
      expect(json['y'], 200.0);
      expect(json['pressure'], 0.8);
    });

    test('toOffset 應該返回正確的 Offset', () {
      const point = DrawingPoint(x: 100.0, y: 200.0);
      final offset = point.toOffset();

      expect(offset, const Offset(100.0, 200.0));
    });
  });

  group('DrawingTool', () {
    test('應該有 4 種工具', () {
      expect(DrawingTool.values.length, 4);
    });

    test('應該包含所有預期工具', () {
      expect(DrawingTool.values, contains(DrawingTool.pencil));
      expect(DrawingTool.values, contains(DrawingTool.marker));
      expect(DrawingTool.values, contains(DrawingTool.highlighter));
      expect(DrawingTool.values, contains(DrawingTool.eraser));
    });
  });

  group('DrawingStroke', () {
    DrawingStroke createTestStroke() {
      return DrawingStroke(
        id: 'stroke-001',
        points: const [
          DrawingPoint(x: 0, y: 0),
          DrawingPoint(x: 100, y: 100),
        ],
        color: Colors.red,
        strokeWidth: 3.0,
        opacity: 0.9,
        tool: DrawingTool.pencil,
      );
    }

    test('應該正確建立實例', () {
      final stroke = createTestStroke();

      expect(stroke.id, 'stroke-001');
      expect(stroke.points.length, 2);
      expect(stroke.color, Colors.red);
      expect(stroke.strokeWidth, 3.0);
      expect(stroke.opacity, 0.9);
      expect(stroke.tool, DrawingTool.pencil);
    });

    test('toJson 應該正確轉換', () {
      final stroke = createTestStroke();
      final json = stroke.toJson();

      expect(json['id'], 'stroke-001');
      expect(json['points'], isA<List>());
      expect(json['color'], Colors.red.value);
      expect(json['stroke_width'], 3.0);
      expect(json['opacity'], 0.9);
      expect(json['tool'], 'DrawingTool.pencil');
    });

    test('fromJson → toJson 往返應該一致', () {
      final original = createTestStroke();
      final json = original.toJson();
      final restored = DrawingStroke.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.points.length, original.points.length);
      expect(restored.color.value, original.color.value);
      expect(restored.strokeWidth, original.strokeWidth);
      expect(restored.opacity, original.opacity);
      expect(restored.tool, original.tool);
    });
  });

  group('DrawingLayer', () {
    DrawingLayer createTestLayer() {
      return const DrawingLayer(
        id: 'layer-001',
        name: '繪圖層',
        isVisible: true,
        isLocked: false,
        strokes: [],
      );
    }

    test('應該正確建立實例', () {
      final layer = createTestLayer();

      expect(layer.id, 'layer-001');
      expect(layer.name, '繪圖層');
      expect(layer.isVisible, isTrue);
      expect(layer.isLocked, isFalse);
      expect(layer.strokes, isEmpty);
    });

    test('fromJson 預設值應該正確', () {
      final json = {
        'id': 'layer-001',
        'name': 'Test',
        // 不提供 is_visible 和 is_locked
      };
      final layer = DrawingLayer.fromJson(json);

      expect(layer.isVisible, isTrue);
      expect(layer.isLocked, isFalse);
    });

    test('copyWith 應該正確複製', () {
      final original = createTestLayer();
      final copied = original.copyWith(isLocked: true);

      expect(copied.id, original.id);
      expect(copied.isLocked, isTrue);
    });

    test('toJson 應該正確轉換', () {
      final layer = createTestLayer();
      final json = layer.toJson();

      expect(json['id'], 'layer-001');
      expect(json['name'], '繪圖層');
      expect(json['is_visible'], isTrue);
      expect(json['is_locked'], isFalse);
      expect(json['strokes'], isEmpty);
    });
  });

  group('DrawingNoteModel', () {
    final testDate = DateTime(2026, 1, 14);

    DrawingNoteModel createTestModel() {
      return DrawingNoteModel(
        id: 'note-001',
        sessionNoteId: 'session-001',
        templateType: 'note1',
        layers: const [],
        createdAt: testDate,
        updatedAt: testDate,
        canvasWidth: 1024.0,
        canvasHeight: 768.0,
      );
    }

    test('應該正確建立實例', () {
      final model = createTestModel();

      expect(model.id, 'note-001');
      expect(model.sessionNoteId, 'session-001');
      expect(model.templateType, 'note1');
      expect(model.canvasWidth, 1024.0);
      expect(model.canvasHeight, 768.0);
    });

    test('預設畫布尺寸應該是 800x600', () {
      final model = DrawingNoteModel(
        id: 'test',
        sessionNoteId: 'session',
        templateType: 'note1',
        layers: const [],
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(model.canvasWidth, 800.0);
      expect(model.canvasHeight, 600.0);
    });

    test('copyWith 應該正確複製', () {
      final original = createTestModel();
      final copied = original.copyWith(templateType: 'note2');

      expect(copied.id, original.id);
      expect(copied.templateType, 'note2');
    });

    test('toJson 應該包含所有欄位', () {
      final model = createTestModel();
      final json = model.toJson();

      expect(json['id'], 'note-001');
      expect(json['session_note_id'], 'session-001');
      expect(json['template_type'], 'note1');
      expect(json['layers'], isA<List>());
      expect(json['canvas_width'], 1024.0);
      expect(json['canvas_height'], 768.0);
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNotNull);
    });
  });

  group('TemplateType', () {
    test('應該有 4 種模板', () {
      expect(TemplateType.values.length, 4);
    });

    group('assetPath', () {
      test('note1 → assets/templates/note1.png', () {
        expect(TemplateType.note1.assetPath, 'assets/templates/note1.png');
      });

      test('所有模板都有 asset 路徑', () {
        for (final template in TemplateType.values) {
          expect(template.assetPath, contains('assets/templates/'));
          expect(template.assetPath, endsWith('.png'));
        }
      });
    });

    group('displayName', () {
      test('note1 → 三視圖（前/側/背）', () {
        expect(TemplateType.note1.displayName, '三視圖（前/側/背）');
      });

      test('note2 → 前視圖', () {
        expect(TemplateType.note2.displayName, '前視圖');
      });

      test('所有模板都有顯示名稱', () {
        for (final template in TemplateType.values) {
          expect(template.displayName, isNotEmpty);
        }
      });
    });
  });
}
