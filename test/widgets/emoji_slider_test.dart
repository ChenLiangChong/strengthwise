import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/views/pages/readiness/widgets/emoji_slider.dart';

/// EmojiSlider Widget 測試
///
/// P4 優先級 - 7 個測試案例
void main() {
  // 標準的 5 個表情
  const emojis = ['😫', '😕', '😐', '🙂', '😄'];

  group('EmojiSlider', () {
    // =========================================================================
    // P4-246: 基本渲染
    // =========================================================================
    testWidgets('正確渲染 title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiSlider(
              title: '睡眠品質',
              value: 3,
              emojis: emojis,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('睡眠品質'), findsOneWidget);
    });

    // =========================================================================
    // P4-247: 值變更回調
    // =========================================================================
    testWidgets('顯示 Slider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiSlider(
              title: '測試',
              value: 3,
              emojis: emojis,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    // =========================================================================
    // P4-248: 邊界值
    // =========================================================================
    testWidgets('value=1 時正確顯示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiSlider(
              title: '測試',
              value: 1,
              emojis: emojis,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(EmojiSlider), findsOneWidget);
    });

    testWidgets('value=5 時正確顯示', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiSlider(
              title: '測試',
              value: 5,
              emojis: emojis,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(EmojiSlider), findsOneWidget);
    });

    // =========================================================================
    // P4-249: 表情顯示
    // =========================================================================
    testWidgets('顯示當前選中的表情', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmojiSlider(
              title: '測試',
              value: 3, // 對應 '😐'
              emojis: emojis,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // 應該顯示第 3 個表情（索引 2）
      expect(find.text('😐'), findsWidgets);
    });
  });

  group('HoursSlider', () {
    // =========================================================================
    // P4-250: 基本渲染
    // =========================================================================
    testWidgets('正確渲染 title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoursSlider(
              title: '睡眠時數',
              value: 7.0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('睡眠時數'), findsOneWidget);
    });

    testWidgets('顯示小時數', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HoursSlider(
              title: '睡眠時數',
              value: 8.0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // 顯示 "8.0 小時"
      expect(find.textContaining('8.0'), findsOneWidget);
    });
  });
}
