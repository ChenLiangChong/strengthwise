import 'package:flutter_test/flutter_test.dart';

/// P10 Edge Cases 測試
///
/// 邊界條件和特殊情況測試
void main() {
  group('邊界條件測試', () {
    // =========================================================================
    // P10-347: 空列表處理
    // =========================================================================
    group('空列表', () {
      test('空列表長度為 0', () {
        final List<int> emptyList = [];
        expect(emptyList.length, 0);
        expect(emptyList.isEmpty, isTrue);
      });

      test('空列表 firstOrNull 返回 null', () {
        final List<int> emptyList = [];
        expect(emptyList.firstOrNull, isNull);
      });

      test('空列表 map 返回空列表', () {
        final List<int> emptyList = [];
        final result = emptyList.map((e) => e * 2).toList();
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // P10-348: 超長文字處理
    // =========================================================================
    group('超長文字', () {
      test('10000 字串長度正確', () {
        final longText = 'a' * 10000;
        expect(longText.length, 10000);
      });

      test('超長字串可以 substring', () {
        final longText = 'a' * 10000;
        final sub = longText.substring(0, 100);
        expect(sub.length, 100);
      });

      test('超長字串 trim 正常', () {
        final longText = '   ${'a' * 10000}   ';
        expect(longText.trim().length, 10000);
      });
    });

    // =========================================================================
    // P10-349: 特殊字符
    // =========================================================================
    group('特殊字符', () {
      test('Emoji 字串長度', () {
        final emoji = '😀😁😂🤣😃';
        expect(emoji.runes.length, 5); // 使用 runes 計算真實字符數
      });

      test('換行符處理', () {
        final text = 'line1\nline2\nline3';
        final lines = text.split('\n');
        expect(lines.length, 3);
      });

      test('Tab 字符處理', () {
        final text = 'col1\tcol2\tcol3';
        final cols = text.split('\t');
        expect(cols.length, 3);
      });

      test('中文字串正常處理', () {
        final chinese = '測試中文字串';
        expect(chinese.length, 6);
      });
    });

    // =========================================================================
    // P10-352: 閏年處理
    // =========================================================================
    group('閏年', () {
      test('2024 是閏年', () {
        final feb29 = DateTime(2024, 2, 29);
        expect(feb29.month, 2);
        expect(feb29.day, 29);
      });

      test('2023 不是閏年', () {
        // 2023-02-29 會自動調整到 3 月
        final feb29 = DateTime(2023, 2, 29);
        expect(feb29.month, 3);
        expect(feb29.day, 1);
      });

      test('閏年 2 月有 29 天', () {
        final lastDayFeb2024 = DateTime(2024, 3, 0); // 2 月最後一天
        expect(lastDayFeb2024.day, 29);
      });

      test('非閏年 2 月有 28 天', () {
        final lastDayFeb2023 = DateTime(2023, 3, 0);
        expect(lastDayFeb2023.day, 28);
      });
    });

    // =========================================================================
    // P10-350: 時區處理
    // =========================================================================
    group('時區', () {
      test('UTC 時間轉換', () {
        final utc = DateTime.utc(2024, 1, 1, 12, 0);
        expect(utc.isUtc, isTrue);
      });

      test('toLocal 轉換', () {
        final utc = DateTime.utc(2024, 1, 1, 12, 0);
        final local = utc.toLocal();
        expect(local.isUtc, isFalse);
      });
    });

    // =========================================================================
    // P10-351: 跨日時間
    // =========================================================================
    group('跨日時間', () {
      test('23:30 加 2 小時跨日', () {
        final time = DateTime(2024, 1, 1, 23, 30);
        final later = time.add(const Duration(hours: 2));
        expect(later.day, 2);
        expect(later.hour, 1);
        expect(later.minute, 30);
      });

      test('Duration.inMinutes 計算正確', () {
        final start = DateTime(2024, 1, 1, 23, 0);
        final end = DateTime(2024, 1, 2, 1, 0);
        final duration = end.difference(start);
        expect(duration.inMinutes, 120);
      });
    });

    // =========================================================================
    // P10-353: 大量資料
    // =========================================================================
    group('大量資料', () {
      test('生成 1000 項列表', () {
        final list = List.generate(1000, (i) => i);
        expect(list.length, 1000);
      });

      test('大量資料過濾', () {
        final list = List.generate(1000, (i) => i);
        final filtered = list.where((e) => e % 2 == 0).toList();
        expect(filtered.length, 500);
      });

      test('大量資料排序', () {
        final list = List.generate(1000, (i) => 999 - i);
        list.sort();
        expect(list.first, 0);
        expect(list.last, 999);
      });
    });
  });

  group('型別安全測試', () {
    // =========================================================================
    // Null 安全
    // =========================================================================
    test('nullable 變數處理', () {
      String? nullableStr;
      expect(nullableStr, isNull);
      expect(nullableStr?.length, isNull);
    });

    test('?? 運算符', () {
      String? nullableStr;
      final result = nullableStr ?? 'default';
      expect(result, 'default');
    });

    test('?. 運算符', () {
      String? nullableStr = 'hello';
      expect(nullableStr?.toUpperCase(), 'HELLO');
    });
  });
}
