import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/note/note.dart';
import 'package:strengthwise/models/note/note_mapper.dart';

/// NoteMapper 測試
///
/// P1 Models 層 - 10 個測試案例
void main() {
  group('NoteMapper', () {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // =========================================================================
    // fromMap
    // =========================================================================
    group('fromMap', () {
      test('正確解析完整數據', () {
        final map = {
          'id': 'note-001',
          'title': '訓練筆記',
          'textContent': '今天訓練很順利',
          'createdAt': nowMs,
          'updatedAt': nowMs,
        };

        final note = NoteMapper.fromMap(map);
        expect(note.id, 'note-001');
        expect(note.title, '訓練筆記');
        expect(note.textContent, '今天訓練很順利');
      });

      test('處理缺失 textContent', () {
        final map = {
          'id': 'note-002',
          'title': '空內容',
          'createdAt': nowMs,
          'updatedAt': nowMs,
        };

        final note = NoteMapper.fromMap(map);
        expect(note.textContent, '');
      });

      test('處理 drawingPoints null', () {
        final map = {
          'id': 'note-003',
          'title': '無繪圖',
          'drawingPoints': null,
          'createdAt': nowMs,
          'updatedAt': nowMs,
        };

        final note = NoteMapper.fromMap(map);
        expect(note.drawingPoints, isNull);
      });
    });

    // =========================================================================
    // toMap
    // =========================================================================
    group('toMap', () {
      test('正確轉換為 Map', () {
        final note = Note(
          id: 'note-004',
          title: '測試筆記',
          textContent: '內容文字',
          createdAt: now,
          updatedAt: now,
        );

        final map = NoteMapper.toMap(note);
        expect(map['id'], 'note-004');
        expect(map['title'], '測試筆記');
        expect(map['textContent'], '內容文字');
        expect(map['createdAt'], nowMs);
      });

      test('drawingPoints 為 null 時正確處理', () {
        final note = Note(
          id: 'note-005',
          title: '無繪圖筆記',
          createdAt: now,
          updatedAt: now,
          drawingPoints: null,
        );

        final map = NoteMapper.toMap(note);
        expect(map['drawingPoints'], isNull);
      });
    });

    // =========================================================================
    // fromJson / toJson
    // =========================================================================
    group('JSON 序列化', () {
      test('toJson 返回有效 JSON', () {
        final note = Note(
          id: 'note-006',
          title: 'JSON 測試',
          textContent: '序列化測試',
          createdAt: now,
          updatedAt: now,
        );

        final jsonStr = NoteMapper.toJson(note);
        expect(() => json.decode(jsonStr), returnsNormally);
      });

      test('fromJson 正確解析 JSON', () {
        final jsonStr =
            '{"id":"note-007","title":"解析測試","textContent":"從 JSON","createdAt":$nowMs,"updatedAt":$nowMs}';

        final note = NoteMapper.fromJson(jsonStr);
        expect(note.id, 'note-007');
        expect(note.title, '解析測試');
      });
    });

    // =========================================================================
    // 往返轉換
    // =========================================================================
    group('往返轉換', () {
      test('toMap → fromMap 往返正確', () {
        final original = Note(
          id: 'note-008',
          title: '往返測試',
          textContent: '這是往返測試內容',
          createdAt: now,
          updatedAt: now,
        );

        final map = NoteMapper.toMap(original);
        final restored = NoteMapper.fromMap(map);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.textContent, original.textContent);
      });

      test('toJson → fromJson 往返正確', () {
        final original = Note(
          id: 'note-009',
          title: 'JSON 往返',
          textContent: 'JSON 往返測試',
          createdAt: now,
          updatedAt: now,
        );

        final jsonStr = NoteMapper.toJson(original);
        final restored = NoteMapper.fromJson(jsonStr);

        expect(restored.id, original.id);
        expect(restored.title, original.title);
      });
    });
  });
}
